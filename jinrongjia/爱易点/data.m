//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "data.h"
#import "storeList.h"
#import "foodList.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreFoundation/CoreFoundation.h>
#import "Reachability.h"

#define USER_BEGIN_LOADGING [NSThread detachNewThreadSelector:@selector(beginLoading) toTarget:self withObject:nil];
#define USER_END_LOADGING [NSThread detachNewThreadSelector:@selector(endLoading) toTarget:self withObject:nil];

//store//////////////////////////////////////////////////////////
static NSMutableArray *menu = nil;
static NSMutableArray *order = nil;

static NSString *storeID = @"";
static NSString *storeName = @"";
static BOOL whiteLabelName = YES; //deprecated
static BOOL support = NO;
static BOOL NoTableNum = YES;
static BOOL wifi = NO;
static BOOL creditCanPay = NO;
static float creditToCentRatio = 0;
static int payOption = 0; //deprecated
static int tableNum = 0;
//preorder
static BOOL preorder_mode = NO;
static int p_option = 0;
static int preorder_minutes_after_now = 15;
/////////////////////////////////////////////////////////////////

//system
static BOOL forceReloadStore = NO;
static int lastMajor = -999, lastMinor = -999;
static int lastMajorLoaded = -9999, lastMinorLoaded = -9999;
static NSDate *lastIDUpdate = nil; //store ID update time

static NSString *currentID = nil;
static NSString *currentUsername = nil;
static NSString *pushToken = nil;
static NSString *server_link = nil; //deprecated
static NSDictionary *userinfo = nil;
static BOOL gotUserinfo = NO;

@implementation beacon

- (beacon*)initWithMajor:(NSInteger)ma andMinor:(NSInteger)mi {
    self.major = ma;
    self.minor = mi;
    return self;
}

@end

@implementation user

+ (BOOL)gotUserinfo {
    return gotUserinfo;
}

+ (NSDictionary*)getUserInfo {
    return userinfo;
}

+ (BOOL)submitUserinfo:(NSInteger)birthyear andBirthMonth:(NSInteger)birthmonth andGender:(NSInteger)gender {
    NSString *uid = [user getCurrentID];
    if (uid == nil) {
        [HTTPRequest alert:@"请您先登录"];
        return NO;
    }
    
    USER_BEGIN_LOADGING
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:uid, @"username",
                                [NSString stringWithFormat:@"%ld", (long)birthyear], @"birthyear",
                                [NSString stringWithFormat:@"%ld", (long)birthmonth], @"birthmonth",
                                [NSString stringWithFormat:@"%ld", (long)gender], @"gender", nil];
    
    NSData *recvData = [HTTPRequest syncGet:SERVER_SUBMIT_USERINFO withData:dic];
    if (recvData == nil) {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return NO;
    }
    if ([HTTPRequest stringFromData:recvData] == nil || [[HTTPRequest stringFromData:recvData] isEqualToString:@""]) {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return NO;
    }
    if ([[HTTPRequest stringFromData:recvData] length] >= 5 && [[[HTTPRequest stringFromData:recvData] substringToIndex:5] isEqualToString:@"ERROR"]) {
        USER_END_LOADGING
        [HTTPRequest alert:[HTTPRequest stringFromData:recvData]];
        return NO;
    }
    if ([[HTTPRequest stringFromData:recvData] length] >= 2 && [[[HTTPRequest stringFromData:recvData] substringToIndex:2] isEqualToString:@"OK"]) {
        USER_END_LOADGING
        return YES;
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return NO;
}

//启动时获取配置信息
//返回nil：要求更新
+ (NSString*)getServerAddress {
    /*
    if (server_link == nil) {
        //connect to start server address and check new version
        int retry = 0;
        while ((server_link == nil || [server_link isEqualToString:@""]) && retry < 3) {
            NSData *recdata = [HTTPRequest syncGet:@"server_config.txt" withData:nil]; //[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
            NSString *response = [HTTPRequest stringFromData:recdata];
        
            if (response == nil || [response isEqualToString:@""]) {
                [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
                retry++;
                continue;
            }
            NSArray *responses = [response componentsSeparatedByString:@";"];
            double new_version = 0;
            for (NSString *component in responses) {
                NSArray *arr = [component componentsSeparatedByString:@"="];
                if ([[arr objectAtIndex:0] isEqualToString:@"link"] && arr.count > 1) {
                    server_link = [arr objectAtIndex:1]; //服务器地址，忽略
                } else if ([[arr objectAtIndex:0] isEqualToString:@"version"] && arr.count > 1) {
                    new_version = [[arr objectAtIndex:1] doubleValue]; //最新版app版本号
                } else if ([[arr objectAtIndex:0] isEqualToString:@"force_update"] && arr.count > 1) { //是否要求更新
                    if (((NSString*)[arr objectAtIndex:1]).length >= 3 && [[[arr objectAtIndex:1] substringToIndex:3] isEqualToString:@"YES"]) {
                        if (new_version > app_version + 0.0001) {
                            //ask for update
                            return nil;
                        }
                    }
                }
            }
        }
        if (retry == 3) { //重试3次
            dispatch_sync(dispatch_get_main_queue(), ^{
                [HTTPRequest alert:NETWORK_ERROR];
            });
        }
    }
     */
    
    if (server_link == nil || [server_link isEqualToString:@""]) {
        server_link = SERVER_ADDRESS;
    }
    
    return server_link;
}

//修改昵称
+ (void)changeNickname:(NSString*)newName {
    USER_BEGIN_LOADGING
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"ID", newName, @"name", @"CHANGE_NAME", @"OPERATION", nil];
    NSString *ret = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_LOGIN withData:dic]];
    if ([ret isEqualToString:@""])
        ret = nil;
    if (ret == nil) {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
    } else if ([ret isEqualToString:@"OK"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"昵称修改成功"];
        currentUsername = newName;
    }
}
//获取当前用户昵称
+ (NSString*)getCurrentUser {
    if ([self getCurrentID] == nil) {
        return nil;
    }
    if (currentUsername == nil || [currentUsername isEqualToString:@""]) {
        return currentID;
    }
    return currentUsername;
}
//app启动
+ (BOOL)start {
    //获取UUID
    NSString *deviceID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UUID"];
    if (deviceID == nil || [deviceID isEqualToString:@""]) {
        deviceID = [self uuid];
        [[NSUserDefaults standardUserDefaults] setObject:deviceID forKey:@"UUID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    NSLog(@"using device ID: %@", deviceID);
    
    /*
    if ([self getServerAddress] == nil) {
        return NO;
    }
     */
    
    return YES;
}

//定时获取服务器通知消息
+ (void)handleNotification {
    [NSThread detachNewThreadSelector:@selector(getNotification) toTarget:self withObject:nil];
}

+ (void)showNotification:(NSArray*)ns {
    NSMutableString *s = [[NSMutableString alloc] init];
    for (int i = 0; i < ns.count; i++) {
        NSString *ss = [ns objectAtIndex:i];
        [s appendString:[NSString stringWithFormat:@"%d. %@\n", i + 1, ss]];
    }
    s = [[s substringToIndex:s.length - 1] mutableCopy];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"您有%d条消息\n", (int)ns.count]
                                                    message:ns.count == 1 ? [ns objectAtIndex:0] : s
                                                   delegate:self cancelButtonTitle:@"确认"
                                          otherButtonTitles:nil];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [alert show];
    //play sound
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

+ (void)getNotification {
    float waitLoop = 3.0;
    while (true) {
        //get notifications from server
        if (currentID == nil || [currentID isEqualToString:@""]) {
            [NSThread sleepForTimeInterval:waitLoop];
            continue;
        }
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"user", nil];
        NSData *recvData = [HTTPRequest syncGet:SERVER_GET_NOTIFICATION withData:dic];
        if (recvData == nil) {
            [NSThread sleepForTimeInterval:waitLoop];
            continue;
        }
        NSError *error;
        NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
        if (jsonRoot == nil) {
            [NSThread sleepForTimeInterval:waitLoop];
            continue;
        }
        NSArray *ns = [jsonRoot objectForKey:@"list"];
        
        //弹出框
        if (ns != nil && ns.count > 0) {
            [self performSelectorOnMainThread:@selector(showNotification:) withObject:ns waitUntilDone:YES];
        }
        [NSThread sleepForTimeInterval:waitLoop];
    }
}

//获取UUID后发送UUID到服务器以获取用户名
+ (void)startGetID {
    currentID = [self getIDbyUUID]; //get user ID using device ID
    
    if (currentID == nil || [currentID isEqualToString:@""]) {
        currentID = nil;
    }
    if (currentID != nil) {
        currentUsername = [self getNicknamebyID];
        if (currentUsername == nil || [currentUsername isEqualToString:@""]) {
            currentUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"usernick"];
            if (currentUsername == nil || [currentUsername isEqualToString:@""]) {
                currentUsername = currentID;
            }
        }
    }
    NSLog(@"using user ID: %@, nickname: %@", currentID, currentUsername);
}
//获取UUID后发送UUID到服务器以获取用户名
+ (NSString*)getIDbyUUID {
    NSString *deviceID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UUID"];
    NSDictionary *dic;
    if (pushToken == nil || [pushToken isEqualToString:@""])
        dic = [NSDictionary dictionaryWithObjectsAndKeys:deviceID, @"UUID", @"GET_ID", @"OPERATION", APP_PLATFORM, @"platform", nil];
    else
        dic = [NSDictionary dictionaryWithObjectsAndKeys:deviceID, @"UUID", pushToken, @"push_token", @"GET_ID", @"OPERATION", APP_PLATFORM, @"platform", nil];
    NSString *ret = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_LOGIN withData:dic]];
    if (ret == nil || [ret isEqualToString:@""]) {
        ret = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    } else if ([ret isEqualToString:@"NOF"]) {
        ret = nil;
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:ret forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return ret;
}

+ (void)setPushToken:(NSString*)t {
    pushToken = t;
    [self startGetID];
}
//获取昵称
+ (NSString*)getNicknamebyID {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"ID", @"GET_NICKNAME", @"OPERATION", nil];
    NSString *ret = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_LOGIN withData:dic]];
    if ([ret isEqualToString:@""])
        ret = nil;
    return ret;
}
//单次MD5加密
+ (NSString*)encMain:(NSString*)pw {
    const char *cStr = [pw UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash uppercaseString];
}
//密码3次相套MD5加密
+ (NSString*)encryptPassword:(NSString*)pw {
    NSString *enc_pw = [self encMain:[self encMain:[self encMain:pw]]];
    return enc_pw;
}
//注册
+ (BOOL)registerWithID:(NSString*)ID andPassword:(NSString*)pass andVerficationCode:(NSString*)code {
    USER_BEGIN_LOADGING
    NSString *deviceID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UUID"];
    pass = [self encryptPassword:pass];
    NSDictionary *dic;
    if (pushToken == nil || [pushToken isEqualToString:@""])
        dic = [NSDictionary dictionaryWithObjectsAndKeys:deviceID, @"UUID", ID, @"ID", pass, @"pass", code, @"verification", @"REGISTER", @"OPERATION", APP_PLATFORM, @"platform", nil];
    else
        dic = [NSDictionary dictionaryWithObjectsAndKeys:deviceID, @"UUID", ID, @"ID", pass, @"pass", code, @"verification", pushToken, @"push_token", @"REGISTER", @"OPERATION", APP_PLATFORM, @"platform", nil];
    NSString *ret = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_LOGIN withData:dic]];
    if ([ret isEqualToString:@"OK"]) {
        currentID = ID;
        currentUsername = ID;
        [[NSUserDefaults standardUserDefaults] setObject:currentID forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:currentUsername forKey:@"usernick"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        USER_END_LOADGING
        return YES;
    } else if ([ret isEqualToString:@"ERROR"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"该手机号已被注册"];
        return NO;
    } else if ([ret isEqualToString:@"ERROR_CODE"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"验证码错误"];
        return NO;
    } else {
        [HTTPRequest alert:NETWORK_ERROR];
        USER_END_LOADGING
        return NO;
    }
}
//重置密码
+ (BOOL)resetPWWithID:(NSString*)ID andPassword:(NSString*)pass andVerficationCode:(NSString*)code {
    USER_BEGIN_LOADGING
    NSString *deviceID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UUID"];
    pass = [self encryptPassword:pass];
    NSDictionary *dic;
    if (pushToken == nil || [pushToken isEqualToString:@""])
        dic = [NSDictionary dictionaryWithObjectsAndKeys:deviceID, @"UUID", ID, @"ID", pass, @"pass", code, @"verification", @"REGISTER", @"OPERATION", APP_PLATFORM, @"platform", nil];
    else
        dic = [NSDictionary dictionaryWithObjectsAndKeys:deviceID, @"UUID", ID, @"ID", pass, @"pass", code, @"verification", pushToken, @"push_token", @"RESET_PW", @"OPERATION", APP_PLATFORM, @"platform", nil];
    NSString *ret = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_LOGIN withData:dic]];
    if ([[ret substringToIndex:2] isEqualToString:@"OK"]) {
        currentID = ID;
        if ([ret length] > 3)
            currentUsername = [ret substringFromIndex:3];
        [[NSUserDefaults standardUserDefaults] setObject:currentID forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:currentUsername forKey:@"usernick"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        USER_END_LOADGING
        return YES;
    } else if ([ret isEqualToString:@"ERROR"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"该手机号还没有被注册"];
        return NO;
    } else if ([ret isEqualToString:@"ERROR_CODE"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"验证码错误"];
        return NO;
    } else {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return NO;
    }
}
//获取短信验证码
+(BOOL)sendVerficationCodeTo:(NSString*)tel {
    USER_BEGIN_LOADGING
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:tel, @"ID", @"get_verf_code", @"OPERATION", nil];
    NSString *ret = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_LOGIN withData:dic]];
    if ([ret isEqualToString:@"ERROR"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"该手机号已被注册"];
        return NO;
    } else if ([ret isEqualToString:@"SENT_SMS"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"您的验证码将以短信发给您"];
        return YES;
    } else if (ret.length == 4) { //OK
        USER_END_LOADGING
        [HTTPRequest alert:[NSString stringWithFormat:@"您的验证码为：%@", ret]];
        return YES;
    } else if (ret != nil && ![ret isEqualToString:@""]) {
        USER_END_LOADGING
        [HTTPRequest alert:ret];
        return NO;
    } else {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return NO;
    }
}
//登陆
+ (BOOL)loginWithID:(NSString*)ID andPassword:(NSString*)pass {
    USER_BEGIN_LOADGING
    NSString *deviceID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UUID"];
    pass = [self encryptPassword:pass];
    NSDictionary *dic;
    if (pushToken == nil || [pushToken isEqualToString:@""])
        dic = [NSDictionary dictionaryWithObjectsAndKeys:deviceID, @"UUID", ID, @"ID", pass, @"pass", @"LOGIN", @"OPERATION", APP_PLATFORM, @"platform", nil];
    else
        dic = [NSDictionary dictionaryWithObjectsAndKeys:deviceID, @"UUID", ID, @"ID", pass, @"pass", pushToken, @"push_token", @"LOGIN", @"OPERATION", APP_PLATFORM, @"platform", nil];
    NSString *ret = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_LOGIN withData:dic]];
    if (ret.length >= 3 && [[ret substringToIndex:3] isEqualToString:@"OK_"]) {
        currentID = ID;
        currentUsername = [ret substringFromIndex:3];
        [[NSUserDefaults standardUserDefaults] setObject:currentID forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:currentUsername forKey:@"usernick"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        USER_END_LOADGING
        return YES;
    } else if ([ret isEqualToString:@"ERROR"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"用户名/密码错误"];
        return NO;
    } else {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return NO;
    }
}
//登出
+ (BOOL)logOut {
    USER_BEGIN_LOADGING
    NSString *deviceID = [[NSUserDefaults standardUserDefaults] stringForKey:@"UUID"];
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:deviceID, @"UUID", @"LOGOUT", @"OPERATION", APP_PLATFORM, @"platform", nil];
    if ([[HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_LOGIN withData:dic]] isEqualToString:@"OK"]) {
        currentID = nil;
        currentUsername = nil;
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"usernick"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        USER_END_LOADGING
        return YES;
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return NO;
}
//获取当前用户名
+ (NSString*)getCurrentID {
    if (currentID == nil || [currentID isEqualToString:@""]) {
        return nil;
    }
    return currentID;
}
//历史点单记录
+ (NSArray*)getHistoryOrders {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"ID", nil];
    NSData *recvData = [HTTPRequest syncGet:SERVER_CUSTOMER_GET_ORDER withData:dic];
    if (recvData == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}

+ (NSArray*)getHistoryPreorders {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"ID", nil];
    NSData *recvData = [HTTPRequest syncGet:SERVER_CUSTOMER_GET_PREORDER withData:dic];
    if (recvData == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}

+ (NSArray*)getHistoryOrdersFromCurrentStore {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"ID", storeID, @"storeID", nil];
    NSData *recvData = [HTTPRequest syncGet:SERVER_GET_CURRENT_HISTORY_ORDER withData:dic];
    if (recvData == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}
//单个单的详细记录
+ (NSArray*)getHistoryOrdersFromStore:(NSString*)sid andOrderID:(int)oid {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"ID", sid, @"storeID", [NSString stringWithFormat:@"%d", oid], @"orderID", nil];
    NSData *recvData = [HTTPRequest syncGet:SERVER_GET_SINGLE_ORDER_HISTORY withData:dic];
    if (recvData == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}

+ (NSArray*)getHistoryPreordersFromStore:(NSString*)sid andOrderID:(int)oid {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"ID", sid, @"storeID", [NSString stringWithFormat:@"%d", oid], @"orderID", nil];
    NSData *recvData = [HTTPRequest syncGet:SERVER_GET_SINGLE_PREORDER_HISTORY withData:dic];
    if (recvData == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}
//钱包余额
+ (float)getPurseMoney {
    USER_BEGIN_LOADGING
    //get money online
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"username", nil];
    NSString *recvData = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_GET_PURSE_MONEY withData:dic]];
    if (recvData == nil || [recvData isEqualToString:@""]) {
        USER_END_LOADGING
        return -1;
    }
    USER_END_LOADGING
    return [recvData floatValue];
}

+ (float)getPurseMoneyAsync {
    //get money online
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"username", nil];
    NSString *recvData = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_GET_PURSE_MONEY withData:dic]];
    if (recvData == nil || [recvData isEqualToString:@""]) {
        return -1;
    }
    return [recvData floatValue];
}
//积分余额
+ (NSInteger)getCreditForStoreID:(NSString*)c_StoreID {
    USER_BEGIN_LOADGING
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"username", c_StoreID, @"storeID", nil];
    NSString *recvData = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_GET_CREDIT withData:dic]];
    if (recvData == nil || [recvData isEqualToString:@""]) {
        USER_END_LOADGING
        return -1;
    }
    USER_END_LOADGING
    return [recvData integerValue];
}

+ (NSInteger)getCreditForStoreIDAsync:(NSString*)c_StoreID {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"username", c_StoreID, @"storeID", nil];
    NSString *recvData = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_GET_CREDIT withData:dic]];
    if (recvData == nil || [recvData isEqualToString:@""]) {
        return -1;
    }
    return [recvData integerValue];
}

+ (void)beginLoading {
    BEGIN_LOADING
}

+ (void)endLoading {
    END_LOADING
}

//payment付款
+ (BOOL)payWithChannel:(NSString*)channel andAmount:(float)amt onViewController:(UIViewController*)vc {
    NSString *amount = [NSString stringWithFormat:@"%.2f", amt];
    NSDictionary* dict = @{
                           @"amount"  : amount,  //金额
                           @"username": currentID,
                           @"storeID" : storeID,
                           @"mall" : [store preorder_mode] ? @"preorder" : @"normal"
                           };
    return [self payWithChannel:channel andInfo:dict onViewController:vc];
}

+ (BOOL)addMoneyToPurseWithChannel:(NSString*)channel andAmount:(float)amt onViewController:(UIViewController*)vc {
    NSString *amount = [NSString stringWithFormat:@"%.2f", amt];
    NSDictionary* dict = @{
                           @"amount"  : amount,  //金额
                           @"username": currentID,
                           @"storeID" : @"0",
                           @"mall" : @"refill"
                           };
    return [self payWithChannel:channel andInfo:dict onViewController:vc];
}

+ (BOOL)payByPurseForAmount:(float)amt {
    NSString *amount = [NSString stringWithFormat:@"%.2f", amt];
    NSDictionary* dict = @{
                           @"amount"  : amount,  //金额
                           @"username": currentID,
                           @"storeID" : storeID,
                           @"mall" : [store preorder_mode] ? @"preorder" : @"normal"
                           };
    return [self payByPurseFor:dict];
}

+(BOOL)payByCreditForTotalCredit:(NSInteger)totalCredit {
    USER_BEGIN_LOADGING
    NSString *amount = [NSString stringWithFormat:@"%d", totalCredit];
    NSDictionary* dict = @{
                           @"amount"  : amount,  //金额
                           @"username": currentID,
                           @"storeID" : storeID,
                           @"mall" : [store preorder_mode] ? @"preorder" : @"normal",
                           @"channel" : @"credit"
                           };
    NSError* error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSData *rawdata = [HTTPRequest syncPost:SERVER_PINGPP_PAY withRawData:data];
    NSString* databody = [[NSMutableString alloc] initWithData:rawdata encoding:NSUTF8StringEncoding];
    if (databody != nil && databody.length > 0) {
        if ([databody isEqualToString:@"OK"]) {
            NSInteger creditValue = [self getCreditForStoreIDAsync:storeID];
            USER_END_LOADGING
            [HTTPRequest alert:[NSString stringWithFormat:@"积分支付成功\n剩余积分为%d分", creditValue]];
            return YES;
        } else {
            USER_END_LOADGING
            [HTTPRequest alert:[NSString stringWithFormat:@"付款失败：%@", databody]];
            return NO;
        }
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return NO;
}

////////////////////////////////////

+ (BOOL)payByPurseFor:(NSDictionary*)dict {
    USER_BEGIN_LOADGING
    NSMutableDictionary *dic = [dict mutableCopy];
    [dic setObject:@"purse" forKey:@"channel"];
    NSError* error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSData *rawdata = [HTTPRequest syncPost:SERVER_PINGPP_PAY withRawData:data];
    NSString* databody = [[NSMutableString alloc] initWithData:rawdata encoding:NSUTF8StringEncoding];
    if (databody != nil && databody.length > 0) {
        if ([databody isEqualToString:@"OK"]) {
            float purseValue = [self getPurseMoneyAsync];
            USER_END_LOADGING
            [HTTPRequest alert:[NSString stringWithFormat:@"付款成功\n剩余金额为%.2f元", purseValue]];
            return YES;
        } else {
            USER_END_LOADGING
            [HTTPRequest alert:[NSString stringWithFormat:@"付款失败：%@", databody]];
            return NO;
        }
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return NO;
}

+ (BOOL)payWithChannel:(NSString*)channel andInfo:(NSDictionary*)dict onViewController:(UIViewController*)vc {
    if ([channel isEqualToString:@"wx"] && ![WXApi isWXAppInstalled]) {
        UIAlertView *al = [[UIAlertView alloc]initWithTitle:@"微信未安装" message:@"您可以选择其他支付方式" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
        [al show];
        return NO;
    }
    USER_BEGIN_LOADGING
    NSMutableDictionary *dic = [dict mutableCopy];
    [dic setObject:channel forKey:@"channel"];
    NSError* error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSData *rawdata = [HTTPRequest syncPost:SERVER_PINGPP_PAY withRawData:data];
    NSString* databody = [[NSMutableString alloc] initWithData:rawdata encoding:NSUTF8StringEncoding];
    if (databody != nil && databody.length > 0) {
        if ([[databody substringToIndex:5] isEqualToString:@"ERROR"]) {
            USER_END_LOADGING
            [HTTPRequest alert:[NSString stringWithFormat:@"付款错误：%@", databody]];
            return NO;
        } else {
            USER_END_LOADGING
            //show waiting for confirmation alertview
            UIAlertView *waitPayDone = [[UIAlertView alloc]initWithTitle:@"等待支付完成..." message:nil delegate:[[UIApplication sharedApplication] delegate] cancelButtonTitle:@"取消"otherButtonTitles:@"支付完成", nil];
            [waitPayDone setTag:2000];
            [waitPayDone show];
            //process databody
            NSString *payIDStr = [[databody componentsSeparatedByString:@":"] objectAtIndex:0];
            NSInteger paymentID = [payIDStr integerValue];
            databody = [databody substringFromIndex:[payIDStr length] + 1];
            [AppDelegate setCurrentPaymentID:paymentID];
            //ping++接口
            //[Pingpp createPayment:databody viewController:vc appURLScheme:PING_URL_SCHEME delegate:(id<PingppDelegate>)([UIApplication sharedApplication].delegate)];
            return YES;
        }
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return NO;
}

////////////////////////////////////

+ (BOOL)payByPurseForWallPost:(NSInteger)postID ofAmount:(float)amt {
    NSString *amount = [NSString stringWithFormat:@"%.2f", amt];
    NSString *postIDstr = [NSString stringWithFormat:@"%d", postID];
    NSDictionary* dict = @{
                           @"username": currentID,
                           @"amount" : amount,  //金额
                           @"postID" : postIDstr,
                           @"storeID" : storeID,
                           @"mall" : @"wall"
                           };
    return [self payByPurseFor:dict];
}

+ (BOOL)payWallPost:(NSInteger)postID byChannel:(NSString*)channel ofAmount:(float)amt onViewContoller:(UIViewController*)vc {
    NSString *amount = [NSString stringWithFormat:@"%.2f", amt];
    NSString *postIDstr = [NSString stringWithFormat:@"%d", postID];
    NSDictionary* dict = @{
                           @"username" : currentID,
                           @"amount"  : amount,  //金额
                           @"postID" : postIDstr,
                           @"storeID" : storeID,
                           @"mall" : @"wall"
                           };
    return [self payWithChannel:channel andInfo:dict onViewController:vc];
}

////////////////////////////////////

+ (NSInteger)purchaseMallItem:(NSDictionary*)info {
    USER_BEGIN_LOADGING
    NSError* error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:&error];
    NSData *rawdata = [HTTPRequest syncPost:SERVER_MALL_ORDER withRawData:data];
    NSString* databody = [[NSMutableString alloc] initWithData:rawdata encoding:NSUTF8StringEncoding];
    if (databody != nil && databody.length > 0) {
        if ([[databody substringToIndex:2] isEqualToString:@"OK"]) {
            USER_END_LOADGING
            return [[databody substringFromIndex:3] integerValue];
        } else if ([databody isEqualToString:@"ERROR_ISF"]) {
            USER_END_LOADGING
            [HTTPRequest alert:@"兑换失败：积分不足"];
            return -1;
        } else if ([databody isEqualToString:@"ERROR_MALL"]) {
            USER_END_LOADGING
            [HTTPRequest alert:@"该商城暂不支持"];
            return -1;
        } else if ([databody isEqualToString:@"ERROR_PRICE"]) {
            USER_END_LOADGING
            [HTTPRequest alert:@"价格错误，可能有价格浮动，请刷新后重试"];
            return -1;
        } else if ([databody isEqualToString:@"ERROR_TIME"]) {
            USER_END_LOADGING
            [HTTPRequest alert:@"该活动已过报名期限"];
            return -1;
        } else if ([databody isEqualToString:@"ERROR_FULL"]) {
            USER_END_LOADGING
            [HTTPRequest alert:@"该活动人数已满"];
            return -1;
        } else if ([databody isEqualToString:@"ERROR_ALREADY_IN"]) {
            USER_END_LOADGING
            [HTTPRequest alert:@"您已经报名该活动，请勿重复报名"];
            return -1;
        } else {
            USER_END_LOADGING
            [HTTPRequest alert:[NSString stringWithFormat:@"错误：%@", databody]];
            return -1;
        }
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return -1;
}

//收藏店家
+ (BOOL)collectStore:(int)c_storeID {
    if ([user getCurrentID] == nil)
        return NO;
    USER_BEGIN_LOADGING
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"COLLECT", @"OPERATION",
                         [NSString stringWithFormat:@"%d", c_storeID], @"storeID",
                         [user getCurrentID], @"username", nil];
    NSData *rawdata = [HTTPRequest syncGet:SERVER_COLLECT_STORE withData:dic];
    if (rawdata != nil && [[HTTPRequest stringFromData:rawdata] isEqualToString:@"OK"]) {
        USER_END_LOADGING
        return YES;
    } else if (rawdata != nil && [HTTPRequest stringFromData:rawdata] != nil) {
        USER_END_LOADGING
        [HTTPRequest alert:[NSString stringWithFormat:@"错误：%@", [HTTPRequest stringFromData:rawdata]]];
        return NO;
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return NO;
}

+ (BOOL)unCollectStore:(int)c_storeID {
    if ([user getCurrentID] == nil)
        return NO;
    USER_BEGIN_LOADGING
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"UNCOLLECT", @"OPERATION",
                         [NSString stringWithFormat:@"%d", c_storeID], @"storeID",
                         [user getCurrentID], @"username", nil];
    NSData *rawdata = [HTTPRequest syncGet:SERVER_COLLECT_STORE withData:dic];
    if (rawdata != nil && [[HTTPRequest stringFromData:rawdata] isEqualToString:@"OK"]) {
        USER_END_LOADGING
        return YES;
    } else if (rawdata != nil && [HTTPRequest stringFromData:rawdata] != nil) {
        USER_END_LOADGING
        [HTTPRequest alert:[NSString stringWithFormat:@"错误：%@", [HTTPRequest stringFromData:rawdata]]];
        return NO;
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return NO;
}

//评价店家
+ (BOOL)evaluteStore:(NSString*)e_storeID rating:(int)r comment:(NSString*)comment {
    if (e_storeID == nil) {
        return NO;
    }
    if ([user getCurrentID] == nil)
        return NO;
    if (r == 0) {
        return NO;
    }
    if (comment == nil) {
        comment = @"";
    }
    USER_BEGIN_LOADGING
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSString stringWithFormat:@"%d", r], @"rating",
                         comment, @"comment",
                         e_storeID, @"storeID",
                         [user getCurrentID], @"username", nil];
    NSData *rawdata = [HTTPRequest syncGet:SERVER_EVALUATE_STORE withData:dic];
    if (rawdata != nil && [[HTTPRequest stringFromData:rawdata] isEqualToString:@"OK"]) {
        USER_END_LOADGING
        return YES;
    } else if (rawdata != nil && [[HTTPRequest stringFromData:rawdata] isEqualToString:@"ERROR_DUPLICATE"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"您已经评价过该店"];
        return NO;
    } else if (rawdata != nil && [HTTPRequest stringFromData:rawdata] != nil) {
        USER_END_LOADGING
        [HTTPRequest alert:[NSString stringWithFormat:@"错误：%@", [HTTPRequest stringFromData:rawdata]]];
        return NO;
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return NO;
}

+ (NSString*)uuid {
    CFUUIDRef puuid = CFUUIDCreate( nil );
    CFStringRef uuidString = CFUUIDCreateString( nil, puuid );
    NSString *result = (NSString *)CFBridgingRelease(CFStringCreateCopy( NULL, uuidString));
    CFRelease(puuid);
    CFRelease(uuidString);
    return result;
}

//分享
+ (void)shareText:(NSString*)text withDescription:(NSString*)desp andImage:(UIImage*)image withURL:(NSString *)url onViewController:(UIViewController *)vc {
    if (url == nil) {
        //app介绍和下载页
        url = @"https://itunes.apple.com/us/app/unicafe-ka-fei-ting-zhi-neng/id933846850?ls=1&mt=8";
    }
    
    if (image == nil) {
        image = [UIImage imageNamed:@"support.png"];
    }
    
    NSArray *myActivities = @[[[WeixinSessionActivity alloc] init], [[WeixinTimelineActivity alloc] init]];
    if (![WXApi isWXAppInstalled]) {
        myActivities = nil;
    }
    NSArray *activityItems = @[text, desp, image, [NSURL URLWithString:url]];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:myActivities];
    activityController.excludedActivityTypes = @[UIActivityTypePostToFacebook, UIActivityTypePostToFlickr, UIActivityTypePostToTwitter, UIActivityTypePostToVimeo, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop, UIActivityTypeMail];
    [vc presentViewController:activityController animated:YES completion:nil];
}

@end

//主页店家列表信息
@implementation any_store

-(any_store*)initWithTitle:(NSString*)title andID:(int)ID andAddress:(NSString*)address withTel:(NSString*)phoneNumber support:(BOOL)spt withRating:(float)r andAvgPrice:(float)ap andImage:(NSString*)image {
    storeID = ID;
    self.title = title;
    self.address = address;
    self.tel = phoneNumber;
    support = spt;
    rating = r;
    avgPrice = ap;
    self.imageName = image;
    whiteName = YES;
    self.notes = [[NSMutableArray alloc] init];
    return self;
}

- (void)setWhiteName:(BOOL)wn {
    whiteName = wn;
}

- (void)setLongitude:(double)lo andLatitude:(double)la {
    longitude = lo;
    latitude = la;
}

- (void)addNote:(NSString*)note {
    [self.notes addObject:note];
}

+ (NSArray*)getProvinces {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"province", @"level", nil];
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:[HTTPRequest syncGet:SERVER_MAP_REQUEST withData:dic] options:kNilOptions error:&error];
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}

+ (NSArray*)getCitiesInProvince:(NSString*)province {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"city", @"level", province, @"province", nil];
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:[HTTPRequest syncGet:SERVER_MAP_REQUEST withData:dic] options:kNilOptions error:&error];
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}

+ (NSArray*)getDistrictInCity:(NSString*)city inProvince:(NSString*)province {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"district", @"level", province, @"province", city, @"city", nil];
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:[HTTPRequest syncGet:SERVER_MAP_REQUEST withData:dic] options:kNilOptions error:&error];
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}

+ (NSArray*)getAllAreas {
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:[HTTPRequest syncGet:SERVER_MAP_REQUEST_ALL withData:nil] options:kNilOptions error:&error];
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}

+ (NSMutableArray*)getStoresInProvince:(NSString*)province andCity:(NSString*)city andDistrict:(NSString*)district andLo:(double)lo andLa:(double)la haveMall:(NSString*)mall numRecords:(int)nrows onlyCollected:(BOOL)collected options:(NSArray*)options {
    if (mall == nil) {
        mall = @"";
    }
    //解决php中文比较问题
    if ([province isEqualToString: @"全部"])
        province = @"ALL";
    if ([city isEqualToString: @"全部"])
        city = @"ALL";
    if ([district isEqualToString: @"全部"])
        district = @"ALL";
    
    NSString *uid = [user getCurrentID];
    if (uid == nil) {
        uid = @"";
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:province, @"province", city, @"city" , district, @"district",
                         [NSString stringWithFormat:@"%f", lo], @"longitude",
                         [NSString stringWithFormat:@"%f", la], @"latitude",
                         mall, @"mall",
                         uid, @"username",
                         [NSString stringWithFormat:@"%d", nrows], @"numRecords",
                         collected ? @"1" : @"0", @"collected", nil];
    for (int i = 0; i < [FILTER_COLUMNS_NAMES count]; i++) {
        [dic setObject:[options objectAtIndex:i] forKey:[FILTER_COLUMNS_NAMES objectAtIndex:i]];
    }
    
    NSData *recvData = [HTTPRequest syncGet:SERVER_STORE_REQUEST withData:dic];
    if (recvData == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    NSMutableArray *storeList = [[NSMutableArray alloc] init];
    for (NSDictionary *storeInfo in listInJSON) {
        BOOL spt = NO;
        if ([storeInfo objectForKey:@"support"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"support"] intValue] == 1) {
            spt = YES;
        }
        any_store *thisStore = [[any_store alloc] initWithTitle:[storeInfo objectForKey:@"name"]
                                                    andID:[(NSString*)[storeInfo objectForKey:@"ID"] intValue]
                                                     andAddress:[storeInfo objectForKey:@"address"]
                                                        withTel:[storeInfo objectForKey:@"tel"]
                                                        support:spt
                                                     withRating:[(NSString*)[storeInfo objectForKey:@"rating"] floatValue]
                                                    andAvgPrice:[(NSString*)[storeInfo objectForKey:@"avgPrice"] floatValue]
                                                       andImage:[storeInfo objectForKey:@"image"]];
        if ([storeInfo objectForKey:@"businessTime"] != [NSNull null] && ![[storeInfo objectForKey:@"businessTime"] isEqualToString:@""])
            [thisStore addNote:[storeInfo objectForKey:@"businessTime"]];
        if ([storeInfo objectForKey:@"desp"] != [NSNull null] && ![[storeInfo objectForKey:@"desp"] isEqualToString:@""])
            [thisStore addNote:[storeInfo objectForKey:@"desp"]];
        if ([storeInfo objectForKey:@"black"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"black"] intValue] == 1)
            [thisStore setWhiteName:NO];
        thisStore.wifi = NO;
        if ([storeInfo objectForKey:@"wifi"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"wifi"] intValue] == 1)
            thisStore.wifi = YES;
        thisStore.credit = NO;
        if ([storeInfo objectForKey:@"have_credit"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"have_credit"] intValue] == 1)
            thisStore.credit = YES;
        thisStore.cash = NO;
        if ([storeInfo objectForKey:@"have_cash"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"have_cash"] intValue] == 1)
            thisStore.cash = YES;
        thisStore.activity = NO;
        if ([storeInfo objectForKey:@"have_activity"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"have_activity"] intValue] == 1)
            thisStore.activity = YES;
        thisStore.groupon = NO;
        if ([storeInfo objectForKey:@"have_groupon"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"have_groupon"] intValue] == 1)
            thisStore.groupon = YES;
        thisStore.discount = NO;
        if ([storeInfo objectForKey:@"have_discount"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"have_discount"] intValue] == 1)
            thisStore.discount = YES;
        thisStore.collected = NO;
        if ([storeInfo objectForKey:@"collected"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"collected"] intValue] == 1)
            thisStore.collected = YES;
        thisStore.preorder = 0;
        if ([storeInfo objectForKey:@"canPreorder"] != [NSNull null] &&
            [(NSString*)[storeInfo objectForKey:@"canPreorder"] intValue] >= 0 &&
            [(NSString*)[storeInfo objectForKey:@"canPreorder"] intValue] <= 2)
            thisStore.preorder = [(NSString*)[storeInfo objectForKey:@"canPreorder"] intValue];
        thisStore.homepage = NO;
        if ([storeInfo objectForKey:@"have_homepage"] != [NSNull null] && [(NSString*)[storeInfo objectForKey:@"have_homepage"] intValue] == 1)
            thisStore.homepage = YES;
        
        [thisStore setLongitude:[[storeInfo objectForKey:@"longitude"] doubleValue] andLatitude:[[storeInfo objectForKey:@"latitude"] doubleValue]];
        [storeList addObject:thisStore];
    }
    return storeList;
}

//活动列表，直接使用json
+ (NSMutableArray*)getActivitiesInProvince:(NSString*)province andCity:(NSString*)city andDistrict:(NSString*)district andLo:(double)lo andLa:(double)la numRecords:(int)nrows onlyCollected:(BOOL)collected options:(NSArray*)options {
    //解决php中文比较问题
    if ([province isEqualToString: @"全部"])
        province = @"ALL";
    if ([city isEqualToString: @"全部"])
        city = @"ALL";
    if ([district isEqualToString: @"全部"])
        district = @"ALL";
    
    NSString *uid = [user getCurrentID];
    if (uid == nil) {
        uid = @"";
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:province, @"province", city, @"city" , district, @"district",
                         [NSString stringWithFormat:@"%f", lo], @"longitude",
                         [NSString stringWithFormat:@"%f", la], @"latitude",
                         uid, @"username",
                         [NSString stringWithFormat:@"%d", nrows], @"numRecords",
                         collected ? @"1" : @"0", @"collected", nil];
    for (int i = 0; i < [FILTER_COLUMNS_ACTIVITY_NAMES count]; i++) {
        [dic setObject:[options objectAtIndex:i] forKey:[FILTER_COLUMNS_ACTIVITY_NAMES objectAtIndex:i]];
    }
    
    NSData *recvData = [HTTPRequest syncGet:SERVER_ACTIVITY_REQUEST withData:dic];
    if (recvData == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return [listInJSON mutableCopy];
}

- (void)setStoreID:(int)sid {
    storeID = sid;
}

- (int)storeID {
    return storeID;
}

- (BOOL)support {
    return support;
}

- (float)rating {
    return rating;
}

- (float)avgPrice {
    return avgPrice;
}

- (BOOL)whiteName {
    return whiteName;
}

- (double)longitude {
    return longitude;
}

- (double)latitude {
    return latitude;
}

@end

//当前店家与菜单信息
@implementation store

+ (NSString*)getMallTitle:(NSString*)mall {
    if ([mall isEqualToString:@"credit"]) {
        return TITLE_CREDIT;
    } else if ([mall isEqualToString:@"cash"]) {
        return TITLE_CASH;
    } else if ([mall isEqualToString:@"activity"]) {
        return TITLE_ACTIVITY;
    } else if ([mall isEqualToString:@"groupon"]) {
        return TITLE_GROUPON;
    }
    return @"";
}

+ (NSString*)getStoreIDForMajor:(int)major andMinor:(int)minor {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSString stringWithFormat:@"%d", major], @"major",
                         [NSString stringWithFormat:@"%d", minor], @"minor", nil];
    NSString *tempStoreID = [[NSString alloc] initWithData:[HTTPRequest syncGet:SERVER_STORE_ID withData:dic] encoding:NSUTF8StringEncoding];
    return tempStoreID;
}

+ (BOOL)storeChanged:(int)major andMinor:(int)minor {
    /*
    if (major == lastMajor && minor == lastMinor) {
        if (lastMajorLoaded == lastMajor && lastMinorLoaded == lastMinor)
            lastIDUpdate = [NSDate date];
        return NO;
    }
    //遍历beacons
    if (beacons != nil) {
        for (beacon *b in beacons) {
            if (b.major == major && b.minor == minor) {
                lastMajor = major;
                lastMinor = minor;
                lastMajorLoaded = lastMajor;
                lastMinorLoaded = lastMinor;
                lastIDUpdate = [NSDate date];
                return NO;
            }
        }
    }
    
    NSString *tempStoreID = [self getStoreIDForMajor:major andMinor:minor];
    if (tempStoreID != nil && ![tempStoreID isEqualToString:@""] && ![tempStoreID isEqualToString:storeID]) {
        NSLog(@"Store Changed major:%d minor:%d storeID:%@", major, minor, tempStoreID);
        lastMajor = major;
        lastMinor = minor;
        return YES;
    }
     */
    return NO;
}

+ (void)setTableNum:(int)num {
    tableNum = num;
}

+ (int)getTableNum {
    return tableNum;
}

+ (BOOL)creditCanPay {
    return creditCanPay;
}

+ (float)creditToCentRatio {
    return creditToCentRatio;
}

+ (int)payOption {
    return payOption;
}

+ (void)set_preorder_mode:(BOOL)p_mode {
    lastIDUpdate = [NSDate distantPast];
    preorder_mode = p_mode;
    if (!preorder_mode) {
        [orderInfo saveOrder];
        storeID = @"";
        //[(storeList*)[AppDelegate getStoreListController] getOutStore];
    } else {
        lastMajor = 0;
        lastMinor = 0;
        lastMajorLoaded = 0;
        lastMinorLoaded = 0;
        //[beacons removeAllObjects];
    }
}

+ (BOOL)preorder_mode {
    return preorder_mode;
}

+ (int)preorder_option_allowed {
    return p_option;
}

+ (int)preorder_minutes_after_now {
    return preorder_minutes_after_now;
}

+ (void)setForceReloadStore:(BOOL)force {
    forceReloadStore = force;
}

+ (void)forceReloadStore {
    forceReloadStore = YES;
}

+ (BOOL)setCurrentStore:(NSString*)tempStoreID {
    if ([tempStoreID isEqualToString:storeID] && !forceReloadStore) {
        lastIDUpdate = [NSDate date];
        return YES;
    } else if (tempStoreID == nil || [tempStoreID isEqualToString:@""]) {
        //not found or same store
        return NO;
    }
    
    forceReloadStore = NO;
    
    whiteLabelName = YES;
    
    //save order
    [orderInfo saveOrder];
    
    //update menu
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:tempStoreID, @"id", nil];
    
    //先用sync的，需要之后再改
    NSData *recvData = [HTTPRequest syncGet:SERVER_STORE_MENU withData:dic];
    if (recvData == nil) {
        [HTTPRequest alert:NETWORK_ERROR];
        return NO;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (jsonRoot == nil) {
        NSLog(@"json failed");
        return NO;
    }
    
    storeID = tempStoreID;
    NSLog(@"change sid : %@", storeID);
    tableNum = 0;
    
    if (menu == nil)
        menu = [[NSMutableArray alloc] init];
    else
        [menu removeAllObjects];
    
    if (order == nil) {
        order = [[NSMutableArray alloc] init];
    } else {
        [order removeAllObjects];
    }
    
    //load order
    if (![db lock])
        NSLog(@"LOCK FAILED");
    NSArray *ar = [db selectInTable:@"orders" withKeysAndValues:[NSDictionary dictionaryWithObjectsAndKeys:storeID, @"store", nil] orderBy:@"placeID"];
    if (ar == nil) {
        NSLog(@"SELECT FAILED");
        if (![db rollback])
            NSLog(@"ROLLBACK FAILED");
    } else {
        for (NSDictionary *dic in ar) {
            int oid = [(NSString*)[dic objectForKey:@"dishID"] intValue];
            int oc = [(NSString*)[dic objectForKey:@"quantity"] intValue];
            orderInfo *oi = [[orderInfo alloc] initWithID:oid andCount:oc];
            [order addObject:oi];
        }
        if (![db commit])
            NSLog(@"COMMIT FAILED");
    }
    
    storeName = [jsonRoot objectForKey:@"storeName"];
    NSLog(@"餐厅名称：%@", storeName);
    support = NO;
    if ([jsonRoot objectForKey:@"support"] != [NSNull null] && [(NSString*)[jsonRoot objectForKey:@"support"] intValue] == 1) {
        support = YES;
    }
    NoTableNum = NO;
    if ([jsonRoot objectForKey:@"tableFlag"] != [NSNull null] && [(NSString*)[jsonRoot objectForKey:@"tableFlag"] intValue] == 0) {
        NoTableNum = YES;
    }
    //label color
    if ([jsonRoot objectForKey:@"black"] != [NSNull null] && [(NSString*)[jsonRoot objectForKey:@"black"] intValue] == 1) {
        whiteLabelName = NO;
    }
    //wifi
    wifi = NO;
    if ([jsonRoot objectForKey:@"wifi"] != [NSNull null] && [(NSString*)[jsonRoot objectForKey:@"wifi"] intValue] == 1) {
        wifi = YES;
    }
    creditToCentRatio = 0;
    if ([jsonRoot objectForKey:@"creditToCentRatio"] != [NSNull null]) {
        creditToCentRatio = [(NSString*)[jsonRoot objectForKey:@"creditToCentRatio"] floatValue];
    }
    creditCanPay = NO;
    if ([jsonRoot objectForKey:@"creditCanPay"] != [NSNull null] && [(NSString*)[jsonRoot objectForKey:@"creditCanPay"] intValue] == 1 && creditToCentRatio > 0) {
        creditCanPay = YES;
    }
    p_option = 0;
    if ([jsonRoot objectForKey:@"canPreorder"] != [NSNull null] &&
        [(NSString*)[jsonRoot objectForKey:@"canPreorder"] intValue] >= 0 &&
        [(NSString*)[jsonRoot objectForKey:@"canPreorder"] intValue] <= 2)
        p_option = [(NSString*)[jsonRoot objectForKey:@"canPreorder"] intValue];
    preorder_minutes_after_now = 15;
    if ([jsonRoot objectForKey:@"preorderAfterMinutes"] != [NSNull null]) {
        preorder_minutes_after_now = [[jsonRoot objectForKey:@"preorderAfterMinutes"] intValue];
    }
    
    //pay option 0-2
    payOption = PAY_OPTION_BEFORE;
    if ([jsonRoot objectForKey:@"payOption"] != [NSNull null])
        payOption = [(NSString*)[jsonRoot objectForKey:@"payOption"] intValue];
    if (payOption > PAY_OPTION_LATER || payOption < PAY_OPTION_BEFORE) {
        payOption = PAY_OPTION_BEFORE;
    }
    
    //load beacons
    //缓存beacon列表，用于同一家店内用户走动
    /*
    if (beacons == nil) {
        beacons = [[NSMutableArray alloc] init];
    } else {
        [beacons removeAllObjects];
    }
    NSArray *beaconsInJSON = [jsonRoot objectForKey:@"beacons"];
    for (NSDictionary *item in beaconsInJSON) {
        //insert into menu
        beacon *b = [[beacon alloc] initWithMajor:[[item objectForKey:@"major"] integerValue] andMinor:[[item objectForKey:@"minor"] integerValue]];
        [beacons addObject:b];
    }
     */
    
    //菜单
    NSArray *foodListInJSON = [jsonRoot objectForKey:@"menu"];
    for (NSDictionary *item in foodListInJSON) {
        //insert into menu
        foodInfo *food = [[foodInfo alloc] initWithName:[item objectForKey:@"name"]
                                               andPrice:[[item objectForKey:@"price"] floatValue]
                                                  image:[item objectForKey:@"image"]
                                               catagory:[item objectForKey:@"catagory"]
                                                   desp:[item objectForKey:@"description"]
                                                  desp2:[item objectForKey:@"note"]
                                                  desp3:[item objectForKey:@"addition"]
                                                 withId:[[item objectForKey:@"dishID"] intValue]];
        food.scoreToEarn = [[item objectForKey:@"score"] integerValue];
        food.originalPrice = [[item objectForKey:@"originalPrice"] floatValue];
        [menu addObject:food];
    }
    
    [orderInfo checkOrder];
    
    if (![store preorder_mode]) {
        lastIDUpdate = [NSDate date];
        lastMajorLoaded = lastMajor;
        lastMinorLoaded = lastMinor;
    }
    [foodList askForReset];
    [storeList refreshMenuAndOrder];
    
    return YES;
}

+ (NSMutableArray*)getMenuOfStore:(NSString*)sid {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:sid, @"id", nil];
    
    //先用sync的，需要之后再改
    NSData *recvData = [HTTPRequest syncGet:SERVER_STORE_MENU withData:dic];
    if (recvData == nil) {
        [HTTPRequest alert:NETWORK_ERROR];
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (jsonRoot == nil) {
        NSLog(@"json failed");
        return nil;
    }
    NSMutableArray *m = [[NSMutableArray alloc] init];
    NSArray *foodListInJSON = [jsonRoot objectForKey:@"menu"];
    for (NSDictionary *item in foodListInJSON) {
        //insert into menu
        foodInfo *food = [[foodInfo alloc] initWithName:[item objectForKey:@"name"]
                                               andPrice:[[item objectForKey:@"price"] floatValue]
                                                  image:[item objectForKey:@"image"]
                                               catagory:[item objectForKey:@"catagory"]
                                                   desp:[item objectForKey:@"description"]
                                                  desp2:[item objectForKey:@"note"]
                                                  desp3:[item objectForKey:@"addition"]
                                                 withId:[[item objectForKey:@"dishID"] intValue]];
        food.scoreToEarn = [[item objectForKey:@"score"] integerValue];
        food.originalPrice = [[item objectForKey:@"originalPrice"] floatValue];
        [m addObject:food];
    }
    return m;
}

+ (NSMutableArray*)getCatagorisOfMenu:(NSMutableArray*)m {
    NSMutableArray *ra = [[NSMutableArray alloc] init];
    for (int i = 0; i < m.count; i++) {
        //start search
        bool found = false;
        NSString *str = ((foodInfo*)[m objectAtIndex:i]).catagory;
        for (int j = 0; j < ra.count; j++) {
            if ([((NSString*)[ra objectAtIndex:j]) isEqualToString:str]) {
                found = true;
                break;
            }
        }
        if (!found) {
            [ra addObject:str];
        }
    }
    return ra;
}

+(NSMutableArray*)getMenuSortedByCatagoriesAndNameOfMenu:(NSMutableArray*)m {
    NSMutableArray *r = [[NSMutableArray alloc] init];
    NSMutableArray *catas = [self getCatagorisOfMenu:m];
    for (NSString *cata in catas) {
        [r addObject:[self getMenubyCatagorySortedByName:cata ofMenu:m]];
    }
    return r;
}
+(NSMutableArray*)getMenuSortedByCatagoriesAndPopularityOfMenu:(NSMutableArray*)m {
    NSMutableArray *r = [[NSMutableArray alloc] init];
    NSMutableArray *catas = [self getCatagorisOfMenu:m];
    for (NSString *cata in catas) {
        [r addObject:[self getMenubyCatagorySortedByPopularity:cata ofMenu:m]];
    }
    return r;
}

+(NSMutableArray*)getMenuSortedByCatagoriesAndDefaultOfMenu:(NSMutableArray*)m {
    NSMutableArray *r = [[NSMutableArray alloc] init];
    NSMutableArray *catas = [self getCatagorisOfMenu:m];
    for (NSString *cata in catas) {
        [r addObject:[self getMenubyCatagory:cata ofMenu:m]];
    }
    return r;
}

+ (NSMutableArray*)getMenubyCatagory:(NSString*)filterCatagory ofMenu:(NSMutableArray*)m {
    NSMutableArray *ra = [[NSMutableArray alloc] init];
    for (int i = 0; i < m.count; i++) {
        //start search
        NSString *str = ((foodInfo*)[m objectAtIndex:i]).catagory;
        if ([str isEqualToString:filterCatagory]) {
            [ra addObject:(foodInfo*)[m objectAtIndex:i]];
        }
    }
    
    //sort by orderCount
    NSArray *resultArray = [ra sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int n1 = [[[((foodInfo*)obj1).addition componentsSeparatedByString:@":"] objectAtIndex:0] intValue];
        int n2 = [[[((foodInfo*)obj2).addition componentsSeparatedByString:@":"] objectAtIndex:0] intValue];
        NSNumber *number1 = [NSNumber numberWithInt:n1];
        NSNumber *number2 = [NSNumber numberWithInt:n2];
        
        NSComparisonResult result = [number1 compare:number2];
        
        return result == NSOrderedAscending;
    }];
    
    return [resultArray mutableCopy];
}

+(NSMutableArray*)getMenubyCatagorySortedByName:(NSString*)filterCatagory ofMenu:(NSMutableArray*)m {
    NSMutableArray *ra = [[NSMutableArray alloc] init];
    for (int i = 0; i < m.count; i++) {
        //start search
        NSString *str = ((foodInfo*)[m objectAtIndex:i]).catagory;
        if ([str isEqualToString:filterCatagory]) {
            [ra addObject:(foodInfo*)[m objectAtIndex:i]];
        }
    }
    
    //sort by orderCount
    NSArray *resultArray = [ra sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSComparisonResult result = [((foodInfo*)obj1).title compare:((foodInfo*)obj2).title];
        return result == NSOrderedAscending;
    }];
    
    return [resultArray mutableCopy];
}

+(NSMutableArray*)getMenubyCatagorySortedByPopularity:(NSString*)filterCatagory ofMenu:(NSMutableArray*)m {
    NSMutableArray *ra = [[NSMutableArray alloc] init];
    for (int i = 0; i < m.count; i++) {
        //start search
        NSString *str = ((foodInfo*)[m objectAtIndex:i]).catagory;
        if ([str isEqualToString:filterCatagory]) {
            [ra addObject:(foodInfo*)[m objectAtIndex:i]];
        }
    }
    
    //sort by orderCount
    NSArray *resultArray = [ra sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int n1 = [[[((foodInfo*)obj1).addition componentsSeparatedByString:@":"] objectAtIndex:0] intValue];
        int n2 = [[[((foodInfo*)obj2).addition componentsSeparatedByString:@":"] objectAtIndex:0] intValue];
        NSNumber *number1 = [NSNumber numberWithInt:n1];
        NSNumber *number2 = [NSNumber numberWithInt:n2];
        
        NSComparisonResult result = [number1 compare:number2];
        
        return result == NSOrderedAscending;
    }];
    
    return [resultArray mutableCopy];
}

+ (BOOL)setCurrentStoreMajor:(int)major andMinor:(int)minor {
    NSString *tempStoreID = app_store_id; //[self getStoreIDForMajor:major andMinor:minor];
    return [self setCurrentStore:tempStoreID];
}

+ (BOOL)supportAiyidian {
    return support;
}

+ (BOOL)needNoTableNum {
    return NoTableNum;
}

//判断是否用户还在店内
+ (BOOL)inStore {
    return YES;
    /*
    if (lastIDUpdate == nil) {
        return NO;
    }
    if ([[NSDate date] timeIntervalSinceDate:lastIDUpdate] < LEAVE_STORE_WAIT) {
        return YES;
    }
    return NO; //fail-safe
     */
}

+ (BOOL)whiteLabel {
    return whiteLabelName;
}

+ (NSString*)getCurrentStoreID {
    if (storeID == nil || [storeID isEqualToString:@""]) {
        return nil;
    }
    return storeID;
}

+ (NSString*)getCurrentStoreName {
    return storeName;
}

+(NSString*)getCurrentStoreFolder {
    return [NSString stringWithFormat:@"images/store%@", storeID];
}

//获取店家宣传信息
+ (NSString*)getStoreNotificationByMajor:(int)major andMinor:(int)minor {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSString stringWithFormat:@"%d", major], @"major",
                         [NSString stringWithFormat:@"%d", minor], @"minor", nil];
    NSData *data = [HTTPRequest syncGet:SERVER_STORE_NOTIFICATION withData:dic];
    if (data == nil) {
        return nil;
    }
    
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([str isEqualToString:@""]) {
        str = nil;
    }
    return str;
}

+ (NSArray*)getCurrentStoreMainPage {
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:[HTTPRequest syncGet:[NSString stringWithFormat:@"%@/main.json", storeID] withData:nil] options:kNilOptions error:&error];
    if (jsonRoot == nil) {
        return nil;
    }
    NSArray *mainpageJSON = [jsonRoot objectForKey:@"mainpage"];
    return mainpageJSON;
}

+ (NSMutableArray*)getMenu {
    if (menu == nil)
        menu = [[NSMutableArray alloc] init];
    return menu;
}

+ (NSMutableArray*)getCatagories {
    NSMutableArray *ra = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self getMenu].count; i++) {
        //start search
        bool found = false;
        NSString *str = ((foodInfo*)[menu objectAtIndex:i]).catagory;
        for (int j = 0; j < ra.count; j++) {
            if ([((NSString*)[ra objectAtIndex:j]) isEqualToString:str]) {
                found = true;
                break;
            }
        }
        if (!found) {
            [ra addObject:str];
        }
    }
    return ra;
}

+ (NSMutableArray*)getMenuSortedByCatagoriesAndName {
    NSMutableArray *r = [[NSMutableArray alloc] init];
    NSMutableArray *catas = [self getCatagories];
    for (NSString *cata in catas) {
        [r addObject:[self getMenubyCatagorySortedByName:cata]];
    }
    return r;
}

+ (NSMutableArray*)getMenuSortedByCatagoriesAndPopularity {
    NSMutableArray *r = [[NSMutableArray alloc] init];
    NSMutableArray *catas = [self getCatagories];
    for (NSString *cata in catas) {
        [r addObject:[self getMenubyCatagorySortedByPopularity:cata]];
    }
    return r;
}

+ (NSMutableArray*)getMenuSortedByCatagoriesAndDefault {
    NSMutableArray *r = [[NSMutableArray alloc] init];
    NSMutableArray *catas = [self getCatagories];
    for (NSString *cata in catas) {
        [r addObject:[self getMenubyCatagory:cata]];
    }
    return r;
}

+ (NSMutableArray*)getMenubyCatagorySortedByName:(NSString*)filterCatagory {
    NSMutableArray *ra = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self getMenu].count; i++) {
        //start search
        NSString *str = ((foodInfo*)[menu objectAtIndex:i]).catagory;
        if ([str isEqualToString:filterCatagory]) {
            [ra addObject:(foodInfo*)[menu objectAtIndex:i]];
        }
    }
    
    //sort by orderCount
    NSArray *resultArray = [ra sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSComparisonResult result = [((foodInfo*)obj1).title compare:((foodInfo*)obj2).title];
        return result == NSOrderedAscending;
    }];
    
    return [resultArray mutableCopy];
}

+ (NSMutableArray*)getMenubyCatagorySortedByPopularity:(NSString*)filterCatagory {
    NSMutableArray *ra = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self getMenu].count; i++) {
        //start search
        NSString *str = ((foodInfo*)[menu objectAtIndex:i]).catagory;
        if ([str isEqualToString:filterCatagory]) {
            [ra addObject:(foodInfo*)[menu objectAtIndex:i]];
        }
    }
    
    //sort by orderCount
    NSArray *resultArray = [ra sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int n1 = [[[((foodInfo*)obj1).addition componentsSeparatedByString:@":"] objectAtIndex:0] intValue];
        int n2 = [[[((foodInfo*)obj2).addition componentsSeparatedByString:@":"] objectAtIndex:0] intValue];
        NSNumber *number1 = [NSNumber numberWithInt:n1];
        NSNumber *number2 = [NSNumber numberWithInt:n2];
        
        NSComparisonResult result = [number1 compare:number2];
        
        return result == NSOrderedAscending;
    }];
    
    return [resultArray mutableCopy];
}

+ (NSMutableArray*)getMenubyCatagory:(NSString*)filterCatagory { //sorted by default
    NSMutableArray *ra = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self getMenu].count; i++) {
        //start search
        NSString *str = ((foodInfo*)[menu objectAtIndex:i]).catagory;
        if ([str isEqualToString:filterCatagory]) {
            [ra addObject:(foodInfo*)[menu objectAtIndex:i]];
        }
    }
    
    return ra;
}

+ (int)getFoodIDForFoodName:(NSString*)name {
    for (foodInfo *f in [self getMenu]) {
        if ([f.title isEqualToString:name]) {
            return [f getID];
        }
    }
    return -1; //not found
}

+ (NSString*)getFoodNameForFoodID:(int)ID {
    int index = [store getIndexForFoodID:ID];
    if (index == -1) {
        return nil;
    }
    return ((foodInfo*)[[self getMenu] objectAtIndex:index]).title;
}

+ (void)beginLoading {
    NSLog(@"loading in class store");
    BEGIN_LOADING
}

+ (void)endLoading {
    END_LOADING
}

+ (NSString*)submitOrder {
    if (currentID == nil || [currentID isEqualToString:@""]) {
        [HTTPRequest alert:@"您还没有登录，请登录后再下单"];
        return nil;
    }
    USER_BEGIN_LOADGING
    NSString *JSONString = [NSString stringWithFormat:@"{\"id\":\"%@\",\"platform\":\"%@\",\"customer\":\"%@\",\"table\":\"%d\",\"total\":\"%.2f\",\"credit\":\"%d\",\"order\":[", [store getCurrentStoreID], APP_PLATFORM, currentID, tableNum, [orderInfo getTotalValue], [orderInfo getTotalCredit]];
    BOOL first = YES;
    for (orderInfo* item in order) {
        if (first) {
            first = NO;
        } else {
            JSONString = [JSONString stringByAppendingString:@","];
        }
        JSONString = [JSONString stringByAppendingString:
                      [NSString stringWithFormat:@"{\"dishID\":\"%d\",\"quantity\":\"%d\"}", [item getID], [item getCount]]];
    }
    JSONString = [JSONString stringByAppendingString:@"]}"];
    NSData *JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *feedback = [HTTPRequest stringFromData:[HTTPRequest syncPost:SERVER_STORE_PUT_ORDER withRawData:JSONData]];
    if (feedback == nil || [feedback isEqualToString:@""]) {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return nil;
    } else if (feedback.length > 3 && [[feedback substringToIndex:2] isEqualToString:@"OK"]) {
        USER_END_LOADGING
        return [feedback substringFromIndex:3];
    }
    USER_END_LOADGING
    [HTTPRequest alert:[NSString stringWithFormat:@"下单失败：%@", feedback]];
    return nil;
}

+ (NSString*)submitPreorder:(int)type withNumPeople:(int)numPeople atDate:(NSString*)date andTime:(NSString*)time {
    if (currentID == nil || [currentID isEqualToString:@""]) {
        [HTTPRequest alert:@"您还没有登录，请登录后再下单"];
        return nil;
    }
    USER_BEGIN_LOADGING
    NSString *JSONString = [NSString stringWithFormat:@"{\"id\":\"%@\",\"platform\":\"%@\",\"customer\":\"%@\",\"numPeople\":\"%d\",\"type\":\"%d\",\"date\":\"%@\",\"time\":\"%@\",\"total\":\"%.2f\",\"credit\":\"%d\",\"order\":[", [store getCurrentStoreID], APP_PLATFORM, currentID, numPeople, type, date, time, [orderInfo getTotalValue], [orderInfo getTotalCredit]];
    BOOL first = YES;
    for (orderInfo* item in order) {
        if (first) {
            first = NO;
        } else {
            JSONString = [JSONString stringByAppendingString:@","];
        }
        JSONString = [JSONString stringByAppendingString:
                      [NSString stringWithFormat:@"{\"dishID\":\"%d\",\"quantity\":\"%d\"}", [item getID], [item getCount]]];
    }
    JSONString = [JSONString stringByAppendingString:@"]}"];
    NSData *JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *feedback = [HTTPRequest stringFromData:[HTTPRequest syncPost:SERVER_STORE_PREORDER withRawData:JSONData]];
    if (feedback == nil || [feedback isEqualToString:@""]) {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return nil;
    } else if (feedback.length > 3 && [[feedback substringToIndex:2] isEqualToString:@"OK"]) {
        USER_END_LOADGING
        return [feedback substringFromIndex:3];
    }
    USER_END_LOADGING
    [HTTPRequest alert:[NSString stringWithFormat:@"下单失败：%@", feedback]];
    return nil;
}

+ (void)callService:(int)type {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:storeID, @"storeID", [NSString stringWithFormat:@"%d", tableNum], @"tableID", [NSString stringWithFormat:@"%d", type], @"type", nil];
    NSString *str = [[NSString alloc] initWithData:[HTTPRequest syncGet:SERVER_GET_SERVICE withData:dic] encoding:NSUTF8StringEncoding];
    if (str == nil || [str isEqualToString:@""]) {
        [HTTPRequest alert:NETWORK_ERROR];
    } else if ([str isEqualToString:@"ERROR"]) {
        [HTTPRequest alert:@"服务员稍后就来，请耐心等待"];
    } else if ([str isEqualToString:@"OK"]) {
        [HTTPRequest alert:@"服务员稍后就来，请耐心等待"];
    } else {
        [HTTPRequest alert:@"服务器错误"];
    }
}

+ (int)getIndexForFoodID:(int)theFoodID {
    for (int i = 0; i < [store getMenu].count; i++) {
        foodInfo *f = [[store getMenu] objectAtIndex:i];
        if ([f getID] == theFoodID) {
            return i;
        }
    }
    return -1; //not found
}

+ (int)getIndexForFoodID:(int)theFoodID inMenu:(NSMutableArray*)m {
    for (int i = 0; i < m.count; i++) {
        foodInfo *f = [m objectAtIndex:i];
        if ([f getID] == theFoodID) {
            return i;
        }
    }
    return -1; //not found
}

+ (void)openStoreWifi {
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/images/store%@/wifi.mobileconfig", SERVER_ADDRESS, storeID]];
    [[UIApplication sharedApplication] openURL:url];
}

+ (BOOL)needStoreWifi {
    Reachability* wifiReach = [Reachability reachabilityForInternetConnection];
    NetworkStatus netStatus = [wifiReach currentReachabilityStatus];
    //ReachableViaWWAN == 3G, ReachableViaWiFi == WIFI, store provides wifi
    if (netStatus != ReachableViaWiFi && wifi) {
        return YES;
    }
    return NO;
}

+ (NSMutableArray*)getCafeWall {
    NSString *uid = [user getCurrentID];
    if (uid == nil) {
        return nil;
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:uid, @"username",
                                [store getCurrentStoreID], @"storeID", nil];
    
    NSData *recvData = [HTTPRequest syncGet:SERVER_CAFE_WALL withData:dic];
    if (recvData == nil) {
        return nil;
    }
    if ([[HTTPRequest stringFromData:recvData] length] >= 5 && [[[HTTPRequest stringFromData:recvData] substringToIndex:5] isEqualToString:@"ERROR"]) {
        [HTTPRequest alert:[HTTPRequest stringFromData:recvData]];
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    gotUserinfo = YES;
    if ([jsonRoot objectForKey:@"userinfo"] == [NSNull null] || [[jsonRoot objectForKey:@"userinfo"] count] == 0) {
        userinfo = nil;
        return nil;
    }
    userinfo = [[jsonRoot objectForKey:@"userinfo"] objectAtIndex:0];
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return [listInJSON mutableCopy];
}

+ (BOOL)getCafeWallCoffee:(NSInteger)pid {
    NSString *uid = [user getCurrentID];
    if (uid == nil) {
        [HTTPRequest alert:@"您需要先登录"];
        return NO;
    }
    
    USER_BEGIN_LOADGING
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:uid, @"username",
                                [store getCurrentStoreID], @"storeID",
                                [NSString stringWithFormat:@"%d", pid], @"postID", nil];
    
    NSData *recvData = [HTTPRequest syncGet:SERVER_CAFE_WALL_GET withData:dic];
    if (recvData == nil) {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return NO;
    }
    if ([HTTPRequest stringFromData:recvData] == nil || [[HTTPRequest stringFromData:recvData] isEqualToString:@""]) {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return NO;
    }
    if ([[HTTPRequest stringFromData:recvData] length] >= 15 && [[[HTTPRequest stringFromData:recvData] substringToIndex:5] isEqualToString:@"ERROR_NOT_FOUND"]) {
        USER_END_LOADGING
        [HTTPRequest alert:@"对不起哦~这个留言可能刚刚被人领取\n看看其他的留言吧"];
        return NO;
    }
    if ([[HTTPRequest stringFromData:recvData] length] >= 5 && [[[HTTPRequest stringFromData:recvData] substringToIndex:5] isEqualToString:@"ERROR"]) {
        USER_END_LOADGING
        [HTTPRequest alert:[HTTPRequest stringFromData:recvData]];
        return NO;
    }
    if ([[HTTPRequest stringFromData:recvData] length] >= 2 && [[[HTTPRequest stringFromData:recvData] substringToIndex:2] isEqualToString:@"OK"]) {
        USER_END_LOADGING
        return YES;
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return NO;
}

+ (NSInteger)submitCafeWallOrder:(NSInteger)foodID withMessage:(NSString*)msg lowerAge:(NSInteger)lower upperAge:(NSInteger)upper gender:(int)gender {
    NSString *uid = [user getCurrentID];
    if (uid == nil) {
        [HTTPRequest alert:@"您需要先登录"];
        return -1;
    }
    
    USER_BEGIN_LOADGING
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:uid, @"username",
                                [store getCurrentStoreID], @"storeID",
                                [NSString stringWithFormat:@"%d", foodID], @"foodID",
                                [NSString stringWithFormat:@"%d", lower], @"lowerAge",
                                [NSString stringWithFormat:@"%d", upper], @"upperAge",
                                [NSString stringWithFormat:@"%d", gender], @"gender",
                                msg, @"message", nil];
    
    NSData *recvData = [HTTPRequest syncGet:SERVER_CAFE_WALL_SUBMIT withData:dic];
    if (recvData == nil) {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return -1;
    }
    if ([HTTPRequest stringFromData:recvData] == nil || [[HTTPRequest stringFromData:recvData] isEqualToString:@""]) {
        USER_END_LOADGING
        [HTTPRequest alert:NETWORK_ERROR];
        return -1;
    }
    if ([[HTTPRequest stringFromData:recvData] length] >= 5 && [[[HTTPRequest stringFromData:recvData] substringToIndex:5] isEqualToString:@"ERROR"]) {
        USER_END_LOADGING
        [HTTPRequest alert:[HTTPRequest stringFromData:recvData]];
        return -1;
    }
    if ([[HTTPRequest stringFromData:recvData] length] >= 2 && [[[HTTPRequest stringFromData:recvData] substringToIndex:2] isEqualToString:@"OK"]) {
        USER_END_LOADGING
        return [[[HTTPRequest stringFromData:recvData] substringFromIndex:3] integerValue];
    }
    USER_END_LOADGING
    [HTTPRequest alert:NETWORK_ERROR];
    return -1;
}

@end



@implementation foodInfo

-(foodInfo*)initWithName:(NSString *)name andPrice:(float)p image:(NSString *)image catagory:(NSString *)cata desp:(NSString *)desp1 desp2:(NSString *)desp2 desp3:(NSString *)desp3 withId:(int)newID {
    price = p;
    ID = newID;
    self.catagory = cata;
    self.title = name;
    self.image = image;
    self.mainDescription = desp1;
    self.note = desp2;
    self.addition = desp3;
    return self;
}

-(float)getPrice {
    return price;
}

-(int)getID {
    return ID;
}

-(void)setID:(int)newID {
    ID = newID;
}

@end

@implementation orderInfo

//load
+ (NSMutableArray*)getOrder {
    if (order == nil) {
        order = [[NSMutableArray alloc] init];
    }
    return order;
}

//save
+ (void)saveOrder {
    if (order != nil) {
        if (![db lock]) {
            NSLog(@"LOCK FAILED");
            return;
        }
        
        if (![db isRunning])
            return;
        //detele original data
        if (![db deleteFromTable:@"orders" withKeysAndValues:[NSDictionary dictionaryWithObjectsAndKeys:storeID, @"store", nil]]) {
            NSLog(@"DELETE FAILED");
            if (![db rollback])
                NSLog(@"ROLLBACK FAILED");
            return;
        }
        
        BOOL insertOK = YES;
        for (int i = 0; i < [self getOrder].count; i++) {
            int dishID = [((orderInfo*)[[self getOrder] objectAtIndex:i]) getID];
            int quantity = [((orderInfo*)[[self getOrder] objectAtIndex:i]) getCount];
            if (![db insertToTable:@"orders" withValues:[NSArray arrayWithObjects:SQL_NULL_STRING,
                                                         storeID,
                                                         storeName,
                                                         [NSString stringWithFormat:@"%d", dishID],
                                                         ((foodInfo*)[[store getMenu] objectAtIndex:[store getIndexForFoodID:dishID]]).title,
                                                         [NSString stringWithFormat:@"%d", quantity],
                                                         [NSString stringWithFormat:@"%.2f", [(foodInfo*)[[store getMenu] objectAtIndex:[store getIndexForFoodID:dishID]] getPrice]], nil]]) {
                NSLog(@"INSERT FAILED");
                insertOK = NO;
                if (![db rollback])
                    NSLog(@"ROLLBACK FAILED");
                break;
            }
                  
        }
        if (insertOK && ![db commit])
            NSLog(@"COMMIT FAILED");
    }
}

+ (int)getCountForFood:(int)foodID {
    for (int i = 0; i < [self getOrder].count; i++) {
        if ([((orderInfo*)[[self getOrder] objectAtIndex:i]) getID] == foodID) {
            return [((orderInfo*)[[self getOrder] objectAtIndex:i]) getCount];
        }
    }
    return 0;
}

+(int)addFood:(int)foodID withCount:(int)count {
    for (int i = 0; i < [self getOrder].count; i++) {
        if ([((orderInfo*)[[self getOrder] objectAtIndex:i]) getID] == foodID) {
            int c = [((orderInfo*)[[self getOrder] objectAtIndex:i]) getCount];
            c += count;
            [((orderInfo*)[[self getOrder] objectAtIndex:i]) setCount:c];
            return c;
        }
    }
    
    //not found
    orderInfo *o = [[orderInfo alloc] initWithID:foodID andCount:count];
    
    [[self getOrder] addObject:o];
    return count;
}

+(int)removeFood:(int)foodID withCount:(int)count {
    for (int i = 0; i < [self getOrder].count; i++) {
        if ([((orderInfo*)[[self getOrder] objectAtIndex:i]) getID] == foodID) {
            int c = [((orderInfo*)[[self getOrder] objectAtIndex:i]) getCount];
            c -= count;
            if (c <= 0) {
                c = 0;
                [[self getOrder] removeObjectAtIndex:i];
            } else {
                [((orderInfo*)[[self getOrder] objectAtIndex:i]) setCount:c];
            }
            return c;
        }
    }
    return 0;
}

+ (void)checkOrder {
    for (int i = 0; i < order.count; i++) {
        int this_id = [((orderInfo*)[order objectAtIndex:i]) getID];
        int indexForID = [store getIndexForFoodID:this_id];
        if (indexForID == -1) {
            [orderInfo removeFood:this_id withCount:[((orderInfo*)[order objectAtIndex:i]) getCount]];
            i--;
        }
    }
}

+ (float)getTotalValue {
    float this_value = 0.0;
    NSMutableArray *orderArray = [orderInfo getOrder];
    if (orderArray == nil) {
        return 0.0;
    }
    for (int i = 0; i < orderArray.count; i++) {
        int this_id = [((orderInfo*)[orderArray objectAtIndex:i]) getID];
        int indexForID = [store getIndexForFoodID:this_id];
        if (indexForID == -1) {
            continue;
        }
        this_value += [((orderInfo*)[orderArray objectAtIndex:i]) getCount] * [((foodInfo*)[[store getMenu] objectAtIndex:indexForID]) getPrice];
    }
    return this_value;
}

+ (int)getTotalCredit {
    int this_value = 0;
    NSMutableArray *orderArray = [orderInfo getOrder];
    if (orderArray == nil) {
        return 0;
    }
    for (int i = 0; i < orderArray.count; i++) {
        int this_id = [((orderInfo*)[orderArray objectAtIndex:i]) getID];
        int indexForID = [store getIndexForFoodID:this_id];
        if (indexForID == -1) {
            continue;
        }
        this_value += [((orderInfo*)[orderArray objectAtIndex:i]) getCount] * ((foodInfo*)[[store getMenu] objectAtIndex:indexForID]).scoreToEarn;
    }
    return this_value;
}

+ (float)getPayTotalOnline {
    if (currentID == nil || [currentID isEqualToString:@""]) {
        return -2;
    }
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentID, @"customerID", [store getCurrentStoreID], @"storeID", nil];
    NSString *valueStr = [HTTPRequest stringFromData:[HTTPRequest syncGet:SERVER_GET_SHOULD_PAY withData:dic]];
    if (valueStr == nil || [valueStr isEqualToString:@""]) {
        return -1;
    }
    float total = [valueStr floatValue];
    return total;
}

- (orderInfo*)initWithID:(int)foodID andCount:(int)count {
    ID = foodID;
    orderCount = count;
    return self;
}

- (int)getID {
    return ID;
}
- (void)setID:(int)newID {
    ID = newID;
}
- (int)getCount {
    return orderCount;
}
- (void)setCount:(int)newCount {
    orderCount = newCount;
}

+ (NSString*)statusStringForPayed:(int)payFlag andOrderFlag:(int)orderFlag andFetchFlag:(int)fetchFlag {
    NSMutableString *statusStr = [[NSMutableString alloc]initWithString:@""];
    if (orderFlag == 3) {
        [statusStr appendString:@"已撤单"];
    } else if (orderFlag == 2) {
        [statusStr appendString:@"已结单"];
    } else if (orderFlag == 1) {
        [statusStr appendString:@"已出单"];
    } else if (fetchFlag == 1) { //orderFlag = 0
        [statusStr appendString:@"接收未出单"];
    } else {
        [statusStr appendString:@"未接收"];
    }
    
    if (payFlag == 1) {
        [statusStr appendString:@" 已付款"];
    } else {
        [statusStr appendString:@" 未付款"];
    }
    
    return statusStr;
}

@end
