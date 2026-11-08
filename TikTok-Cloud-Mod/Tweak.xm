#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString * const kColorKey = @"CloudMod.LikeColor";
static UIColor *gLikeColor;

static const void *kEntryTargetKey = &kEntryTargetKey;

static UIColor *GetColor(NSString *name) {
    NSDictionary *colors = @{
        @"Pink": [UIColor colorWithRed:1 green:0.15 blue:0.48 alpha:1],
        @"Red": [UIColor redColor],
        @"Purple": [UIColor purpleColor],
        @"Blue": [UIColor blueColor],
        @"Cyan": [UIColor cyanColor],
        @"Green": [UIColor greenColor],
        @"Orange": [UIColor orangeColor],
        @"Gold": [UIColor colorWithRed:1 green:0.75 blue:0.05 alpha:1],
        @"White": [UIColor whiteColor]
    };

    return colors[name] ?: colors[@"Pink"];
}

// Проверяем, похож ли элемент на кнопку лайка
static BOOL IsLikeView(UIView *view) {
    NSString *label = view.accessibilityLabel.lowercaseString ?: @"";
    NSString *identifier = view.accessibilityIdentifier.lowercaseString ?: @"";
    NSString *className = NSStringFromClass(view.class).lowercaseString;

    NSString *combined = [NSString stringWithFormat:@"%@ %@ %@",
                          label, identifier, className];

    return [combined containsString:@"like"] ||
           [combined containsString:@"heart"] ||
           [combined containsString:@"favorite"];
}

// Применяем выбранный цвет
static void ApplyColor(UIView *view) {
    if (!gLikeColor || !IsLikeView(view)) return;

    view.tintColor = gLikeColor;

    if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;

        imageView.image = [imageView.image
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
}

// Обходим интерфейс приложения
static void ScanViews(UIView *view) {
    ApplyColor(view);

    for (UIView *child in view.subviews) {
        ScanViews(child);
    }
}

static void RefreshLikes(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;

        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            ScanViews(window);
        }
    }
}

// Сохраняем выбор цвета
static void SelectLikeColor(NSString *name) {
    [[NSUserDefaults standardUserDefaults] setObject:name
                                              forKey:kColorKey];

    gLikeColor = GetColor(name);
    RefreshLikes();
}

// Окно выбора LikeColor
@interface CloudModController : NSObject
@property(nonatomic, weak) UIButton *entryButton;
- (void)openSettings;
@end

@implementation CloudModController

- (void)openSettings {
    UIViewController *host = nil;

    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;

        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) {
                host = window.rootViewController;
                break;
            }
        }
    }

    if (!host) return;

    while (host.presentedViewController) {
        host = host.presentedViewController;
    }

    UIAlertController *menu =
    [UIAlertController alertControllerWithTitle:@"TikTok Cloud Mod"
                                        message:@"Выбери цвет лайка"
                                 preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *names = @[
        @"Pink", @"Red", @"Purple",
        @"Blue", @"Cyan", @"Green",
        @"Orange", @"Gold", @"White"
    ];

    for (NSString *name in names) {
        UIAlertAction *action =
        [UIAlertAction actionWithTitle:name
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *a) {
            SelectLikeColor(name);
        }];

        [menu addAction:action];
    }

    [menu addAction:[UIAlertAction actionWithTitle:@"Close"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];

    UIPopoverPresentationController *popover = menu.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.entryButton ?: host.view;
        popover.sourceRect = self.entryButton
            ? self.entryButton.bounds
            : host.view.bounds;
    }

    [host presentViewController:menu animated:YES completion:nil];
}

@end

static void AddCloudButton(void) {
    UIWindow *window = nil;

    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;

        for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }
    }

    if (!window || [window viewWithTag:882211]) return;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];

    button.tag = 882211;
    button.frame = CGRectMake(window.bounds.size.width - 120, 90, 108, 38);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    button.backgroundColor = [UIColor colorWithRed:0.35
                                              green:0.15
                                               blue:0.8
                                              alpha:0.95];

    button.layer.cornerRadius = 14;

    [button setTitle:@"Cloud Mod" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];

    CloudModController *controller = [CloudModController new];
    controller.entryButton = button;

    objc_setAssociatedObject(
        button,
        kEntryTargetKey,
        controller,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC
    );

    [button addTarget:controller
               action:@selector(openSettings)
     forControlEvents:UIControlEventTouchUpInside];

    [window addSubview:button];
}

// Запуск
__attribute__((constructor))
static void CloudModInit(void) {
    @autoreleasepool {
        NSString *saved =
            [[NSUserDefaults standardUserDefaults] stringForKey:kColorKey]
            ?: @"Pink";

        gLikeColor = GetColor(saved);

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
                addObserverForName:UIApplicationDidBecomeActiveNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(NSNotification *notification) {
                AddCloudButton();
                RefreshLikes();
            }];

            AddCloudButton();
        });
    }
}