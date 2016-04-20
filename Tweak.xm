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

@interface SCSnapSaver
+(id) shared;
-(void) saveSnapImageToSnapAlbum:(id)image completionBlock:(id)block;
@end

@interface SCMediaView : UIView
-(id) imageView;
@end

/* ============
   Variables
============= */
id currentSnap = nil;
int bounds = 40;
UIButton *saveSnapButton = nil;

/* ============
   Overrides
============= */
// Screenshot Blocking
%hook SCChatViewController
-(void)userDidTakeScreenshot {
	return;
}
%end

//Blocks screenshot detection on new chat interface introduced on 9.27.0

%hook SCChatViewControllerV2
-(void)userDidTakeScreenshot {
	return;
}
%end

%hook SCViewingStoryViewController
-(void)userDidTakeScreenshot {
	return;
}
%end

// Handles tap to progress
%hook SCFeedViewController
-(void)tapToSkip:(UIGestureRecognizer *)tap {
	CGPoint coords = [tap locationInView:tap.view];

	if (coords.x < [UIScreen mainScreen].bounds.size.width - bounds - 5 || coords.y < [UIScreen mainScreen].bounds.size.height - bounds - 5) {
		@try {
			if (currentSnap) {
				[[%c(Manager) shared] markSnapAsViewed:currentSnap];
				currentSnap = nil;
			}
		}
		@catch(NSException *){}
	}

	%orig;
}
- (void)didFinishSnapPlaying:(id)snap {
	currentSnap = nil;
	%orig;
}
- (void)didSucceedSetUpSnapPlaying:(id)snap {
	currentSnap = snap;
	%orig;
}
-(void)userDidTakeScreenshot {
	return;
}
%end

%hook SCMediaView
// Hides the timer from the display
-(id) snapTimer {
	return nil;
}

-(void) setImageView:(id)imageView {
	%orig;

	// Add Save Snap Button
	saveSnapButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[saveSnapButton addTarget:self action:@selector(saveImage:) forControlEvents:UIControlEventTouchUpInside];
	[saveSnapButton setImage:[UIImage imageNamed:@"save_button.png"] forState:UIControlStateNormal];

	saveSnapButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - bounds - 5, [UIScreen mainScreen].bounds.size.height - bounds - 5, bounds, bounds);

	[self addSubview:saveSnapButton];
	[self bringSubviewToFront:saveSnapButton];	

	[self setUserInteractionEnabled:YES];
}

%new
-(void) saveImage:(id)sender {
	if ([self.imageView image] != nil) {
		// Empty block for callback method to prevent crash.
		void (^fillerBlock)(void) = ^{};

		[[%c(SCSnapSaver) shared] saveSnapImageToSnapAlbum:[self.imageView image] completionBlock:fillerBlock];
	}
}
%end

%hook UIImageView
-(void) setImage:(id)image {
	%orig;

	if ([[self.superview performSelector:@selector(className)] isEqualToString:@"SCMediaView"] && !CGSizeEqualToSize(((UIImage *)image).size, CGSizeMake(0,0)) && saveSnapButton != nil && ![[[saveSnapButton actionsForTarget:self.superview forControlEvent:UIControlEventTouchUpInside] objectAtIndex:0] isEqualToString:@"saveImage:"]) {
		NSLog(@"Converting to saveImage!");
		// Remove the action.
		[saveSnapButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
		// Add the right action.
		[saveSnapButton addTarget:self.superview action:@selector(saveImage:) forControlEvents:UIControlEventTouchUpInside];
	}
}
%end

%hook AVPlayer
-(void) play {
	if (saveSnapButton != nil && ![[[saveSnapButton actionsForTarget:self forControlEvent:UIControlEventTouchUpInside] objectAtIndex:0] isEqualToString:@"saveVideo:"]) {
		NSLog(@"Converting to saveVideo!");
		// Remove the action.
		[saveSnapButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
		// Add the right action.
		[saveSnapButton addTarget:self action:@selector(saveVideo:) forControlEvents:UIControlEventTouchUpInside];
	}

	%orig;
}

%new
-(void) saveVideo:(id)sender {
	if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([[[[self performSelector:@selector(currentItem)] performSelector:@selector(asset)] performSelector:@selector(URL)] performSelector:@selector(path)]))
		UISaveVideoAtPathToSavedPhotosAlbum([[[[self performSelector:@selector(currentItem)] performSelector:@selector(asset)] performSelector:@selector(URL)] performSelector:@selector(path)], nil, nil, nil);
}
%end

// Removes the caption text limit
%hook SCCaptionDefaultTextView
-(void) trimTextViewTextIfNecessary {
    return;
}

#if defined(__arm__)
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (range.length == 0) {
        if ([text isEqualToString:@"\n"]) {
            textView.text = [NSString stringWithFormat:@"%@\n\t",textView.text];
            return NO;
        }
    }
    return YES;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return YES;
}
-(int)contentHeight {
    int orig = _orig(int);
    return orig*3; // 480 x 3
}
-(int)contentWidth {
    int orig = _orig(int);
    return orig*3; // 480 x 3
}
#elif defined(__arm64__)
- (_Bool)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (range.length == 0) {
        if ([text isEqualToString:@"\n"]) {
            textView.text = [NSString stringWithFormat:@"%@\n\t",textView.text];
            return NO;
        }
    }
    return YES;
}
- (_Bool)textViewShouldEndEditing:(UITextView *)textView {
    return YES;
}
-(long long)contentHeight {
    long long orig = _orig(long long);
    return orig*3; // 480 x 3
}
-(long long)contentWidth {
    long long orig = _orig(long long);
    return orig*3; // 480 x 3
}
#else
#endif
%end

// Stops timer from progressing
%hook Manager
-(void)tick:(id)tick {
	return;
}
#if defined(__arm__)
-(void)startTimer:(id)snap source:(int)source {
	currentSnap = snap;

	%orig;
}
#elif defined(__arm64__)
- (void)startTimer:(id)arg1 source:(long long)arg2 {
	currentSnap = snap;

	%orig;
}
#else
#endif

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
