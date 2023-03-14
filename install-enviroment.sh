#!/bin/bash
# Shell script for installing/updating a build environment

source utility-functions.sh
source packages.sh

install_home_brew() {
  message "Checking HomeBrew installation."

  # checking if homebrew is already installed
  if command -v brew >/dev/null 2>&1; then
    message "HomeBrew is already installed."
    printf "%s$(brew -v)\n"

    if [ $SILENT == 0 ]; then
      read -r -p "Do you want to update HomeBrew? ${tty_bold}[y/N]${tty_reset} " response
    fi

    if [[ $SILENT == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
      message "Updating HomeBrew"
      brew update
    else
      return
    fi
  else
    message "Installing HomeBrew"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval /opt/homebrew/bin/brew shellenv
    chmod -R go-w "$(brew --prefix)/share/zsh"

    message "HomeBrew Installed"
  fi

  wait_for_user
}

install_android_cmd_tools() {
  build_tools_version=$1
  platforms_version=$2

  message "Checking Android SDK Installation..."

  if ! command -v sdkmanager; then
    message "Android SDK is not yet installed or configured."
    action="install"
  else
    echo "$(sdkmanager --list_installed)"
    action="reinstall"
  fi

  if [ $SILENT == 0 ]; then
    read -r -p "\nDo you want to $action Android SDK? ${tty_bold}[y/N]${tty_reset}" response
  fi

  if [[ $SILENT == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    if ! command -v sdkmanager; then
      brew reinstall android-commandlinetools
    fi

    ANDROID_LOCATION=/opt/homebrew/share/android-commandlinetools

    if ! command -v sdkmanager; then
      brew reinstall --cask android-commandlinetools
    fi

    info "Please export the following to you terminal's profile."

    echo "export ANDROID_HOME=$ANDROID_LOCATION"
    echo "export ANDROID_SDK_ROOT=$ANDROID_LOCATION"

    export ANDROID_HOME=$ANDROID_LOCATION
    export ANDROID_SDK_ROOT=$ANDROID_LOCATION

    eval "sdkmanager install \"build-tools;$build_tools_version\" \"platforms;android-$platforms_version\" "

    message "\nAccepting Android SDK License:"
    yes | /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager --licenses
  else
    return
  fi

  wait_for_user
}

install_xcode_cmd_tools() {
  if [ $SILENT == 0 ]; then
    read -r -p "Do you want to set up XCode CLI? ${tty_bold}[y/N]${tty_reset}" response
  fi

  if [[ $SILENT == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    message "Installing XCode:"

    xcode-select --install
    sudo xcodebuild -license accept

    message "XCode Installed"
  else
    return
  fi

  wait_for_user
}

install_ruby() {
  version=$1

  if [ $SILENT == 0 ]; then
    read -r -p "Do you want to set up Ruby? ${tty_bold}[y/N]${tty_reset}" response
  fi

  if [[ $SILENT == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    message "Checking if rvm is installed."

    if ! command -v rvm; then
      echo "Installing rvm."

      brew reinstall gnupg
      gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
      \curl -sSL https://get.rvm.io | bash
    fi

    source ~/.rvm/scripts/rvm
    type rvm | head -n 1

    echo "Installing Ruby $version"

    if "$ruby_version" == "latest"; then
      rvm install --latest
      rvm use --latest
    else
      rvm install $version
      rvm use $version
    fi

    message "Ruby version $(ruby --version) is installed now."
  else
    return
  fi

  wait_for_user
}

install_bundler() {
  bundler_version=$1

  if [ $SILENT == 0 ]; then
    read -r -p "Do you want to set up Bundler? ${tty_bold}[y/N]${tty_reset}" response
  fi

  if [[ $SILENT == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    message "Checking Bundler Installation:"

    if ! command -v bundler; then
      echo "Bundler is already installed. Reinstalling..."
      gem uninstall bundler
    fi

    if "$BUNDLER_TARGET_VERSION" == "latest"; then
      gem install bundler
    else
      gem install bundler --version "$bundler_version"
    fi

    rbenv rehash

    message "$(bundler --version) Installed"
  else
    return
  fi

  wait_for_user
}

install_java() {
  version=$1

  if ! command -v yarn; then
    action="install"
  else
    action="reinstall"
  fi

  if [ $SILENT == 0 ]; then
    read -r -p "Do you want to $action JDK? ${tty_bold}[y/N]${tty_reset}" response
  fi

  if [[ $SILENT == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then

    if [ "$version" == "latest" ]; then
      brew reinstall openjdk
    else
      eval "brew reinstall openjdk@$version"

      message "Linking JDK\n"
      eval "sudo ln -sfn /opt/homebrew/opt/openjdk@$version /opt/homebrew/opt/openjdk"
    fi

    # For the system Java wrappers to find this JDK
    sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
  else
    return
  fi

  wait_for_user
}

install_yarn() {
  if ! command -v yarn; then
    action="install"
  else
    action="reinstall"
  fi

if [ $SILENT == 0 ]; then
  read -r -p "Do you want to $action Yarn? ${tty_bold}[y/N]${tty_reset}" response
  fi

  if [[ $SILENT == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    brew reinstall yarn
  fi
}

remove_environment() {
  message "Cleaning environment before reinstall..."
  brew uninstall openjdk
  brew uninstall android-commandlinetools
  brew uninstall gnupg

  sudo gem uninstall rvm
  sudo gem uninstall bundler

  sudo rm -rf /Library/Developer/CommandLineTools
}

install_environment() {
  git --version 2>&1 >/dev/null
  GIT_IS_AVAILABLE=$?

  #  # Checking if git is installed
  if [[ $GIT_IS_AVAILABLE -eq 0 ]]; then
    install_home_brew
    install_java "$JAVA_VERSION"
    install_android_cmd_tools "$ANDROID_SDK_BUILD_TOOLS_VERSION" "$ANDROID_SDK_PLATFORMS_VERSION"
    install_ruby "$RUBY_VERSION"
    install_bundler "$BUNDLER_VERSION"
    install_xcode_cmd_tools
    install_yarn
  else
    error "\nGit is required in order to proceed. Please install it manually."
  fi
}

check_xcode_installation() {
  message "Checking XCode installation."

  xcode_build_installation_path=$(/usr/bin/xcodebuild -version)
  xcode_cli_installation_path=$(xcode-select --print-path)
  xcode_cli_version=$(xcode-select --version)

  # Checking if xcode is installed
  if command -v xcodebuild >/dev/null; then
    printf "%sxcode path: $xcode_cli_installation_path\n"
    printf "%sxcode version: $xcode_build_installation_path\n"
    printf "%s$xcode_cli_version\n\n"

    if [ $CLEAN_INSTALL == 1 ]; then
      remove_environment
    fi
    install_environment
  else
    error "XCode must be installed manually before running this script!"
  fi
}

check_xcode_installation

message "Finished Enviroment Setup."
abort
