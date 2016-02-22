# ScreenChat

iOS Tweak for non-jailbroken devices to avoid screenshot detection on Snapchat app

This is a test, not a project for invading the privacy of users. I am not responsible for any use which can give a user of this.

Requirements
============
* iOS device
* Apple Developer account or certificates
* XCode with iPhone SDK
* Decrypted ipa file of the app
* [optool](https://github-cloud.s3.amazonaws.com/releases/22631446/0b1ec9dc-30a6-11e4-9203-69b6df10bc50.zip?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAISTNZFOVBIJMK3TQ%2F20160222%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20160222T064146Z&X-Amz-Expires=300&X-Amz-Signature=6e3a9c66771d0dacaf8601cd42f9e84b31a20f2353a552f343978d2590212e30&X-Amz-SignedHeaders=host&actor_id=8087896&response-content-disposition=attachment%3B%20filename%3Doptool.zip&response-content-type=application%2Foctet-stream)
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
