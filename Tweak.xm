#include "fishhook/fishhook.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "substrate.h"

/* ============
   Interfaces
============= */
@interface Manager
+(id) shared;
-(void) startTimer:(id)snap source:(int)source;
-(void) markSnapAsViewed:(id)snap;
@end

/* ============
   Variables
============= */
id currentSnap = nil;
int currentSnapSource = 0;

/* ============
   Overrides
============= */
   
// Screenshot Blocking
%hook SCDiscoverEditionViewController
-(void)userDidTakeScreenshot {
	return;
}
%end

%hook FeedViewController
-(void)userDidTakeScreenshot {
	return;
}

-(void) showSnap:(id)snap {
	currentSnap = snap;
	%orig;
}
%end

%hook MyFriendsViewController
-(void)userDidTakeScreenshot {
	return;
}
%end

%hook SCChatViewController
-(void)userDidTakeScreenshot {
	return;
}
%end

// Handles tap to progress
%hook SCFeedViewController
-(void)tapToSkip:(id)arg1 {
	@try {
		if (currentSnap) {
			[[%c(Manager) shared] markSnapAsViewed:currentSnap];
			currentSnap = nil;
		}
	}
	@catch(NSException *){}

	%orig;
}
%end

// Hides the timer from the display
%hook SCMediaView
-(id) snapTimer {
	return nil;
}
%end

// Removes the caption text limit
%hook SCCaptionDefaultTextView
-(CGFloat) maxTextWidth {
	return DBL_MAX;
}
%end

// Stops timer from progressing
%hook Manager
-(void)tick:(id)tick {
	return;
}

-(void) startTimer:(id)snap source:(int)source {
	currentSnap = snap;
	currentSnapSource = source;

	%orig;
}
%end
