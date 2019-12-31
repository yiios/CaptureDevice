

#import "HUD.h"
#import "QuartzCore/QuartzCore.h"

static UIView* lastViewWithHUD = nil;

@interface GlowButton : UIButton <MBProgressHUDDelegate>

@end

@implementation GlowButton
{
    NSTimer* timer;
    float glowDelta;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //effect
        self.layer.shadowColor = [UIColor whiteColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(1,1);
        self.layer.shadowOpacity = 0.9;
        
        glowDelta = 0.2;
        timer = [NSTimer timerWithTimeInterval:0.05
                                        target:self
                                      selector:@selector(glow)
                                      userInfo:nil
                                       repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
    return self;
}

-(void)glow
{
    if (self.layer.shadowRadius>7.0 || self.layer.shadowRadius<0.1) {
        glowDelta *= -1;
    }
    self.layer.shadowRadius += glowDelta;
}

-(void)dealloc
{
    [timer invalidate];
    timer = nil;
}

@end

@implementation HUD

+ (UIView*)rootView
{
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;   //从alert 点击事件里之行的HUD,获取的keywindow为alert层的UIAlertShimPresentingViewController，这里判断一下，重新给window赋值
    if ([NSStringFromClass(window.class) containsString:@"UIAlert"]) {
        window = [UIApplication sharedApplication].windows[0];
    }
    UIViewController *topController = window.rootViewController;
    
        while (topController.presentedViewController) {
            topController = topController.presentedViewController;
        }
        
    return topController.view;
}

+ (UIWindow *)systemKeyboardWindow
{
    UIWindow *keyboardWindow = [[[UIApplication sharedApplication] windows] lastObject];
    return keyboardWindow;
}
+ (UIWindow *)keyWindow {
    return [UIApplication sharedApplication].keyWindow;
}
+ (UIView *)systemContainerWindow
{
    int count = (int)[[[[UIApplication sharedApplication] keyWindow] subviews] count];
    UIView *window = nil;
    for (int i = count - 1; i >= 0; i --) {
        UIView *view = [[[UIApplication sharedApplication] keyWindow] subviews][i];
        if (!view.hidden && view.alpha) {
            window = view;
        }
    }
    return window;
}



+ (MBProgressHUD*)showUIBlockingIndicatorWithText:(NSString*)str
{
    [HUD hideUIBlockingIndicator];
    UIView* targetView = [self rootView];
    if (targetView==nil) return nil;

    lastViewWithHUD = targetView;
    [MBProgressHUD hideHUDForView:targetView animated:YES];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:targetView animated:YES];
	if (str!=nil) {
        hud.label.text = str;
    } else {
        hud.label.text  = @"Loading...";
    }
    
    return hud;
}

+ (void)hideUIBlockingIndicator
{
    [MBProgressHUD hideHUDForView:lastViewWithHUD animated:YES];
}

@end
