//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "storeList.h"
#import "creditMallList.h"
#import "rootTabViewController.h"

/*
static NSArray *allProvinces = nil;
static NSMutableArray *allCities = nil;
static NSMutableArray *allDistrcits = nil;
 */

#define USER_BEGIN_LOADGING [NSThread detachNewThreadSelector:@selector(beginLoading) toTarget:self withObject:nil];
#define USER_END_LOADGING [NSThread detachNewThreadSelector:@selector(endLoading) toTarget:self withObject:nil];
#define USER_BEGIN_LOADGING_FULL [NSThread detachNewThreadSelector:@selector(beginLoadingFull) toTarget:self withObject:nil];
#define USER_END_LOADGING_FULL [NSThread detachNewThreadSelector:@selector(endLoadingFull) toTarget:self withObject:nil];

static BOOL doneLaunch = NO;
static CGSize shadowOffset;
static BOOL firstLaunch = NO;

//pass values to storeDetails
static any_store *passDetails = nil;
static BOOL beaconLocated;

static double longitude = 0.0;
static double latitude = 0.0;

static NSArray *allareas = nil;

static NSMutableArray *stores = nil;
static NSString *currentProvince = @"附近";
static NSString *currentCity = @"附近";
static NSString *currentDistrict = @"1000米";
static NSString *currentArea = @"";
static NSString *notificationText = @"加载中...";

static int cellID = 0;
static int numRowsToShow = NUM_STORE_ROWS_PER_PAGE;

static UIImage *starImage = nil;
static UIImage *starImageHalf = nil;

static foodList *myMenu = nil;
static cart *myOrder = nil;
static cafeWall *myWall = nil;

static singleItem *itemDetailViewController = nil;

@interface storeList ()

@property (atomic) NSInteger usingThreads;
@property (atomic) NSInteger usingThreadsStore;
@property (atomic) NSInteger usingThreadsCheck;
@property (atomic) NSInteger doneLoading;
@property (atomic) BOOL justLaunched;

@property (strong, atomic) UIViewController *storeView;

@property (atomic, strong) CLLocationManager *locationManager;

@property (atomic, strong) NSDate *storeListLastUpdate;
@property (atomic, strong) NSDate *lastPromoteWifi;

@end

@implementation storeList

@synthesize mainPage;

+ (double)getCurrentLongitude {
    return longitude;
}

+ (double)getCurrentLatitude {
    return latitude;
}

+ (singleItem*)getItemDetailVC {
    return itemDetailViewController;
}

+ (void)registerMenuView:(foodList*)menuView {
    myMenu = menuView;
}

+ (void)registerOrderView:(cart*)orderView {
    myOrder = orderView;
}

+ (void)registerCafeWallView:(UIViewController*)wallView {
    myWall = (cafeWall*)wallView;
}

+ (any_store*)getDetails {
    return passDetails;
}

+ (UIImage*)getStarImage {
    if (starImage == nil)
        starImage = [UIImage imageNamed:@"star.png"];
    return starImage;
}

+ (UIImage*)getStarImageHalfed {
    if (starImageHalf == nil)
        starImageHalf = [UIImage imageNamed:@"star_half.png"];
    return starImageHalf;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == -1) {
        //jump to app store
        NSString *str = @"https://itunes.apple.com/us/app/jin-rong-jia-ka-fei/id962789847?ls=1&mt=8";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
    } else if (alertView.tag == 101 && buttonIndex == 1) {
        [store openStoreWifi];
    }
}

- (void)beginLoading {
    BEGIN_LOADING
}

- (void)endLoading {
    END_LOADING
}

- (void)beginLoadingFull {
    BEGIN_LOADING
}

- (void)endLoadingFull {
    END_LOADING
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //count launch
    NSInteger launchTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"launchCount"];
    launchTime++;
    [[NSUserDefaults standardUserDefaults] setInteger:launchTime forKey:@"launchCount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //show instructions at first launch
    /*
    if (launchTime == 1) {
        firstLaunch = YES;
        UIViewController *launchInstructions = [self.storyboard instantiateViewControllerWithIdentifier:@"launchInstructions"];
        [self presentViewController:launchInstructions animated:NO completion:nil];
    }
     */
    
    SET_NAVBAR
    
    [self.pickerView setHidden:YES];
    
    self.needReloadStoreList = NO;
    
    shadowOffset = CGSizeMake(0, 0);
    self.justLaunched = YES;
    // Do any additional setup after loading the view, typically from a nib.
    
    itemDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"itemDetails"];
    
    [self.view setBackgroundColor:COFFEE_LIGHT];
    
    self.storeView = nil;
    beaconLocated = NO;
    self.usingThreads = 0;
    self.usingThreadsStore = 0;
    self.usingThreadsCheck = 0;
    
    self.filterOptionList = [INIT_FILTER_COLUMNS mutableCopy];
    self.selectedFilterOptions = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.filterOptionList count]; i++) {
        [self.selectedFilterOptions setObject:[[self.filterOptionList objectAtIndex:i] objectAtIndex:0] atIndexedSubscript:i];
    }
    
    [self.storeTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.storeTable setBackgroundColor:COFFEE_LIGHT];
    
    [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:NO];
    //[[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:NO];
    
    [AppDelegate setStoreListController:self];
    [rootTabViewController setStoreListNavController:self.navigationController];
    
    /*
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"附近" style:UIBarButtonItemStylePlain target:self action:@selector(showPicker)];
    [leftButton setTintColor:[UIColor redColor]];
    [self.navigationItem setLeftBarButtonItem:leftButton];
    
    [self.pickerView setParentViewController:self];
    
    allareas = [any_store getAllAreas];
    stores = [[NSMutableArray alloc] init];
    
    BMKLocationService *locService = [[BMKLocationService alloc] init];
    locService.delegate = self;
    [locService startUserLocationService];
    
    [self.areaPickerRoll selectRow:0 inComponent:0 animated:NO];
    [self.areaPickerRoll selectRow:0 inComponent:1 animated:NO];
    [self.areaPickerRoll selectRow:2 inComponent:2 animated:NO];
    
    [self pickerDone];
     */
    
    //toolbar
    if (SHOW_FILTER_OPTIONS) {
        DOPDropDownMenu *menu = [[DOPDropDownMenu alloc] initWithOrigin:CGPointMake(0, 0) andHeight:38];
        menu.dataSource = self;
        menu.delegate = self;
        [self.view addSubview:menu];
    }
}

- (NSInteger)numberOfColumnsInMenu:(DOPDropDownMenu *)menu {
    return [self.filterOptionList count];
}

- (NSInteger)menu:(DOPDropDownMenu *)menu numberOfRowsInColumn:(NSInteger)column {
    return [[self.filterOptionList objectAtIndex:column] count];
}

- (NSString *)menu:(DOPDropDownMenu *)menu titleForRowAtIndexPath:(DOPIndexPath *)indexPath {
    return [[self.filterOptionList objectAtIndex:indexPath.column] objectAtIndex:indexPath.row];
}

- (void)menu:(DOPDropDownMenu *)menu didSelectRowAtIndexPath:(DOPIndexPath *)indexPath {
    NSString *option = [[self.filterOptionList objectAtIndex:indexPath.column] objectAtIndex:indexPath.row];
    [self.selectedFilterOptions setObject:option atIndexedSubscript:indexPath.column];
    [self.storeTable headerBeginRefreshing];
}

- (void)loadStores {
    GLOBAL_LOCK
    if (self.usingThreads > 0 || [[NSDate date] timeIntervalSinceDate:self.storeListLastUpdate] < 0.5) {
        if (self.usingThreads == 0) {
            [self.storeTable headerEndRefreshing];
            [self.storeTable footerEndRefreshing];
        }
        GLOBAL_UNLOCK
        return;
    }
    //not this view, skip
    if (self.tabBarController.selectedIndex != 0 && self.tabBarController.selectedIndex != 4) {
        [self.storeTable headerEndRefreshing];
        [self.storeTable footerEndRefreshing];
        GLOBAL_UNLOCK
        return;
    }
    self.usingThreads++;
    GLOBAL_UNLOCK
    //NSLog(@"storelist_loadstorelist");
    //USER_BEGIN_LOADGING
    BOOL load_ok = NO;
    int retry = 0;
    while (!load_ok && retry < 3 /* stores == nil || stores.count == 0*/) {
        stores = [any_store getStoresInProvince:@"全部" andCity:@"全部" andDistrict:@"全部" andLo:longitude andLa:latitude haveMall:self.mall numRecords:numRowsToShow onlyCollected:self.showOnlyCollected options:self.selectedFilterOptions];
        if (stores == nil) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
            retry++;
        } else {
            load_ok = YES;
        }
    }
    GLOBAL_LOCK
    self.usingThreads--;
    self.storeListLastUpdate = [NSDate date];
    GLOBAL_UNLOCK
    //USER_END_LOADGING
    if (retry < 3)
        [self.storeTable reloadData];
    else
        [HTTPRequest alert:NETWORK_ERROR];
    [self.storeTable headerEndRefreshing];
    [self.storeTable footerEndRefreshing];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *loc = [locations objectAtIndex:0];
    longitude = loc.coordinate.longitude;
    latitude = loc.coordinate.latitude;
    //[NSThread detachNewThreadSelector:@selector(loadStores) toTarget:self withObject:nil];
    
    [self.storeTable headerBeginRefreshing];
}

- (void)goStart {
    [self reloadCartBadge];
    
    self.storeListLastUpdate = [NSDate distantPast];
    self.lastPromoteWifi = [NSDate distantPast];
    
    /*
    [self.storeTable addHeaderWithTarget:self action:@selector(loadStoresAsyncBridge) dateKey:@"tableStore"];
    [self.storeTable addFooterWithTarget:self action:@selector(loadMoreStoresAsyncBridge)];
    self.locationManager = [[CLLocationManager alloc]init];
    if (![CLLocationManager locationServicesEnabled]) {
        longitude = 0.0;
        latitude = 0.0;
        //[NSThread detachNewThreadSelector:@selector(loadStores) toTarget:self withObject:nil];
        [self.storeTable headerBeginRefreshing];
    }
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locationManager.distanceFilter = 50.0;
    [self.locationManager startUpdatingLocation];
    
    notificationText = @"加载中...";
    [self.storeTable reloadData];
     */
     
    doneLaunch = YES;
    
    //load store menu
    [NSThread detachNewThreadSelector:@selector(loadPageAsync) toTarget:self withObject:nil];
}

- (void)loadStoresAsyncBridge {
    numRowsToShow = NUM_STORE_ROWS_PER_PAGE;
    [NSThread detachNewThreadSelector:@selector(loadStores) toTarget:self withObject:nil];
}

- (void)loadMoreStoresAsyncBridge {
    numRowsToShow += NUM_STORE_ROWS_PER_PAGE;
    [NSThread detachNewThreadSelector:@selector(loadStores) toTarget:self withObject:nil];
}

/*
- (void)pauseLocation {
    if (self.locationManager != nil) {
        [self.locationManager stopUpdatingLocation];
        [self.beaconManager stopRangingBeaconsInRegion:self.region];
    }
}
 */

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.showOnlyCollected) {
        [self.navigationItem setTitle:@"收藏的咖啡馆"];
    } else if (self.mall == nil || [self.mall isEqualToString:@""]) {
        [self.navigationItem setTitle:@"首页"];
    } else {
        if ([self.mall isEqualToString:@"cash"]) {
            [self.navigationItem setTitle:@"商城"];
        } else {
            [self.navigationItem setTitle:[store getMallTitle:self.mall]];
        }
    }
    if (doneLaunch && self.needReloadStoreList) {
        numRowsToShow = NUM_STORE_ROWS_PER_PAGE;
        [stores removeAllObjects];
        [self.storeTable reloadData];
    }
}

- (void)loadWebPage {
    UIWebView *webview = [[UIWebView alloc] initWithFrame:mainPage.frame];
    [webview.scrollView setShowsVerticalScrollIndicator:NO];
    [webview.scrollView setShowsHorizontalScrollIndicator:NO];
    [webview.scrollView setBackgroundColor:[UIColor whiteColor]];
    [webview setScalesPageToFit:YES];
    NSURLRequest *webrequest =[NSURLRequest requestWithURL:[NSURL URLWithString:app_web_url]];
    [webview loadRequest:webrequest];
    [mainPage addSubview:webview];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //启动
    if (self.justLaunched) {
        [NSThread detachNewThreadSelector:@selector(appstart) toTarget:self withObject:nil];
        [self loadWebPage];
        self.justLaunched = NO;
    }
    
    return;
    
    //刷新
    /*
    if (doneLaunch && self.needReloadStoreList) {
        numRowsToShow = NUM_STORE_ROWS_PER_PAGE;
        [self.view layoutSubviews];
        for (int i = 0; i < [self.filterOptionList count]; i++) {
            [self.selectedFilterOptions setObject:[[self.filterOptionList objectAtIndex:i] objectAtIndex:0] atIndexedSubscript:i];
        }
        [self.storeTable headerBeginRefreshing];
    }
    self.needReloadStoreList = NO;
     */
}

- (void)appstart {
    //[NSThread detachNewThreadSelector:@selector(beginLoadingFull) toTarget:self withObject:nil];
    if (!firstLaunch)
        USER_BEGIN_LOADGING_FULL
    if (![user start]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"有必要更新" message:@"有你咖啡有必要的更新，请更新后使用" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil];
        alert.tag = -1;
        [alert show];
    }
    //[user handleNotification];
    //[NSThread detachNewThreadSelector:@selector(endLoadingFull) toTarget:self withObject:nil];
    if (!firstLaunch)
        USER_END_LOADGING_FULL
    
    //[self goStart];
    [self performSelectorOnMainThread:@selector(goStart) withObject:nil waitUntilDone:YES];
}

/*
//不显示列表页时不刷新
- (void)viewWillDisappear:(BOOL)animated {
    [self.beaconManager stopRangingBeaconsInRegion:self.region];
}
 */

- (void)reloadStoreForMajor:(int)major andMinor:(int)minor {
    //预定时不判断
    if ([store preorder_mode]) {
        return;
    }
    //self.arr = [NSArray arrayWithObjects:[NSNumber numberWithInt:major], [NSNumber numberWithInt:minor], nil];
    [NSThread detachNewThreadSelector:@selector(loadPageAsync) toTarget:self withObject:nil];
}

+ (void)refreshMenuAndOrder {
    if (myMenu != nil)
        [myMenu refresh];
    if (myOrder != nil)
        [myOrder refresh];
    if (myWall != nil)
        [myWall refresh];
}

+ (void)kickOrderToMenu {
    if (myOrder != nil)
        [myOrder.navigationController popToRootViewControllerAnimated:YES];
}

- (void)refreshMenuAndOrderLocal {
    if (myMenu != nil)
        [myMenu viewWillAppear:NO];
    if (myOrder != nil)
        [myOrder viewWillAppear:NO];
}

- (void)loadPageAsync {
    BOOL storeChangedForWifi = NO;
    GLOBAL_LOCK
    if (self.usingThreadsStore > 0) {
        GLOBAL_UNLOCK
        return;
    }
    self.usingThreadsStore++;
    GLOBAL_UNLOCK
    
    /*
    int major = [(NSNumber*)[self.arr objectAtIndex:0] intValue], minor = [(NSNumber*)[self.arr objectAtIndex:1] intValue];
    
    if ([store storeChanged:major andMinor:minor]) {
        beaconLocated = YES;
        storeChangedForWifi = YES;
    } else {
        GLOBAL_LOCK
        self.usingThreadsStore--;
        GLOBAL_UNLOCK
        return;
    }
     */
    
    //NSLog(@"storelist_loadstore");
    if (self.tabBarController.selectedIndex == 1 || self.tabBarController.selectedIndex == 2)
        USER_BEGIN_LOADGING
    
    //[[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:NO];
    //[[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:NO];
    
    self.doneLoading = 0;
    int retry = 0;
    while (self.doneLoading == 0/* && retry < 1*/) {
        //加载信息
        if (![store setCurrentStore:app_store_id]) {
            retry++;
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
            continue;
        }
        
        NSLog(@"STORE LOADING COMPLETED");
        
        self.doneLoading = 1;
        
        //done
        [self reloadCartBadge];
    }
    if (retry > 0) {
        NSLog(@"load retry: %d", retry);
    }
    
    //[self.indicatorAlert dismissWithClickedButtonIndex:0 animated:YES];
    
    [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:YES];
    //[[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:YES];
    
    //提示发现新餐厅
    /*
    UITabBarItem *baritem;
    for (UIViewController *v in self.tabBarController.viewControllers) {
        if (v.tabBarItem.tag == 1) {
            baritem = (UITabBarItem*)v.tabBarItem;
        }
    }
    [baritem setBadgeValue:@"点"];
     */
    
    GLOBAL_LOCK
    self.usingThreadsStore--;
    GLOBAL_UNLOCK
    
    //end loading whichever the page user on
    //if (self.tabBarController.selectedIndex == 1)
        USER_END_LOADGING
        
    if (storeChangedForWifi && [store needStoreWifi] && [[NSDate date] timeIntervalSinceDate:self.lastPromoteWifi] > 60) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Wi-Fi" message:@"本店提供Wi-Fi，是否设置？\n\n设置过程中，可能需要输入解锁密码" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"连接", nil];
        [alertView setTag:101];
        [alertView show];
        self.lastPromoteWifi = [NSDate date];
    }
}


- (void)alertOutOfStore {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"离店" message:@"您已离开咖啡厅" delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil];
    [alert show];
}

/*
- (void)getInStore {
    [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:YES];
    [[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:YES];
    UITabBarItem *baritem;
    for (UIViewController *v in self.tabBarController.viewControllers) {
        if (v.tabBarItem.tag == 1) {
            baritem = (UITabBarItem*)v.tabBarItem;
        }
    }
    [baritem setBadgeValue:@"点"];
    [self reloadCartBadge];
}

- (void)getOutStore {
    for (UIViewController *v in self.tabBarController.viewControllers) {
        UITabBarItem *baritem;
        if (v.tabBarItem.tag == 1) {
            baritem = (UITabBarItem*)v.tabBarItem;
            [baritem setBadgeValue:nil];
        }
    }
    if (self.tabBarController.selectedIndex == 1 || self.tabBarController.selectedIndex == 2) {
        self.tabBarController.selectedIndex = 0;
    }
    [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:NO];
    [[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:NO];
}
 */

- (void)reloadCartBadge {
    float _totalvalue = [orderInfo getTotalValue];
    if (_totalvalue == 0) {
        REFRESH_VALUE_BADGE(nil);
    } else {
        NSString *s = [NSString stringWithFormat:@"￥%.0f", _totalvalue];
        REFRESH_VALUE_BADGE(s);
    }
}

/*
- (void)showPicker {
    if (self.pickerView.hidden == YES)
        [self.pickerView setHidden:NO];
    else {
        [self.pickerView setHidden:YES];
        [self pickerDone];
    }
}
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (stores == nil)
        return 0;
    if (stores.count == 0) {
        return 1;
    }
    return stores.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UI_STORE_TABLE_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (USE_NIL_CELL_ID) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:nil];
    } else {
        NSString *TableSampleIdentifier = [NSString stringWithFormat:@"tableCellID%d", cellID];
        cellID++;
        
        cell = [tableView dequeueReusableCellWithIdentifier:
                                 TableSampleIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:TableSampleIdentifier];
        }
    }
    
    if (stores.count == 0) {
        UILabel *noActivityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_STORE_TABLE_CELL_HEIGHT)];
        [noActivityLabel setText:@"没有店家"];
        [noActivityLabel setTextAlignment:NSTextAlignmentCenter];
        [noActivityLabel setTextColor:[UIColor blackColor]];
        [noActivityLabel setFont:UI_TEXT_FONT];
        [cell addSubview:noActivityLabel];
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    }
    
    int margin = 6;
    
    //add image
    UIImageView *largeImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_STORE_TABLE_CELL_HEIGHT)];
    UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(0, UI_STORE_TABLE_CELL_HEIGHT - 3, self.view.frame.size.width, 3)];
    [loading setProgress:0.0];
    [loading setProgressViewStyle:UIProgressViewStyleDefault];
    [loading setTrackTintColor:[UIColor whiteColor]];
    [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
    [loading setTransform:CGAffineTransformMakeScale(1.0, 1.5)];
    [largeImageView addSubview:loading];
    NSString *url = [NSString stringWithFormat:@"%@/images/store%d/logoimage/%@", SERVER_ADDRESS, [((any_store*)[stores objectAtIndex:indexPath.row]) storeID], @"homelarge.png"];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [largeImageView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"homelarge.png"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        float percentage = (float)receivedSize / (float)expectedSize;
        //update loading progress bar
        [loading setProgress:percentage];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        //dismiss loading progress bar
        [loading removeFromSuperview];
    }];
    [largeImageView setContentMode:UIViewContentModeScaleAspectFill];
    UIImageView *shadowView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_STORE_TABLE_CELL_HEIGHT)];
    [shadowView setImage:[UIImage imageNamed:@"homeshadow.png"]];
    [largeImageView setClipsToBounds:YES];
    [largeImageView addSubview:shadowView];
    [cell addSubview:largeImageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, UI_STORE_TABLE_CELL_HEIGHT - 44, self.view.frame.size.width - 120, 20)];
    [titleLabel setText:((any_store*)[stores objectAtIndex:indexPath.row]).title];
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [titleLabel setShadowColor:[UIColor blackColor]];
    [titleLabel setShadowOffset:shadowOffset];
    [titleLabel sizeToFit];
    float width = titleLabel.frame.size.width;
    if (width > tableView.frame.size.width - 120) {
        width = tableView.frame.size.width - 120;
    }
    [titleLabel setFrame:CGRectMake(margin, UI_STORE_TABLE_CELL_HEIGHT - 44, width, 20)];
    [cell addSubview:titleLabel];
    
    float iconX = margin + width + 7;
    for (int i = 0; i < 2; i++) {
        UIImageView *support = [[UIImageView alloc] initWithFrame:CGRectMake(iconX, UI_STORE_TABLE_CELL_HEIGHT - 42.5, 17, 17)];
        CALayer *l = [support layer];
        [l setMasksToBounds:YES];
        [l setCornerRadius:3.0];
        BOOL available = NO;
        switch (i) {
            case 0:
                if ([((any_store*)[stores objectAtIndex:indexPath.row]) support]) {
                    [support setImage:[UIImage imageNamed:@"support.png"]];
                    available = YES;
                }
                break;
                
            case 1:
                if ([((any_store*)[stores objectAtIndex:indexPath.row]) discount]) {
                    [support setImage:[UIImage imageNamed:@"discount.png"]];
                    available = YES;
                }
                break;
                
            default:
                break;
        }
        if (available) {
            [cell addSubview:support];
            iconX += 19;
        }
    }
    
    UILabel *addrLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, UI_STORE_TABLE_CELL_HEIGHT - 18, self.view.frame.size.width - 100 - 45, 10)];
    [addrLabel setText:((any_store*)[stores objectAtIndex:indexPath.row]).address];
    [addrLabel setTextAlignment:NSTextAlignmentLeft];
    [addrLabel setTextColor:[UIColor colorWithWhite:1 alpha:0.93]];
    [addrLabel setFont:[UIFont systemFontOfSize:12]];
    [addrLabel setShadowColor:[UIColor blackColor]];
    [addrLabel setShadowOffset:shadowOffset];
    [addrLabel sizeToFit];
    width = addrLabel.frame.size.width;
    if (width > tableView.frame.size.width - 100 - 45) {
        width = tableView.frame.size.width - 100 - 45;
    }
    [addrLabel setFrame:CGRectMake(margin, UI_STORE_TABLE_CELL_HEIGHT - 18, width, 10)];
    [cell addSubview:addrLabel];
    
    if (longitude != 0.0 || latitude != 0.0) {
        UILabel *disLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin + width, UI_STORE_TABLE_CELL_HEIGHT - 18, 80, 10)];
        CLLocation *from = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        CLLocation *toX = [[CLLocation alloc] initWithLatitude:latitude longitude:((any_store*)[stores objectAtIndex:indexPath.row]).longitude];
        double distanceX = [from distanceFromLocation:toX];
        CLLocation *toY = [[CLLocation alloc] initWithLatitude:((any_store*)[stores objectAtIndex:indexPath.row]).latitude longitude:longitude];
        double distanceY = [from distanceFromLocation:toY];
        double distance = distanceX + distanceY;
        NSString *disText;
        if (distance < 10) {
            distance = 10;
        }
        if(distance < 1000)
            disText = [NSString stringWithFormat:@" ● %d0m", (int)(distance / 10.0)];
        else if(distance < 10000)
            disText = [NSString stringWithFormat:@" ● %.1fkm", distance / 1000.0];
        else
            disText = @" ● 10km外";
        [disLabel setText:disText];
        [disLabel setTextAlignment:NSTextAlignmentLeft];
        [disLabel setTextColor:[UIColor colorWithWhite:1 alpha:0.93]];
        [disLabel setFont:[UIFont systemFontOfSize:12]];
        [disLabel setShadowColor:[UIColor blackColor]];
        [disLabel setShadowOffset:shadowOffset];
        [cell addSubview:disLabel];
    }
    
    if (self.mall == nil || [self.mall isEqualToString:@""] || [self.mall isEqualToString:@"normal"]) {
        UILabel *starLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - margin - 80, UI_STORE_TABLE_CELL_HEIGHT - 20, 80, 13)];
        [starLabel setText:@""]; //[NSString stringWithFormat:@"评价：%.1f星", ((any_store*)[stores objectAtIndex:indexPath.row]).rating]];
        [starLabel setTextAlignment:NSTextAlignmentRight];
        [starLabel setTextColor:[UIColor whiteColor]];
        [starLabel setFont:UI_TEXT_FONT];
        int numStars = round(((any_store*)[stores objectAtIndex:indexPath.row]).rating * 2.0);
        int starNum = 0;
        for (starNum = 0; starNum < numStars / 2; starNum++) {
            UIImageView *starView = [[UIImageView alloc] initWithImage:[storeList getStarImage]];
            if (numStars % 2 == 0)
                [starView setFrame:CGRectMake(80 - 13 - 13 * starNum, 0, 13, 13)];
            else
                [starView setFrame:CGRectMake(80 - 13 - 13 * (starNum + 1), 0, 13, 13)];
            [starLabel addSubview:starView];
        }
        if (numStars % 2 == 1) {
            UIImageView *starView = [[UIImageView alloc] initWithImage:[storeList getStarImageHalfed]];
            [starView setFrame:CGRectMake(80 - 13, 0, 13, 13)];
            [starLabel addSubview:starView];
        }
        [cell addSubview:starLabel];
        
        if (((any_store*)[stores objectAtIndex:indexPath.row]).avgPrice != 0) {
            UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - margin - 100, UI_STORE_TABLE_CELL_HEIGHT - 40, 100, 16)];
            [priceLabel setText:[NSString stringWithFormat:@"￥%.0f", ((any_store*)[stores objectAtIndex:indexPath.row]).avgPrice]];
            [priceLabel setTextAlignment:NSTextAlignmentRight];
            [priceLabel setTextColor:DARK_RED];
            [priceLabel setFont:[UIFont boldSystemFontOfSize:16]];
            [priceLabel setShadowColor:[UIColor blackColor]];
            [priceLabel setShadowOffset:shadowOffset];
            [cell addSubview:priceLabel];
        }
    }
    
    //add shadow
    UIView *topShadowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 2)];
    CAGradientLayer *topShadow = [CAGradientLayer layer];
    topShadow.frame = CGRectMake(0, 0, self.view.frame.size.width, 2);
    topShadow.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:1 alpha:0.5] CGColor], (id)[[UIColor colorWithWhite:1 alpha:0.1] CGColor], nil];
    [topShadowView.layer insertSublayer:topShadow atIndex:0];
    if (indexPath.row > 0)
        [cell addSubview:topShadowView];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (stores == nil || stores.count == 0) { //not used
        [self.storeTable deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    if ([self.mall isEqualToString:@"cash"]) {
        creditMallList *v = [self.storyboard instantiateViewControllerWithIdentifier:@"creditMall"];
        [v setMall:@"cash"];
        [v setStoreID:((any_store*)[stores objectAtIndex:indexPath.row]).storeID];
        [self.navigationController pushViewController:v animated:YES];
    } else if ([self.mall isEqualToString:@"credit"]) {
        creditMallList *v = [self.storyboard instantiateViewControllerWithIdentifier:@"creditMall"];
        [v setMall:@"credit"];
        [v setStoreID:((any_store*)[stores objectAtIndex:indexPath.row]).storeID];
        [self.navigationController pushViewController:v animated:YES];
    } else {
        //[self performSegueWithIdentifier:@"storeDetail" sender:self];
        if (self.storeView == nil) {
            self.storeView = [self.storyboard instantiateViewControllerWithIdentifier:@"storeDetails"];
        }
        
        //pass details via array
        passDetails = (any_store*)[stores objectAtIndex:indexPath.row];
        
        [self.navigationController pushViewController:self.storeView animated:YES];
    }
    [self.storeTable deselectRowAtIndexPath:indexPath animated:YES];
}











/*
//area picker
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSArray*)getCities:(NSString*)provinceName {
    for (NSDictionary *cities in allareas) {
        if ([[cities objectForKey:@"province"] isEqualToString:provinceName]) {
            return [cities objectForKey:@"list"];
        }
    }
    return nil;
}

- (NSArray*)getDistricts:(NSString*)cityName inProvince:(NSString*)provinceName {
    for (NSDictionary *districts in [self getCities:provinceName]) {
        if ([[districts objectForKey:@"city"] isEqualToString:cityName]) {
            return [districts objectForKey:@"list"];
        }
    }
    return nil;
}

- (NSArray*)getDistricts:(NSString*)cityName inProvinceArray:(NSArray*)provinces {
    for (NSDictionary *districts in provinces) {
        if ([[districts objectForKey:@"city"] isEqualToString:cityName]) {
            return [districts objectForKey:@"list"];
        }
    }
    return nil;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch (component) {
        case 0:
            return allareas.count;
            break;
            
        case 1:
            return [[self getCities:currentProvince] count];
            break;
            
        default:
            return [[self getDistricts:currentCity inProvince:currentProvince] count];
            break;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    switch (component) {
        case 0:
            return [[allareas objectAtIndex:row] objectForKey:@"province"];
            break;
            
        case 1:
            return [[[self getCities:currentProvince] objectAtIndex:row] objectForKey:@"city"];
            break;
            
        default:
            return [[self getDistricts:currentCity inProvince:currentProvince] objectAtIndex:row];
            break;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        NSString *newProvince = [[allareas objectAtIndex:row] objectForKey:@"province"];
        if (![newProvince isEqualToString:currentProvince]) {
            currentProvince = newProvince;
            currentCity = [[[self getCities:currentProvince] firstObject] objectForKey:@"city"];
            currentDistrict = [[self getDistricts:currentCity inProvince:currentProvince] firstObject];
            [pickerView selectRow:0 inComponent:1 animated:NO];
            [pickerView selectRow:0 inComponent:2 animated:NO];
        }
    } else if (component == 1) {
        NSString *newCity = [[[self getCities:currentProvince] objectAtIndex:row] objectForKey:@"city"];
        if (![newCity isEqualToString:currentCity]) {
            currentCity = newCity;
            currentDistrict = [[self getDistricts:currentCity inProvince:currentProvince] firstObject];
            [pickerView selectRow:0 inComponent:2 animated:NO];
        }
    } else {
        currentDistrict = [[self getDistricts:currentCity inProvince:currentProvince] objectAtIndex:row];
    }
    
    [pickerView reloadAllComponents];
}

- (void)pickerDone {
    NSString *newArea = [NSString stringWithFormat:@"%@-%@-%@", currentProvince, currentCity, currentDistrict];
    if ([newArea isEqualToString:currentArea])
        return;
    else
        currentArea = newArea;
    
    if ([currentCity isEqualToString:@"附近"]) {
        searchRadius = [[currentDistrict substringToIndex:currentDistrict.length - 1] intValue];
        [self.navigationItem.leftBarButtonItem setTitle:[NSString stringWithFormat:@"附近%d米", searchRadius]];
    } else
        [self.navigationItem.leftBarButtonItem setTitle:[NSString stringWithFormat:@"%@-%@", currentCity, currentDistrict]];
    
    //refresh store list
    notificationText = @"加载中...";
    [stores removeAllObjects];
    [self.storeTable reloadData];
    
    if ([currentCity isEqualToString:@"附近"]) {
        if (currentLatitude == 0 && currentLongitude == 0) {
            return;
        }
        //搜索附近餐厅，百度POI搜索
        
        BMKPoiSearch *poiSearcher = [[BMKPoiSearch alloc] init];
        poiSearcher.delegate = self;
        BMKNearbySearchOption *option = [[BMKNearbySearchOption alloc] init];
        option.pageIndex = 0;
        option.pageCapacity = 20;
        option.location = (CLLocationCoordinate2D){currentLatitude, currentLongitude};
        option.keyword = @"餐厅";
        option.radius = searchRadius;
        if(![poiSearcher poiSearchNearBy:option]) {
            NSLog(@"POI发送检索失败！");
        }
         
    } else {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *newStores = [any_store getStoresInProvince:currentProvince andCity:currentCity andDistrict:currentDistrict andLo:longitude andLa:latitude haveMall:self.mall numRecords:numRowsToShow onlyCollected:self.showOnlyCollected options:self.selectedFilterOptions];
            if (newStores != nil) {
                stores = newStores;
            } else {
                notificationText = @"对不起，该区域没有咖啡厅。";
            }
            [self.storeTable reloadData];
        });
    }
    
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:currentProvince, @"province", currentCity, @"city" , currentDistrict, @"district", nil];
    [HTTPRequest asyncGet:SERVER_STORE_REQUEST withData:dic onCompletion:^(NSData *recvdata) {
        NSError *error;
        NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvdata options:kNilOptions error:&error];
        stores = [[jsonRoot objectForKey:@"list"] mutableCopy];
        
        [self.storeTable reloadData];
    }];
    
}



- (void)onGetPoiDetailResult:(BMKPoiSearch *)searcher result:(BMKPoiDetailResult *)poiDetailResult errorCode:(BMKSearchErrorCode)errorCode {
    
}

- (void)onGetPoiResult:(BMKPoiSearch *)searcher result:(BMKPoiResult *)poiResult errorCode:(BMKSearchErrorCode)errorCode {
    if (errorCode == BMK_SEARCH_NO_ERROR && [currentCity isEqualToString:@"附近"]) {
        [stores removeAllObjects];
        for (int i = 0; i < poiResult.poiInfoList.count; i++)
        {
            BMKPoiInfo* poi = [poiResult.poiInfoList objectAtIndex:i];
            NSLog(@"found POI: %@ : %@", poi.name, poi.address);
            //add to stores
            //any_store *thisStore = [[any_store alloc] initWithTitle:poi.name andAddress:poi.address];
            //[stores addObject:thisStore];
        }
        [self.storeTable reloadData];
    }
}

- (void)didUpdateUserLocation:(BMKUserLocation *)userLocation {
    currentLatitude = userLocation.location.coordinate.latitude;
    currentLatitude = userLocation.location.coordinate.longitude;
    NSLog(@"Coordinate: %f, %f", currentLatitude, currentLongitude);
    if ([currentCity isEqualToString:@"附近"]) {
        //搜索附近餐厅，百度POI搜索
        BMKPoiSearch *poiSearcher = [[BMKPoiSearch alloc] init];
        poiSearcher.delegate = self;
        BMKNearbySearchOption *option = [[BMKNearbySearchOption alloc] init];
        option.pageIndex = 0;
        option.pageCapacity = 20;
        option.location = (CLLocationCoordinate2D){currentLatitude, currentLongitude};
        option.keyword = @"餐厅";
        option.radius = searchRadius;
        if(![poiSearcher poiSearchNearBy:option]) {
            NSLog(@"POI发送检索失败！");
        }
    }
}
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
