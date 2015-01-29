//
//  AppDelegate.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "data.h"
#import "storeList.h"
#import "WXApi.h"

/*
#import "ESTBeacon.h"
#import "ESTBeaconManager.h"
 */

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
//@property (strong, nonatomic) ESTBeaconManager *myBeaconManager;

+(void)setStoreListController:(UIViewController*)slc;
+(UIViewController*)getStoreListController;

+(void)setPayingModule:(int)module;
+(void)donePayingModuleWithSuccess:(BOOL)success;

+(void)setCurrentPaymentID:(NSInteger)pid;

@end

