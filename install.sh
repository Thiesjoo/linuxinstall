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

OPTIONS=dzo:p
LONGOPTS=debug,nozsh,output:,nopython

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
    echo "  -d, --debug       enable debug options (echo warnings)"
    echo "  -z, --nozsh       do no install zsh"
    echo "  -p, --nopython       do no install pyenv"

    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

d=y zsh=y pyth=y
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
        -p|--nopython)
            pyth=n
            shift
            ;;
        -o|--output)
            outFile="$2"
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

# # handle non-option arguments
# if [[ $# -ne 1 ]]; then
#     echo "$0: A single input file is required."
#     exit 4
# fi

function debug () {
    [[ $d = y ]] && return 0 || return 1
}


#### MY SCRIPTS STARTS HERE

echo "debug: $d, zsh: $zsh "

debug && echo "Running in debug mode"

debug && echo "Updating & upgrading all packages"

sudo -u root bash << EOF
apt update -y -q
apt upgrade -y -q
echo "Apt updated and upgraded"

apt install zsh git net-tools curl software-properties-common apt-transport-https -y -q
echo "Installed deps for all scripts and software"
EOF


if [ $zsh = y ];
then
echo "Going to install ZSH next"
args="-t bureau -p zsh-autosuggestions -p zsh-nvm -p git"

if [ $pyth = y ];
then
args+=" -p zsh-pyenv"
debug && echo "Installing pyenv"
# curl https://pyenv.run | bash
fi
    sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.1/zsh-in-docker.sh)" -- $args
#git clone https://github.com/mattberther/zsh-pyenv ~/.oh-my-zsh/custom/plugins/zsh-pyenv

fi




# TO ADD TO .zshrc
#