#!/bin/bash
mkdir ~/.install-backup

sudo -u root bash << EOF
echo "RUNNING AS ROOT"

# Updates
apt update -y -q
apt upgrade -y -q
echo "Apt updated and upgraded"
apt install zsh git net-tools curl software-properties-common apt-transport-https -y -q
echo "Installed deps for all scripts and software"

#if ! command -v python3 &> /dev/null
#then
#    apt-get install --yes libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libgdbm-dev lzma lzma-dev tcl-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev wget curl make build-essential python-openssl
#fi

EOF
echo "Running as normal user"

#Shell
if [ "$1" == "test" ] || [ "$2" == "test" ]; then
    echo "Not installing zsh"
else
    sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Installed oh-my-zsh"

    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
    
    echo "Cloned the extra plugins"
    mv ~/.zshrc ~/.install-backup

    wget -O ~/.zshrc -q https://gist.githubusercontent.com/Thiesjoo/5aa31380576de140c83ca1a0849a2d2d/raw/.zshrc
    # Set as default shell
    chsh -s "$(command -v zsh)" "${USER}"
    echo "Added configs and set as default shell"
fi

if [ "$1" == "wsl" ]; then
    echo "WSL INSTALL: Add extra stuff to path. Specified in the gist"
    wget -qO- https://gist.githubusercontent.com/Thiesjoo/5aa31380576de140c83ca1a0849a2d2d/raw/wsl.zshrc > /tmp/newfile
    cat ~/.zshrc >> /tmp/newfile
    cp /tmp/newfile ~/.zshrc
else
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    echo "Added vscode repo's"
        # Chrome
    if ! command -v google-chrome &> /dev/null
    then
        echo "google-chrome could not be found"
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        apt install ./google-chrome-stable_current_amd64.deb -q
        rm google-chrome-stable_current_amd64.deb 
        echo "Installed chrome"

        cp /usr/share/applications/google-chrome.desktop ~/.install-backup
        sudo sed -i 's/google-chrome-stable/google-chrome-stable --ignore-gpu-blacklist --enable-parallel-downloading /g' /usr/share/applications/google-chrome.desktop
        
        echo "For further chrome tweaking: go to chrome://flags and disable hardware-media-key-handling. For 4k display set page zoom in chrome://settings to 150%"    fi
    fi
    # Command applications
    snap install whatsdesk
    snap install spotify
    snap install discord
    echo "Installed spotify, whatsapp and discord"
    
    #Vscode
    sudo apt install code
    echo "Sudo installed vscode"


    # Autostart apps
    wget -qO /tmp/autostart.py https://gist.githubusercontent.com/Thiesjoo/5aa31380576de140c83ca1a0849a2d2d/raw/autostart.py
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

echo "Finished script. launching new shell"
zsh