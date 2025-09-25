#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# --- Configuration ---
# Define the directory where the dotfiles are located.
# We get the directory of the script itself to make it portable.
readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of packages to stow
STOW_PACKAGES=(
    git
    nvim
    zsh
    ghostty
)

# --- Helper Functions ---

# Print a message to the console.
msg() {
    echo -e "\n\e[1;32m[INFO]\e[0m $@"
}

# --- Main Logic ---

# Function to install dependencies based on the OS
install_dependencies() {
    msg "Installing dependencies..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ "$(id -u)" == "0" ]]; then
            msg "Running as root. Installing packages directly with apt..."
            apt-get update -y
            apt-get install -y git stow curl zsh vim
        else
            msg "Requesting sudo access for Linux package installation..."
            sudo apt-get update -y
            sudo apt-get install -y git stow curl zsh vim
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # On macOS, check for and install Homebrew if it's missing
        if ! command -v brew &> /dev/null; then
            msg "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        msg "Installing packages with Homebrew..."
        brew install git stow curl zsh nvim
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Function to stow the dotfiles
stow_dotfiles() {
    if ! command -v stow &> /dev/null; then
        msg "'stow' command not found. Please install it first."
        exit 1
    fi

    msg "Stowing dotfiles from $DOTFILES_DIR..."
    cd "$DOTFILES_DIR"

    for pkg in "${STOW_PACKAGES[@]}"; do
        msg "Stowing $pkg..."
        # Special handling for nvim and ghostty which need their parent dirs created
        if [[ "$pkg" == "nvim" ]] || [[ "$pkg" == "ghostty" ]]; then
            mkdir -p "$HOME/.config/$pkg"
            stow -R -t "$HOME/.config/$pkg" "$pkg"
        else
            stow -R -t "$HOME" "$pkg"
        fi
done
}

# Function to set up Zsh and Oh My Zsh
setup_zsh() {
    if ! command -v zsh &> /dev/null; then
        msg "'zsh' command not found. Please install it first."
        return
    fi

    # Install Oh My Zsh if not already installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        msg "Installing Oh My Zsh..."
        # By setting RUNZSH=no, we prevent the installer from starting a new zsh shell
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        msg "Oh My Zsh is already installed."
    fi

    # Define Zsh custom plugin paths
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local ZSH_PLUGINS_DIR="$ZSH_CUSTOM/plugins"

    # Install zsh-autosuggestions if not already installed
    if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]]; then
        msg "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
    else
        msg "zsh-autosuggestions is already installed."
    fi

    # Install zsh-syntax-highlighting if not already installed
    if [[ ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
        msg "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"
    else
        msg "zsh-syntax-highlighting is already installed."
    fi

    # Change the default shell to Zsh
    local zsh_path
    zsh_path=$(which zsh)
    if [[ "$SHELL" != "$zsh_path" ]]; then
        msg "Changing default shell to Zsh. You may be prompted for your password."
        # Add the new shell to the list of allowed shells if it's not there already
        if ! grep -Fxq "$zsh_path" /etc/shells; then
            msg "Adding $zsh_path to /etc/shells. This requires sudo access."
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
        chsh -s "$zsh_path"
    else
        msg "Zsh is already the default shell."
    fi
}

# --- Main Execution ---
install_dependencies
stow_dotfiles
setup_zsh
msg "Bootstrap complete! Please restart your terminal."

