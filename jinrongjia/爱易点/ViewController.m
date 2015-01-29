//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "ViewController.h"
#import "data.h"

@interface ViewController ()

@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (atomic, strong) NSArray *beaconsArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.beaconManager = [[ESTBeaconManager alloc] init];
    
    self.beaconManager.delegate = self;
    self.region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID identifier:@"UnicafeRegionBackgound"];
    
    self.region.notifyOnEntry = YES;
    self.region.notifyOnExit = YES;
    self.region.notifyEntryStateOnDisplay = YES;
    
    [self.beaconManager stopMonitoringForRegion:self.region];
}

- (void)beaconManager:(ESTBeaconManager *)manager didEnterRegion:(ESTBeaconRegion *)region
{
    NSLog(@"enter");
    [self.beaconManager stopRangingBeaconsInRegion:self.region];
    [self.beaconManager startRangingBeaconsInRegion:self.region];
}

- (void)beaconManager:(ESTBeaconManager *)manager didExitRegion:(ESTBeaconRegion *)region
{
    [self.beaconManager stopRangingBeaconsInRegion:self.region];
    [self.beaconManager startRangingBeaconsInRegion:self.region];
}

- (void)onLocateBeacons:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region {
    [self.beaconManager stopRangingBeaconsInRegion:self.region];
    
    if (beacons == nil || beacons.count == 0)
        return;
    
    int major = ((ESTBeacon*)[beacons objectAtIndex:0]).major.intValue;
    int minor = ((ESTBeacon*)[beacons objectAtIndex:0]).minor.intValue;
    //float distance = ((ESTBeacon*)[beacons objectAtIndex:0]).distance.floatValue;
    
    NSString *notificationInfo = [store getStoreNotificationByMajor:major andMinor:minor];
    
    if (notificationInfo == nil || [notificationInfo isEqualToString:@""])
        return;
    
    NSString *lastFound = [[NSString alloc]initWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"background_storeid"] encoding:NSUTF8StringEncoding];
    if (lastFound == nil)
        lastFound = @"";
    
    if (![notificationInfo isEqualToString:lastFound]) {
        //save notification to prevent duplicated notifications
        NSData *thisFoundData = [notificationInfo dataUsingEncoding:NSUTF8StringEncoding];
        [[NSUserDefaults standardUserDefaults] setObject:thisFoundData forKey:@"background_storeid"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        //show notification
        UILocalNotification *notification = [UILocalNotification new];
        notification.alertBody = notificationInfo;
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

- (void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region
{
    [self onLocateBeacons:manager didRangeBeacons:beacons inRegion:region];
}

- (void)beaconManager:(ESTBeaconManager *)manager didDiscoverBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region
{
    [self onLocateBeacons:manager didRangeBeacons:beacons inRegion:region];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
