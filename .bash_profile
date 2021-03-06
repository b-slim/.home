
# append to the history file, don't overwrite it
shopt -s histappend
# check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
# correct minor errors in the spelling of a directory component in a cd command
shopt -s cdspell
# save all lines of a multiple-line command in the same history entry (allows easy re-editing of multi-line commands)
shopt -s cmdhist

# setup color variables
color_is_on=
color_red=
color_green=
color_yellow=
color_blue=
color_white=
color_gray=
color_bg_red=
color_off=
color_user=
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_is_on=true
    color_red="\[$(/usr/bin/tput setaf 1)\]"
    color_green="\[$(/usr/bin/tput setaf 2)\]"
    color_yellow="\[$(/usr/bin/tput setaf 3)\]"
    color_blue="\[$(/usr/bin/tput setaf 6)\]"
    color_white="\[$(/usr/bin/tput setaf 7)\]"
    color_gray="\[$(/usr/bin/tput setaf 8)\]"
    color_off="\[$(/usr/bin/tput sgr0)\]"

    color_error="$(/usr/bin/tput setab 1)$(/usr/bin/tput setaf 7)"
    color_error_off="$(/usr/bin/tput sgr0)"

    # set user color
    case `id -u` in
        0) color_user=$color_red ;;
        *) color_user=$color_green ;;
    esac
fi

# some kind of optimization - check if git installed only on config load
PS1_GIT_BIN=$(which git 2>/dev/null)
PS1_HG_BIN=$(which hg 2>/dev/null)

function prompt_command {
    if [ -f ~/.bash_local_prompt ]; then
        . ~/.bash_local_prompt
    fi

    local PS1_VCS=
    local VCS_NAME=
    local VCS_INFO=
    local VCS_DIRTY=
    local PWDNAME=$PWD
    local HOSTNAME=`hostname -s`
    local BATTERY=`pmset -g batt | tail -1 | cut -f2 | cut -d \; -f1`
    local BATTERY_STATUS=`pmset -g batt | tail -1 | cut -f2 | cut -d \; -f2 | sed s/\ //g`
    local JAVA_VERSION=$(java -version 2>&1 | head -2 | tail -1 | sed s/[^0-9._\\-]//g)
    local DATE=$(date "+%Y-%m-%d %H:%M:%S")

    # beautify working directory name
    if [[ "${HOME}" == "${PWD}" ]]; then
        PWDNAME="~"
    elif [[ "${HOME}" == "${PWD:0:${#HOME}}" ]]; then
        PWDNAME="~${PWD:${#HOME}}"
    fi

    # parse git status and get git variables
    if [[ ! -z $PS1_GIT_BIN ]]; then
        # check we are in git repo
        local CUR_DIR=$PWD
        while [[ ! -d "${CUR_DIR}/.git" ]] && [[ ! "${CUR_DIR}" == "/" ]] && [[ ! "${CUR_DIR}" == "~" ]] && [[ ! "${CUR_DIR}" == "" ]]; do CUR_DIR=${CUR_DIR%/*}; done
        if [[ -d "${CUR_DIR}/.git" ]]; then
            # 'git repo for dotfiles' fix: show git status only in home dir and other git repos
            if [[ "${CUR_DIR}" != "${HOME}" ]] || [[ "${PWD}" == "${HOME}" ]]; then
                # get git branch
                VCS_NAME="git"
                VCS_INFO=$($PS1_GIT_BIN symbolic-ref HEAD 2>/dev/null)
                if [[ ! -z $VCS_INFO ]]; then
                    VCS_INFO=${VCS_INFO#refs/heads/}

                    # get git status
                    local GIT_STATUS=$($PS1_GIT_BIN status --porcelain 2>/dev/null)
                    [[ -n $GIT_STATUS ]] && VCS_DIRTY=1
                fi
            fi
        fi
    fi
    if [[ ! -z $PS1_HG_BIN ]]; then
        #check we are in hg repo
        local CUR_DIR=$PWD
        while [[ ! -d "${CUR_DIR}/.hg" ]] && [[ ! "${CUR_DIR}" == "/" ]] && [[ ! "${CUR_DIR}" == "~" ]] && [[ ! "${CUR_DIR}" == "" ]]; do CUR_DIR=${CUR_DIR%/*}; done
        if [[ -d "${CUR_DIR}/.hg" ]]; then
            if [[ "${CUR_DIR}" != "${HOME}" ]] || [[ "${PWD}" == "${HOME}" ]]; then
                VCS_NAME="hg"
                VCS_INFO=$($PS1_HG_BIN branch 2>/dev/null)
                if [[ ! -z $VCS_INFO ]]; then
                    local HG_STATUS=$($PS1_HG_BIN status 2>/dev/null)
                    [[ -n $HG_STATUS ]] && VCS_DIRTY=1
                fi
            fi
        fi
    fi

    [[ ! -z $VCS_NAME ]] && PS1_VCS=" (${VCS_NAME}: ${VCS_INFO})"

    # calculate prompt length
    local PS1_length=$((${#USER}+${#HOSTNAME}+${#PWDNAME}+${#BATTERY}+${#DATE}+${#PS1_VCS}+${#JAVA_VERSION}+9))
    local FILL=

    # if length is greater, than terminal width
    if [[ $PS1_length -gt $COLUMNS ]]; then
        # strip working directory name
        PWDNAME="...${PWDNAME:$(($PS1_length-$COLUMNS+3))}"
    else
        # else calculate fillsize
        local fillsize=$(($COLUMNS-$PS1_length))
        FILL=$color_gray
        while [[ $fillsize -gt 0 ]]; do FILL="${FILL}─"; fillsize=$(($fillsize-1)); done
        FILL="${FILL}${color_off}"
    fi

    if $color_is_on; then
        # build vsc status for prompt
        if [[ ! -z $VCS_NAME ]]; then
            if [[ -z $VCS_DIRTY ]]; then
              PS1_VCS="(${VCS_NAME}: ${color_green}${VCS_INFO}${color_off})"
            else
              PS1_VCS="(${VCS_NAME}: ${color_red}${VCS_INFO}${color_off})"
            fi
        fi

        # color battery
        local BATTERY_NUM=$(echo "$BATTERY" | sed s/%//g)
        if [ "$BATTERY_NUM" -ge "25" ] && [ "$BATTERY_NUM" -le "50" ] ; then
          BATTERY="${color_yellow}${BATTERY}${color_off}"
        elif [ "$BATTERY_NUM" -lt "25" ] ; then
          BATTERY="${color_red}${BATTERY}${color_off}"
        fi

    fi

    # set new color prompt
    PS1="${color_user}${USER}${color_off}@${color_yellow}${HOSTNAME}${color_off}:${color_white}${PWDNAME}${color_off} (${DATE} ${BATTERY})${PS1_VCS}($JAVA_VERSION) ${FILL}\n$ "

    # get cursor position and add new line if we're not in first column
    # cool'n'dirty trick (http://stackoverflow.com/a/2575525/1164595)
    # XXX FIXME: this hack broke ssh =(
#	exec < /dev/tty
#	local OLDSTTY=$(stty -g)
#	stty raw -echo min 0
#	echo -en "\033[6n" > /dev/tty && read -sdR CURPOS
#	stty $OLDSTTY
    echo -en "\033[6n" && read -sdR CURPOS
    [[ ${CURPOS##*;} -gt 1 ]] && echo "${color_error}↵${color_error_off}"

    # set title
    echo -ne "\033]0;${USER}@${HOSTNAME}:${PWDNAME}"; echo -ne "\007"
}

# set prompt command (title update and color prompt)
PROMPT_COMMAND=prompt_command
# set new b/w prompt (will be overwritten in 'prompt_command' later for color prompt)
PS1='\u@\h:\w\$ '

# grep colorize
export GREP_OPTIONS="--color=auto"

# bash completion
if [ -f /usr/local/bin/brew ]; then
  if [ -f `/usr/local/bin/brew --prefix`/etc/bash_completion ]; then
    . `/usr/local/bin/brew --prefix`/etc/bash_completion
  fi
fi

if [ -f ~/bin/hg_completion.sh ]; then
  . ~/bin/hg_completion.sh
fi

if [ -f ~/bin/git_completion.sh ]; then
  . ~/bin/git_completion.sh
fi

# bash aliases
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

#machine-specific profile (e.g. $JAVA_HOME)
if [ -f ~/.bash_local_profile ]; then
  . ~/.bash_local_profile
fi
