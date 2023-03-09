#!/bin/sh
# Bash script for installing/updating a build environment

source utility-functions.sh

install_home_brew() {
   message "Checking HomeBrew installation."

  # checking if homebrew is already installed
  if command -v brew >/dev/null 2>&1; then
    message "HomeBrew is already installed."
    printf "%s$(brew -v)\n"

    read -r -p "Do you want to update HomeBrew? Type ${tty_bold}y${tty_reset} to update. Type ${tty_bold}n${tty_reset} to skip. [y/N] " response
    if [[ "$response" =~ ^[yY]$ ]]
    then
      message "Updating HomeBrew"
      brew update
      wait_for_user
    else
      return
      wait_for_user
    fi
  else
    message "Installing HomeBrew"

    HOME_BREW_EVAL="$(/opt/homebrew/bin/brew shellenv)"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # exporting homebrew env variable
    echo "eval $HOME_BREW_EVAL" >>~/.zprofile
    eval HOME_BREW_EVAL

    message "HomeBrew Installed"
    wait_for_user
  fi
}

install_android_cmd_tools() {
  message "Installing Android SDK:"

  ANDROID_LOCATION=/opt/homebrew/share/android-commandlinetools

  brew install --cask android-commandlinetools
  export ANDROID_HOME=$ANDROID_LOCATION
  export ANDROID_SDK_ROOT=$ANDROID_LOCATION
  echo "export ANDROID_HOME=$ANDROID_LOCATION" >>~/.zprofile
  echo "export ANDROID_SDK_ROOT=$ANDROID_LOCATION" >>~/.zprofile

  message "\nAccepting Android SDK License:"
  /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager --licenses

  message "\nAndroid SDK Installed"
  wait_for_user
}

install_xcode_cmd_tools() {
  message "\nInstalling XCode:"

  xcode-select --install
  sudo xcodebuild -license accept

  message "\nXCode Installed"
  wait_for_user
}

install_ruby() {
  message "Installing Ruby:"

  arch -arm64 brew install rbenv ruby-build
  eval "$(rbenv init - zsh)"

  message "Ruby Installed"
  wait_for_user
}

install_bundler() {
  message "Installing Bundler:"

  sudo gem install bundler
  rbenv rehash

  message "Bundler Installed"
  wait_for_user
}

install_java() {
  message "Checking Java Installation"

  brew install openjdk
  sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk

  message "\nJava Installed"
  wait_for_user
}

install_environment() {
  git --version 2>&1 >/dev/null
  GIT_IS_AVAILABLE=$?

  # Checking if git is installed
  if [[ $GIT_IS_AVAILABLE -eq 0 ]]; then
    install_home_brew
    install_java
    install_android_cmd_tools
    install_xcode_cmd_tools
    install_ruby
    install_bundler
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
  if [[ -n "$xcode_cli_installation_path" ]] && [[ -x /Applications/Xcode.app ]]; then
    printf "%sxcode path: $xcode_cli_installation_path\n"
    printf "%sxcode version: $xcode_build_installation_path\n"
    printf "%s$xcode_cli_version\n\n"

    install_environment
  else
    error "XCode must be installed manually before running this script!"
  fi
}

check_xcode_installation

message "Finished Enviroment Setup."
abort
