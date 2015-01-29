//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "storeActivity.h"
#import "rootTabViewController.h"
#import "storeList.h"
#import "activityDetails.h"

/*
static NSArray *allProvinces = nil;
static NSMutableArray *allCities = nil;
static NSMutableArray *allDistrcits = nil;
 */

#define USER_BEGIN_LOADGING [NSThread detachNewThreadSelector:@selector(beginLoading) toTarget:self withObject:nil];
#define USER_END_LOADGING [NSThread detachNewThreadSelector:@selector(endLoading) toTarget:self withObject:nil];

#define T_COLOR [UIColor blackColor]
#define T_COLOR_SUB [UIColor colorWithWhite:0 alpha:0.75]
#define T_COLOR_SUB_2 [UIColor colorWithWhite:0 alpha:0.65]

static CGSize shadowOffset;


static NSArray *allareas = nil;

static NSMutableArray *activities = nil;
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

@interface storeActivity ()

@property (atomic) NSInteger usingThreads;
@property (atomic) NSInteger usingThreadsStore;
@property (atomic) NSInteger usingThreadsCheck;
@property (atomic) NSInteger doneLoading;
@property (atomic) BOOL justLaunched;

@property (atomic, strong) CLLocationManager *locationManager;

@property (atomic, strong) NSDate *storeListLastUpdate;
@property (atomic, strong) NSDate *lastPromoteWifi;

//@property (atomic, strong) NIDropDown *dropDown;

@end

@implementation storeActivity

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
    [self.navigationItem setTitle:@"咖啡馆的活动"];
    
    [self.pickerView setHidden:YES];
    shadowOffset = CGSizeMake(0, 0);
    self.justLaunched = YES;
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view setBackgroundColor:COFFEE_NOT_VERY_DARK];
    //[self.toolbarView setBackgroundColor:COFFEE_NOT_VERY_DARK];
    
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
    
    self.showOnlyCollected = NO;
    
    //toolbar
    if (SHOW_ACTIVITY_FILTER_OPTIONS) {
        DOPDropDownMenu *menu = [[DOPDropDownMenu alloc] initWithOrigin:CGPointMake(0, 0) andHeight:38];
        menu.dataSource = self;
        menu.delegate = self;
        [self.view addSubview:menu];
    }
    
    //toolbar, ignore
    /*
    UIButton *dropdownButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [dropdownButton setTitle:@"全部" forState:UIControlStateNormal];
    [dropdownButton setBackgroundColor:COFFEE_VERY_DARK];
    [dropdownButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //[dropdownButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    [dropdownButton setFrame:CGRectMake(0, 64, [[UIScreen mainScreen] bounds].size.width, 36)];
    [dropdownButton addTarget:self action:@selector(optionFilterClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dropdownButton];
     */
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
- (void)niDropDownDelegateMethod:(NIDropDown *)sender withIndex:(NSInteger)index {
    self.dropDown = nil;
    if (index == 0) {
        self.showOnlyCollected = NO;
    } else {
        self.showOnlyCollected = YES;
    }
    [self.storeTable headerBeginRefreshing];
}

- (void)optionFilterClicked:(id)sender {
    NSArray * arr = @[@"全部", @"收藏的店"];
    if(self.dropDown == nil) {
        CGFloat f = 80;
        self.dropDown = [[NIDropDown alloc] showDropDown:sender withHeight:&f andArray:arr];
        self.dropDown.delegate = self;
    }
    else {
        [self.dropDown hideDropDown:sender];
        self.dropDown = nil;
    }
}
 */

- (void)loadActivities {
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
    if (self.tabBarController.selectedIndex != 3) {
        [self.storeTable headerEndRefreshing];
        [self.storeTable footerEndRefreshing];
        GLOBAL_UNLOCK
        return;
    }
    self.usingThreads++;
    GLOBAL_UNLOCK
    //USER_BEGIN_LOADGING
    BOOL load_ok = NO;
    int retry = 0;
    while (!load_ok && retry < 3 /* stores == nil || stores.count == 0*/) {
        activities = [any_store getActivitiesInProvince:@"全部" andCity:@"全部" andDistrict:@"全部" andLo:[storeList getCurrentLongitude] andLa:[storeList getCurrentLatitude] numRecords:numRowsToShow onlyCollected:self.showOnlyCollected options:self.selectedFilterOptions];
        
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
    if (retry < 3)
        [self.storeTable reloadData];
    else
        [HTTPRequest alert:NETWORK_ERROR];
    [self.storeTable headerEndRefreshing];
    [self.storeTable footerEndRefreshing];
}

- (void)loadActivitiesAsyncBridge {
    numRowsToShow = NUM_STORE_ROWS_PER_PAGE;
    [NSThread detachNewThreadSelector:@selector(loadActivities) toTarget:self withObject:nil];
}

- (void)loadMoreActivitiesAsyncBridge {
    numRowsToShow += NUM_STORE_ROWS_PER_PAGE;
    [NSThread detachNewThreadSelector:@selector(loadActivities) toTarget:self withObject:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.justLaunched) {
        [self.storeTable addHeaderWithTarget:self action:@selector(loadActivitiesAsyncBridge) dateKey:@"tableActivity"];
        [self.storeTable addFooterWithTarget:self action:@selector(loadMoreActivitiesAsyncBridge)];
        self.justLaunched = NO;
        [self.storeTable headerBeginRefreshing];
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
    if (activities == nil)
        return 0;
    if (activities.count == 0)
        return 1;
    return activities.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (activities != nil && activities.count > 0 && indexPath.row == 0) {
        return 8;
    }
    return UI_ACTIVITY_TABLE_CELL_HEIGHT;
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
    
    if (activities.count == 0) {
        UILabel *noActivityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_ACTIVITY_TABLE_CELL_HEIGHT)];
        [noActivityLabel setText:@"没有活动"];
        [noActivityLabel setTextAlignment:NSTextAlignmentCenter];
        [noActivityLabel setTextColor:[UIColor whiteColor]];
        [noActivityLabel setFont:FONT15];
        [cell addSubview:noActivityLabel];
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
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
    
    /*
    //add image
    UIImageView *roundedView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_ACTIVITY_TABLE_CELL_HEIGHT)];
    UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(0, UI_ACTIVITY_TABLE_CELL_HEIGHT - 3, self.view.frame.size.width, 3)];
    [loading setProgress:0.0];
    [loading setProgressViewStyle:UIProgressViewStyleDefault];
    [loading setTrackTintColor:[UIColor whiteColor]];
    [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
    [loading setTransform:CGAffineTransformMakeScale(1.0, 1.5)];
    [roundedView addSubview:loading];
    NSString *url = [NSString stringWithFormat:@"%@/images/store%@/logoimage/%@", SERVER_ADDRESS, [activity objectForKey:@"storeID"], @"homelarge.png"];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [roundedView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"homelarge.png"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        float percentage = (float)receivedSize / (float)expectedSize;
        //update loading progress bar
        [loading setProgress:percentage];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        //dismiss loading progress bar
        [loading removeFromSuperview];
    }];
    //[roundedView setContentMode:UIViewContentModeScaleAspectFit];
    [cell addSubview:roundedView];
    UIImageView *shadowView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, UI_ACTIVITY_TABLE_CELL_HEIGHT)];
    [shadowView setImage:[UIImage imageNamed:@"activityhomeshadow.png"]];
    [roundedView addSubview:shadowView];
     */
    
    UILabel *outLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 0, self.view.frame.size.width - 12, UI_ACTIVITY_TABLE_CELL_HEIGHT - 9)];
    [outLabel setBackgroundColor:[UIColor colorWithRed:185.0/255.0 green:182.0/255.0 blue:179.0/255.0 alpha:1]];
    CALayer *l = [outLabel layer];
    l.shadowOffset = CGSizeMake(0, -3);
    l.shadowRadius = 6.0;
    l.shadowColor = [UIColor blackColor].CGColor; //shadow的颜色
    l.shadowOpacity = 1;
    [l setMasksToBounds:YES];
    [l setCornerRadius:6.0];
    
    UILabel *activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 8, outLabel.frame.size.width - 2 * margin, 24)];
    [activityLabel setText:[activity objectForKey:@"name"]];
    [activityLabel setTextAlignment:NSTextAlignmentLeft];
    [activityLabel setTextColor:T_COLOR];
    if ([[activity objectForKey:@"name"] length] <= 10)
        [activityLabel setFont:[UIFont boldSystemFontOfSize:22]];
    else if ([[activity objectForKey:@"name"] length] <= 15)
        [activityLabel setFont:[UIFont boldSystemFontOfSize:18]];
    else
        [activityLabel setFont:[UIFont boldSystemFontOfSize:14]];
    //[activityLabel setShadowColor:[UIColor blackColor]];
    //[activityLabel setShadowOffset:shadowOffset];
    [outLabel addSubview:activityLabel];
    
    NSMutableString *deadlineTimeStr = [[activity objectForKey:@"deadline_date"] mutableCopy];
    [deadlineTimeStr insertString:@"日" atIndex:8];
    [deadlineTimeStr insertString:@"月" atIndex:6];
    [deadlineTimeStr insertString:@"年" atIndex:4];
    //timeStr = [[timeStr substringFromIndex:2] mutableCopy];
    [deadlineTimeStr appendString:@" "];
    if ([activity objectForKey:@"deadline_time"] != [NSNull null] && ![[activity objectForKey:@"deadline_time"] isEqualToString:@""])
        [deadlineTimeStr appendString:[activity objectForKey:@"deadline_time"]];
    else
        [deadlineTimeStr appendString:@"09:00"];
    
    NSMutableString *timeStr = [[activity objectForKey:@"date"] mutableCopy];
    [timeStr insertString:@"日" atIndex:8];
    [timeStr insertString:@"月" atIndex:6];
    [timeStr insertString:@"年" atIndex:4];
    //timeStr = [[timeStr substringFromIndex:2] mutableCopy];
    [timeStr appendString:@" "];
    if ([activity objectForKey:@"time"] != [NSNull null] && ![[activity objectForKey:@"time"] isEqualToString:@""])
        [timeStr appendString:[activity objectForKey:@"time"]];
    else
        [timeStr appendString:@"09:00"];
    
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, activityLabel.frame.origin.y + activityLabel.frame.size.height + 1, outLabel.frame.size.width - 2 * margin, 13)];
    [dateLabel setText:timeStr];
    [dateLabel setTextAlignment:NSTextAlignmentLeft];
    [dateLabel setTextColor:T_COLOR_SUB_2];
    [dateLabel setFont:[UIFont systemFontOfSize:13]];
    //[dateLabel setShadowColor:[UIColor blackColor]];
    //[dateLabel setShadowOffset:shadowOffset];
    [outLabel addSubview:dateLabel];
    
    UILabel *deadlineDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, activityLabel.frame.origin.y + activityLabel.frame.size.height + 1 + 13, outLabel.frame.size.width - 2 * margin, 13)];
    [deadlineDateLabel setText:[NSString stringWithFormat:@"报名截止 %@", deadlineTimeStr]];
    [deadlineDateLabel setTextAlignment:NSTextAlignmentLeft];
    [deadlineDateLabel setTextColor:T_COLOR_SUB_2];
    [deadlineDateLabel setFont:[UIFont systemFontOfSize:13]];
    //[dateLabel setShadowColor:[UIColor blackColor]];
    //[dateLabel setShadowOffset:shadowOffset];
    [outLabel addSubview:deadlineDateLabel];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, outLabel.frame.size.height - 34, outLabel.frame.size.width - 120, 14)];
    [titleLabel setText:[NSString stringWithFormat:@"@ %@", [activity objectForKey:@"storeName"]]];
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    [titleLabel setTextColor:T_COLOR_SUB];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
    //[titleLabel setShadowColor:[UIColor blackColor]];
    //[titleLabel setShadowOffset:shadowOffset];
    [titleLabel sizeToFit];
    float width = titleLabel.frame.size.width;
    if (width > tableView.frame.size.width - 120) {
        width = tableView.frame.size.width - 120;
    }
    [titleLabel setFrame:CGRectMake(margin, outLabel.frame.size.height - 38, width, 14)];
    [outLabel addSubview:titleLabel];
    
    UILabel *addrLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, outLabel.frame.size.height - 18, outLabel.frame.size.width - 100 - 45, 10)];
    [addrLabel setText:[NSString stringWithFormat:@"%@", [activity objectForKey:@"addr"]]];
    [addrLabel setTextAlignment:NSTextAlignmentLeft];
    [addrLabel setTextColor:T_COLOR_SUB];
    [addrLabel setFont:[UIFont systemFontOfSize:12]];
    //[addrLabel setShadowColor:[UIColor blackColor]];
    //[addrLabel setShadowOffset:shadowOffset];
    [addrLabel sizeToFit];
    width = addrLabel.frame.size.width;
    if (width > tableView.frame.size.width - 100 - 45) {
        width = tableView.frame.size.width - 100 - 45;
    }
    [addrLabel setFrame:CGRectMake(margin, outLabel.frame.size.height - 18, width, 10)];
    [outLabel addSubview:addrLabel];
    
    if ([storeList getCurrentLongitude] != 0.0 || [storeList getCurrentLatitude] != 0.0) {
        UILabel *disLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin + width, outLabel.frame.size.height - 18, 80, 10)];
        CLLocation *from = [[CLLocation alloc] initWithLatitude:[storeList getCurrentLatitude] longitude:[storeList getCurrentLongitude]];
        CLLocation *toX = [[CLLocation alloc] initWithLatitude:[storeList getCurrentLatitude] longitude:[[activity objectForKey:@"longitude"] doubleValue]];
        double distanceX = [from distanceFromLocation:toX];
        CLLocation *toY = [[CLLocation alloc] initWithLatitude:[[activity objectForKey:@"latitude"] doubleValue] longitude:[storeList getCurrentLongitude]];
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
        [disLabel setTextColor:T_COLOR_SUB];
        [disLabel setFont:[UIFont systemFontOfSize:12]];
        //[disLabel setShadowColor:[UIColor blackColor]];
        //[disLabel setShadowOffset:shadowOffset];
        [outLabel addSubview:disLabel];
    }
    
    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.width - margin - 100, outLabel.frame.size.height - 19, 100, 12)];
    [countLabel setText:[NSString stringWithFormat:@"%d/%d人", [[activity objectForKey:@"enrolled"] intValue], [[activity objectForKey:@"max"] intValue]]];
    if ([[activity objectForKey:@"max"] intValue] == 0) {
        [countLabel setText:[NSString stringWithFormat:@"%d人/不限", [[activity objectForKey:@"enrolled"] intValue]]];
    }
    [countLabel setTextAlignment:NSTextAlignmentRight];
    [countLabel setTextColor:T_COLOR_SUB];
    [countLabel setFont:[UIFont systemFontOfSize:13]];
    [outLabel addSubview:countLabel];
    
    /******************** status ********************/
    //need bottom left and right corner to be rounded
    float statusLabelWidth = 38, statusLabelHeight = 50;
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.width - margin - 48, 0, statusLabelWidth, statusLabelHeight * 0.9)];
    //[[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.width - margin - 100, outLabel.frame.size.height - 38, 100, 14)];
    NSDateFormatter* formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy年MM月dd日 HH:mm"];
    NSDate *acDate = [formater dateFromString:timeStr];
    NSDateFormatter* ddformater = [[NSDateFormatter alloc] init];
    [ddformater setDateFormat:@"yyyy年MM月dd日 HH:mm"];
    NSDate *ddDate = [formater dateFromString:deadlineTimeStr];
    if ([[NSDate date] compare:acDate] == NSOrderedDescending) {
        [statusLabel setText:@"已结束"];
    } else if ([[NSDate date] compare:ddDate] == NSOrderedDescending) {
        [statusLabel setText:@"报名\n截止"];
    } else if ([[activity objectForKey:@"userEnrolled"] intValue] == 1) {
        [statusLabel setText:@"已报名"];
    } else if ([[activity objectForKey:@"max"] intValue] > 0 && [[activity objectForKey:@"enrolled"] intValue] >= [[activity objectForKey:@"max"] intValue]) {
        [statusLabel setText:@"名额\n已满"];
    } else {
        [statusLabel setText:@"报名中"];
    }
    [statusLabel setTextAlignment:NSTextAlignmentCenter];
    [statusLabel setTextColor:[UIColor whiteColor]];
    [statusLabel setBackgroundColor:[UIColor clearColor]];
    [statusLabel setNumberOfLines:0];
    [statusLabel setFont:[UIFont boldSystemFontOfSize:11]];
    //[statusLabel setShadowColor:[UIColor blackColor]];
    //[statusLabel setShadowOffset:shadowOffset];
    
    UILabel *statusBackLabel = [[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.width - margin - 48, 0, statusLabelWidth, statusLabelHeight / 2.0)];
    if ([statusLabel.text isEqualToString:@"报名中"])
        [statusBackLabel setBackgroundColor:BLUE];
    else
        [statusBackLabel setBackgroundColor:PINK_RED];
    
    UILabel *statusBackLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.width - margin - 48, 0, statusLabelWidth, statusLabelHeight)];
    if ([statusLabel.text isEqualToString:@"报名中"])
        [statusBackLabel2 setBackgroundColor:BLUE];
    else
        [statusBackLabel2 setBackgroundColor:PINK_RED];
    [statusBackLabel2.layer setMasksToBounds:YES];
    [statusBackLabel2.layer setCornerRadius:statusLabelWidth / 2.0];
    
    if (![statusLabel.text isEqualToString:@"报名中"]) {
        [outLabel addSubview:statusBackLabel];
        [outLabel addSubview:statusBackLabel2];
        [outLabel addSubview:statusLabel];
    }

    UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(outLabel.frame.size.width - 100, outLabel.frame.size.height - 36, 100 - margin, 13)];
    [priceLabel setText:[NSString stringWithFormat:@"￥%.2f", [[activity objectForKey:@"price"] floatValue]]];
    if ([[activity objectForKey:@"price"] floatValue] == 0) {
        [priceLabel setText:@"免费"];
    }
    [priceLabel setTextAlignment:NSTextAlignmentRight];
    [priceLabel setTextColor:DDARK_RED];
    [priceLabel setFont:[UIFont boldSystemFontOfSize:13]];
    //[priceLabel setShadowColor:DDARK_RED];
    //[priceLabel setShadowOffset:CGSizeMake(0.5, 0.5)];
    [outLabel addSubview:priceLabel];
    
    //add shadow
    /*
    UIView *topShadowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 2)];
    CAGradientLayer *topShadow = [CAGradientLayer layer];
    topShadow.frame = CGRectMake(0, 0, self.view.frame.size.width, 2);
    topShadow.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:1 alpha:0.5] CGColor], (id)[[UIColor colorWithWhite:1 alpha:0.1] CGColor], nil];
    [topShadowView.layer insertSublayer:topShadow atIndex:0];
    [cell addSubview:topShadowView];
     */
    
    [cell addSubview:outLabel];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (activities == nil || activities.count == 0) { //not used
        [self.storeTable deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    activityDetails *activityDetialsForSingleStore = [self.storyboard instantiateViewControllerWithIdentifier:@"activityDetails"];
    [activityDetialsForSingleStore setActivityInfo:[activities objectAtIndex:indexPath.row - 1]];
    [self.navigationController pushViewController:activityDetialsForSingleStore animated:YES];
 
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
    [activities removeAllObjects];
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
            NSMutableArray *newActivities = [any_store getStoresInProvince:currentProvince andCity:currentCity andDistrict:currentDistrict andLo:[storeList getCurrentLongitude] andLa:[storeList getCurrentLatitude] haveMall:nil numRecords:numRowsToShow onlyCollected:NO];
            if (newActivities != nil) {
                activities = newActivities;
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
