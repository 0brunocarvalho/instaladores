#!/bin/bash

# Define o caminho do log
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
logfile="/var/log/instalacao_extras_$timestamp.log"
exec > >(tee -a "$logfile") 2>&1

# Funções auxiliares
pause() {
  read -p "Pressione qualquer tecla para continuar..."
}

clear

# Verificação de funcionalidades extras habilitadas
echo "Verificando se funcionalidades extras estão habilitadas para o sistema operacional..."
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  case "$ID" in
    debian|ubuntu|raspbian)
      echo "Ativando repositórios contrib e non-free..."
      sudo sed -i -e "s/main/main contrib non-free/" /etc/apt/sources.list
      sudo apt update
      ;;
    arch)
      echo "Ativando o suporte ao AUR (Arch User Repository)..."
      if ! command -v yay &>/dev/null; then
        echo "Instalando yay para suporte ao AUR..."
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay && makepkg -si && cd .. && rm -rf yay
      else
        echo "yay já está instalado."
      fi
      ;;
    fedora)
      echo "Ativando repositórios extras (RPM Fusion)..."
      sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
      sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
      ;;
    opensuse*)
      echo "Habilitando repositórios necessários..."
      sudo zypper addrepo -f https://download.opensuse.org/repositories/community/openSUSE_Tumbleweed/community.repo
      sudo zypper refresh
      ;;
    void)
      echo "Void Linux detectado. Não há repositórios adicionais padrão para habilitar."
      ;;
    *)
      echo "Sistema operacional não suportado para habilitação de funcionalidades extras."
      ;;
  esac
else
  echo "Não foi possível detectar o sistema operacional."
  exit 1
fi
pause

# Funções para instalação de pacotes extras
instalar_extras_debian() {
  echo "Instalando pacotes extras para Debian/Ubuntu/Raspbian..."

  # Google Chrome
  echo "Instalando Google Chrome..."
  sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install google-chrome-stable -y

  # Mono-Project
  echo "Instalando Mono-Project..."
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
  sudo sh -c 'echo "deb https://download.mono-project.com/repo/debian stable-bullseye main" > /etc/apt/sources.list.d/mono-official-stable.list'
  sudo apt update
  sudo apt install mono-complete -y

  # TLDR
  echo "Instalando TLDR..."
  npm install -g tldr

  # Sublime Text
  echo "Instalando Sublime Text..."
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  sudo apt update
  sudo apt install sublime-text -y

  # Dbeaver
  echo "Instalando Dbeaver..."
  sudo add-apt-repository ppa:serge-rider/dbeaver-ce
  sudo apt-get update
  sudo apt-get install dbeaver-ce -y

  # AnyDesk
  echo "Instalando AnyDesk..."
  wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add -
  echo "deb http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk-stable.list
  sudo apt update
  sudo apt install anydesk -y

  # TeamViewer
  echo "Instalando TeamViewer..."
  wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
  sudo dpkg -i teamviewer_amd64.deb
  sudo apt -f install -y

  # Asbru-cm
  echo "Instalando Asbru-cm..."
  curl -1sLf 'https://dl.cloudsmith.io/public/asbru-cm/release/cfg/setup/bash.deb.sh' | sudo -E bash
  sudo apt install asbru-cm ftp xtightvncviewer mosh cu uuid libyaml-shell-perl rdesktop -y

  # Makedeb
  echo "Instalando Makedeb..."
  bash -ci "$(wget -qO - 'https://shlink.makedeb.org/install')"

  # Bashtop
  echo "Instalando Bashtop..."
  git clone https://github.com/aristocratos/bashtop.git
  cd bashtop
  sudo make install
  pip install psutil

  # GTK YouTube Viewer
  echo "Instalando GTK YouTube Viewer..."
  git clone 'https://mpr.makedeb.org/youtube-viewer'
  cd youtube-viewer/
  makedeb -si

  # VirtualBox
  echo "Instalando VirtualBox..."
  wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor
  echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $distro contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
  sudo apt update && sudo apt install virtualbox-7.1 -y
  sudo usermod -a -G vboxusers $USER

  # Discord
  echo "Instalando Discord..."
  wget "https://discordapp.com/api/download?platform=linux&format=deb" -O discord.deb
  sudo dpkg -i discord.deb
  sudo apt -f install -y

  # GitHub CLI
  echo "Instalando GitHub CLI..."
  type -p curl >/dev/null || sudo apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update && sudo apt install gh -y
}

instalar_extras_arch() {
  echo "Instalando pacotes extras para Arch Linux..."
  # Google Chrome
  echo "Instalando Google Chrome..."
  yay -S google-chrome

  # Mono-Project
  echo "Instalando Mono-Project..."
  yay -S mono-complete

  # TLDR
  echo "Instalando TLDR..."
  yay -S tldr

  # Sublime Text
  echo "Instalando Sublime Text..."
  yay -S sublime-text

  # Dbeaver
  echo "Instalando Dbeaver..."
  yay -S dbeaver

  # AnyDesk
  echo "Instalando AnyDesk..."
  yay -S anydesk

  # TeamViewer
  echo "Instalando TeamViewer..."
  yay -S teamviewer

  # Asbru-cm
  echo "Asbru-cm não encontrado no Arch. Não há alternativa no repositório."

  # Makedeb
  echo "Makedeb não encontrado no Arch. Não há alternativa no repositório."

  # Bashtop
  echo "Bashtop encontrado no AUR. Instalando..."
  yay -S bashtop

  # GTK YouTube Viewer
  echo "GTK YouTube Viewer não encontrado no AUR. Não há alternativa no repositório."

  # VirtualBox
  echo "Instalando VirtualBox..."
  yay -S virtualbox

  # Discord
  echo "Instalando Discord..."
  yay -S discord

  # GitHub CLI
  echo "Instalando GitHub CLI..."
  yay -S github-cli
}

instalar_extras_fedora() {
  echo "Instalando pacotes extras para Fedora..."
  # Google Chrome
  echo "Instalando Google Chrome..."
  sudo dnf install google-chrome-stable -y

  # Mono-Project
  echo "Instalando Mono-Project..."
  sudo dnf install mono-complete -y

  # TLDR
  echo "Instalando TLDR..."
  sudo npm install -g tldr

  # Sublime Text
  echo "Instalando Sublime Text..."
  sudo dnf install sublime-text -y

  # Dbeaver
  echo "Instalando Dbeaver..."
  sudo dnf install dbeaver-ce -y

  # AnyDesk
  echo "Instalando AnyDesk..."
  sudo dnf install anydesk -y

  # TeamViewer
  echo "Instalando TeamViewer..."
  sudo dnf install teamviewer -y

  # Asbru-cm
  echo "Asbru-cm não encontrado no Fedora. Não há alternativa no repositório."

  # Makedeb
  echo "Makedeb não encontrado no Fedora. Não há alternativa no repositório."

  # Bashtop
  echo "Bashtop encontrado no Fedora. Instalando..."
  sudo dnf install bashtop -y

  # GTK YouTube Viewer
  echo "GTK YouTube Viewer não encontrado no Fedora. Não há alternativa no repositório."

  # VirtualBox
  echo "Instalando VirtualBox..."
  sudo dnf install virtualbox -y

  # Discord
  echo "Instalando Discord..."
  sudo dnf install discord -y

  # GitHub CLI
  echo "Instalando GitHub CLI..."
  sudo dnf install gh -y
}

# Execução conforme a distribuição
if [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID" == "raspbian" ]]; then
  distro=$VERSION_ID
  instalar_extras_debian
elif [[ "$ID" == "arch" ]]; then
  instalar_extras_arch
elif [[ "$ID" == "fedora" ]]; then
  instalar_extras_fedora
else
  echo "Distribuição não suportada para instalação automática de pacotes."
  exit 1
fi

echo "Instalação concluída!"
pause
