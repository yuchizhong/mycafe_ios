//
//  AppDelegate.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "AppDelegate.h"
#import "cart.h"
#import "purse.h"
#import "activityDetails.h"
#import "cafewall.h"

//BMKMapManager* _mapManager;
static NSDate *lastRefreshTime = nil;
static storeList *sl = nil;
static JDStatusBarView *topStatusBar = nil;
static BOOL locationOn = NO, BTON = NO;
static int payingModule = 0;
static NSInteger currentPaymentID = 0;

@interface AppDelegate ()

@end

@implementation AppDelegate

//@synthesize locationManager;

+ (void)setCurrentPaymentID:(NSInteger)pid {
    currentPaymentID = pid;
}

+ (void)setStoreListController:(UIViewController*)slc {
    sl = (storeList*)slc;
}

+ (UIViewController*)getStoreListController {
    return sl;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *t = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    t = [t stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"My token is: %@", t);
    [user setPushToken:t];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [user startGetID];
    NSLog(@"Failed to get token, error: %@", error);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    /*
    //百度地图SDK
    _mapManager = [[BMKMapManager alloc]init];
    BOOL ret = [_mapManager start:BAIDU_MAP_KEY generalDelegate:nil];
    if (!ret) {
        NSLog(@"Baidu Map Manager start failed");
    }
     */
    
    [[UITextField appearance] setTintColor:COFFEE_VERY_DARK];
    
    //remote notifications
    /*
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:
         [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    UIRemoteNotificationType types;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        types = [[UIApplication sharedApplication] currentUserNotificationSettings].types;
    }
    else
    {
        types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    }
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"launched"] == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"launched"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        if ((types & UIRemoteNotificationTypeAlert) != UIRemoteNotificationTypeAlert) {
            [HTTPRequest alert:@"请打开推送服务。\n有你咖啡需要推送服务通知您必要的信息，如取餐等。"];
        }
    }
     */
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    if (![db open]) {
        NSLog(@"DB OPEN FAILED AT LAUNCH");
    } else {
        if (![db _exec:@"CREATE TABLE IF NOT EXISTS orders (placeID INTEGER PRIMARY KEY AUTOINCREMENT, store TEXT, storeName TEXT, dishID INTEGER, dishName TEXT, quantity INTEGER, price TEXT)"]) {
            NSLog(@"CREATE TABLE FAILED");
        }
    }
    
    lastRefreshTime = [NSDate date];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    /*
    [JDStatusBarNotification addStyleNamed:STATUS_BAR_NOTIFICATION_STYLE_NAME
                                   prepare:^JDStatusBarStyle *(JDStatusBarStyle *style) {
                                       style.barColor = NOTIFICATION_COLOR;
                                       style.textColor = [UIColor whiteColor];
                                       style.animationType = JDStatusBarAnimationTypeMove;
                                       style.font = [UIFont systemFontOfSize:14];
                                       return style;
                                   }];
    
    [NSThread detachNewThreadSelector:@selector(checkLocationAndBT) toTarget:self withObject:nil];
     */
    
    [SDWebImageManager.sharedManager.imageDownloader setMaxConcurrentDownloads:MAX_CONCURRENT_IMAGE_DOWNLOAD];
    
    if(![WXApi registerApp:WEIXIN_APPID]) {
        NSLog(@"WX start failed");
    }
    
    return YES;
}

- (void)popNotification:(NSString*)notificationBody {
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = notificationBody;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

//app开启式提示
/*
- (void)checkLocationAndBT {
    BOOL shown = NO;
    while (STATUS_BAR_NOTIFICATION_ALWAYS_SHOW || !shown) {
        //check services
        //location
        if ([CLLocationManager locationServicesEnabled] &&
            ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways ||
             [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
                locationOn = YES;
            } else {
                locationOn = NO;
            }
        
        //BT handled by CB delegate
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([store preorder_mode]) {
                topStatusBar = [JDStatusBarNotification showWithStatus:@"当前为预订模式" styleName:STATUS_BAR_NOTIFICATION_STYLE_NAME];
                [JDStatusBarNotification dismissAfter:STATUS_BAR_NOTIFICATION_DISMISS_AFTER];
            } else if (!locationOn && !BTON) {
                topStatusBar = [JDStatusBarNotification showWithStatus:@"请开启定位服务和蓝牙" styleName:STATUS_BAR_NOTIFICATION_STYLE_NAME];
                if (!STATUS_BAR_NOTIFICATION_ALWAYS_SHOW) {
                    [JDStatusBarNotification dismissAfter:STATUS_BAR_NOTIFICATION_DISMISS_AFTER];
                }
            } else if (!locationOn) {
                topStatusBar = [JDStatusBarNotification showWithStatus:@"请开启定位服务" styleName:STATUS_BAR_NOTIFICATION_STYLE_NAME];
                if (!STATUS_BAR_NOTIFICATION_ALWAYS_SHOW) {
                    [JDStatusBarNotification dismissAfter:STATUS_BAR_NOTIFICATION_DISMISS_AFTER];
                }
            } else if (!BTON) {
                topStatusBar = [JDStatusBarNotification showWithStatus:@"请开启蓝牙" styleName:STATUS_BAR_NOTIFICATION_STYLE_NAME];
                if (!STATUS_BAR_NOTIFICATION_ALWAYS_SHOW) {
                    [JDStatusBarNotification dismissAfter:STATUS_BAR_NOTIFICATION_DISMISS_AFTER];
                }
            } else {
                [JDStatusBarNotification dismiss];
            }
        });
        
        shown = YES;
        
        if (STATUS_BAR_NOTIFICATION_ALWAYS_SHOW) {
            [NSThread sleepForTimeInterval:0.5];
        }
    }
}
 */

//支付回调，忽略
- (void)paymentResult:(NSString *)result {
    /*
     支付成功：@"success"
     支付失败：@"fail"
     用户取消：@"cancel"
     未安装控件：@"invalid"
     */
    
    NSLog(@"payment result: %@", result);
    END_LOADING
    return; //not using this method
    
    if ([result isEqualToString:@"success"]) {
        [HTTPRequest alert:[NSString stringWithFormat:@"支付成功\n您可以在消费记录中查看"]];
        [AppDelegate donePayingModuleWithSuccess:YES];
    } else if ([result isEqualToString:@"fail"]) {
        [HTTPRequest alert:[NSString stringWithFormat:@"支付失败，请重试"]];
        [AppDelegate donePayingModuleWithSuccess:NO];
    } else if ([result isEqualToString:@"cancel"]) {
        [HTTPRequest alert:[NSString stringWithFormat:@"支付被取消，请重试"]];
        [AppDelegate donePayingModuleWithSuccess:NO];
    } else if ([result isEqualToString:@"invalid"]) {
        [HTTPRequest alert:[NSString stringWithFormat:@"未安装支付控件，请重试"]];
        [AppDelegate donePayingModuleWithSuccess:NO];
    } else {
        [HTTPRequest alert:[NSString stringWithFormat:@"支付返回代码错误，请重试"]];
        [AppDelegate donePayingModuleWithSuccess:NO];
    }
    if ([purse getInstance] != nil) {
        [[purse getInstance] viewWillAppear:NO];
    }
    if ([cart getInstance] != nil) {
        [[cart getInstance] viewWillAppear:NO];
    }
}

//获取最后支付的状态
- (BOOL)getLastPaymentStatus {
    if ([user getCurrentID] == nil) {
        return NO;
    }
    if (currentPaymentID == 0) {
        [HTTPRequest alert:@"确认支付结果时错误，您可以在消费记录中查看"];
    }
    BEGIN_LOADING
    NSString *query = [NSString stringWithFormat:@"SELECT pay_status FROM payment WHERE paymentID=%d", currentPaymentID];
    currentPaymentID = 0;
    NSData *recvData = [HTTPRequest syncPost:@"select.php" withRawData:
                        [HTTPRequest dataFromString:query]];
    if (recvData == nil) {
        END_LOADING
        [HTTPRequest alert:@"确认支付结果时网络错误，请在消费记录中查看"];
        return NO;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        END_LOADING
        [HTTPRequest alert:@"确认支付结果时网络错误，请在消费记录中查看"];
        return NO;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    if ([[[listInJSON objectAtIndex:0] objectForKey:@"pay_status"] isEqualToString:@"payed"]) {
        END_LOADING
        return YES;
    } else {
        END_LOADING
        [HTTPRequest alert:@"支付未完成\n如遇到问题请联系我们的客服"];
        return NO;
    }
    
    END_LOADING
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2000 && buttonIndex == 1) {
        //check status
        if ([self getLastPaymentStatus]) {
            [HTTPRequest alert:@"支付成功"];
            [AppDelegate donePayingModuleWithSuccess:YES];
        } else {
            [AppDelegate donePayingModuleWithSuccess:NO];
        }
    }
}

+ (void)setPayingModule:(int)module {
    NSLog(@"SET PAYING MODULE %d", module);
    payingModule = module;
}

+ (void)donePayingModuleWithSuccess:(BOOL)success {
    if (success) {
        switch (payingModule) {
            case MODULE_NORMAL:
                [[orderInfo getOrder] removeAllObjects];
                [orderInfo saveOrder];
                [storeList refreshMenuAndOrder];
                [storeList kickOrderToMenu];
                break;
                
            case MODULE_PREORDER:
                [store set_preorder_mode:NO];
                [[orderInfo getOrder] removeAllObjects];
                [orderInfo saveOrder];
                break;
                
            case MODULE_MALL_ACTIVITY:
                //ask for collection
                [activityDetails askInstanceForCollection];
                break;
                
            case MODULE_PURSE:
                [[purse getInstance] viewWillAppear:NO];
                break;
                
            case MODULE_CAFE_WALL:
                if ([cafeWall getInstance] != nil) {
                    [[cafeWall getInstance].navigationController popToRootViewControllerAnimated:YES];
                    [[cafeWall getInstance] refresh];
                }
                break;
                
            default:
                break;
        }
    }
    
    payingModule = 0;
}

//url scheme
- (BOOL)myHandleURL:(NSURL*)url {
    //return [TencentOAuth HandleOpenURL:url];
    NSLog(@"handle URL: %@", [url absoluteString]);
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"Opened from %@", sourceApplication);
    return [self myHandleURL:url];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self myHandleURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    /*
    if (sl != nil) {
        [sl pauseLocation];
    }
     */
    
    [orderInfo saveOrder];
    [db close];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if (![db open])
        NSLog(@"DB OPEN FAILED WHEN ENTER FOREGROUND");
    
    /*
    if (!STATUS_BAR_NOTIFICATION_ALWAYS_SHOW) {
        [NSThread detachNewThreadSelector:@selector(checkLocationAndBT) toTarget:self withObject:nil];
    }
     */
    
    /*
    if (sl != nil) {
        [sl goStart];
    }
     */
    
    //在后台时间过长需重新刷新菜单
    /*
    if (lastRefreshTime == nil)
        lastRefreshTime = [NSDate distantPast];
    
    NSTimeInterval timeGap = [[NSDate date] timeIntervalSinceDate:lastRefreshTime];
    
    if (ABS(timeGap) > 60 * 60) { //1 hour
        [store forceReloadStore];
        [store setCurrentStore:app_store_id];
        [storeList refreshMenuAndOrder];
        lastRefreshTime = [NSDate date];
    }
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    /*
    if (sl != nil) {
        [sl pauseLocation];
    }
     */
    [orderInfo saveOrder];
    [db close];
}

@end
