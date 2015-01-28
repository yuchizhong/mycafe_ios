//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomIOS7AlertView.h"

#import "ESTBeacon.h"
#import "ESTBeaconManager.h"

/*
 * test settings moved to config.h
 */

typedef enum : int
{
    ESTScanTypeBluetooth,
    ESTScanTypeBeacon
    
} ESTScanType;

@interface recommend : UIViewController<UIScrollViewDelegate, ESTBeaconManagerDelegate, UIAlertViewDelegate> {
    int scrollviewID;
    BOOL beaconLocated;
}

@property (strong, nonatomic) IBOutlet UIScrollView *mainView;

- (void)reloadStoreForMajor:(int)major andMinor:(int)minor;

@end

static BOOL storeChanged = NO;