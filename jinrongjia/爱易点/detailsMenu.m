//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "detailsMenu.h"
#import "data.h"
#import "singleItem.h"
#import "cart.h"
#import "storeList.h"
#import "storeDetails.h"

#import <QuartzCore/QuartzCore.h>
#import "ECSlidingViewController.h"
#import "extra.h"

#define USER_BEGIN_LOADGING [NSThread detachNewThreadSelector:@selector(beginLoading) toTarget:self withObject:nil];
#define USER_END_LOADGING [NSThread detachNewThreadSelector:@selector(endLoading) toTarget:self withObject:nil];

@interface detailsMenu ()

@end

static BOOL returnFromSingleItem = NO;
static int detailsFoodlistCellID;

@implementation detailsMenu

+ (void)askForReset {
    returnFromSingleItem = NO;
}

- (void)goStore {
    if ([store setCurrentStore:[NSString stringWithFormat:@"%d", self.storeInfo.storeID]]) {
        [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:YES];
        //[[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:YES];
        [self.tabBarController setSelectedIndex:1];
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
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
    [self.catagoryTable addSubview:self.selectedBack];

    detailsFoodlistCellID = 0;
    self.menuOriginal = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    followScroll = YES;
        
    if (returnFromSingleItem) {
        /*
        if ([self.storeInfo whiteName]) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
            [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
            [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
            self.navigationController.navigationBar.shadowImage = [UIImage new];
            [self.navigationController.navigationBar setTranslucent:YES];
        } else {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
            [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
            [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
            [self.navigationController.navigationBar setTranslucent:YES];
        }
         */
        [self menuLoadDone];
    } else if (!self.giftMode) {
        [self setStoreDetailInfo:[storeDetails getPassedStoreDetails]];
    } else {
        any_store *thisStore = [[any_store alloc]init];
        [thisStore setStoreID:[[store getCurrentStoreID] intValue]];
        [self setStoreDetailInfo:thisStore];
    }
    
    if (self.menuOriginal == nil || self.menuOriginal.count == 0) {
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
    NSString *url = [NSString stringWithFormat:@"%@/images/store%d/logoimage/%@", SERVER_ADDRESS, [self.storeInfo storeID], @"topbar.png"];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [self.topimage setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"topimage.png"] options:SDWebImageRetryFailed];
     */
}

- (void)beginLoading {
    BEGIN_LOADING
}

- (void)endLoading {
    END_LOADING
}

- (void)setStoreDetailInfo:(any_store*)sinfo {
    USER_BEGIN_LOADGING
    
    self.storeInfo = sinfo;
    
    [self.navigationItem setTitle:@"菜单"];
    if (self.giftMode) {
        [self.navigationItem setTitle:@"咖啡墙 - 选咖啡"];
    }
    /*
    if ([self.storeInfo whiteName]) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"empty.png"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        [self.navigationController.navigationBar setTranslucent:YES];
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
        [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
        [self.navigationController.navigationBar setTranslucent:YES];
    }
     */
    
    [self loadingMenu];
}

- (void)loadingMenu {
    self.menuOriginal = [store getMenuOfStore:[NSString stringWithFormat:@"%d", self.storeInfo.storeID]];
    if (self.menuOriginal == nil) {
        USER_END_LOADGING
        [self.navigationController popViewControllerAnimated:YES];
        return;
    } else {
        if (self.showOnlyDiscount) {
            NSMutableArray *discounted = [[NSMutableArray alloc]init];
            for (foodInfo *finfo in self.menuOriginal) {
                if (finfo.originalPrice != 0.0 && [finfo getPrice] < finfo.originalPrice) {
                    [discounted addObject:finfo];
                }
            }
            self.menuOriginal = discounted;
        }
        [self menuLoadDone];
    }
}

- (void)menuLoadDone {
    if (self.menuOriginal == nil || self.menuOriginal.count == 0) {
        return;
    }
    
    self.catagories = [store getCatagorisOfMenu:self.menuOriginal];
    self.menuByCataAndDefault = [store getMenuSortedByCatagoriesAndDefaultOfMenu:self.menuOriginal];
    self.menuByCataAndName = [store getMenuSortedByCatagoriesAndNameOfMenu:self.menuOriginal];
    self.menuByCataAndPopularity = [store getMenuSortedByCatagoriesAndPopularityOfMenu:self.menuOriginal];
    self.menu = self.menuByCataAndPopularity; //for ordering switch
    if (returnFromSingleItem)
        returnFromSingleItem = NO;
    else {
        [self.foodTable setScrollsToTop:YES];
        [self.foodTable reloadData];
        [self.catagoryTable reloadData];
        [self pickMenu:0];
    }
    
    USER_END_LOADGING
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.menuOriginal == nil || self.menuOriginal.count == 0) {
        return;
    }
    
    if (scrollView.tag == 0) {
        NSUInteger showSection = [[self.foodTable indexPathForCell:[[self.foodTable visibleCells] objectAtIndex:0]] section];
        if (followScroll) {
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.menuOriginal == nil || self.menuOriginal.count == 0) {
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
        [itemView setGiftMode:self.giftMode];
        [extra setFoodID:-self.storeInfo.storeID];
        [extra setFoodInfo:((foodInfo*)[[self.menu objectAtIndex:section] objectAtIndex:row])];
        
        returnFromSingleItem = YES;
        //[self presentViewController:itemView animated:YES completion:nil];
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
        NSString *TableSampleIdentifier = [NSString stringWithFormat:@"tableCellID%d", detailsFoodlistCellID];
        detailsFoodlistCellID++;
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
            [labelscore setText:[NSString stringWithFormat:@"+%d分", finfo.scoreToEarn]];
            [cell addSubview:labelscore];
        }
        
        //add image
        UIImageView *roundedView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 60, 60)];
        UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(10, roundedView.frame.size.height / 2 - 1, roundedView.frame.size.width - 20, 2)];
        [loading setProgress:0.0];
        [loading setProgressViewStyle:UIProgressViewStyleDefault];
        [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
        [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
        [roundedView addSubview:loading];
        NSString *url = [NSString stringWithFormat:@"%@/%@/dishimage/dish%d/%@", SERVER_ADDRESS, [NSString stringWithFormat:@"images/store%d", self.storeInfo.storeID], [finfo getID], finfo.image];
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
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 79.5, cellWidth, 0.5)];
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
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1, 1, 1, 1.0);  //颜色
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
