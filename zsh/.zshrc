# ZMODLOAD
zmodload zsh/zprof

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

source "$ZSH/oh-my-zsh.sh"

# Completions
autoload -U compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# Environment Variables
export EDITOR='nvim'
export LANG=en_US.UTF-8
export GOPATH="$HOME/go"
export GOBIN="$HOME/go/bin"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export JAVA_HOME="$(/usr/libexec/java_home)"
export GPG_TTY=$(tty)

# PATH Configuration
export PATH="$PATH:$GOPATH"
export PATH="$PATH:$GOBIN"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Zoxide
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
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
  function de() {
    cd ~/dev/$(ls ~/dev | fzf) && nvim
  }
fi

# Terraform
if command -v terraform &> /dev/null; then
  alias tf="terraform"
  alias tp="terraform plan"
  alias tpp="terraform plan -out planned"
  alias ta="terraform apply"
  alias tap="terraform apply planned"
  complete -o nospace -C /opt/homebrew/bin/terraform terraform
fi

# Git
if command -v git &> /dev/null; then
  gpgconf --launch gpg-agent
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
if command -v npm &> /dev/null; then . <(npm completion); fi
if command -v kubectl &> /dev/null; then . <(kubectl completion zsh); fi
if command -v helm &> /dev/null; then . <(helm completion zsh); fi
if command -v docker &> /dev/null; then . <(docker completion zsh); fi
if command -v stackit &> /dev/null; then . <(stackit completion zsh); fi
if command -v flux &> /dev/null; then . <(flux completion zsh); fi
if command -v k3d &> /dev/null; then . <(k3d completion zsh); fi
if command -v minikube &> /dev/null; then . <(minikube completion zsh); fi


# Load Custom Local Config
[ -f ~/.zshrc.local ] && source ~/.zshrc.local