<style>
r { color: Red }
o { color: Orange }
g { color: Green }
</style>

# Environment Configurator

***

## What is it for?

It's a fairly simple and straightforward script purposed for configuring(installing/updating) a build environment for KMM and React Native projects:
* XCode CLI
* Ruby
* CocoaPods
* JDK
* Android SDK
* Bundler
* Node
* Yarn

<g>*If you find any bug or have improvement ideas but can't contribute, feel free to add to the TODO section at the bottom of this README ;)*</r>


***

## How to use it?

Simply call:
```
/bin/bash install-enviroment.sh
```

<o>**Important!**</o> Always execute the script under `bash`. It doesn't work well with `zsh`.

### Arguments

All arguments are optional to use. If you don't include one the corresponding default value will be used.

### `--interactive <flag>` 
**Values**: `0`, `1` - *default* 

**Description**: Interactive mode allows user input. Useful if you want to install/update only certain dependency or just check versions.

### `--clean <flag>`
**Values**: `0` - *default*, `1`

**Description**: In clean mode the environment gets removed before reinstalling it. <o>**Keep in mind that expressions and `PATH` variables exported to your shell profile will not be removed. You must reset them manually.**</o>


### `--version-java <version>`
**Values**: `8`, `11`, `17`, `latest` - *default*

**Description**: Sets the desired version for the JDK package.

### `--version-ruby <version>`
**Values**: `<version_name>`(e.g. `3.2.1`), `latest` - *default*

**Description**: Sets the desired version for the Ruby package. Choosing to install Ruby you also install RVM from HomeBrew which is used for switching between Rubies.

### `--version-android-build <version>`
**Values**: `<version_name>`, `33.0.1` - *default*

**Description**: Sets the desired version for the Android SDK Build package. Installing different version doesn't remove already installed ones.

### `--version-android-platforms <version>`
**Values**: `<version_code>`, `33` - *default*

**Description**: Sets the desired version for the Android SDK Platforms package. Installing different version doesn't remove already installed ones.

### `--version-node <version>`
**Values**: `10`, `12`, `14`, `16`, `18`, `latest` - *default*

**Description**: Sets the desired version for the Node package.

### `--require-version-xcode <version>`
**Values**: `<version_name>`(e.g. `14.2`), `any` - *default*

**Description**: Sets the exact version that must be installed manually in order for the script to succeed. In case this requirement is not met the execution will fail with an error message.

### `--require-version-astudio <version>`
**Values**: `<build_name>`(e.g. `AI-221.6008.13.2211.9619390`), `any` - *default*

**Description**: Sets the desired target build version of Android Studio. <o>**This requirement is not strict and will not fail the execution but just display an error message.**</o>

***

# TODO

-[x] ~~Write README.~~
-[ ] Add possibility to install multiple Android SDK versions at once.

***