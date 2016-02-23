# ScreenChat

iOS Tweak for non-jailbroken devices to avoid screenshot detection on Snapchat app

This is a test, not a project for invading the privacy of users. I am not responsible for any use which can give a user of this.

Requirements
============
* iOS device
* Apple Developer account or certificates
* XCode with iPhone SDK
* Decrypted ipa file of the app
* [optool](https://github.com/alexzielenski/optool/releases)
* [theos-jailed] (https://codeload.github.com/BishopFox/theos-jailed/zip/master)
* iModSign?

How to install
============
* Uninstall Snapchat from the iOS device.
* Extract or download an Snapchat decrypted ipa file.
* Place an symlink in the project folder named `theos` pointing to the theos-jailed folder you downloaded.
* Edit the `patchapp.sh`, change the first variable with the path to the optool binary you downloaded.
* Run `make package`
* Run `./patchapp.sh info /path/to/your/file.ipa`
* Take the information from that and use the Apple Member Center to create a matching Provisionin Profile or create an empty Xcode project and use the Provisionin Profile of the project.
* Save the Provisioning Profile somewhere on your computer.
* Run `.patchapp.sh patch /path/to/Snapchat.ipa /path/to/your/file.mobileprovision` to inject the tweak into the .ipa
* Install the ipa to the device
* If Xcode gives you an "unknown error" resign the ipa with iModSign and install it with Xcode, this fixed the problem for me :)
