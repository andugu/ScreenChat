#!/bin/bash

#
# You shouldn't need to change this
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
SUFFIX="-"$(uuidgen)

#
# Usage / syntax
#
function usage {
	if [ "$2" == "" -o "$1" == "" ]; then
		cat <<USAGE
Syntax: $0 <command> </path/to/your/ipa/file.ipa> [/path/to/your/file.mobileprovision | bundle-id]"
Where 'command' is one of:"
	info  - Show the information required to create a Provisioning Profile
	        that matches the specified .ipa file
	patch - Inject the current Theos tweak into the specified .ipa file.
	        Requires that you specify a .mobileprovision file or the bundle id
	        for the provision.

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
	BUNDLE_ID=`plutil -convert xml1 -o - $APPDIR/Info.plist|grep -A1 CFBundleIdentifier|tail -n1|cut -f2 -d\>|cut -f1 -d\<`$SUFFIX
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

	IDENTIFIER=`sed -e "s|\(.*\)\..*|\1|" <<< $BUNDLE_ID`
	PRODUCTNAME=`sed -e "s|.*\.\(.*\)|\1|" <<< $BUNDLE_ID`
	
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
3. Run "$0 patch $IPA $BUNDLE_ID" to patch the .ipa
4. Install the patched .ipa to your device using XCode 

=====================================
= Creating the provisioning profile =
=====================================
1. Open up XCode, and create a new project.
2. Choose "Master-Detail Application", and click "Next"
3. For 'Product Name' use: 
	$PRODUCTNAME
4. For 'Organization Identifier' use: 
	$IDENTIFIER
5. Leave all other fields the way they are, and click "Next", and then "Create" wherever you want to save it.
6. Under "Deployment Info", change the "Deployment Target" to whatever your device version is (or below it).
7. In the top bar, where it currently says "iPhone ....", set the device to your current phone (make sure it's plugged in).
8. Under "Identity", change "Team" to whatever developer account is yours (it can be a free one).
9. Click "Fix Issue", under where it says "No matching provisioning profiles found".
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
					GROUP_ID=`echo $group | cut -f2 -d\>|cut -f1 -d\<`$SUFFIX
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
Make sure that you've created the provisioning profile (steps above).
Run the following command:
    $0 patch $IPA $BUNDLE_ID
Install 'provision.mobileprovision' onto your device (steps above).
Install the patched app onto your device (steps above). 
INFO2
}

#
# Inject the current Theos tweak into the specified .ipa file
#
function ipa_patch {

	setup_environment

	# No argument for provision given
	if [ "$MOBILEPROVISION" == "" ]; then
		usage
		exit 1
	fi

	# File can't be read (try making it)
	if [ ! -r "$MOBILEPROVISION" ]; then
		# found one
		if (( `grep -rn ~/Library/MobileDevice/Provisioning\ Profiles -e "$MOBILEPROVISION" | wc -l` > 0)); then
			echo '[+] Copying provision from provided Bundle ID'
			cp "`grep -rn ~/Library/MobileDevice/Provisioning\ Profiles -e "$MOBILEPROVISION" | sed -e "s|Binary file \(.*\) matches|\1|"`" "provision.mobileprovision"
			MOBILEPROVISION=`pwd`"/provision.mobileprovision"

			if [ ! -r "$MOBILEPROVISION" ]; then
				echo "Can't read $MOBILEPROVISION"
				exit 1
			fi
		else # didn't find one
			echo "Can't read $MOBILEPROVISION"
			exit 1
		fi
	fi

	if [ ! -x "$OPTOOL" ]; then
		echo "You need to install optool from here: https://github.com/alexzielenski/optool"
		echo "Then update OPTOOL variable in '$0' to reflect the correct path to the optool binary."
		exit 1
	fi

	DEVELOPER_ID=`security dump-keychain login.keychain|grep "$DEV_CERT_NAME"|head -n1|cut -f2 -d \(|cut -f1 -d\)`
	if [ "$?" != "0" ]; then
		echo "Error getting Apple \"iPhone Developer\" certificate ID."
		exit 1
	fi

	# copy the files into the .app folder (theos-jailed dependencies)
	echo '[+] Copying .dylib dependences into "'$TMPDIR/Payload/$APP'"'
	cp "$DYLIB" $TMPDIR/Payload/$APP/
	cp PatchApp/CydiaSubstrate $TMPDIR/Payload/$APP/
	cp PatchApp/cycript/* $TMPDIR/Payload/$APP/

	cp "$MOBILEPROVISION" "$TMPDIR/Payload/$APP/embedded.mobileprovision"

	echo '[+] Codesigning .dylib dependencies with certificate "'$CODESIGN_NAME'"'
	find -d $TMPDIR/Payload/$APP  \( -name "*.app" -o -name "*.appex" -o -name "*.framework" -o -name "*.dylib" -o -name "*cycript" -o -name "*CydiaSubstrate" -o -name "$DYLIB" \) > directories.txt
	security cms -D -i "$TMPDIR/Payload/$APP/embedded.mobileprovision" > t_entitlements_full.plist
	/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' t_entitlements_full.plist > t_entitlements.plist
	while IFS='' read -r line || [[ -n "$line" ]]; do
	    /usr/bin/codesign --continue -f -s "$CODESIGN_NAME" --entitlements "t_entitlements.plist"  "$line"
	done < directories.txt

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

	# Make sure to sign any Plugins in the app. Do NOT attempt to optimize this, the order is important!
	echo '[+] Codesigning Plugins and Frameworks with certificate "'$CODESIGN_NAME'"'
	for file in `ls -1 $APPDIR/PlugIns/com.*/com.*`; do
		echo -n '     '
		codesign -fs "$CODESIGN_NAME" --deep --entitlements t_entitlements.plist $file
	done
	for file in `ls -d1 $APPDIR/PlugIns/com.*`; do
		echo -n '     '
		codesign -fs "$CODESIGN_NAME" --deep --entitlements t_entitlements.plist $file
	done

	# re-sign Frameworks, too
	for file in `ls -1 $APPDIR/Frameworks/*`; do
		echo -n '     '
		codesign -fs "$CODESIGN_NAME" --entitlements t_entitlements.plist $file
	done

	# re-sign the app
	echo '[+] Codesigning the patched .app bundle with certificate "'$CODESIGN_NAME'"'
	cd $TMPDIR/Payload
	echo -n '     '
	codesign -fs "$CODESIGN_NAME" --deep --entitlements ../../t_entitlements.plist $APP
	if [ "$?" != "0" ]; then
		cd ..
		echo "Failed to sign $APP with entitlements.xml. You're on your own, sorry."
		exit 1
	fi
	cd ..

	rm ../directories.txt
	rm ../t_entitlements.plist
	rm ../t_entitlements_full.plist
	
	# re-pack the .ipa
	echo '[+] Repacking the .ipa'
	rm -f "${IPA%*.ipa}-patched.ipa" >/dev/null 2>&1
	zip -qry "${IPA%*.ipa}-patched.ipa" Payload/ >/dev/null 2>&1
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
