# ScreenChat

iOS Tweak for non-jailbroken devices to avoid screenshot detection on Snapchat app

This is a test, not a project for invading the privacy of users. I am not responsible for any use which can give a user of this.

###Current features:
* Block screenshot detection
* Remove caption character limit
* Remove timer and timer UI

###Planned features:
* Saving to camera roll

#####Thanks to
* [andugu](https://github.com/andugu) (me) for the main source code.
* [dado3212](https://github.com/dado3212) for the extra features he added, and the implementation of a new signing method.
* Giovanni Di Grezia, whose [code](http://www.xgiovio.com/blog-photos-videos-other/blog/resign-your-ios-ipa-frameworks-and-plugins-included/) served as the basis for the (upcoming) patchapp.sh revisions.
* [alexzielenski](https://github.com/alexzielenski) for optool.
* [BishopFox](https://github.com/BishopFox) for theos-jailed.


How to install
============

###Requirements

* iOS device
* Apple Developer account or certificates
* XCode with iPhone SDK
* Decrypted ipa file of the app
* [optool](https://github.com/alexzielenski/optool/releases)
* [theos-jailed](https://codeload.github.com/BishopFox/theos-jailed/zip/master)
* iModSign?

###Steps

* Uninstall Snapchat from the iOS device.
* Extract or download an Snapchat decrypted ipa file.
* Place an symlink in the tweak folder named `theos` pointing to the theos-jailed folder you downloaded.
* Place the optool binary you downloaded on the tweak folder.
* Run `make package`
* Run `./patchapp.sh info /path/to/your/file.ipa`
* Take the information from that and use the Apple Member Center to create a matching Provisionin Profile or create an empty Xcode project and use the Provisionin Profile of the project.
* Save the Provisioning Profile somewhere on your computer.
* Run `./patchapp.sh patch /path/to/Snapchat.ipa /path/to/your/file.mobileprovision` to inject the tweak into the .ipa
* Install the ipa to the device
* If Xcode gives you an "unknown error" resign the ipa with iModSign and install it with Xcode, this fixed the problem for me :)
