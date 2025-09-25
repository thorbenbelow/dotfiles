# Dotfiles

My personal collection of dotfiles and development environment setup, managed with `stow`.

## Installation

This repository uses the `bootstrap.sh` script to automate the setup process.

**1. Clone the repository:**

```bash
git clone https://github.com/thorbenbelow/dotfiles.git ~/.dotfiles
```

**2. Run the bootstrap script:**

```bash
cd ~/.dotfiles
./bootstrap.sh
```

## What the Bootstrap Script Does

The `bootstrap.sh` script is idempotent and can be run safely multiple times. It will:

-   **Install Dependencies:**
    -   On macOS, it installs [Homebrew](https://brew.sh/) if not present, then installs packages like `git`, `stow`, and `neovim`.
    -   On Linux, it uses `apt` to install necessary packages.
-   **Symlink Dotfiles:** Uses `stow` to symlink the configuration files for `git`, `nvim`, `zsh`, etc., into your home directory.
-   **Set up Zsh:**
    -   Installs [Oh My Zsh](https://ohmyz.sh/).
    -   Installs the `zsh-autosuggestions` and `zsh-syntax-highlighting` plugins.
    -   Sets Zsh as your default shell.

## Local Overrides

For machine-specific configurations, you can create the following files. They are ignored by version control.

-   `~/.gitconfig.local`
-   `~/.zshrc.local`
