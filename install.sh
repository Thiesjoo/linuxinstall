#!/bin/bash

# SOURCE OF THE OPTION PARSING: https://stackoverflow.com/a/29754866

# More safety, by turning some bugs into errors.
# Without `errexit` you don’t need ! and can replace
# PIPESTATUS with a simple $?, but I don’t do that.
set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=dzs:pgP
LONGOPTS=debug,nozsh,ssh:,nopython,gui,personal

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    echo "Usage: $0"
    echo "With ALL optional arguments: "
    echo "  -d, --debug                  Enable debug options (echo warnings)"
    echo "  -z, --nozsh                  Do no install zsh"
    echo "  -p, --python                 Install pyenv"
    echo "  -s, --ssh [email]            Generate a github ssh key with provided email (Program WILL ask for a ssh password)"
    echo "  -g, --gui                    Install gui apps (Vscode, Google Chrome)"
    echo "  -P, --personal               Install gui apps (Spotify, Discord, Whatsapp)"

    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

d=y zsh=y pyth=y 
ssh=- gui=n guiextra=n
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -d|--debug)
            d=y
            shift
            ;;
        -z|--nozsh)
            zsh=n
            shift
            ;;
        -p|--python)
            pyth=n
            shift
            ;;
        -g|--gui)
            gui=y
            shift
            ;;
        -P|--personal)
            extragui=y
            shift
            ;;
        -s|--ssh)
            ssh="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

function debug () {
    [[ $d = y ]] && return 0 || return 1
}

#### MY SCRIPTS STARTS HERE

echo "Debug mode: $d, Installing zsh: $zsh . Installing python: $pyth . Installing GUI apps: $gui (Personal: $extragui ). Generating ssh keys with email: $ssh "

debug && echo "Running in debug mode"

debug && echo "Updating & upgrading all packages"

sudo -u root bash << EOF
apt update -y -q
apt upgrade -y -q
echo "Apt updated and upgraded"

apt install zsh git net-tools curl software-properties-common apt-transport-https -y -q
echo "Installed deps for all scripts and software"
EOF

# Install keychain https://www.cyberciti.biz/faq/ubuntu-debian-linux-server-install-keychain-apt-get-command/
if [ $ssh != - ];
then
    echo "Generating SSH key"
    sudo apt-get install keychain
    ssh-keygen -t ed25519 -f $HOME/.ssh/id_github -C $ssh
# Perhaps generate SSH & GPG keys
fi


if [ $zsh = y ];
then
    echo "Going to install ZSH next"
    args="-t bureau \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/lukechilds/zsh-nvm \
    -p git "

    if [ $pyth = y ];
    then
        debug && echo "Installing pyenv"
        args+=" -p https://github.com/mattberther/zsh-pyenv"
        sudo apt-get install make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    fi

    if [ $ssh != - ];
    then
        args+='/usr/bin/keychain --clear $HOME/.ssh/id_github \n source $HOME/.keychain/$HOSTNAME-sh'
    fi

    sh -c "$(wget -O- https://raw.githubusercontent.com/Thiesjoo/linuxinstall/main/assets/ohymyzsh.sh)" -- $args \
        -a 'alias codeAll="ls ./*/ -d | xargs -I{} code {}"' \
        -a 'alias pullAll="ls ./*/ -d | xargs -I{} git -C {} pull"' \
        -a 'alias mainAll="ls ./*/ -d | xargs -I{} git -C {} checkout main"'

    sudo chsh -s "$(command -v zsh)" "${USER}"
    debug && echo "Finished ZSH installation"

    zsh

    if [ $pyth = y ];
    then
        debug && echo "Going to install latest python version"
        pyenv install 3.9.6
        pyenv global 3.9.6
    fi
    nvm install 14 --lts
fi


# Install GUI apps
if [ $gui = y ];
then
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    echo "Added vscode repo's"
        # Chrome
    if ! command -v google-chrome &> /dev/null
    then
        cd /tmp
        echo "google-chrome could not be found"
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt install ./google-chrome-stable_current_amd64.deb -q
        rm google-chrome-stable_current_amd64.deb 
        echo "Installed chrome"

        cp /usr/share/applications/google-chrome.desktop ~/.install-backup
        sudo sed -i 's/google-chrome-stable/google-chrome-stable --ignore-gpu-blacklist --enable-parallel-downloading /g' /usr/share/applications/google-chrome.desktop
        
        echo "For further chrome tweaking: go to chrome://flags and disable hardware-media-key-handling. For 4k display set page zoom in chrome://settings to 150%"    fi
    fi

    #Vscode
    sudo apt install code
    echo "Sudo installed vscode"

    if [ $guiextra = y ];
    then    
        debug && echo "Installing extra gui applications"

        # Command applications
        snap install whatsdesk
        snap install spotify
        snap install discord
        echo "Installed spotify, whatsapp and discord"
        

        # Autostart apps
        wget -qO /tmp/autostart.py https://raw.githubusercontent.com/Thiesjoo/linuxinstall/main/assets/autostart.py
        echo "Cloned autostart script"

        whatsdesk &>/dev/null &
        python3 /tmp/autostart.py Whatsapp whatsdesk
        echo "Started whatsapp, and autostarted it"

        spotify &>/dev/null &
        python3 /tmp/autostart.py Spotify spotify
        echo "Started spotify, and autostarted it"


        discord &>/dev/null &
        python3 /tmp/autostart.py Discord discord
        echo "Started discord, and autostarted it"
    fi
fi