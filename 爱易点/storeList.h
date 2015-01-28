//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "areaPicker.h"
#import "data.h"
#import "singleItem.h"
#import "foodList.h"
#import "cart.h"
#import "cafewall.h"
#import "AppDelegate.h"
#import "MJRefresh.h"

#import "ESTBeacon.h"
#import "ESTBeaconManager.h"

@interface storeList : UIViewController<UITableViewDelegate, UITableViewDataSource, /*UIPickerViewDelegate, UIPickerViewDataSource, BMKPoiSearchDelegate, BMKLocationServiceDelegate,*/ ESTBeaconManagerDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, DOPDropDownMenuDataSource, DOPDropDownMenuDelegate>

@property (strong, atomic) IBOutlet UITableView *storeTable;
@property (strong, nonatomic) IBOutlet areaPicker *pickerView;
@property (strong, atomic) IBOutlet UIPickerView *areaPickerRoll;

@property (atomic) BOOL needReloadStoreList;
@property (atomic) BOOL showOnlyCollected;

@property (strong, atomic) NSMutableArray *filterOptionList;
@property (strong, atomic) NSMutableArray *selectedFilterOptions;

//for special use
@property (strong, atomic) NSString *mall;

//-(void)pickerDone;
-(void)getOutStore;

+(any_store*)getDetails;
+(UIImage*)getStarImage;
+(UIImage*)getStarImageHalfed;

+(void)registerMenuView:(foodList*)menuView;
+(void)registerOrderView:(cart*)orderView;
+(void)registerCafeWallView:(UIViewController*)wallView;
+(void)refreshMenuAndOrder;
+(void)kickOrderToMenu;

+(singleItem*)getItemDetailVC;

+(double)getCurrentLongitude;
+(double)getCurrentLatitude;

@end

