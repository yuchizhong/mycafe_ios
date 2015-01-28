//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "foodList.h"
#import "singleItem.h"
#import "cart.h"
#import "storeList.h"

#import <QuartzCore/QuartzCore.h>
#import "ECSlidingViewController.h"
#import "extra.h"

static BOOL refreshing = NO;
static BBBadgeBarButtonItem *cartButton = nil;

@interface foodList ()

@end

static BOOL shouldReset = NO;
static int foodlistCellID;

@implementation foodList

+ (BBBadgeBarButtonItem*)cartButton {
    return cartButton;
}

+ (void)askForReset {
    shouldReset = YES;
}

- (void)reloadCataCount {
    /*
    for (BBBadgeBarButtonItem *item in self.bar.items) {
        UIButton *barbutton = (UIButton*)item.customView;
        if (barbutton == nil)
            continue;
        int count = 0;
        NSMutableArray *foodInThisCata = [store getMenubyCatagory:barbutton.titleLabel.text];
        //遍历order
        for (orderInfo *orInfo in [orderInfo getOrder]) {
            //遍历foodInThisCata
            for (foodInfo *f in foodInThisCata) {
                if ([orInfo getID] == [f getID]) {
                    count += [orInfo getCount];
                }
            }
        }
        
        //item set badge
        item.badgeValue = [NSString stringWithFormat:@"%d", count];
    }
     */
}

- (void)pickMenu:(int)index {
    NSIndexPath *ip2 = [NSIndexPath indexPathForRow:0 inSection:index];
    followScroll = NO;
    [self.foodTable scrollToRowAtIndexPath:ip2 atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
    //[UIView beginAnimations:@"ToggleViews" context:nil];
    //[UIView setAnimationDuration:0.1];
    [self.selectedBack setFrame:CGRectMake(0, index * 40, 76, 40)];
    //[UIView commitAnimations];
    for (UIView *v in self.selectedBack.subviews) {
        if (v.tag == 1) {
            [((UILabel*)v) setText:[self.catagories objectAtIndex:index]];
        }
    }
}

- (void)reloadCartBadge {
    float _totalvalue = [orderInfo getTotalValue];
    if (_totalvalue == 0) {
        REFRESH_VALUE_BADGE(nil);
    } else {
        NSString *s = [NSString stringWithFormat:@"￥%.0f", _totalvalue];
        REFRESH_VALUE_BADGE(s);
    }
}

- (void)goOrders {
    [self.navigationController pushViewController:[cart getInstance] animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    SET_NAVBAR
    
    cart *cartInstance = [self.storyboard instantiateViewControllerWithIdentifier:@"cart"];
    [cartInstance viewDidLoad];
    
    refreshing = NO;
    [storeList registerMenuView:self];
    
    [self.catagoryTable setBackgroundColor:[UIColor colorWithRed:66.0/255.0 green:54.0/255.0 blue:48.0/255.0 alpha:1]];
    [self.foodTable setBackgroundColor:COFFEE_LIGHT];
    
    self.selectedBack = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 76, 40)];
    [self.selectedBack setBackgroundColor:COFFEE_LIGHT/*[UIColor colorWithRed:140.0/255.0 green:98.0/255.0 blue:56.0/255.0 alpha:1]*/];
    UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, 73, 40)];
    [labelTitle setFont:[UIFont systemFontOfSize:13]];
    [labelTitle setTextAlignment:NSTextAlignmentLeft];
    [labelTitle setNumberOfLines:0];
    [labelTitle setLineBreakMode:NSLineBreakByCharWrapping];
    [labelTitle setTextColor:[UIColor blackColor]];
    [labelTitle setTag:1];
    [self.selectedBack addSubview:labelTitle];
    
    
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [customButton setFrame:CGRectMake(0, 0, 28, 28)];
    // Add your action to your button
    [customButton addTarget:self action:@selector(goOrders) forControlEvents:UIControlEventTouchUpInside];
    // Customize your button as you want, with an image if you have a pictogram to display for example
    [customButton setImage:[UIImage imageNamed:@"cart.png"] forState:UIControlStateNormal];
    
    BBBadgeBarButtonItem *rightButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:customButton];
    rightButton.badgeOriginX = 3;
    rightButton.badgeOriginY = -2;
    cartButton = rightButton;
    [self.navigationItem setRightBarButtonItem:rightButton];
    
    
    /*
    //draw line
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 76, 1)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1, 0, 0, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), 76, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.selectedBack addSubview:imageView];
    imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 29, 76, 1)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 39, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1, 0, 0, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), 76, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.selectedBack addSubview:imageView];
     */
    [self.catagoryTable addSubview:self.selectedBack];
    
    [self.navigationItem setTitle:@"菜单"];
    /*
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"order.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showService)];
    [self.navigationItem setLeftBarButtonItem:leftButton];
     */
        
    foodlistCellID = 0;
    shouldReset = NO;
    
    [self.foodTable setScrollsToTop:YES];
    [self.catagoryTable setScrollsToTop:YES];
    
    //slide-out
    // Add a shadow to the top view so it looks like it is on top of the others
    /*
    self.view.layer.shadowOpacity = 0.75;
    self.view.layer.shadowRadius = 10.0;
    self.view.layer.shadowColor = [[UIColor blackColor] CGColor];
     */
    // Tell it which view should be created under left
    /*
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[extra class]]) {
        self.slidingViewController.underLeftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"extra"];
    }
    */
    // Add the pan gesture to allow sliding
    //[self.view addGestureRecognizer:self.slidingViewController.panGesture];
}

- (void)showService {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationItem.backBarButtonItem setTitle:@"返回"];
    //[self.slidingViewController resetTopView];
    [orderInfo saveOrder];
}

- (void)refresh {
    followScroll = YES;
    
    if ([store getMenu] == nil || [store getMenu].count == 0) {
        [self.foodTable reloadData];
        [self.catagoryTable reloadData];
        return;
    }
    
    [self.navigationItem setTitle:[store getCurrentStoreName]];
    
    /*
    if ([store whiteLabel] && self.tabBarController.selectedIndex == 1) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        [self.navigationController.navigationBar setTranslucent:YES];
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
        [self.navigationController.navigationBar setTranslucent:YES];
    }
     */
    
    self.catagories = [store getCatagories];
    self.menuByCataAndDefault = [store getMenuSortedByCatagoriesAndDefault];
    self.menuByCataAndName = [store getMenuSortedByCatagoriesAndName];
    self.menuByCataAndPopularity = [store getMenuSortedByCatagoriesAndPopularity];
    self.menu = self.menuByCataAndPopularity; //for ordering switch
    if (shouldReset) {
        shouldReset = NO;
        followScroll = NO;
        NSIndexPath *tableTopCell = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.catagoryTable scrollToRowAtIndexPath:tableTopCell atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [self.foodTable scrollToRowAtIndexPath:tableTopCell atScrollPosition:UITableViewScrollPositionTop animated:NO];
        followScroll = YES;
        [self pickMenu:0];
    }
    
    [self.foodTable reloadData];
    [self.catagoryTable reloadData];
    
    [self reloadCartBadge];
    [self reloadCataCount];
    
    /*
    NSString *url = [NSString stringWithFormat:@"%@/images/store%@/logoimage/%@", SERVER_ADDRESS, [store getCurrentStoreID], @"topbar.png"];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [self.topimage setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"topimage.png"] options:SDWebImageRetryFailed];
     */
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
    
    [self.navigationItem setTitle:[store getCurrentStoreName]];
    /*
    if ([store whiteLabel]) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        [self.navigationController.navigationBar setTranslucent:YES];
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
        [self.navigationController.navigationBar setTranslucent:YES];
    }
     */
    
    if ([store preorder_mode]) {
        UIBarButtonItem *cancelPreorderModeButton = [[UIBarButtonItem alloc]initWithTitle:@"结束预订" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPreorder)];
        /*
        [cancelPreorderModeButton setBackgroundImage:[UIImage imageNamed:@"barRedBack.png"] forState:UIControlStateNormal style:UIBarButtonItemStylePlain barMetrics:UIBarMetricsDefault];
         */
        [cancelPreorderModeButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont boldSystemFontOfSize:17], NSFontAttributeName, [UIColor whiteColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
        [self.navigationItem setLeftBarButtonItem:cancelPreorderModeButton];
    }
}

- (void)cancelPreorder {
    [store set_preorder_mode:NO];
    [self.navigationItem setLeftBarButtonItem:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([store getMenu] == nil || [store getMenu].count == 0) {
        return;
    }
    
    NSUInteger showSection = [[self.foodTable indexPathForCell:[[self.foodTable visibleCells] objectAtIndex:0]] section];
    [self.selectedBack setFrame:CGRectMake(0, showSection * 40, 76, 40)];
    for (UIView *v in self.selectedBack.subviews) {
        if (v.tag == 1) {
            [((UILabel*)v) setText:[self.catagories objectAtIndex:showSection]];
        }
    }
    
    /*
    if ([store whiteLabel]) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
     */
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([store getMenu] == nil || [store getMenu].count == 0) {
        return;
    }
    
    if (scrollView.tag == 0) {
        if (followScroll) {
            NSUInteger showSection = [[self.foodTable indexPathForCell:[[self.foodTable visibleCells] objectAtIndex:0]] section];
            [self.selectedBack setFrame:CGRectMake(0, showSection * 40, 76, 40)];
            for (UIView *v in self.selectedBack.subviews) {
                if (v.tag == 1) {
                    [((UILabel*)v) setText:[self.catagories objectAtIndex:showSection]];
                }
            }
            NSIndexPath *ip2 = [NSIndexPath indexPathForRow:showSection inSection:0];
            [self.catagoryTable scrollToRowAtIndexPath:ip2 atScrollPosition:UITableViewScrollPositionTop animated:NO];
        } else {
            followScroll = YES;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView.tag == 0) {
        return self.menu.count;
    } else {
        return 1;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView.tag == 0) {
        //NSString *cataName = [self.catagories objectAtIndex:section];
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 76, 25)];
        [v setBackgroundColor:COFFEE_LIGHT];
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(5, 1, self.view.frame.size.width - 81, 22)];
        [title setText:[self.catagories objectAtIndex:section]];
        [title setTextAlignment:NSTextAlignmentLeft];
        [title setBackgroundColor:[UIColor clearColor]];
        [title setFont:[UIFont systemFontOfSize:15]];
        [v addSubview:title];
        
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 76, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), self.view.frame.size.width - 76, 0);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [v addSubview:imageView];
        
        imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 23.5, self.view.frame.size.width - 76, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), self.view.frame.size.width - 76, 0);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [v addSubview:imageView];
        
        return v;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView.tag == 0)
        return 24;
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([store getMenu] == nil || [store getMenu].count == 0) {
        return 0;
    }
    if (tableView.tag == 0) {
        return [[self.menu objectAtIndex:section] count];
    } else {
        return self.catagories.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 0) {
        return UI_TABLE_CELL_HEIGHT;
    } else {
        return 40;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    if (tableView.tag == 0) {
        singleItem *itemView = [storeList getItemDetailVC]; // [self.storyboard instantiateViewControllerWithIdentifier:@"itemDetails"];
        [itemView setGiftMode:NO];
        [extra setFoodID:[((foodInfo*)[[self.menu objectAtIndex:section] objectAtIndex:row]) getID]];
        [self.navigationController pushViewController:itemView animated:YES];
    } else {
        [self pickMenu:(int)row];
    }
    [self.catagoryTable deselectRowAtIndexPath:indexPath animated:NO];
    [self.foodTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (USE_NIL_CELL_ID) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:nil];
    } else {
        NSString *TableSampleIdentifier = [NSString stringWithFormat:@"tableCellID%d", foodlistCellID];
        foodlistCellID++;
        cell = [tableView dequeueReusableCellWithIdentifier:
                TableSampleIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:TableSampleIdentifier];
        }
    }
    
    if (tableView.tag == 0) {
        NSUInteger row = [indexPath row];
        NSUInteger section = [indexPath section];
        
        foodInfo *finfo = ((foodInfo*)[[self.menu objectAtIndex:section] objectAtIndex:row]);
        int foodCount = [orderInfo getCountForFood:[finfo getID]];
        
        float button_size = UI_TABLE_BUTTON_WIDTH, text_width = UI_TABLE_COUNT_WIDTH - 2;
        float cellWidth = self.view.frame.size.width - 76;
        
        UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(78, 10, cellWidth - 10 - 78, 18)];
        [labelTitle setFont:[UIFont systemFontOfSize:16]];
        [labelTitle setTextAlignment:NSTextAlignmentLeft];
        [labelTitle setTextColor:[UIColor blackColor]];
        [labelTitle setText:finfo.title];
        [cell addSubview:labelTitle];
        
        float gapOffset = 2.0;
        
        UILabel *labelprice = [[UILabel alloc] initWithFrame:CGRectMake(78, 28 + gapOffset, UI_TABLE_PRICE_WIDTH, 15)];
        [labelprice setFont:[UIFont systemFontOfSize:15]];
        [labelprice setTextAlignment:NSTextAlignmentLeft];
        [labelprice setTextColor:[UIColor redColor]];
        NSString *priceString = [NSString stringWithFormat:@"￥%.2f", [finfo getPrice]];
        [labelprice setText:priceString];
        [labelprice sizeToFit];
        [cell addSubview:labelprice];
        
        if (finfo.originalPrice != 0 && finfo.originalPrice > [finfo getPrice]) {
            UILabel *orilabelprice = [[UILabel alloc] initWithFrame:CGRectMake(labelprice.frame.origin.x + labelprice.frame.size.width + 5, 31 + gapOffset, UI_TABLE_PRICE_WIDTH, 12)];
            [orilabelprice setFont:[UIFont systemFontOfSize:12]];
            [orilabelprice setTextAlignment:NSTextAlignmentLeft];
            [orilabelprice setTextColor:[UIColor grayColor]];
            [orilabelprice setText: [NSString stringWithFormat:@"￥%.2f", finfo.originalPrice]];
            [orilabelprice sizeToFit];
            [cell addSubview:orilabelprice];
            
            //add line
            UIImageView *imageViewLine = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, orilabelprice.frame.size.width, orilabelprice.frame.size.height)];
            UIGraphicsBeginImageContext(CGSizeMake(imageViewLine.frame.size.width, imageViewLine.frame.size.height));
            [imageViewLine.image drawInRect:CGRectMake(0, 0, imageViewLine.frame.size.width, imageViewLine.frame.size.height)];
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 0.7);  //线宽
            CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.2, 0.2, 0.2, 1.0);  //颜色
            CGContextBeginPath(UIGraphicsGetCurrentContext());
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, imageViewLine.frame.size.height / 2);  //起点坐标
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), imageViewLine.frame.size.width, imageViewLine.frame.size.height / 2);   //终点坐标
            CGContextStrokePath(UIGraphicsGetCurrentContext());
            imageViewLine.image=UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [orilabelprice addSubview:imageViewLine];
        }
        
        UILabel *labeladd = [[UILabel alloc] initWithFrame:CGRectMake(78 + 17 - 1, 55, 35, 15)];
        [labeladd setFont:[UIFont systemFontOfSize:14]];
        [labeladd setTextAlignment:NSTextAlignmentLeft];
        [labeladd setTextColor:[UIColor colorWithWhite:0.55 alpha:1]];
        [labeladd setText:[[finfo.addition componentsSeparatedByString:@":"] objectAtIndex:0]];
        [labeladd sizeToFit];
        [cell addSubview:labeladd];
        
        UIImageView *upImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star.png"]];
        [upImage setFrame:CGRectMake(78, labeladd.frame.origin.y, labeladd.frame.size.height - 2, labeladd.frame.size.height - 1)];
        [cell addSubview:upImage];
        
        if (/* DISABLES CODE */ (NO) && finfo.scoreToEarn > 0) {
            UILabel *labelscore = [[UILabel alloc] initWithFrame:CGRectMake(labeladd.frame.origin.x + labeladd.frame.size.width + 5, 56, 60, 15)];
            [labelscore setFont:[UIFont systemFontOfSize:13]];
            [labelscore setTextAlignment:NSTextAlignmentLeft];
            [labelscore setTextColor:COFFEE_VERY_DARK];
            [labelscore setText:[NSString stringWithFormat:@"+%d积分", finfo.scoreToEarn]];
            [cell addSubview:labelscore];
        }
        
        //right side
        UIButton *addButtonB = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [addButtonB setFrame:CGRectMake(cellWidth - 8 - button_size - 10, 0, button_size + 20, UI_TABLE_CELL_HEIGHT)];
        [addButtonB setBackgroundColor:[UIColor clearColor]];
        [addButtonB setTag:[finfo getID]];
        [addButtonB addTarget:self action:@selector(addToCart:) forControlEvents:UIControlEventTouchDown];
        [cell addSubview:addButtonB];
        
        UIButton *addButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [addButton setFrame:CGRectMake(cellWidth - 8 - button_size, 70 - button_size /*(80 - button_size) / 2*/, button_size, button_size)];
        [addButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [addButton setBackgroundColor:[UIColor clearColor]];
        [addButton setBackgroundImage:[UIImage imageNamed:@"add.png"] forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(addToCart:) forControlEvents:UIControlEventTouchDown];
        [addButton setTag:[finfo getID]];
        [cell addSubview:addButton];
        if (foodCount > 0) {
            UIButton *subButtonB = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [subButtonB setFrame:CGRectMake(cellWidth - 8 - 2 * button_size - text_width - 10, 0, button_size + 20, UI_TABLE_CELL_HEIGHT)];
            [subButtonB setBackgroundColor:[UIColor clearColor]];
            [subButtonB setTag:[finfo getID]];
            [subButtonB addTarget:self action:@selector(removeFromCart:) forControlEvents:UIControlEventTouchDown];
            [cell addSubview:subButtonB];
            
            UIButton *subButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [subButton setFrame:CGRectMake(cellWidth - 8 - 2 * button_size - text_width, 70 - button_size /*(80 - button_size) / 2*/, button_size, button_size)];
            [subButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [subButton setBackgroundColor:[UIColor clearColor]];
            [subButton setBackgroundImage:[UIImage imageNamed:@"sub.png"] forState:UIControlStateNormal];
            [subButton addTarget:self action:@selector(removeFromCart:) forControlEvents:UIControlEventTouchDown];
            [subButton setTag:[finfo getID]];
            [cell addSubview:subButton];
            
            UILabel *labelcount = [[UILabel alloc] initWithFrame:CGRectMake(cellWidth - 8 - button_size - text_width, 70 - button_size /*30*/, text_width, button_size)];
            [labelcount setFont:[UIFont systemFontOfSize:18]];
            [labelcount setTextAlignment:NSTextAlignmentCenter];
            [labelcount setTextColor:[UIColor blackColor]];
            NSString *countStr = [NSString stringWithFormat:@"%d", foodCount];
            [labelcount setText:countStr];
            [cell addSubview:labelcount];
        }
        
        //add image
        UIImageView *roundedView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 60, 60)];
        UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(10, roundedView.frame.size.height / 2 - 1, roundedView.frame.size.width - 20, 2)];
        [loading setProgress:0.0];
        [loading setProgressViewStyle:UIProgressViewStyleDefault];
        [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
        [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
        [roundedView addSubview:loading];
        NSString *url = [NSString stringWithFormat:@"%@/%@/dishimage/dish%d/%@", SERVER_ADDRESS, [store getCurrentStoreFolder], [finfo getID], finfo.image];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [roundedView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"noimage.png"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            float percentage = (float)receivedSize / (float)expectedSize;
            //update loading progress bar
            [loading setProgress:percentage];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            //dismiss loading progress bar
            [loading removeFromSuperview];
        }];
        [roundedView setContentMode:UIViewContentModeScaleAspectFill];
        CALayer *l = [roundedView layer];
        [l setMasksToBounds:YES];
        [l setCornerRadius:6.0];
        roundedView.frame = CGRectMake(10, 10, 60, 60);
        [cell addSubview:roundedView];
        
        //draw line
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, cellWidth, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.99, 0.99, 0.99, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), cellWidth, 0);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell addSubview:imageView];
        
        imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, UI_TABLE_CELL_HEIGHT - 0.5, cellWidth, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), cellWidth, 0);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell addSubview:imageView];
        [cell setBackgroundColor:[UIColor clearColor]];
    } else {
        UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, 73, 40)];
        [labelTitle setFont:[UIFont systemFontOfSize:13]];
        [labelTitle setTextAlignment:NSTextAlignmentLeft];
        [labelTitle setNumberOfLines:0];
        [labelTitle setLineBreakMode:NSLineBreakByCharWrapping];
        [labelTitle setTextColor:[UIColor whiteColor]];
        [labelTitle setText:[self.catagories objectAtIndex:[indexPath row]]];
        //draw line
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 39.5, 76, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1, 1, 1, 1);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), 76, 0);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell addSubview:imageView];
        [cell addSubview:labelTitle];
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    
    return cell;
}

- (void)addToCart:(id)sender {
    int foodid = (int)((UIButton*)sender).tag;
    [orderInfo addFood:foodid withCount:1];
    [self.foodTable reloadData];
    [self reloadCartBadge];
    [self reloadCataCount];
}

- (void)removeFromCart:(id)sender {
    int foodid = (int)((UIButton*)sender).tag;
    [orderInfo removeFood:foodid withCount:1];
    [self.foodTable reloadData];
    [self reloadCartBadge];
    [self reloadCataCount];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
