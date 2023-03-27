#!/bin/bash
# Shell script for installing/updating a build environment

# Global versions, flags and variables

NONINTERACTIVE=0
export NONINTERACTIVE

HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ENV_HINTS

# Local versions, flags and variables

home_dir=~
eval home_dir=$home_dir

JAVA_VERSION="latest"                    # Possible values: 8, 11, 17, latest
RUBY_VERSION="latest"                    # Possible values: release number, latest
NODE_VERSION="latest"                    # Possible values: 10, 12, 14, 16, 18, latest
BUNDLER_VERSION="latest"                 # Possible values: release number, latest
ANDROID_SDK_PLATFORMS_VERSION="33"       # Possible values: https://developer.android.com/studio/releases/platforms
ANDROID_SDK_BUILD_TOOLS_VERSION="33.0.1" # Possible values: https://developer.android.com/studio/releases/build-tools

REQUIRE_XCODE_VERSION="any"   # Will abort execution if required XCode version was not installed manually. Value "any" skips the check.
REQUIRE_ASTUDIO_VERSION="any" # Will show warning if required Android Studio build is not detected in the Applications folder. Value "any" skips the check.

CLEAN_INSTALL=0 # Removes the environment prior to the installation.

SHELL_PROFILE_PATH="" # Path to the shell's profile file.

# Parsing flags and arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
  --interactive)
    if [ $2 == 0 ]; then
      export NONINTERACTIVE=1
    elif [ $2 == 1 ]; then
      export NONINTERACTIVE=0
    fi
    shift 2
    ;;
  --clean)
    CLEAN_INSTALL=$2
    shift 2
    ;;
  --version-java)
    JAVA_VERSION="$2"
    shift 2
    ;;
  --version-ruby)
    RUBY_VERSION="$2"
    shift 2
    ;;
  --version-node)
    NODE_VERSION="$2"
    shift 2
    ;;
  --version-bundler)
    BUNDLER_VERSION="$2"
    shift 2
    ;;
  --version-android-platforms)
    ANDROID_SDK_PLATFORMS_VERSION="$2"
    shift 2
    ;;
  --version-android-build)
    ANDROID_SDK_BUILD_TOOLS_VERSION="$2"
    shift 2
    ;;
  --require-version-xcode)
    REQUIRE_XCODE_VERSION="$2"
    shift 2
    ;;
  --require-version-astudio)
    REQUIRE_ASTUDIO_VERSION="$2"
    shift 2
    ;;
  --shell-profile-name)
    SHELL_PROFILE_PATH="$home_dir/$2"
    touch "$SHELL_PROFILE_PATH"
    shift 2
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

# Utility Functions

# Red
error() {
  printf "\n"
  printf $(tput setaf 1)"%s\n" "Error: $1" "${@:2}" $(tput sgr0) >&2
  abort
}

warning() {
  printf $(tput setaf 1)"%s" "$@" $(tput sgr0) >&2
  printf "\n"
}

# Green
message() {
  if [ $NONINTERACTIVE == 0 ]; then
    printf $(tput setaf 2)"%s" "$@" $(tput sgr0) >&2
    printf "\n"
  fi
}

# Yellow
info() {
  if [ $NONINTERACTIVE == 0 ]; then
    printf $(tput setaf 3)"%s" "$@" $(tput sgr0) >&2
    printf "\n"
  fi
}

print_header() {
  printf "\n"
  message "### $1 ###"
  printf "\n"
  info "Checking installation..."
  printf "\n"
}

# String formatting

if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi

tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

# User input

getc() {
  local save_state
  save_state="$(/bin/stty -g)"
  /bin/stty raw -echo
  IFS='' read -r -n 1 -d '' "$@"
  /bin/stty "${save_state}"
}

abort() {
  local c
  echo
  echo "Press ${tty_bold}ANY KEY${tty_reset} to exit."
  getc c
  exit 1
}

wait_for_user() {
  if [ $NONINTERACTIVE == 0 ]; then
    local c
    echo
    echo "Press ${tty_bold}RETURN${tty_reset}/${tty_bold}ENTER${tty_reset} to continue or any other key to abort..."
    getc c
    # we test for \r and \n because some stuff does \r instead
    if ! [[ "${c}" == $'\r' || "${c}" == $'\n' ]]; then
      exit 1
    fi
  fi
}

# copy to the buffer

set_shell_profile_path() {
  if [ ! "$SHELL_PROFILE_PATH" ]; then
    if [ "$SHELL" == "/bin/zsh" ]; then
      SHELL_PROFILE_PATH="$home_dir/.zshrc"
    elif [ "$SHELL" == "/bin/bash" ]; then
      SHELL_PROFILE_PATH="$home_dir/.bash_profile"
    fi
  fi

  touch "$SHELL_PROFILE_PATH"
}

install_home_brew() {
  print_header "HOMEBREW"

  # checking if homebrew is already installed
  if command -v brew >/dev/null 2>&1; then
    info "Current HomeBrew installation:"
    printf "%s$(brew -v)\n\n"

    if [ $NONINTERACTIVE == 0 ]; then
      read -r -p "Do you want to update HomeBrew? ${tty_bold}[y/N]${tty_reset} " response
    fi

    if [[ $NONINTERACTIVE == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
      message "Updating HomeBrew"
      brew update
    else
      return
    fi
  else
    message "Installing HomeBrew"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "/opt/homebrew/bin/brew shellenv"
    chmod -R go-w "$(brew --prefix)/share/zsh"

    message "HomeBrew Installed"
  fi

  wait_for_user
}

install_android_cmd_tools() {
  local build_tools_version=$1
  local platforms_version=$2
  local required_as_build_number=$3

  print_header "ANDROID SDK"

  if ! [ -x "$(command -v sdkmanager)" ]; then
    local action="install"

    info "Android SDK manager is not yet installed."
  else
    local action="reinstall"

    info "Current Android SDK installation:"
    printf "%s$(sdkmanager --list_installed)\n"

    local ANDROID_STUDIO_PATH="/Applications/Android Studio.app"

    if [ -x "$ANDROID_STUDIO_PATH" ]; then
      local as_build_number
      as_build_number="$(cat "$ANDROID_STUDIO_PATH"/Contents/Resources/build.txt)"

      printf "%s\n  Android Studio: $as_build_number\n"
      printf "%s  Android Studio path: $ANDROID_STUDIO_PATH\n\n"

      if ! [[ "$as_build_number" == *"$required_as_build_number"* ]] && [ "$required_as_build_number" != "any" ]; then
        warning "WARNING: Detected Android Studio installation build number doesn't match required one: $required_as_build_number."
        printf "\n"
      fi
    else
      printf "\n"
      warning "WARNING: Could not detect Android Studio installation. It's not necessary, but you may want to install it manually if you plan on using bundled SDK."
      printf "\n"
    fi
  fi

  if [ $NONINTERACTIVE == 0 ]; then
    read -r -p "Do you want to $action Android SDK? Selected build-tools version: $build_tools_version; platforms version: $platforms_version ${tty_bold}[y/N]${tty_reset} " response
  fi

  if [[ $NONINTERACTIVE == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    brew reinstall android-commandlinetools

    local ANDROID_LOCATION=/opt/homebrew/share/android-commandlinetools
    local ANDROID_HOME="export ANDROID_HOME=$ANDROID_LOCATION"
    local ANDROID_SDK_ROOT="export ANDROID_SDK_ROOT=$ANDROID_LOCATION"
    local EXPORT_SDK_ROOT="export PATH=\$ANDROID_HOME:\$PATH"
    local EXPORT_TOOLS="export PATH=\$ANDROID_HOME/tools:\$PATH"
    local EXPORT_PLATFORM_TOOLS="export PATH=\$ANDROID_HOME/platform-tools:\$PATH"

    printf "\n"
    info "Please export the following to you terminal's profile:"
    printf "\n"
    message "  $ANDROID_HOME"
    message "  $ANDROID_SDK_ROOT"
    message "  $EXPORT_SDK_ROOT"
    message "  $EXPORT_TOOLS"
    message "  $EXPORT_PLATFORM_TOOLS"

    printf "\n"
    info "You may as well want to set the sdk path in your projects manually. For that copy and paste this in your project's local.properties:"
    printf "\n"
    message "  sdk.dir=$ANDROID_LOCATION"
    printf "\n"

    if [ $NONINTERACTIVE == 0 ]; then
      read -r -p "Do you want to open your shell profile file? The export variables will be copied to the clipboard you just need paste them and save the file. ${tty_bold}[y/N]${tty_reset} " response
    fi

    if [[ $NONINTERACTIVE == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
      echo -e "$ANDROID_HOME\n$ANDROID_SDK_ROOT\n$EXPORT_SDK_ROOT\n$EXPORT_TOOLS\n$EXPORT_PLATFORM_TOOLS" | pbcopy
      nano "$SHELL_PROFILE_PATH"
    fi

    eval "$ANDROID_HOME"
    eval "$ANDROID_SDK_ROOT"

    printf "\n"
    message "Updating packages..."
    printf "\n"
    eval "sdkmanager \"build-tools;$build_tools_version\" \"platforms;android-$platforms_version\" "

    message "Accepting Android SDK Licenses..."
    printf "\n"

    eval "yes | /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager --licenses"
  else
    return
  fi

  wait_for_user
}

install_ruby() {
  local version=$1

  print_header "RUBY"

  if [ -x "$(command -v ruby)" ]; then
    local action="reinstall"

    info "Current Ruby installation:"
    printf "%s$(ruby --version)\n\n"
  else
    local action="install"

    info "Ruby is not yet installed."
  fi

  if [ $NONINTERACTIVE == 0 ]; then
    read -r -p "Do you want $action Ruby? Selected version: $version ${tty_bold}[y/N]${tty_reset} " response
  fi

  if [[ $NONINTERACTIVE == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    message "Checking if rvm is installed."

    if ! [ -x "$(command -v rvm)" ]; then
      echo "Installing rvm."

      brew reinstall gnupg
      gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
      \curl -sSL https://get.rvm.io | bash
    fi

    source $home_dir/.rvm/scripts/rvm
    type rvm | head -n 1

    echo "Installing Ruby $version"

    export warnflags=-Wno-error=implicit-function-declaration

    if [ "$version" = "latest" ]; then
      eval "rvm install ruby --latest"
      eval "rvm use ruby --latest --default"
    else
      rvm reinstall "$version" --disable-dtrace
      rvm use "$version --default"
    fi

    message "Ruby version $(ruby --version) is installed now."
  else
    return
  fi

  wait_for_user
}

install_bundler() {
  local version=$1

  print_header "BUNDLER"

  if ! [ -x "$(command -v bundler)" ]; then
    local action="install"

    info "Bundler is not yet installed."
  else
    local action="reinstall"

    info "Current Bundler installation:"
    printf "%s$(bundler --version)\n\n"
  fi

  if [ $NONINTERACTIVE == 0 ]; then
    read -r -p "Do you want to $action Bundler? Selected version: $version ${tty_bold}[y/N]${tty_reset} " response
  fi

  if [[ $NONINTERACTIVE == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    message "Checking Bundler Installation:"

    if ! [ -x "$(command -v bundler)" ]; then
      echo "Bundler is already installed. Reinstalling..."
      gem uninstall bundler
    fi

    if [ "$version" == "latest" ]; then
      gem install bundler
    else
      gem install bundler --version "$version"
    fi

    rbenv rehash

    message "$(bundler --version) Installed"
  else
    return
  fi

  wait_for_user
}

install_java() {
  local version=$1

  print_header "JDK"

  if ! [ -x "$(command -v java)" ]; then
    local action="install"

    info "JDK is not yet installed."
  else
    local action="reinstall"

    info "Current JDK installation:"
    printf "%s$(java --version)\n\n"
  fi

  if [ $NONINTERACTIVE == 0 ]; then
    read -r -p "Do you want to $action JDK? Selected version: $version ${tty_bold}[y/N]${tty_reset} " response
  fi

  if [[ $NONINTERACTIVE == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then

    if [ "$version" == "latest" ]; then
      brew reinstall openjdk
    else
      eval "brew reinstall openjdk@$version"

      message "Linking JDK"
      eval "sudo ln -sfn /opt/homebrew/opt/openjdk@$version /opt/homebrew/opt/openjdk"
    fi

    local EXPORT_CPPFLAGS="export CPPFLAGS=\"-I/opt/homebrew/opt/openjdk/include\""
    local EXPORT_JAVA_HOME="export JAVA_HOME=/opt/homebrew/opt/openjdk"
    local EXPORT_PATH="export PATH=\$JAVA_HOME/bin:\$PATH"

    printf "\n"
    info "Please export the following to you terminal's profile."
    printf "\n"
    message " $EXPORT_CPPFLAGS"
    message " $EXPORT_JAVA_HOME"
    message " $EXPORT_PATH"

    if [ $NONINTERACTIVE == 0 ]; then
      printf "\n"
      read -r -p "Do you want to open your shell profile? The export variables will be copied to the clipboard you just need paste them and save the file. ${tty_bold}[y/N]${tty_reset} " response
    fi

    if [[ $NONINTERACTIVE == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
      echo -e "$EXPORT_CPPFLAGS\n$EXPORT_JAVA_HOME\n$EXPORT_PATH" | pbcopy

      nano $SHELL_PROFILE_PATH
    fi

    # For the system Java wrappers to find this JDK
    sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
  else
    return
  fi

  wait_for_user
}

install_yarn() {
  local node_version=$1
  print_header "YARN"

  if ! [ -x "$(command -v yarn)" ]; then
    local action="install"
  else
    local action="reinstall"

    info "Current Yarn installation:"
    printf "%s$(yarn --version)\n\n"
  fi

  if [ $NONINTERACTIVE == 0 ]; then
    read -r -p "Do you want to $action Yarn? ${tty_bold}[y/N]${tty_reset} " response
  fi

  if [[ $NONINTERACTIVE == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    if [ "$node_version" == "latest" ]; then
      brew reinstall node
    else
      brew reinstall "node@$node_version"
    fi

    brew reinstall yarn
  else
    return
  fi

  wait_for_user
}

check_and_install_xcode() {
  local require_version=$1
  print_header "XCODE"

  if ! [ -x "$(command -v xcodebuild)" ]; then
    error "XCode must be installed manually before running this script!"
  else
    local xcode_build_version
    xcode_build_version="$(/usr/bin/xcodebuild -version)"

    info "Current XCode installation:"
    printf "%sxcode version: $xcode_build_version\n"

    if ! [[ "$xcode_build_version" == *"$require_version"* ]] && [ "$require_version" != "any" ]; then
      error "Required XCode installation version $require_version. Please install required version manually and run te script again."
    fi
  fi

  print_header "XCODE CLI"

  if ! [ -x "$(command -v xcode-select)" ]; then
    local action="install"
  else
    local action="reinstall"

    local xcode_cli_installation_path
    xcode_cli_installation_path="$(xcode-select --print-path)"
    local xcode_cli_version
    xcode_cli_version="$(xcode-select --version)"

    info "Current XCode CLI installation:"
    printf "%sxcode path: $xcode_cli_installation_path\n"
    printf "%s$xcode_cli_version\n\n"
  fi

  if [ $NONINTERACTIVE == 0 ]; then
    read -r -p "Do you want to $action XCode CLI? ${tty_bold}[y/N]${tty_reset} " response
  fi

  if [[ $NONINTERACTIVE == 1 ]] || [[ "$response" =~ ^[yY]$ ]]; then
    message "Installing XCode Command Line Tools:"
    printf "\n"

    xcode-select --install
    sudo xcodebuild -license accept

    printf "\n"
    message "XCode Installed"
  else
    return
  fi

  wait_for_user
}

remove_environment() {
  message "Cleaning environment before reinstall..."

  brew uninstall openjdk
  brew uninstall android-commandlinetools
  brew uninstall gnupg

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

  sudo gem uninstall rvm
  sudo gem uninstall bundler

  sudo rm -rf /Library/Developer/CommandLineTools
}

install_environment() {
  git --version 2>&1 >/dev/null
  local GIT_IS_AVAILABLE=$?

  #  # Checking if git is installed
  if [[ $GIT_IS_AVAILABLE -eq 0 ]]; then
    set_shell_profile_path

    if [ $CLEAN_INSTALL == 1 ]; then
      remove_environment
    fi

    # The order of install calls must be preserved
    check_and_install_xcode "$REQUIRE_XCODE_VERSION"
    install_home_brew
    install_java "$JAVA_VERSION"
    install_android_cmd_tools "$ANDROID_SDK_BUILD_TOOLS_VERSION" "$ANDROID_SDK_PLATFORMS_VERSION" "$REQUIRE_ASTUDIO_VERSION"
    install_ruby "$RUBY_VERSION"
    install_bundler "$BUNDLER_VERSION"
    install_yarn "$NODE_VERSION"
  else
    error "Git is required in order to proceed. Please install it manually."
  fi
}

install_environment

message "Finished Environment Setup."
