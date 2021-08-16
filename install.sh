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

OPTIONS=dzs:pgPDg:
LONGOPTS=debug,nozsh,ssh:,python,gui,personal,docker,gpg:

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
    echo "  -s, --ssh [key]              Import ssh key from specific file"
    echo "  -g, --gpg [gpg key | y]      If Y, checks for imported gpg keys and adds them to git. With gpg filename it imports and then adds"
    echo "  -D, --docker                 install docker & docker compose"
    echo "  -g, --gui                    Install gui apps (Vscode, Google Chrome)"
    echo "  -P, --personal               Install gui apps (Spotify, Discord, Whatsapp)"

    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

d=y zsh=y pyth=n
ssh=- gui=n guiextra=n
docker=n gpg=-
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
            pyth=y
            shift
            ;;
        -g|--gui)
            gui=y
            shift
            ;;
        -P|--personal)
            guiextra=y
            shift
            ;;
        -g|--gpg)
            gpg="$2"
            shift 2
            ;;
        -s|--ssh)
            ssh="$2"
            shift 2
            ;;
        -D|--docker)
            docker=y
            shift
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

echo "Debug mode: $d, Installing zsh: $zsh . Installing python: $pyth . Installing GUI apps: $gui (Personal: $guiextra ). Generating ssh keys with email: $ssh "

debug && echo "Running in debug mode"
debug && echo "Updating & upgrading all packages"

echo "THIS WILLL DELETE THE OLD ZSH INSTALLATION! It's recommened to make an LVM snapshot/VM snapshot first (:"

sudo -u root bash << EOF
apt update -y -q
apt upgrade -y -q
echo "Apt updated and upgraded"

apt install zsh git net-tools curl software-properties-common apt-transport-https -y -q
echo "Installed deps for all scripts and software"
EOF

if [ $ssh != - ];
then
    echo "Generating SSH key"
    sudo apt-get install keychain
    ssh-add $ssh
fi



if [ $gpg != - ];
then
    if [ $gpg != y ];
    then
        gpg --import $gpg
    fi
    key=$(gpg --list-secret-keys --keyid-format=long --with-colons | awk -F: '/sec:-:4096/ { print $5 }')
    echo "Parsed key: $key"
    git config --global user.signingkey $key
    git config --global commit.gpgsign true

 if [ -r ~/.bash_profile ]; then echo 'export GPG_TTY=$(tty)' >> ~/.bash_profile; \
  else echo 'export GPG_TTY=$(tty)' >> ~/.profile; fi

fi  

if [ $zsh = y ];
then
    echo "Going to install ZSH next"
    rm -rf $HOME/.zshrc
    rm -rf $HOME/.oh-my-zsh

    args="-t bureau \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/lukechilds/zsh-nvm \
    -p git "

    if [ $pyth = y ];
    then
        debug && echo "Installing pyenv"
        args+=" -p https://github.com/mattberther/zsh-pyenv"
        sudo apt install -y -q make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    fi

    if [ $ssh != - ];
    then
        args+='/usr/bin/keychain --clear $HOME/.ssh/'+$ssh+' \n source $HOME/.keychain/$HOSTNAME-sh'
    fi

    sh -c "$(wget -O- https://raw.githubusercontent.com/Thiesjoo/linuxinstall/main/assets/ohymyzsh.sh)" -- $args \
        -a 'alias codeAll="ls ./*/ -d | xargs -I{} code {}"' \
        -a 'alias pullAll="ls ./*/ -d | xargs -I{} git -C {} pull"' \
        -a 'alias mainAll="ls ./*/ -d | xargs -I{} git -C {} checkout main"'

    sudo chsh -s "$(command -v zsh)" "${USER}"
    debug && echo "Finished ZSH installation"
fi


# Install GUI apps
if [ $gui = y ];
then
    #Vscode
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository -y "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    debug && echo "Added vscode repo's"
    sudo apt install code -y
    echo "Installed vscode"
    # Chrome
    if ! command -v google-chrome &> /dev/null
    then
        cd /tmp
        echo "google-chrome could not be found"
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt install ./google-chrome-stable_current_amd64.deb -qy
        rm google-chrome-stable_current_amd64.deb 
        echo "Installed chrome"

        cp /usr/share/applications/google-chrome.desktop ~/.install-backup
        sudo sed -i 's/google-chrome-stable/google-chrome-stable --ignore-gpu-blacklist --enable-parallel-downloading /g' /usr/share/applications/google-chrome.desktop
        
        echo "For further chrome tweaking: go to chrome://flags and disable hardware-media-key-handling. For 4k display set page zoom in chrome://settings to 150%"    fi
    fi

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



if [ $docker = y ];
then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg --batch --yes
    echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io
    # sudo groupadd docker 
    sudo usermod -aG docker $USER
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker run hello-world
fi

# TODO: AUto github key upload? (You can just copy your old key)
# Auto apply gnome config https://linuxconfig.org/how-to-install-gnome-shell-extensions-from-zip-file-using-command-line-on-ubuntu-18-04-bionic-beaver-linux
# Maybe spicetify

echo "This script is done and will now boot your new ZSH config"
echo "To install python & node please run: "
echo "
    pyenv install 3.9.6
    pyenv global 3.9.6
    nvm install 14 --lts \n\n"

echo "To restore gnome config: dconf load / < saved_settings.dconf"
echo "(Also copy extensions folders ~/.local/share/gnome-shell/extensions) \n\n"
echo "Setup git creds:
  git config --global user.email 'you@example.com'
  git config --global user.name 'Your Name'
\n\n"

echo "Ubuntu pulseaudio delay:
sudo nano /etc/pulse/daemon.conf
enable-deferred-volume = no

pulseaudio -k && pulseaudio --start
\n\n"

if [ $docker = y ];
then
    newgrp docker 
fi
zsh
