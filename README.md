# Linuxinstall of Thies

`wget -qO- 'install.thies.dev' | bash -s --help`

## Folder structure
`install.sh` is the file that runs everything.
`assets/` directory contains files from different repo's with very slight changes. Sources are on the top of the file

### Not used
`old.sh` was the previous script that inspired all this. Sourced from: [this script](https://gist.github.com/Thiesjoo/5aa31380576de140c83ca1a0849a2d2d)

## TODO
- [ ] Create ~/prod ~/dev ~/school directory's (Or similiar folder structure)
- [ ] Auto github key upload?  
    - Would be handy, but maybe secure SSH key storage to just copy old key
    - Also add GPG key import/generation
- [ ] Auto apply gnome config ( [With zip files](https://linuxconfig.org/how-to-install-gnome-shell-extensions-from-zip-file-using-command-line-on-ubuntu-18-04-bionic-beaver-linux) )
- [ ] Add spicetify
- [ ] Launch the ZSH shell and execute the NVM & pyenv install commands [source](https://stackoverflow.com/a/18756584)
- [ ] Install [Chatterino](https://github.com/Chatterino/chatterino2/releases/tag/nightly-build)
- [ ] Add UvA install script as an extra option
    - [ ] Sync current course from github?
- [ ] Install notetaking app / pdf reader app

## Other features to think about
- [ ] Download VMWare image from (my?) server and just get a snapshot of this
