# ScreenChat

iOS Tweak for non-jailbroken devices to avoid screenshot detection on Snapchat app

This is a test, not a project for invading the privacy of users. I am not responsible for any use which can give a user of this.

###Current features:
* Block screenshot detection
* Remove caption character limit by dado3212
* Remove timer and timer UI by dado3212
* Saving to camera roll by dado3212

#####Thanks to
* [andugu](https://github.com/andugu) (me) for the main source code.
* [dado3212](https://github.com/dado3212) for the extra features he added, and the implementation of an alternative signing method.
* Giovanni Di Grezia, whose [code](http://www.xgiovio.com/blog-photos-videos-other/blog/resign-your-ios-ipa-frameworks-and-plugins-included/) served as the basis for the patchapp.sh revisions.
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

###Steps

* Uninstall Snapchat from the iOS device.
* Extract or download an Snapchat decrypted ipa file.
* Place an symlink in the project folder named `theos` pointing to the theos-jailed folder you downloaded: `ln -s /path/to/theos-jailed/ theos`
* Place the optool binary you downloaded on the tweak folder.
* Run `make package`
* Run `./patchapp-2.sh info /path/to/your/file.ipa`
* Take the information from that and use XCode to create a Provisioning Profile
* Here we have two different methods, choose the one that works for you!

1) Run `./patchapp-2.sh patch /path/to/Snapchat.ipa BUNDLE_ID` to inject the tweak into the .ipa (get the BUNDLE_ID from the info command)

2) Or run `./patchapp-1.sh patch /path/to/Snapchat.ipa /path/to/.mobileprovision`

* If you used the first method install the .mobileprovision to the device, and if you used the second one you should resign the ipa file with iModSign.
* Install the ipa to the device
