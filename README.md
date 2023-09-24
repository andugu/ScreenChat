# 📱👻 ScreenChat
ScreenChat is a Proof of Concept (POC) open-source iOS tweak that allows developers and exploiters to inject custom code
into a Snapchat application (`.ipa`), even on Non-Jailbroken iOS Devices.

This project was originally developed as part of a **scholarly exploration** into the **potential attack vectors**
and vulnerabilities of **iOS systems**.

During the course of this project, it was found that due to the extensive permissions granted to some applications
(including access to the camera, microphone, contacts, etc), an attacker could access such resources by injecting
malicious code into an application file (`.ipa`), and later convincing the victim to install the malicious package.

While more advanced exploitation techniques can be challenging to achieve, this one proved to be the cheapest, but yet 
highly effective way to extract private data from an iOS device. Since there are no vulnerabilities involved in the
process, and it's the victim itself the one installing the malicious payload into its device.
Plus, the demand for modified applications was on the rising.

## Disclaimer
It's essential to recognize that this project is intended for **research and educational purposes only**.
By using this software, you acknowledge and assume all responsibilities derived from its use. Misuse of this project may
lead to account bans, privacy violations, and even legal consequences. **Please, use it responsibly and ethically.**

## Installation Guide

### Prerequisites
Before installing ScreenChat, ensure you have the following prerequisites in place:

- An iOS device
- An Apple Developer account or valid certificates
- XCode with the iPhone SDK
- A decrypted IPA file of the Snapchat app
- [optool](https://github.com/alexzielenski/optool/releases)
- [theos-jailed](https://codeload.github.com/BishopFox/theos-jailed/zip/master)

### Installation Steps
Follow these steps to successfully install ScreenChat:

1. **Uninstall Snapchat**: Start by uninstalling the Snapchat app from your iOS device.
2. **Decrypted IPA File**: Obtain or extract a decrypted IPA file of the Snapchat app.
3. **Set Up theos**: Create a symbolic link in your project folder named `theos`, pointing to the theos-jailed 
folder you downloaded. Use the following command:
   ```
   ln -s /path/to/theos-jailed/ theos
   ```
4. **Include optool**: Place the optool binary you downloaded into the tweak folder.
5. **Package Creation**: Run the following command to create a package:
   ```
   make package
   ```
6. **Provisioning Profile**: Use XCode to create a Provisioning Profile based on the information obtained from the
following command:
   ```
   ./patchapp-2.sh info /path/to/your/file.ipa
   ```
7. **Choose a Signing Method**: You have two options for injecting the tweak into the Snapchat IPA:
   - Option 1: Run the following command to inject the tweak:
     ```
     ./patchapp-2.sh patch /path/to/Snapchat.ipa BUNDLE_ID
     ```
     (Retrieve the BUNDLE_ID from the previous info command)
   - Option 2: Alternatively, run the following command to patch the IPA:
     ```
     ./patchapp-1.sh patch /path/to/Snapchat.ipa /path/to/.mobileprovision
     ```
   Depending on your chosen method, either install the `.mobileprovision` to the device or resign the IPA file with
`iModSign.`
8. **Install IPA**: Finally, install the modified IPA file onto your iOS device.

## Acknowledgments
We would like to express our gratitude to the following individuals and projects for their contributions to ScreenChat:

- [andugu](https://github.com/andugu) (Author of the main source code)
- [dado3212](https://github.com/dado3212) (Contributor for additional features and an alternative signing method)
- Giovanni Di Grezia, whose [code](http://www.xgiovio.com/blog-photos-videos-other/blog/resign-your-ios-ipa-frameworks-and-plugins-included/)
served as the foundation for the `patchapp.sh` revisions
- [alexzielenski](https://github.com/alexzielenski) (Creator of optool)
- [BishopFox](https://github.com/BishopFox) (Creators of theos-jailed)
- [iMokhles](https://github.com/iMokhles) (Contributor for bug fixes and improved `arm64` compatibility)
