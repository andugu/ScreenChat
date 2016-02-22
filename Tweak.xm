#include "fishhook/fishhook.h"
#import <Foundation/Foundation.h>
#import "substrate.h"
#import <UIKit/UIKit.h>

%hook SCDiscoverEditionViewController
-(void)userDidTakeScreenshot {
}
%end

%hook FeedViewController
-(void)userDidTakeScreenshot {
}
%end

%hook MyFriendsViewController
-(void)userDidTakeScreenshot {
}
%end

%hook SCChatViewController
-(void)userDidTakeScreenshot {
}
%end