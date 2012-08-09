# Source .bashrc for non-interactive Bash shells
export BASH_ENV=~/.bashrc

if [[ $- != *i* ]] ; then
  # Shell is non-interactive.  Be done now!
  return
fi

OS=$(uname | awk '{print tolower($1)}')

_setpath() {
  paths="/usr/local/bin"
  paths="${paths} ${HOME}/bin"

  local i
  for i in $paths; do
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
  alias ls='ls -G'
  alias ll='ls -hl'

  alias cruft="find . -regextype posix-egrep -regex '.*swo|.*swp|.*pyc|.*pyo|.*~' -exec rm {} \;"

  alias p="ps aux |grep "
  alias grep="grep --color=auto"

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
}

_setprompt() {
  local SAVEHISTORY="history -a;$PROMPT_COMMAND"
  local SETWINDOWTITLE='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

  export PROMPT_COMMAND="$SETWINDOWTITLE;$SAVEHISTORY"
  export PS1="\[\[\e[32;1m\]\h \W> \[\e[0m\]"
  # Send tmux some path info
  #PS1="$PS1"'$([ -n "$TMUX" ] && tmux setenv TMUXPWD_$(tmux display -p "#I_#P") "$PWD")'
  #export PS1="\[\e]2;\u@\H \w\a\e[32;1m\e[32;40m\]\h \w $\[\e[0m\] "
  #export PS1="\[\e[36;1m\]\u@\[\e[32;1m\]\H> \[\e[0m\]"
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
  local sources=""
  sources="${sources} ${HOME}/.nvm/nvm.sh"
  sources="${sources} /etc/bash_completion"
  sources="${sources} ${HOME}/.sources"
  sources="${sources} ${HOME}/.sources/bashrc/${HOSTNAME}.bashrc"
  sources="${sources} ${HOME}/.sources/bashrc/${OS}.bashrc"
  sources="${sources} ${HOME}/.bash_completion.d"

  local i
  for i in $sources; do
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

# Show what is on a certain port
port() { lsof -i :"$1" ; }
# Create an executable file with the specified shebang line
shebang() { if i=$(which $1); then printf '#!%s\n\n' $i >  $2 && $EDITOR + $2 && chmod 755 $2; else echo "'which' could not find $1, is it in your \$PATH?"; fi; }
# Get stock quote
stock() { curl -s "http://download.finance.yahoo.com/d/quotes.csv?s=$1&f=l1" ; }
fur() { curl -sL 'http://www.commandlinefu.com/commands/random/plaintext' | grep -v "^# commandlinefu" ; }
alias funfacts='wget http://www.randomfunfacts.com -O - 2>/dev/null | grep \<strong\> | sed "s;^.*<i>\(.*\)</i>.*$;\1;";'

_setpath
_setaliases
_setprompt
_sethistory
_moreless

export EDITOR=vim

# Correct minor spelling errors in cd commands
shopt -s cdspell
# Enable egrep-style pattern matching
shopt -s extglob
shopt -s checkwinsize

export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
#export TERM=ansi
export TERM=xterm-color

_sources
unset OS
