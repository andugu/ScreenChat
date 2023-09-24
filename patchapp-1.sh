#!/bin/bash

#
# You WILL need to change this
#
OPTOOL="./optool"

#
# You shouldn't need to change these unless you have multiple Dev certs
#
COMMAND=$1
IPA=$2
MOBILEPROVISION=$3
DEV_CERT_NAME="iPhone Developer"
CODESIGN_NAME=`security dump-keychain login.keychain|grep "$DEV_CERT_NAME"|head -n1|cut -f4 -d \"|cut -f1 -d\"`
TMPDIR=".patchapp.cache"
TWEAKNAME=`grep TWEAK_NAME Makefile 2>/dev/null | awk '{print $3}'`
DYLIB=obj/$TWEAKNAME.dylib

#
# Usage / syntax
#
function usage {
	if [ "$2" == "" -o "$1" == "" ]; then
		cat <<USAGE
Syntax: $0 <command> </path/to/your/ipa/file.ipa> [/path/to/your/file.mobileprovision]"
Where 'command' is one of:"
	info  - Show the information required to create a Provisioning Profile
	        that matches the specified .ipa file
	patch - Inject the current Theos tweak into the specified .ipa file.
	        Requires that you specify a .mobileprovision file.

USAGE
	fi
}

#
# Setup all the things.
#
function setup_environment {
	if [ "$IPA" == "" ]; then
		usage
		exit 1
	fi
	if [ ! -r "$IPA" ]; then
		echo "$IPA not found or not readable"
		exit 1
	fi

	# setup
	rm -rf "$TMPDIR" >/dev/null 2>&1
	mkdir "$TMPDIR"
	SAVED_PATH=`pwd`

	# uncompress the IPA into tmpdir
	echo '[+] Unpacking the .ipa file ('"`pwd`/$IPA"')...'
	unzip -o -d "$TMPDIR" "$IPA" >/dev/null 2>&1
	if [ "$?" != "0" ]; then
		echo "Couldn't unzip the IPA file."
		exit 1
	fi

	cd "$TMPDIR"
	cd Payload/*.app
	if [ "$?" != "0" ]; then
		echo "Couldn't change into Payload folder. Wat."
		exit 1
	fi
	APP=`pwd`
	APP=${APP##*/}
	APPDIR=$TMPDIR/Payload/$APP
	cd "$SAVED_PATH"
	BUNDLE_ID=`plutil -convert xml1 -o - $APPDIR/Info.plist|grep -A1 CFBundleIdentifier|tail -n1|cut -f2 -d\>|cut -f1 -d\<`-patched
	APP_BINARY=`plutil -convert xml1 -o - $APPDIR/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`

	file "$APPDIR/$APP_BINARY" | grep "universal binary" 2>/dev/null 1>&2
	if [ "$?" == "0" ]; then
		lipo "$APPDIR/$APP_BINARY" -thin armv7 -output "$APPDIR/$APP_BINARY".new
		cp "$APPDIR/$APP_BINARY".new "$APPDIR/$APP_BINARY"
		rm -f "$APPDIR/$APP_BINARY".new
	fi

}

#
# Show the user the information necessary to generate a .mobileprovision
#
function ipa_info {

	setup_environment
	
	cat <<INFO

=================
= Prerequisites =
=================
1. Patience and luck
2. XCode and iPhone SDK
3. iOS Developer Account with Apple
4. An .ipa file that's already been decrypted using Clutch
   Note: Encrypted apps WILL NOT work. Don't bother trying. Use Clutch.

==================
= What to do now =
==================
1. Build your Theos tweak if you haven't already done so. Just run "make".
2. Create a provisioning profile for this app (run "$0 info $IPA" for help)
3. Run "$0 patch $IPA /path/to/your/file.mobileprovision" to patch the .ipa
4. Install the patched .ipa to your device using XCode 

=====================================
= Creating the provisioning profile =
=====================================
1. Sign into the Apple Member Center: 
		https://developer.apple.com/membercenter/index.action
2. Choose "Certificates, Identifiers & Profiles"
3. From "iOS Apps" choose "Identifiers"
4. Add a new App ID with the following information:
	a. For "Explicit App ID" / "Bundle ID" use: $BUNDLE_ID
	b. Under "App Services" enable the following services:

INFO
	codesign -d --entitlements - "$APPDIR/$APP_BINARY" > entitlements.xml 2>/dev/null
	if [ "$?" != "0" ]; then
		echo "Failed to get entitlements for $APPDIR/$APP_BINARY"
		exit 1
	fi
	for ent in `grep -a '<key>' entitlements.xml`; do
		entitlement=`echo $ent | cut -f2 -d\> | cut -f1 -d\<`
		case $entitlement in
			com.apple.developer.networking.vpn.api)
				echo ">>> VPN Configuration & Control"
				;;
			com.apple.developer.in-app-payments)
				echo ">>> Apple Pay (requires extra configuration)"
				;;
			com.apple.external-accessory.wireless-configuration)
				echo ">>> Wireless Accessory Configuration"
				;;
			com.apple.developer.homekit)
				echo ">>> HomeKit"
				;;
			com.apple.security.application-groups)
				echo ">>> App Groups:"
				for group in `dd if=entitlements.xml bs=1 skip=8 2>/dev/null|sed -ne '/application-groups/,/<\/array/p'|grep '<string>' 2>/dev/null`; do #|tail -n1` #|cut -f2 -d\>|cut -f1 -d\<`
					GROUP_ID=`echo $group | cut -f2 -d\>|cut -f1 -d\<`-patched
					echo "    $GROUP_ID"
				done				
				;;
			com.apple.developer.associated-domains)
				echo ">>> Associated Domains"
				;;
			com.apple.developer.healthkit)
				echo ">>> HealthKit"
				;;
			inter-app-audio)
				echo ">>> Inter-App Audio"
				;;
			com.apple.developer.ubiquity*)
				echo ">>> Passbook"
				echo ">>> iCloud (requires extra configuration)"
				echo ">>> Data Protection"
				;;
		esac
	done | tee entitlements.txt
	cat <<INFO2

5. Add a new Provisioning Profile
	a. For "type of provisioning profile" choose "iOS App Development"
	b. For "App ID" choose "$BUNDLE_ID"
	c. Choose the development cert you want associate with this profile (or "select All")
	d. "Select All" devices unless you want to choose a specific device
	e. Give the profile a name, anything will do.
6. Download the provisioning profile (.mobileprovision file) from the Member Center
	a. Take note of the path/filename to which the .mobileprovision file is saved.

==================================================================
= Installing the provisioning profile on your device using XCode =
==================================================================
	a. In XCode goto Window / Devices
	b. Right-click on your device and choose "Show Provisioning Profiles"
	c. Click the + sign to install your new profile. You'll be asked to browse to the .mobileprovision file.

==========================================
= Installing the patched app using XCode =
==========================================
1. Delete any existing copies of the app from your device. 
	Note: You can't install over the top of the real application,
	      so it must be deleted first. This only needs to be done
	      once per patched application.
2. In XCode goto Window / Devices
3. Under "Installed Apps" click the + button
4. Browse to your .ipa file and cross your fingers
4. The patched app should appear on your device.

===========
= Summary =
===========
Do all of the things mentioned under "What to do now", above.
Make sure that the provisioning profile contains the correct entitlements (see above).
Once you've installed the provisioning profile on your device, run the following command:
    $0 patch $IPA /path/to/your/file.mobileprovision

Bundle ID: $BUNDLE_ID
Required Entitlements: 
INFO2
	cat entitlements.txt
	exit 0

	loop=0
	for group in `dd if=entitlements.xml bs=1 skip=8 2>/dev/null|sed -ne '/application-groups/,/<\/array/p'|grep '<string>' 2>/dev/null`; do #|tail -n1` #|cut -f2 -d\>|cut -f1 -d\<`
		GROUP_ID=`echo $group | cut -f2 -d\>|cut -f1 -d\<`-patched
		if [ $loop == 0 ]; then
			echo -n "App Groups: "
		else
			echo -n "            "
		fi
		echo $GROUP_ID
		loop=1
	done
	exit 0
}

#
# Inject the current Theos tweak into the specified .ipa file
#
function ipa_patch {

	setup_environment

	if [ "$MOBILEPROVISION" == "" ]; then
		usage
		exit 1
	fi
	if [ ! -r "$MOBILEPROVISION" ]; then
		echo "Can't read $MOBILEPROVISION"
		exit 1
	fi

	if [ ! -x "$OPTOOL" ]; then
		echo "You need to install optool from here: https://github.com/alexzielenski/optool"
		echo "Then update OPTOOL variable in '$0' to reflect the correct path to the optool binary."
		exit 1
	fi

	DEVELOPER_ID=`security dump-keychain login.keychain|grep "iPhone Distribution"|head -n1|cut -f2 -d \(|cut -f1 -d\)`
	if [ "$?" != "0" ]; then
		echo "Error getting Apple \"iPhone Developer\" certificate ID."
		exit 1
	fi

	# copy the files into the .app folder
	echo '[+] Copying .dylib dependences into "'$TMPDIR/Payload/$APP'"'
	cp "$DYLIB" $TMPDIR/Payload/$APP/
	cp PatchApp/CydiaSubstrate $TMPDIR/Payload/$APP/
	cp PatchApp/cycript/* $TMPDIR/Payload/$APP/

	# sign all of the .dylib files we're injecting into the app
	echo '[+] Codesigning .dylib dependencies with certificate "'$CODESIGN_NAME'"'
	for file in "$APPDIR/${DYLIB##*/}" "$APPDIR/CydiaSubstrate" "$APPDIR/ap.dylib" "$APPDIR/cy.dylib" "$APPDIR/readlin.dylib" "$APPDIR/ncur.dylib" "$APPDIR/cycript" "$DYLIB"; do
		echo '     '$file
		codesign -fs "$CODESIGN_NAME" "$file" >& /dev/null
		if [ "$?" != "0" ]; then
			echo "Codesign failed. Have you ran 'make' yet?"
			exit 1
		fi
	done

	# patch the app to load the new .dylib (sames a _backup file)
	echo '[+] Patching "'$APPDIR/$APP_BINARY'" to load "'${DYLIB##*/}'"'
	if [ "$?" != "0" ]; then
		echo "Failed to grab executable name from Info.plist. Debugging required."
		exit 1
	fi
	$OPTOOL install -c load -p "@executable_path/"${DYLIB##*/} -t $APPDIR/$APP_BINARY >& /dev/null
	if [ "$?" != "0" ]; then
		echo "Failed to inject "${DYLIB##*/}" into $APPDIR/${APP_BINARY}. Can I interest you in debugging the problem?"
		exit 1
	fi
	chmod +x "$APPDIR/$APP_BINARY"

	# generate the correct entitlements
	echo '[+] Generating entitlements.xml for distribution ID '$DEVELOPER_ID
	cat <<XML > entitlements.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
XML
	strings "$MOBILEPROVISION" | sed -e '1,/<key>Entitlements<\/key>/d' -e '/<\/dict>/,$d' >> entitlements.xml
	echo "</dict></plist>" >> entitlements.xml

	# Make sure to sign any Plugins in the app. Do NOT attempt to optimize this, the order is important!
	echo '[+] Codesigning Plugins and Frameworks with certificate "'$CODESIGN_NAME'"'
	for file in `ls -1 $APPDIR/PlugIns/com.*/com.*`; do
		echo -n '     '
		codesign -fs "$CODESIGN_NAME" --deep --entitlements entitlements.xml $file
	done
	for file in `ls -d1 $APPDIR/PlugIns/com.*`; do
		echo -n '     '
		codesign -fs "$CODESIGN_NAME" --deep --entitlements entitlements.xml $file
	done

	# re-sign Frameworks, too
	for file in `ls -1 $APPDIR/Frameworks/*`; do
		echo -n '     '
		codesign -fs "$CODESIGN_NAME" --entitlements entitlements.xml $file
	done

	# re-sign the .app
	echo '[+] Codesigning the patched .app bundle with certificate "'$CODESIGN_NAME'"'
	cd $TMPDIR/Payload
	echo -n '     '
	codesign -fs "$CODESIGN_NAME" --deep --entitlements ../../entitlements.xml $APP
	if [ "$?" != "0" ]; then
		cd ..
		echo "Failed to sign $APP with entitlements.xml. You're on your own, sorry."
		exit 1
	fi
	cd ..
	
	# re-pack the .ipa
	echo '[+] Repacking the .ipa'
	rm -f "${IPA%*.ipa}-patched.ipa" >/dev/null 2>&1
	zip -9r "${IPA%*.ipa}-patched.ipa" Payload/ >/dev/null 2>&1
	if [ "$?" != "0" ]; then
		echo "Failed to compress the app into an .ipa file."
		exit 1
	fi
	IPA=${IPA#../*}
	mv "${IPA%*.ipa}-patched.ipa" ..
	echo "[+] Wrote \"${IPA%*.ipa}-patched.ipa\""
	echo "[+] Great success!"
	cd - >/dev/null 2>&1
}

#
# Main
#
case $COMMAND in
	info)
		ipa_info
		;;
	patch)
		ipa_patch
		;;
	*)
		usage
		exit 1
		;;
esac
	
# success!
exit 0

