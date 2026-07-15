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

# Run a command as root, using sudo if available and not already root.
run_as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo &>/dev/null; then
        sudo "$@"
    else
        msg "Error: Root privileges are required but sudo is not installed and you are not root."
        exit 1
    fi
}

# Read packages from a package list file, filtering comments and empty lines.
read_packages_from_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        grep -vE '^\s*(#|$)' "$file_path"
    fi
}

# Get the absolute normalized path of a file, resolving symlinks safely.
get_abs_path() {
    local target="$1"
    if [[ -L "$target" ]]; then
        local link_val
        link_val=$(readlink "$target") || return 1
        if [[ "$link_val" != /* ]]; then
            local parent_dir
            parent_dir=$(dirname "$target")
            local resolved_dir
            resolved_dir=$(cd "$parent_dir" && cd "$(dirname "$link_val")" &>/dev/null && pwd) || return 1
            echo "$resolved_dir/$(basename "$link_val")"
        else
            echo "$link_val"
        fi
    else
        local parent_dir
        parent_dir=$(dirname "$target")
        if [[ -d "$parent_dir" ]]; then
            local resolved_parent
            resolved_parent=$(cd "$parent_dir" &>/dev/null && pwd) || return 1
            echo "$resolved_parent/$(basename "$target")"
        else
            echo "$target"
        fi
    fi
}

# Resolve conflicts at target destination before stowing
resolve_conflicts() {
    local pkg_dir="$1"
    local target_dir="$2"
    
    if [[ ! -d "$pkg_dir" ]]; then
        return 0
    fi
    
    (
        cd "$pkg_dir"
        find . -mindepth 1 | while IFS= read -r rel_path; do
            # Strip leading './'
            rel_path="${rel_path#./}"
            local src_item="$pkg_dir/$rel_path"
            local dest_item="$target_dir/$rel_path"
            
            if [[ -e "$dest_item" || -L "$dest_item" ]]; then
                if [[ -L "$dest_item" ]]; then
                    local abs_src
                    abs_src=$(get_abs_path "$src_item") || continue
                    local abs_dest
                    abs_dest=$(get_abs_path "$dest_item") || continue
                    if [[ "$abs_src" == "$abs_dest" ]]; then
                        continue
                    fi
                    local backup="${dest_item}.backup-$(date +%Y%m%d%H%M%S)"
                    msg "Backing up conflicting symlink: $dest_item -> $backup"
                    mv "$dest_item" "$backup"
                elif [[ -d "$dest_item" && -d "$src_item" ]]; then
                    # No conflict; both are directories, so stow will merge/descend.
                    continue
                else
                    local backup="${dest_item}.backup-$(date +%Y%m%d%H%M%S)"
                    msg "Backing up conflicting file/directory: $dest_item -> $backup"
                    mv "$dest_item" "$backup"
                fi
            fi
        done
    )
}

# --- Main Logic ---

# Function to install dependencies based on the OS
install_dependencies() {
    msg "Installing dependencies..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local apt_list_path="$DOTFILES_DIR/packages/apt.list"
        
        # Fallback hardcoded packages in case packages/apt.list is missing
        local apt_packages=(git stow curl zsh neovim passwd)
        if [[ -f "$apt_list_path" ]]; then
            apt_packages=()
            while IFS= read -r line; do
                [[ -n "$line" ]] && apt_packages+=("$line")
            done < <(read_packages_from_file "$apt_list_path")
        fi

        # Detect package manager
        if command -v apt-get &>/dev/null; then
            msg "Installing packages via apt..."
            run_as_root apt-get update -y
            DEBIAN_FRONTEND=noninteractive run_as_root apt-get install -y "${apt_packages[@]}"
        elif command -v dnf &>/dev/null; then
            msg "Installing packages via dnf..."
            run_as_root dnf install -y git stow curl zsh neovim util-linux-user
        elif command -v pacman &>/dev/null; then
            msg "Installing packages via pacman..."
            run_as_root pacman -Sy --noconfirm git stow curl zsh neovim
        elif command -v apk &>/dev/null; then
            msg "Installing packages via apk..."
            run_as_root apk add --no-cache git stow curl zsh neovim shadow
        else
            msg "Unsupported Linux distribution. Please install packages manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # On macOS, check for and install Homebrew if it's missing
        if ! command -v brew &> /dev/null; then
            msg "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Immediately add Homebrew to current shell's PATH
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi

        local brew_list_path="$DOTFILES_DIR/packages/brew.list"
        local brew_packages=(git stow curl zsh nvim)
        if [[ -f "$brew_list_path" ]]; then
            brew_packages=()
            while IFS= read -r line; do
                [[ -n "$line" ]] && brew_packages+=("$line")
            done < <(read_packages_from_file "$brew_list_path")
        fi

        msg "Installing packages with Homebrew..."
        brew install "${brew_packages[@]}"
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
        local target_dir
        if [[ "$pkg" == "nvim" ]] || [[ "$pkg" == "ghostty" ]]; then
            target_dir="$HOME/.config/$pkg"
            mkdir -p "$target_dir"
        else
            target_dir="$HOME"
        fi

        # Resolve any conflicting existing files before stowing
        resolve_conflicts "$DOTFILES_DIR/$pkg" "$target_dir"

        msg "Stowing $pkg..."
        stow -R -t "$target_dir" "$pkg"
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
    zsh_path=$(command -v zsh)
    if [[ "${SHELL:-}" != "$zsh_path" ]]; then
        # Check if we can change shell without password (if we are root) OR if stdin is a TTY
        if [[ "$(id -u)" -eq 0 ]] || [[ -t 0 ]]; then
            msg "Changing default shell to Zsh..."
            # Add the new shell to the list of allowed shells if it's not there already
            if ! grep -Fxq "$zsh_path" /etc/shells; then
                msg "Adding $zsh_path to /etc/shells."
                echo "$zsh_path" | run_as_root tee -a /etc/shells >/dev/null
            fi
            if [[ "$(id -u)" -eq 0 ]]; then
                chsh -s "$zsh_path"
            else
                chsh -s "$zsh_path" || msg "Warning: Failed to change default shell via chsh. You can change it manually."
            fi
        else
            msg "Non-interactive environment detected. Skipping default shell change. Please run: chsh -s $zsh_path"
        fi
    else
        msg "Zsh is already the default shell."
    fi
}

# --- Main Execution ---
install_dependencies
setup_zsh
stow_dotfiles
msg "Bootstrap complete! Please restart your terminal."
