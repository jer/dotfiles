# Source .bashrc for non-interactive Bash shells
export BASH_ENV=~/.bashrc

if [[ $- != *i* ]] ; then
  # Shell is non-interactive.  Be done now!
  return
fi

OS=$(uname | awk '{print tolower($1)}')

_setpath() {
  local paths=(
    /usr/local/bin
    /usr/local/sbin
    ${HOME}/bin
    /usr/local/heroku/bin
    $HOME/.rvm/bin
  )

  local i
  for i in ${paths[@]}; do
    # Move these paths to the front
    PATH=$(echo $PATH | sed -e "s#$i##g")
    if [ -d $i ]; then
      PATH=$i:$PATH
    fi
  done

  PATH=`echo $PATH | sed -e 's/^\://' -e 's/\:\:/:/g'`

  export PATH
}

# Function to calculate total memory consumption grouped by process name
mem() {
  local GREPCMD="cat"
  if [ ! -z $1 ]; then
    GREPCMD="grep -P $1"
  fi
  ps aux | awk '{print $4"\t"$6"\t"$11}' | 
     sort -k3 | 
     awk '{rss[$3]+=$2; per[$3]+=$1} END {for (i in rss) {print rss[i],i,per[i]"%"}}' | 
     sort -n | 
     eval $GREPCMD
}

_setaliases() {
  case "$OS" in
    darwin)
        # Use MacVim's terminal vim for awesomeness support
        hash rvim 2>/dev/null  && alias vim=rvim
        local FIND_EGREP="-E .";
        ;;
    linux)
        local FIND_EGREP=". -regextype posix-egrep";
        ;;
  esac

  alias ls='ls -G'
  alias ll='ls -hl'
  alias tree='tree -C'

  alias cruft="find $FIND_EGREP -regex '.*swo|.*swp|.*pyc|.*pyo|.*~' -exec rm {} \;"

  alias p="ps aux |grep "
  alias grep="grep --color=auto"

  alias facts="echo -ne '\033[36m'; curl -s randomfunfacts.com | grep '<i>' | sed 's/.*<i>\(.*\)<\/i>.*/\1/'; echo -ne '\033[0m'; tput sgr0"

  # show numeric permissions
  local FORMATFLAG="-c"
  if ( uname -a | grep Darwin >/dev/null); then
    FORMATFLAG="-f"
  fi
  alias perms="stat $FORMATFLAG '%A %a %n' *"

  # Add an "alert" alias for long running commands.  Use like so:
  #   sleep 10; alert
  alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

  alias dotfiles='git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
  alias d='dotfiles'
  alias .bashrc='source ~/.bashrc'
}

_setprompt() {
  local SAVEHISTORY="history -a"
  local SETWINDOWTITLE='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

  local TMUXCMD=''
  if [ -n $TMUX ]; then
    local TMUXENV='tmux set-environment -g CWD "$PWD"'
    local TMUXPATH='tmux set-option default-path $PWD'
    local TMUXCMD="($TMUXENV 2>/dev/null && $TMUXPATH 2>/dev/null >&2)"
  fi

  export PROMPT_COMMAND="$SETWINDOWTITLE;$SAVEHISTORY;$TMUXCMD"
  export PS1="\[\[\e[32;1m\]\h \W> \[\e[0m\]"
}

_prompt_2line() {
  # Reset
  local Color_Off='\[\e[0m\]'       # Text Reset

  # Regular Colors
  local Black='\[\e[0;30m\]'        # Black
  local Red='\[\e[0;31m\]'          # Red
  local Green='\[\e[0;32m\]'        # Green
  local Yellow='\[\e[0;33m\]'       # Yellow
  local Blue='\[\e[0;34m\]'         # Blue
  local Purple='\[\e[0;35m\]'       # Purple
  local Cyan='\[\e[0;36m\]'         # Cyan
  local White='\[\e[0;37m\]'        # White

  # Default PROMPT_COLOR values
  : ${PROMPT_COLOR:=Blue}
  : ${PROMPT_COLOR2:=Yellow}
  local C1=${!PROMPT_COLOR}
  local C2=${!PROMPT_COLOR2}

  # ┌(jer@myhost)─(✗)─(10:18 PM Sun Apr 14)
  # └─(~/dev/git/myproject)─>
  local DASH="\342\224\200"
  local X="\342\234\227"
  local ERRCODE="\$([[ \$? != 0 ]] && echo \"${DASH}(${Red}${X}${White})\")${DASH}"

  local NEWLINE="\n"
  LINE1="${White}\342\224\214(${C1}\u@\h${White})${ERRCODE}(${C1}\@ \d${White})"
  local LINE2="\342\224\224\342\224\200(${C2}\w${White})-> "
  export PS1="${NEWLINE}${LINE1}${NEWLINE}${LINE2}"
}

_sethistory() {
  export HISTFILE=~/.bash_history
  export HISTSIZE=10000
  export HISTFILESIZE=${HISTSIZE}
  export HISTCONTROL=ignoredups:ignorespace
  shopt -s histappend

  # Do *not* append the following to our history:
  HISTIGNORE='\&:fg:bg:ls:pwd:cd ..:cd ~-:cd -:cd:jobs:set -x:ls -l:ls -l'
  HISTIGNORE=${HISTIGNORE}':%1:%2:popd:top:shutdown*'
  export HISTIGNORE

  # Save multi-line commands in history as single line
  shopt -s cmdhist
}

_sources() {
  local sources=(
      ${HOME}/.nvm/nvm.sh
      /etc/bash_completion
      ${HOME}/.sources
      ${HOME}/.sources/${HOSTNAME}
      ${HOME}/.sources/${OS}
      ${HOME}/.bash_completion.d
      ${HOME}/.rvm/scripts/rvm
  )

  local i
  for i in ${sources[@]}; do
    # Source files
    if [ -f $i ]; then
      source $i
      continue
    fi

    # Source all files in a directory
    if [ -d $i ]; then
      for j in $i/*; do
        if [ -f $j ]; then
          source $j
        fi
      done
    fi
  done
}

# Use lesspipe for more powerful less output
_moreless() {
  local lesspipe=''
  if ( type lesspipe >/dev/null 2>&1 ); then
    lesspipe=$(which lesspipe)
  fi
  if ( type lesspipe.sh >/dev/null 2>&1 ); then
    lesspipe=$(which lesspipe.sh)
  fi

  if [ ! "x${lesspipe}" = "x" ]; then
    export LESSOPEN="|$lesspipe %s"
  fi
}

_manpagecolor() {
  export LESS_TERMCAP_mb=$'\E[01;31m'
  export LESS_TERMCAP_md=$'\E[01;31m'
  export LESS_TERMCAP_me=$'\E[0m'
  export LESS_TERMCAP_se=$'\E[0m'
  export LESS_TERMCAP_so=$'\E[01;44;33m'
  export LESS_TERMCAP_ue=$'\E[0m'
  export LESS_TERMCAP_us=$'\E[01;32m'
}

# Vagrant up plus vagrant ssh
vssh() {
  vagrant up $1
  vagrant ssh $1
}

tmuxssh() {
  for i in $@; do tmux split -v "ssh $i"; tmux select-layout tiled; done
}

# Check if we're online
connected() { 
  case "$OS" in
    darwin)
      ping -c1 -w2 google.com > /dev/null 2>&1;
      ;;
    linux)
      ping -c1 -t2 google.com > /dev/null 2>&1;
      ;;
  esac
}

# Fetch a little info about a domain name
url-info()
{
  doms=$@
  if [ $# -eq 0 ]; then
    echo -e "No domain given\nTry $0 domain.com domain2.org anyotherdomain.net"
  fi
  local i
  for i in $doms; do
    _ip=$(host $i|grep 'has address'|awk {'print $4'})
    if [ "$_ip" == "" ]; then
      echo -e "\nERROR: $i DNS error or not a valid domain\n"
      continue
    fi
    ip=`echo ${_ip[*]}|tr " " "|"`
    echo -e "\nInformation for domain: $i [ $ip ]\nQuerying individual IPs"
    for j in ${_ip[*]}; do
      echo -e "\n$j results:"
      whois $j |egrep -w 'OrgName:|City:|Country:|OriginAS:|NetRange:'
    done
  done
}

# Map over a list of files
map-find() { find $1 -name $2 -exec ${@:3} {} \; ; }

# Map over a bunch of lines piped in
map() {
  [ -z $1 ] && exit 1
  local IFS="$(printf '\n\t')"
  local i cmd
  case "$@" in
    *\$i*) cmd="$@" ;;
    *) cmd="$@ \$i" ;;
  esac
  while read i; do
    eval $cmd
  done
}

# Filter on a predicate. Return all of the matches
filter() {
  [ -z $1 ] && exit 1
  local IFS="$(printf '\n\t')"
  local i cmd
  case "$@" in
    *\$i*) cmd="$@" ;;
    *) cmd="$@ \$i" ;;
  esac
  while read i; do
    eval $cmd >/dev/null && echo $i;
  done
}

# Execute command $i times, returning the time
timerepeat() {
  time (
  local count=$1; shift;
  for ((i=0; i< $count; i++)); do
    eval $@
  done )
}

# For the tmux status bar
git_tmuxstatus() {
  [ -d .git ] || git rev-parse --git-dir 2> /dev/null || return
  local BRANCH=$(git branch --no-color 2>/dev/null | sed -e "/^[^*]/d" -e "s/* //")
  local ALLCHANGED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  #local CHANGED=$(git status --porcelain 2>/dev/null| egrep "^(M| M)" | wc -l)
  #local NEW=$(git status --porcelain 2>/dev/null| grep "^??" | wc -l)
  echo "[${BRANCH}:${ALLCHANGED}]"
}

randomizelines() {
  awk 'BEGIN {srand()} {print int(rand()*1000000) "\t" $0}' $1 |
  sort -n | cut -f 2-
}

memoize() {
  local CACHETIME=$1
  [[ "$CACHETIME" =~ ^[0-9]+$ ]] && shift || CACHETIME=1
  local SHA=$( shasum<<<$@ | cut -f1 -d' ' )
  local MEMODIR=/tmp/bash_memoized/$USER
  local MEMOFILE=${MEMODIR}/${SHA}

  [ -d $MEMODIR ] || mkdir $MEMODIR
  ( [ ! -f $MEMOFILE ] || ( test $(find $MEMOFILE -mmin +${CACHETIME})) ) && $@ | tee ${MEMOFILE}  || cat $MEMOFILE
}

# Show what is on a certain port
port() { lsof -i :"$1" ; }
# Create an executable file with the specified shebang line
shebang() { if i=$(which $1); then printf '#!%s\n\n' $i >  $2 && chmod +x $2 && $EDITOR + $2 ; else echo "'which' could not find $1, is it in your \$PATH?"; fi; }
# Get stock quote
stock() { curl -s "http://download.finance.yahoo.com/d/quotes.csv?s=$1&f=l1" ; }

fur() { curl -sL 'http://www.commandlinefu.com/commands/random/plaintext' | grep -v "^# commandlinefu" ; }
alias funfacts='wget http://www.randomfunfacts.com -O - 2>/dev/null | grep \<strong\> | sed "s;^.*<i>\(.*\)</i>.*$;\1;";'
nicemount() { (echo "DEVICE PATH TYPE FLAGS" && mount | awk '$2=$4="";1') | column -t ; }
wiki() { dig +short txt $1.wp.dg.cx; }

_setpath
_setaliases
#_setprompt
_prompt_2line
_sethistory
_moreless
_manpagecolor

export EDITOR=vim

# Correct minor spelling errors in cd commands
shopt -s cdspell
# Enable egrep-style pattern matching
shopt -s extglob
shopt -s checkwinsize

export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
#export TERM=ansi
export TERM=xterm-256color
export PIP_REQUIRE_VIRTUALENV=true

_sources
unset OS

# Mac likes to discard ctl-o
stty discard undef
