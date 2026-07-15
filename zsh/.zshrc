# Profile startup if ZSH_PROFILE is set
if [[ -n "$ZSH_PROFILE" ]]; then
  zmodload zsh/zprof
fi

# Ensure unique entries in path and fpath (prevents duplicates on reload)
typeset -U path fpath mailpath

# Prepend custom completion cache to fpath (must be before sourcing Oh My Zsh)
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR/completions" 2>/dev/null
fpath=("$ZSH_CACHE_DIR/completions" $fpath)

# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
HIST_STAMPS="yyyy-mm-dd"

plugins=(
    git
    docker
    dotenv
    docker-compose
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# ------------------------------------------------------------------------------
# COMPINIT OPTIMIZATION WRAPPER
# ------------------------------------------------------------------------------
# Intercept compinit from Oh My Zsh. If the dump file is less than 24 hours old,
# load compinit with `-C` to bypass the costly directory check.
autoload -Uz compinit
autoload -U +X compinit
functions[real_compinit]=$functions[compinit]

compinit() {
  if [[ -z "$ZSH_COMPDUMP" ]]; then
    local short_host
    if [[ "$OSTYPE" = darwin* ]]; then
      short_host=$(scutil --get LocalHostName 2>/dev/null) || short_host="${HOST/.*/}"
    else
      short_host="${HOST/.*/}"
    fi
    ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump-${short_host}-${ZSH_VERSION}"
  fi

  local -a dump_fresh
  setopt localoptions extendedglob
  dump_fresh=( "$ZSH_COMPDUMP"(#qN.m-1) )

  if (( $#dump_fresh )); then
    # Cache is fresh; load compinit with -C (fast)
    real_compinit -C "$@"
  else
    # Cache is stale/missing; run full compinit (slower, recreates cache)
    real_compinit "$@"
  fi
}

source "$ZSH/oh-my-zsh.sh"

# Completions
# (compinit is loaded automatically by Oh My Zsh; we only load bashcompinit here)
autoload -U +X bashcompinit && bashcompinit

# Environment Variables
export EDITOR='nvim'
export LANG=en_US.UTF-8
export GOPATH="$HOME/go"
export GOBIN="$HOME/go/bin"
export ANDROID_HOME="$HOME/Library/Android/sdk"

# Optimize JAVA_HOME detection (macOS only, cached to avoid executing the helper)
if [[ "$OSTYPE" = darwin* && -x /usr/libexec/java_home ]]; then
  JAVA_HOME_CACHE="$ZSH_CACHE_DIR/java_home"
  if [[ ! -f "$JAVA_HOME_CACHE" || /usr/libexec/java_home -nt "$JAVA_HOME_CACHE" ]]; then
    mkdir -p "${JAVA_HOME_CACHE:h}"
    /usr/libexec/java_home > "$JAVA_HOME_CACHE" 2>/dev/null
  fi
  export JAVA_HOME="$(< "$JAVA_HOME_CACHE")"
else
  export JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null)"
fi

export GPG_TTY=$(tty 2>/dev/null || echo "")

# PATH Configuration
export PATH="$PATH:$GOPATH"
export PATH="$PATH:$GOBIN"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Zoxide (cached initialization)
if command -v zoxide &> /dev/null; then
  ZOXIDE_CACHE="$ZSH_CACHE_DIR/zoxide_init.zsh"
  if [[ ! -f "$ZOXIDE_CACHE" || "$(command -v zoxide)" -nt "$ZOXIDE_CACHE" ]]; then
    mkdir -p "${ZOXIDE_CACHE:h}"
    zoxide init zsh > "$ZOXIDE_CACHE" 2>/dev/null
  fi
  source "$ZOXIDE_CACHE"
fi

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ------------------------------------------------------------------------------
# ALIASES & FUNCTIONS
# ------------------------------------------------------------------------------

# Config
alias dotconfig="nvim ~/.dotfiles/"
alias zshconfig="nvim ~/.zshrc"
alias nvimconfig="nvim ~/.config/nvim"
alias ohmyzsh="nvim ~/.oh-my-zsh"
alias reload="source ~/.zshrc"

# helpers
alias hit="history | grep"

# Files and directories
if command -v bat &> /dev/null; then
  alias cat="bat -n"
fi

if command -v eza &> /dev/null; then
  alias ls="eza"
  alias l="eza --long --all"
  alias la="eza --long --all"
  alias ll="clear && la"
fi

if command -v fzf &> /dev/null; then
  # Quick navigate & edit in dev directory, handling exit/cancel gracefully
  function de() {
    local dir
    dir=$(find ~/dev -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf)
    if [[ -n "$dir" ]]; then
      cd "$dir" && nvim
    fi
  }
fi

# Terraform
if command -v terraform &> /dev/null; then
  alias tf="terraform"
  alias tp="terraform plan"
  alias tpp="terraform plan -out planned"
  alias ta="terraform apply"
  alias tap="terraform apply planned"
  # Make terraform completion command path dynamic
  complete -o nospace -C "$(command -v terraform)" terraform
fi

# Git
if command -v git &> /dev/null; then
  # gpg-agent will automatically launch on-demand when signing is triggered.
  # gpgconf --launch gpg-agent is commented out to speed up shell startup.
  # gpgconf --launch gpg-agent
  alias gm="git commit -S -s -m"
  alias ga="git add"
  alias gp="git pull"
fi

# Kubectl
if command -v kubectl &> /dev/null; then
  alias k="kubectl"
  alias ks="kubectl get secret -o go-template='\'{{range $k,$v := .data}}{{printf \"%s: \" $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{\"\n\"}}{{end}}'"
  alias kustom="kubectl apply -k"
fi

# Docker
if command -v docker &> /dev/null; then
  alias d="docker"
  alias dcu="docker compose up"
  alias dcd="docker compose down"
  alias docker-compose="docker compose"
fi


# ------------------------------------------------------------------------------
# COMPLETIONS (for tools not covered by Oh My Zsh plugins)
# ------------------------------------------------------------------------------
# Asynchronously cache completions for faster shell startup
cache_completion() {
  local cmd="$1"
  local file="$ZSH_CACHE_DIR/completions/_$cmd"
  if command -v "$cmd" &>/dev/null && [[ ! -f "$file" ]]; then
    (
      case "$cmd" in
        npm) (echo "#compdef npm"; npm completion) > "$file" 2>/dev/null &! ;;
        *) "$cmd" completion zsh > "$file" 2>/dev/null &! ;;
      esac
    ) &!
  fi
}

# Run caching in the background (disowned)
# Note: docker and docker-compose are already handled by Oh My Zsh plugins
for tool in npm kubectl helm stackit flux k3d minikube kubebuilder; do
  cache_completion "$tool"
done


# Load Custom Local Config
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# End profiling if ZSH_PROFILE is active
if [[ -n "$ZSH_PROFILE" ]]; then
  zprof
fi
