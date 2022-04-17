export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="afowler"
HIST_STAMPS="yyyy-mm-dd"

source $ZSH/oh-my-zsh.sh

# Env
export LANG=en_US.UTF-8
export EDITOR='nvim'

function loadenv() {
if [ -f $1 ]
then
  export $(cat $1 | sed 's/#.*//g' | xargs)
fi
}

export PATH=$PATH:/usr/local/go/bin

plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
)

if [ -f ~/.zsh/completions/_zsh ]; then
    source ~/.zsh/completions/_zsh
fi

# Config
alias zshconfig="nvim ~/.zshrc"
alias ohmyzsh="code ~/.oh-my-zsh"
alias kittyconfig="nvim ~/.config/kitty/kitty.conf"
alias awesomeconfig="code ~/.config/awesome"
alias config="/usr/bin/git --git-dir=$HOME/.myconf/ --work-tree=$HOME"
alias pkglist="nvim ~/.myconf/init/pkg.txt"

# Files and directories
alias bat="batcat"
alias dev="cd ~/dev"
alias cat="bat -n"
alias copy="xclip -sel c"
alias ls="exa"
alias la="exa --long --all"
alias o="xdg-open"

# Misc
alias pi="sudo pacman -S"
alias py="python"
alias vi="nvim"
alias aspire="ssh thorben@192.168.0.103"
alias battery="acpi -b"

# Git
export GPG_TTY=$(tty)
function gitid() {
	f=$(gpg --list-secret-keys --keyid-format=long $1)
	[[ $f =~ '^sec +rsa4096\/(\w+) ' ]]
	key=$match[1]
	git config user.email $1
	git config user.signingkey $match[1]
	echo "Git Email: " $1
	echo "Git Signingkey: " $key
}
alias gm="git commit -m"

# kube
alias km="kubectl --kubeconfig ~/dev/pv/kube/k3s/k3s.yaml"
alias k="kubectl"
alias kustom="kubectl apply -k"

# Docker
alias d="docker"
alias dcu="docker compose up"
alias dcd="docker compose down"

# Terraform
alias ti="terraform init"
alias tiu="terraform init -upgrade"
alias tp="terraform plan"
alias tpp="terraform plan -out planned"
alias ta="terraform apply"
alias tap="terraform apply planned"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[[ /usr/local/bin/kubectl ]] && source <(kubectl completion zsh)
