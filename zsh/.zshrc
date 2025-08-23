zmodload zsh/zprof
export ZSH="$HOME/.oh-my-zsh"


ZSH_THEME="robbyrussell"
# Good themes: robbyrussell afowler af-magic dieter
HIST_STAMPS="yyyy-mm-dd"

plugins=(
	git
	docker
        dotenv
	docker-compose
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

autoload -U compinit && compinit
autoload -U +X bashcompinit && bashcompinit

export GOPATH=$HOME/go
export GOBIN=$HOME/go/bin
export PATH=$PATH:$GOPATH
export PATH=$PATH:$GOBIN


# Env
export LANG=en_US.UTF-8
export EDITOR='nvim'

if [ -f ~/.zsh/completions/_zsh ]; then
    source ~/.zsh/completions/_zsh
fi

# Zoxide
if command -v zoxide &> /dev/null
then
  eval "$(zoxide init zsh)"
fi

# Config
alias dotconfig="nvim ~/.dotfiles/"
alias zshconfig="nvim ~/.zshrc"
alias nvimconfig="nvim ~/.config/nvim"
alias ohmyzsh="nvim ~/.oh-my-zsh"

# Files and directories
if command -v bat &> /dev/null
then
  alias cat="bat -n"
fi

if command -v eza &> /dev/null
then
  alias ls="eza"
  alias l="eza --long --all"
  alias la="eza --long --all"
  alias ll="clear && la"
fi

if command -v fzf &> /dev/null 
then
  function de() {
    cd ~/dev/$(ls ~/dev | fzf) && nvim
  }
fi

# Terraform
if command -v terraform &> /dev/null
then
  alias tf="terraform"
  alias tp="terraform plan"
  alias tpp="terraform plan -out planned"
  alias ta="terraform apply"
  alias tap="terraform apply planned"

  complete -o nospace -C /opt/homebrew/bin/terraform terraform
fi

# Git
if command -v git &> /dev/null
then
  export GPG_TTY=$(tty)
  gpgconf --launch gpg-agent
  alias gm="git commit -S -s -m"
  alias ga="git add"
  alias gp="git pull"
fi

if command -v npm &> /dev/null
then
  . <(npm completion)
fi

# kube
if command -v kubectl &> /dev/null
then
  alias k="kubectl"
  alias ks="kubectl get secret -o go-template='{{range \$k,\$v := .data}}{{printf \"%s: \" \$k}}{{if not \$v}}{{\$v}}{{else}}{{\$v | base64decode}}{{end}}{{\"\n\"}}{{end}}'"
  alias kustom="kubectl apply -k"
  . <(kubectl completion zsh)
fi

if command -v helm &> /dev/null
then
  . <(helm completion zsh)
fi

# Docker
if command -v docker &> /dev/null
then
  alias d="docker"
  alias dcu="docker compose up"
  alias dcd="docker compose down"
  alias docker-compose="docker compose"
  . <(docker completion zsh)
fi

if command -v flux &> /dev/null
then
  . <(flux completion zsh)
fi

if command -v k3d &> /dev/null
then
  . <(k3d completion zsh)
fi

if command -v minikube &> /dev/null
then
  . <(minikube completion zsh)
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load Custom Local Config
[ -f ~/.zshrc.local ] && source ~/.zshrc.local


#appium
export ANDROID_HOME=/Users/thorben/Library/Android/sdk
export JAVA_HOME=/usr
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
