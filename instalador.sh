#!/bin/bash

# Variáveis globais
LOG_FILE="$HOME/installation_log_$(date +%F_%T).log"
ARCH=$(uname -m)
OS=""
BITNESS=""
clear

# Funções auxiliares
pause() {
  read -rp "Pressione Enter para continuar..."
}

echo_log() {
  echo "$1" | tee -a "$LOG_FILE"
}

clear_log() {
  > "$LOG_FILE"
}

detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      debian) OS="Debian" ;;
      ubuntu) OS="Ubuntu" ;;
      linuxmint) OS="Linux Mint" ;;
      arch) OS="Arch Linux" ;;
      fedora) OS="Fedora" ;;
      opensuse*|suse) OS="OpenSUSE" ;;
      void) OS="Void Linux" ;;
      raspbian) OS="Raspbian" ;;
      *) OS="Unknown" ;;
    esac
  fi

  if [[ $ARCH == *"64"* ]]; then
    BITNESS="64-bit"
  else
    BITNESS="32-bit"
  fi
}

setup_multilib() {
  echo_log "Configurando multiarquitetura para sistemas 64 bits..."
  case "$OS" in
    Debian|Ubuntu|Linux\ Mint|Raspbian)
      sudo dpkg --add-architecture i386 && sudo apt update -y
      ;;
    Arch\ Linux)
      sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
      sudo pacman -Syu
      ;;
    Fedora)
      sudo dnf install -y glibc.i686
      ;;
    OpenSUSE)
      sudo zypper install -y glibc-32bit
      ;;
    Void\ Linux)
      echo_log "Void Linux não requer configuração adicional para multiarquitetura."
      ;;
    *)
      echo_log "Sistema não suportado para multiarquitetura."
      ;;
  esac
}

expand_system() {
  echo_log "Habilitando repositórios adicionais..."
  case "$OS" in
    Debian|Ubuntu|Linux\ Mint|Raspbian)
      sudo sed -i '/main/ s/$/ contrib non-free/' /etc/apt/sources.list
      sudo apt update -y
      ;;
    Arch\ Linux)
      sudo pacman -S --needed git base-devel
      git clone https://aur.archlinux.org/yay.git
      cd yay && makepkg -si && cd .. && rm -rf yay
      ;;
    Fedora)
      sudo dnf install -y rpmfusion-free-release
      ;;
    OpenSUSE)
      sudo zypper addrepo -f https://download.opensuse.org/repositories/Packman/openSUSE_Tumbleweed/ packman
      sudo zypper refresh
      ;;
    Void\ Linux)
      sudo xbps-install -S void-repo-nonfree
      sudo xbps-install -Su
      ;;
    *)
      echo_log "Sistema não suportado para expansão de repositórios."
      ;;
  esac
}

install_packages() {
  local packages=(
    intel-microcode firmware-linux linux-headers-amd64 dkms build-essential firmware-realtek
    firmware-misc-nonfree wpasupplicant wireless-tools rfkill iwd dialog curl net-tools gcc g++
    make libarchive-tools software-properties-common unrar zip p7zip network-manager-openvpn openssl
    sshpass xfce4-goodies xfce4-pulseaudio-plugin x11vnc gparted locate openssh-server wine winbind
    openvpn libavcodec-extra xfce4 ntpdate smbclient apt-transport-https htop simplescreenrecorder
    plank neofetch tldr exa ncdu bat python3-pip ffmpeg obs-studio winetricks nodejs npm timeshift
    pulseaudio pavucontrol libcanberra0 sound-theme-freedesktop gvfs ntp libnfs-utils samba mtools
    fonts-terminus telegram-desktop guvcview audacity vlc mpv timeshift xarchiver catfish bleachbit
    blueman grub-customizer tldr exa ncdu bat kdenlive obs-studio recordmydesktop steam plymouth-themes
    filezilla qbittorrent thunderbird thunderbird-l10n-pt-br gpodder libreoffice libreoffice-help-pt-br
    duff meld btop python3-full libasound2-plugins:i386
  )

  echo_log "Instalando pacotes padrão..."
  case "$OS" in
    Debian|Ubuntu|Linux\ Mint|Raspbian)
      for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
          echo_log "Instalando $pkg..."
          sudo apt install -y "$pkg" || echo_log "$pkg não está disponível para instalação."
        fi
      done
      ;;
    Arch\ Linux)
      for pkg in "${packages[@]}"; do
        if ! pacman -Q | grep -q "$pkg"; then
          echo_log "Instalando $pkg..."
          sudo pacman -S --noconfirm "$pkg" || echo_log "$pkg não está disponível para instalação."
        fi
      done
      ;;
    Fedora)
      for pkg in "${packages[@]}"; do
        if ! rpm -q "$pkg"; then
          echo_log "Instalando $pkg..."
          sudo dnf install -y "$pkg" || echo_log "$pkg não está disponível para instalação."
        fi
      done
      ;;
    OpenSUSE)
      for pkg in "${packages[@]}"; do
        if ! zypper se -i "$pkg"; then
          echo_log "Instalando $pkg..."
          sudo zypper install -y "$pkg" || echo_log "$pkg não está disponível para instalação."
        fi
      done
      ;;
    Void\ Linux)
      for pkg in "${packages[@]}"; do
        if ! xbps-query -l | grep -q "$pkg"; then
          echo_log "Instalando $pkg..."
          sudo xbps-install -y "$pkg" || echo_log "$pkg não está disponível para instalação."
        fi
      done
      ;;
    *)
      echo_log "Sistema não suportado para instalação de pacotes."
      ;;
  esac
}

# Execução principal
clear_log
echo_log "Detectando sistema operacional..."
detect_os
echo_log "Sistema operacional detectado: $OS ($BITNESS)"
setup_multilib
expand_system
install_packages

echo_log "Instalação concluída. O log está salvo em $LOG_FILE."
echo_log "Obrigado por usar o script de instalação automatizada."
pause
