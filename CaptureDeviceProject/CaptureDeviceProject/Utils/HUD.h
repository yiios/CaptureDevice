

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@interface HUD : NSObject

+ (MBProgressHUD*)showUIBlockingIndicatorWithText:(NSString*)str;

+ (void)hideUIBlockingIndicator;

@end
