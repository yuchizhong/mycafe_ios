//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "cafewall.h"
#import "rootTabViewController.h"
#import "storeList.h"
#import "activityDetails.h"
#import "cafewallItem.h"
#import "detailsMenu.h"

#define USER_BEGIN_LOADGING [NSThread detachNewThreadSelector:@selector(beginLoading) toTarget:self withObject:nil];
#define USER_END_LOADGING [NSThread detachNewThreadSelector:@selector(endLoading) toTarget:self withObject:nil];

#define T_COLOR [UIColor blackColor]
#define T_COLOR_SUB [UIColor colorWithWhite:0 alpha:0.75]
#define T_COLOR_SUB_2 [UIColor colorWithWhite:0 alpha:0.65]

static cafeWall *wallInstance = nil;

static CGSize shadowOffset;

static NSMutableArray *activities = nil;

static int cellID = 0;

static UIImage *starImage = nil;
static UIImage *starImageHalf = nil;

static BOOL askedForUserinfo = NO;

@interface cafeWall ()

@property (atomic) NSInteger usingThreads;
@property (atomic) NSInteger usingThreadsStore;
@property (atomic) NSInteger usingThreadsCheck;
@property (atomic) NSInteger doneLoading;
@property (atomic) BOOL justLaunched;

@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (atomic, strong) NSArray *beaconsArray;
@property (atomic, strong) NSArray *arr;
@property (atomic) BOOL inStore;

@property (atomic, strong) CLLocationManager *locationManager;

@property (atomic, strong) NSDate *storeListLastUpdate;
@property (atomic, strong) NSDate *lastPromoteWifi;

@property (atomic, strong) NSDate *lastListUpdate;

//@property (atomic, strong) NIDropDown *dropDown;

@end

@implementation cafeWall

+ (cafeWall*)getInstance {
    return wallInstance;
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

- (void)beginLoading {
    BEGIN_LOADING
}

- (void)endLoading {
    END_LOADING
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SET_NAVBAR
    [self.navigationItem setTitle:@"咖啡墙"];
    
    shadowOffset = CGSizeMake(0, 0);
    self.justLaunched = YES;
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view setBackgroundColor:COFFEE_NOT_VERY_DARK];
    
    self.usingThreads = 0;
    self.usingThreadsStore = 0;
    self.usingThreadsCheck = 0;
    self.storeListLastUpdate = [NSDate distantPast];
    
    self.filterOptionList = [INIT_FILTER_COLUMNS_ACTIVITY mutableCopy];
    self.selectedFilterOptions = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.filterOptionList count]; i++) {
        [self.selectedFilterOptions setObject:[[self.filterOptionList objectAtIndex:i] objectAtIndex:0] atIndexedSubscript:i];
    }
    
    [self.storeTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.storeTable setBackgroundColor:COFFEE_NOT_VERY_DARK];
    
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [customButton setFrame:CGRectMake(0, 0, 28, 28)];
    // Add your action to your button
    [customButton addTarget:self action:@selector(trySendCoffee) forControlEvents:UIControlEventTouchUpInside];
    // Customize your button as you want, with an image if you have a pictogram to display for example
    [customButton setImage:[UIImage imageNamed:@"sendCoffee.png"] forState:UIControlStateNormal];

    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    [self.navigationItem setRightBarButtonItem:rightItem];
    
    wallInstance = self;
    [storeList registerCafeWallView:self];
}

- (void)trySendCoffee {
    if ([user getCurrentID] == nil) {
        [HTTPRequest alert:@"请您先登录"];
        return;
    } else if ([user getUserInfo] == nil) {
        UIViewController *goLoginController = [self.storyboard instantiateViewControllerWithIdentifier:@"enterUserinfo"];
        [self presentViewController:goLoginController animated:YES completion:nil];
        return;
    } else if ([store getCurrentStoreID] == nil) {
        [HTTPRequest alert:@"您不在任何一家店内"];
        return;
    }
    
    //go coffee sending view
    [self startSendCoffeeProcess];
}

- (void)startSendCoffeeProcess {
    detailsMenu *menuView = [self.storyboard instantiateViewControllerWithIdentifier:@"storeDetailsMenu"];
    [menuView setGiftMode:YES];
    [menuView setShowOnlyDiscount:NO];
    [detailsMenu askForReset];
    [self.navigationController pushViewController:menuView animated:YES];
}

- (void)loadActivities {
    GLOBAL_LOCK
    if (self.usingThreads > 0) {
        if (self.usingThreads == 0) {
            [self.storeTable headerEndRefreshing];
            //[self.storeTable footerEndRefreshing];
        }
        GLOBAL_UNLOCK
        return;
    }
    //not this view, skip
    if (self.tabBarController.selectedIndex != 2) {
        [self.storeTable headerEndRefreshing];
        //[self.storeTable footerEndRefreshing];
        GLOBAL_UNLOCK
        return;
    }
    self.usingThreads++;
    GLOBAL_UNLOCK
    //USER_BEGIN_LOADGING
    BOOL load_ok = NO;
    int retry = 0;
    while (!load_ok && retry < 3 /* stores == nil || stores.count == 0*/) {
        activities = [store getCafeWall];
        
        if ([user gotUserinfo] && [user getUserInfo] == nil) {
            if (!askedForUserinfo) {
                [self performSelectorOnMainThread:@selector(showEnterUserinfo) withObject:nil waitUntilDone:YES];
                askedForUserinfo = YES;
            }
            break;
        }
        
        if (activities == nil) {
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
    [self.storeTable reloadData];
    [self.storeTable headerEndRefreshing];
    //[self.storeTable footerEndRefreshing];
}

- (void)showEnterUserinfo {
    UIViewController *enterUserinfo = [self.storyboard instantiateViewControllerWithIdentifier:@"enterUserinfo"];
    [self presentViewController:enterUserinfo animated:YES completion:nil];
}

- (void)loadActivitiesAsyncBridge {
    [NSThread detachNewThreadSelector:@selector(loadActivities) toTarget:self withObject:nil];
}

- (void)loadMoreActivitiesAsyncBridge {
    [NSThread detachNewThreadSelector:@selector(loadActivities) toTarget:self withObject:nil];
}

- (void)refresh {
    if (self.usingThreads > 0) {
        return;
    }
    
    self.lastListUpdate = [NSDate date];
    [self.navigationController popToRootViewControllerAnimated:YES];
    if ([user getCurrentID] != nil && [store getCurrentStoreID] != nil)
        [self.storeTable headerBeginRefreshing];
    else
        [self.storeTable reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.justLaunched) {
        [self.storeTable addHeaderWithTarget:self action:@selector(loadActivitiesAsyncBridge) dateKey:@"tableCafeWall"];
        //[self.storeTable addFooterWithTarget:self action:@selector(loadMoreActivitiesAsyncBridge)];
        self.justLaunched = NO;
        if ([user getCurrentID] != nil && [store getCurrentStoreID] != nil) {
            self.lastListUpdate = [NSDate date];
            [self.storeTable headerBeginRefreshing];
        } else
            [self.storeTable reloadData];
    } else {
        //refresh if time expires
        NSDate *now = [NSDate date];
        if (self.lastListUpdate == nil || ABS([now timeIntervalSinceDate:self.lastListUpdate]) > 60/*1 minute*/) {
            [self refresh];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([user getCurrentID] == nil)
        return 1;
    if ([user getUserInfo] == nil)
        return 1;
    if ([store getCurrentStoreID] == nil)
        return 1;
    if (activities == nil)
        return 0;
    if (activities.count == 0)
        return 1;
    return activities.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([user getCurrentID] == nil || [store getCurrentStoreID] == nil || [user getUserInfo] == nil) {
        return UI_CAFE_WALL_TABLE_CELL_HEIGHT;
    }
    if (activities != nil && activities.count > 0 && indexPath.row == 0) {
        return 8;
    }
    return UI_CAFE_WALL_TABLE_CELL_HEIGHT;
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
    
    if ([user getCurrentID] == nil) {
        UILabel *noActivityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_CAFE_WALL_TABLE_CELL_HEIGHT)];
        [noActivityLabel setText:@"咖啡墙需要您登陆\n点我登陆"];
        [noActivityLabel setNumberOfLines:0];
        [noActivityLabel setTextAlignment:NSTextAlignmentCenter];
        [noActivityLabel setTextColor:[UIColor whiteColor]];
        [noActivityLabel setFont:FONT15];
        [cell addSubview:noActivityLabel];
        [cell setBackgroundColor:[UIColor clearColor]];
        return cell;
    }
    
    if ([user getUserInfo] == nil) {
        UILabel *noActivityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_CAFE_WALL_TABLE_CELL_HEIGHT)];
        [noActivityLabel setText:@"咖啡墙需要您的基本信息\n点我输入"];
        [noActivityLabel setNumberOfLines:0];
        [noActivityLabel setTextAlignment:NSTextAlignmentCenter];
        [noActivityLabel setTextColor:[UIColor whiteColor]];
        [noActivityLabel setFont:FONT15];
        [cell addSubview:noActivityLabel];
        [cell setBackgroundColor:[UIColor clearColor]];
        return cell;
    }
    
    if ([store getCurrentStoreID] == nil) {
        UILabel *noActivityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_CAFE_WALL_TABLE_CELL_HEIGHT)];
        [noActivityLabel setText:@"当前您不在任何一家店里"];
        [noActivityLabel setNumberOfLines:0];
        [noActivityLabel setTextAlignment:NSTextAlignmentCenter];
        [noActivityLabel setTextColor:[UIColor whiteColor]];
        [noActivityLabel setFont:FONT15];
        [cell addSubview:noActivityLabel];
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    }
    
    if (activities.count == 0) {
        UILabel *noActivityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_CAFE_WALL_TABLE_CELL_HEIGHT)];
        [noActivityLabel setText:@"还没有咖啡哦~\n赶紧留一杯吧！"];
        [noActivityLabel setNumberOfLines:0];
        [noActivityLabel setTextAlignment:NSTextAlignmentCenter];
        [noActivityLabel setTextColor:[UIColor whiteColor]];
        [noActivityLabel setFont:FONT15];
        [cell addSubview:noActivityLabel];
        [cell setBackgroundColor:[UIColor clearColor]];
        return cell;
    }
    
    if (activities.count > 0 && indexPath.row == 0) {
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    }
    
    /**
     * left and right margin to bounds
     */
    int margin = 8;
    
    NSMutableDictionary *activity = [activities objectAtIndex:indexPath.row - 1];
    
    UILabel *outLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 0, self.view.frame.size.width - 12, UI_CAFE_WALL_TABLE_CELL_HEIGHT - 9)];
    [outLabel setBackgroundColor:[UIColor colorWithRed:220.0/255.0 green:217.0/255.0 blue:214.0/255.0 alpha:1]];
    CALayer *l = [outLabel layer];
    l.shadowOffset = CGSizeMake(0, -3);
    l.shadowRadius = 6.0;
    l.shadowColor = [UIColor blackColor].CGColor; //shadow的颜色
    l.shadowOpacity = 1;
    [l setMasksToBounds:YES];
    [l setCornerRadius:6.0];
    
    //add image
    //round corner image
    UIImageView *roundedView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, outLabel.frame.size.height - 20, outLabel.frame.size.height - 20)];
    UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(10, roundedView.frame.size.height / 2 - 1, roundedView.frame.size.width - 20, 2)];
    [loading setProgress:0.0];
    [loading setProgressViewStyle:UIProgressViewStyleDefault];
    [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
    [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
    [roundedView addSubview:loading];
    NSString *url = [NSString stringWithFormat:@"%@/%@/dishimage/dish%@/%@", SERVER_ADDRESS, [store getCurrentStoreFolder], [activity objectForKey:@"dishID"], [activity objectForKey:@"picPath"]];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //[[SDImageCache sharedImageCache] clearDisk];
    [roundedView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"noimage.png"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        float percentage = (float)receivedSize / (float)expectedSize;
        //update loading progress bar
        [loading setProgress:percentage];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        //dismiss loading progress bar
        [loading removeFromSuperview];
    }];
    [roundedView setContentMode:UIViewContentModeScaleAspectFill];
    CALayer *l2 = [roundedView layer];
    [l2 setMasksToBounds:YES];
    [l2 setCornerRadius:6.0];
    roundedView.frame = CGRectMake(10, 10, outLabel.frame.size.height - 20, outLabel.frame.size.height - 20);
    [outLabel addSubview:roundedView];
    
    UILabel *activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.height, 10, outLabel.frame.size.width - margin - outLabel.frame.size.height, 20)];
    [activityLabel setText:[activity objectForKey:@"dishName"]];
    [activityLabel setTextAlignment:NSTextAlignmentLeft];
    [activityLabel setTextColor:T_COLOR];
    if ([[activity objectForKey:@"dishName"] length] <= 15)
        [activityLabel setFont:[UIFont boldSystemFontOfSize:18]];
    else
        [activityLabel setFont:[UIFont boldSystemFontOfSize:15]];
    //[activityLabel setShadowColor:[UIColor blackColor]];
    //[activityLabel setShadowOffset:shadowOffset];
    [outLabel addSubview:activityLabel];
    
    NSMutableString *timeStr = [[activity objectForKey:@"post_date"] mutableCopy];
    [timeStr insertString:@"日" atIndex:8];
    [timeStr insertString:@"月" atIndex:6];
    [timeStr insertString:@"年" atIndex:4];
    
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.height, activityLabel.frame.origin.y + activityLabel.frame.size.height + 1, outLabel.frame.size.width - margin - outLabel.frame.size.height, 13)];
    [dateLabel setText:timeStr];
    [dateLabel setTextAlignment:NSTextAlignmentLeft];
    [dateLabel setTextColor:T_COLOR_SUB_2];
    [dateLabel setFont:[UIFont systemFontOfSize:13]];
    //[dateLabel setShadowColor:[UIColor blackColor]];
    //[dateLabel setShadowOffset:shadowOffset];
    [outLabel addSubview:dateLabel];
    
    int male = [[activity objectForKey:@"gender"] intValue];
    int birthyear = [[activity objectForKey:@"birthyear"] integerValue];
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit;
    NSDateComponents *dateComponent = [calendar components:unitFlags fromDate:now];
    int currentyear = [dateComponent year];
    int age = currentyear - birthyear;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.height, outLabel.frame.size.height - 36, outLabel.frame.size.width - margin - outLabel.frame.size.height, 14)];
    [titleLabel setText:[NSString stringWithFormat:@"from %@（%@, %d岁）", [activity objectForKey:@"customerName"], male == 0 ? @"男" : @"女", age]];
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    [titleLabel setTextColor:T_COLOR_SUB];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
    //[titleLabel setShadowColor:[UIColor blackColor]];
    //[titleLabel setShadowOffset:shadowOffset];
    [outLabel addSubview:titleLabel];
    
    UILabel *addrLabel = [[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.height, outLabel.frame.size.height - 20, outLabel.frame.size.width - margin - outLabel.frame.size.height, 10)];
    [addrLabel setText:[NSString stringWithFormat:@"%@", [activity objectForKey:@"message"]]];
    [addrLabel setTextAlignment:NSTextAlignmentLeft];
    [addrLabel setTextColor:T_COLOR_SUB];
    [addrLabel setFont:[UIFont systemFontOfSize:12]];
    //[addrLabel setShadowColor:[UIColor blackColor]];
    //[addrLabel setShadowOffset:shadowOffset];
    [outLabel addSubview:addrLabel];
    
    [cell addSubview:outLabel];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([user getCurrentID] == nil) {
        //login
        UIViewController *goLoginController = [self.storyboard instantiateViewControllerWithIdentifier:@"loginRoot"];
        [self presentViewController:goLoginController animated:YES completion:nil];
        
        [self.storeTable deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    if ([user getUserInfo] == nil) {
        //need userinfo
        UIViewController *goLoginController = [self.storyboard instantiateViewControllerWithIdentifier:@"enterUserinfo"];
        [self presentViewController:goLoginController animated:YES completion:nil];
        
        [self.storeTable deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    if (activities != nil && [store getCurrentStoreID] != nil && activities.count == 0) {
        //go coffee sending view
        [self startSendCoffeeProcess];
        
        [self.storeTable deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    if ([store getCurrentStoreID] == nil || activities == nil || activities.count == 0) { //not used
        [self.storeTable deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    cafeWallItem *wallItem = [self.storyboard instantiateViewControllerWithIdentifier:@"cafeWallItem"];
    [wallItem setWallItemDetailInfo:[activities objectAtIndex:indexPath.row - 1]];
    [self.navigationController pushViewController:wallItem animated:YES];
 
    [self.storeTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
