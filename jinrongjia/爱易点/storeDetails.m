//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "storeDetails.h"
#import "detailsMenu.h"
#import "creditMallList.h"
#import "storeIntro.h"
#import <MapKit/MapKit.h>

static int infoDetailCellID;
static any_store *storeDetailsPassed;

@interface storeDetails ()

@property (strong, atomic) UIViewController *b_mapViewController;
//@property (strong, atomic) BMKMapView* b_mapView;

@end

@implementation storeDetails

@synthesize b_mapViewController;
//@synthesize b_mapView;

- (void)refreshCollectButton {
    if (storeDetailsPassed.collected)
        [self.collect setTitle:UNCOLLECT forState:UIControlStateNormal];
    else
        [self.collect setTitle:COLLECT forState:UIControlStateNormal];
}

- (IBAction)doCollect:(id)sender {
    if ([user getCurrentID] == nil) {
        [HTTPRequest alert:@"您还没有登陆"];
        return;
    }
    if (!storeDetailsPassed.collected) {
        //if not collected
        if ([user collectStore:storeDetailsPassed.storeID]) {
            storeDetailsPassed.collected = YES;
        }
    } else {
        //if collected
        if ([user unCollectStore:storeDetailsPassed.storeID]) {
            storeDetailsPassed.collected = NO;
        }
    }
    [self refreshCollectButton];
}

+ (any_store*)getPassedStoreDetails {
    return storeDetailsPassed;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    infoDetailCellID = 0;
    
    UINavigationItem *item = self.navigationItem;
    
    [item setTitle:@"咖啡厅"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.infotable setBackgroundColor:COFFEE_LIGHT];
    
    [self.navigationItem.backBarButtonItem setTitle:@"返回"];
    
    [self.storetitle setNumberOfLines:0];
    [self.storetitle setLineBreakMode:NSLineBreakByCharWrapping];
    
    storeDetailsPassed = [storeList getDetails];
    
    UINavigationItem *item = self.navigationItem;
    [item setTitle:storeDetailsPassed.title];
    
    [self refreshCollectButton];
    
    //set UI
    if (storeDetailsPassed.title.length <= 10) {
        [self.storetitle setFont:[UIFont systemFontOfSize:18]];
    } else {
        [self.storetitle setFont:[UIFont systemFontOfSize:16]];
    }
    [self.storetitle setText:storeDetailsPassed.title];
    CALayer *l = [self.supportIcon layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:3.0];
    l = [self.collect layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:5.0];
    if ([storeDetailsPassed support]) {
        [self.supportLabel setHidden:NO];
        [self.supportIcon setHidden:NO];
    } else {
        [self.supportLabel setHidden:YES];
        [self.supportIcon setHidden:YES];
    }
    
    [self.stars setText:@""];
    int numStars = round(storeDetailsPassed.rating * 2.0);
    int starNum = 0;
    for (starNum = 0; starNum < numStars / 2; starNum++) {
        UIImageView *starView = [[UIImageView alloc] initWithImage:[storeList getStarImage]];
        [starView setFrame:CGRectMake(15 * starNum, 0, 15, 15)];
        [self.stars addSubview:starView];
    }
    if (numStars % 2 == 1) {
        UIImageView *starView = [[UIImageView alloc] initWithImage:[storeList getStarImageHalfed]];
        [starView setFrame:CGRectMake(15 * starNum, 0, 15, 15)];
        [self.stars addSubview:starView];
    }
    
    if ([storeDetailsPassed avgPrice] != 0)
        [self.price setText:[NSString stringWithFormat:@"￥%.0f/人", [storeDetailsPassed avgPrice]]];
    else
        [self.price setText:@""];
    
    //async load image
    /*
    UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(5, self.image.frame.size.height / 2.0 - 1, self.image.frame.size.width - 10, 2)];
    [loading setProgress:0.0];
    [loading setProgressViewStyle:UIProgressViewStyleDefault];
    [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
    [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
    [self.image addSubview:loading];
     */
    NSString *url = [NSString stringWithFormat:@"%@/images/store%d/logoimage/%@", SERVER_ADDRESS, [storeDetailsPassed storeID], storeDetailsPassed.imageName];

    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [self.image setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"noimage.png"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        //float percentage = (float)receivedSize / (float)expectedSize;
        //update loading progress bar
        //[loading setProgress:percentage];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        //dismiss loading progress bar
        //[loading removeFromSuperview];
    }];
    [self.image setContentMode:UIViewContentModeScaleAspectFill];
    //rounded button
    CALayer *l2 = [self.image layer];
    [l2 setMasksToBounds:YES];
    [l2 setCornerRadius:10.0];
    
    [self.infotable setScrollsToTop:YES];
    [self.infotable reloadData];
    
    //scroll to top
    [self.infotable setScrollsToTop:YES];
    
    NSIndexPath *tableTopCell = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.infotable scrollToRowAtIndexPath:tableTopCell atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

//info table

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    return v;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 35;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return 35;
    }
    return 29;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (storeDetailsPassed.homepage) {
        return 4;
    }
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int hpoffset = 0;
    if (storeDetailsPassed.homepage) {
        hpoffset++;
    }
    if (indexPath.section < 2 + hpoffset) {
        if (indexPath.section == 0 + hpoffset) {
            switch (indexPath.row) {
                case 1:
                    return storeDetailsPassed.discount ? 44 : 0;
                    break;
                case 2:
                    return storeDetailsPassed.credit ? 44 : 0;
                    break;
                case 3:
                    return storeDetailsPassed.cash ? 44 : 0;
                    break;
                case 4:
                    return storeDetailsPassed.activity ? 44 : 0;
                    break;
                case 5:
                    return storeDetailsPassed.groupon ? 44 : 0;
                    break;
                default:
                    break;
            }
        }
        return 44;
    } else {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        NSDictionary *attribute = @{NSFontAttributeName:UI_TEXT_FONT, NSParagraphStyleAttributeName:paragraphStyle.copy};
        
        CGRect sizeTT = [@"测试文字" boundingRectWithSize:CGSizeMake(tableView.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        float margin = (44 - sizeTT.size.height) / 2;
        
        CGRect sizeT = [[storeDetailsPassed.notes objectAtIndex:indexPath.row] boundingRectWithSize:CGSizeMake(tableView.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        float h = sizeT.size.height + margin * 2;
        if (h < 44) {
            return 44;
        }
        return h;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int hpoffset = 0;
    if (storeDetailsPassed.homepage) {
        hpoffset++;
        
        if (section == 0)
            return 1;
    }
    if (section == 0 + hpoffset) {
        int rows = 6;
        if (storeDetailsPassed.preorder > 0) //预订/外带
            rows++;
        return rows;
    } else if (section == 1 + hpoffset) {
        int rows = 0;
        if (storeDetailsPassed.tel != nil && ![storeDetailsPassed.tel isEqualToString:@""])
            rows++;
        if (storeDetailsPassed.address != nil && ![storeDetailsPassed.address isEqualToString:@""])
            rows++;
        return rows;
    } else if (section == 2 + hpoffset) {
        return [storeDetailsPassed.notes count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (USE_NIL_CELL_ID) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:nil];
    } else {
        NSString *TableSampleIdentifier = [NSString stringWithFormat:@"tableCellID%d", infoDetailCellID];
        infoDetailCellID++;
        
        cell = [tableView dequeueReusableCellWithIdentifier:
                                 TableSampleIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:TableSampleIdentifier];
        }
    }
    
    int hpoffset = 0;
    if (storeDetailsPassed.homepage) {
        hpoffset++;
    }
    
    float cellHeight = 44;
    if (indexPath.section < 2 + hpoffset) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(16, 1, tableView.frame.size.width - 63, 43)];
        [l setNumberOfLines:0];
        [l setLineBreakMode:NSLineBreakByCharWrapping];
        if (storeDetailsPassed.homepage && indexPath.section == 0) {
            [l setText:@"本店介绍"];
        } if (indexPath.section == 0 + hpoffset) {
            switch (indexPath.row) {
                case 0:
                    [l setText:@"菜单预览"];
                    break;
                    
                case 1:
                    if (!storeDetailsPassed.discount) return cell;
                    [l setText:@"有你咖啡特价"];
                    break;
                    break;
                    
                case 2:
                    if (!storeDetailsPassed.credit) return cell;
                    [l setText:TITLE_CREDIT];
                    break;
                    
                case 3:
                    if (!storeDetailsPassed.cash) return cell;
                    [l setText:TITLE_CASH];
                    break;
                    
                case 4:
                    if (!storeDetailsPassed.activity) return cell;
                    [l setText:TITLE_ACTIVITY];
                    break;
                    
                case 5:
                    if (!storeDetailsPassed.groupon) return cell;
                    [l setText:TITLE_GROUPON];
                    break;
                    
                default:
                    if (storeDetailsPassed.preorder == 1)
                        [l setText:@"本日预订"];
                    else if (storeDetailsPassed.preorder == 2)
                        [l setText:@"本日预订/外带"];
                    break;
            }
            
            UILabel *go = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 26, 1, 10, 43)];
            [go setTextAlignment:NSTextAlignmentRight];
            [go setTextColor:COFFEE_VERY_DARK];
            [go setFont:UI_TITLE_FONT];
            [go setText:@"》"];
            [cell addSubview:go];
        } else if (indexPath.section == 1 + hpoffset) {
            NSString *goImg = nil;
            switch (indexPath.row) {
                case 0:
                    [l setText:[NSString stringWithFormat:@"%@", storeDetailsPassed.address]];
                    goImg = @"mapicon.png";
                    break;
                    
                default:
                    [l setText:[NSString stringWithFormat:@"%@", storeDetailsPassed.tel]];
                    goImg = @"phoneicon.png";
                    break;
            }
            UIImageView *go = [[UIImageView alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 37.5, 8, 28, 28)];
            [go setImage:[UIImage imageNamed:goImg]];
            [go setContentMode:UIViewContentModeScaleAspectFit];
            [cell addSubview:go];
        }
        
        [l setTextAlignment:NSTextAlignmentLeft];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    } else {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        NSDictionary *attribute = @{NSFontAttributeName:UI_TEXT_FONT, NSParagraphStyleAttributeName:paragraphStyle.copy};
        CGRect sizeTT = [@"测试文字" boundingRectWithSize:CGSizeMake(tableView.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        float margin = (44 - sizeTT.size.height) / 2;

        CGRect sizeT = [[storeDetailsPassed.notes objectAtIndex:indexPath.row] boundingRectWithSize:CGSizeMake(tableView.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        float h = sizeT.size.height + margin * 2;
        if (h > 44)
            cellHeight = h;
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(16, margin, tableView.frame.size.width - 32, sizeT.size.height)];
        [l setNumberOfLines:0];
        [l setText:[storeDetailsPassed.notes objectAtIndex:indexPath.row]];
        [l setLineBreakMode:NSLineBreakByCharWrapping];
        [l setTextAlignment:NSTextAlignmentLeft];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, cellHeight, tableView.frame.size.width, 0.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell addSubview:imageView];
    
    imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell addSubview:imageView];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int hpoffset = 0;
    if (storeDetailsPassed.homepage) {
        hpoffset++;
        
        if (indexPath.section == 0) {
            storeIntro *si = [self.storyboard instantiateViewControllerWithIdentifier:@"storeIntro"];
            [si setStoreInfoPassed:storeDetailsPassed];
            [self.navigationController pushViewController:si animated:YES];
        }
    }
    if (indexPath.section == 0 + hpoffset) {
        if (indexPath.row == 0) {
            detailsMenu *menuView = [self.storyboard instantiateViewControllerWithIdentifier:@"storeDetailsMenu"];
            [menuView setGiftMode:NO];
            [menuView setShowOnlyDiscount:NO];
            [detailsMenu askForReset];
            [self.navigationController pushViewController:menuView animated:YES];
        } else if (indexPath.row == 1) { //打折特价
            detailsMenu *menuView = [self.storyboard instantiateViewControllerWithIdentifier:@"storeDetailsMenu"];
            [menuView setGiftMode:NO];
            [menuView setShowOnlyDiscount:YES];
            [detailsMenu askForReset];
            [self.navigationController pushViewController:menuView animated:YES];
        } else if (indexPath.row == 2) { //积分商城
            creditMallList *v = [self.storyboard instantiateViewControllerWithIdentifier:@"creditMall"];
            [v setMall:@"credit"];
            [self.navigationController pushViewController:v animated:YES];
        } else if (indexPath.row == 3) { //周边商城
            creditMallList *v = [self.storyboard instantiateViewControllerWithIdentifier:@"creditMall"];
            [v setMall:@"cash"];
            [self.navigationController pushViewController:v animated:YES];
        } else if (indexPath.row == 4) { //活动/////////////////////////////////////////////////////////////////////////////////
            creditMallList *v = [self.storyboard instantiateViewControllerWithIdentifier:@"creditMall"];
            [v setMall:@"activity"];
            [self.navigationController pushViewController:v animated:YES];
        } else if (indexPath.row == 5) { //团购/////////////////////////////////////////////////////////////////////////////////
            creditMallList *v = [self.storyboard instantiateViewControllerWithIdentifier:@"creditMall"];
            [v setMall:@"groupon"];
            [self.navigationController pushViewController:v animated:YES];
        } else if (indexPath.row == 6) {
            if ([[NSString stringWithFormat:@"%d", storeDetailsPassed.storeID] isEqualToString:[store getCurrentStoreID]]) {
                if (![store preorder_mode])
                    [HTTPRequest alert:@"您不能在店内预订"];
                else
                    [self.tabBarController setSelectedIndex:1];
            } else if ([store setCurrentStore:[NSString stringWithFormat:@"%d", storeDetailsPassed.storeID]]) {
                [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:YES];
                UITabBarItem *baritem;
                for (UIViewController *v in self.tabBarController.viewControllers) {
                    if (v.tabBarItem.tag == 1) {
                        baritem = (UITabBarItem*)v.tabBarItem;
                    }
                }
                [baritem setBadgeValue:@"订"];
                [store set_preorder_mode:YES];
                //[[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:YES];
                [self.tabBarController setSelectedIndex:1];
                [[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:NO];
                [self.navigationController popToRootViewControllerAnimated:NO];
            } else {
                [HTTPRequest alert:NETWORK_ERROR];
            }
        }
    } else if (indexPath.section == 1 + hpoffset) {
        switch (indexPath.row) {
            case 0: //地图
                [self openMap];
                break;
                
            default: //电话
                if (storeDetailsPassed.tel != nil && ![storeDetailsPassed.tel isEqualToString:@""])
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", storeDetailsPassed.tel]]];
                break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)openMap {
    BEGIN_LOADING
    
    UIViewController *mapView = [[UIViewController alloc]init];
    [mapView.view setBackgroundColor:[UIColor whiteColor]];
    
    MKMapView *mkView = [[MKMapView alloc]initWithFrame:mapView.view.frame];
    [mapView.view addSubview:mkView];
    
    if (storeDetailsPassed.longitude == 0 && storeDetailsPassed.latitude == 0) {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder geocodeAddressString:storeDetailsPassed.address
                     completionHandler:^(NSArray* placemarks, NSError* error){
                         if (placemarks && placemarks.count > 0) {
                             CLPlacemark *topResult = [placemarks objectAtIndex:0];
                             MKPlacemark *placemark = [[MKPlacemark alloc] initWithPlacemark:topResult];
                             
                             CLLocationCoordinate2D dest = CLLocationCoordinate2DMake(placemark.coordinate.latitude, placemark.coordinate.longitude);
                             
                             if (USE_BAIDU_MAP) {
                                 //[self showRouteFromSelfToCoordinate:dest];
                             } else {
                                 MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
                                 MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithPlacemark:placemark]];
                                 
                                 toLocation.name = storeDetailsPassed.title;
                                 END_LOADING
                                 [MKMapItem openMapsWithItems:[NSArray arrayWithObjects:currentLocation, toLocation, nil] launchOptions:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeWalking, nil] forKeys:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeKey, nil]]];
                             }
                         }
                     }];
    } else {
        CLLocationCoordinate2D dest = CLLocationCoordinate2DMake(storeDetailsPassed.latitude, storeDetailsPassed.longitude);
        
        if (USE_BAIDU_MAP) {
            //[self showRouteFromSelfToCoordinate:dest];
        } else {
            MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
            MKMapItem *toLocation = [[MKMapItem alloc]initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:dest
                                                                                              addressDictionary:nil]];
            
            toLocation.name = storeDetailsPassed.title;
            END_LOADING
            [MKMapItem openMapsWithItems:[NSArray arrayWithObjects:currentLocation, toLocation, nil] launchOptions:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeWalking, nil] forKeys:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeKey, nil]]];
        }
    }
}

- (NSString*)base64decode:(NSString*)encodedString {
    // NSData from the Base64 encoded str
    NSData *nsdataFromBase64String = [[NSData alloc]
                                      initWithBase64EncodedString:encodedString options:0];
    
    // Decoded NSString from the NSData
    NSString *base64Decoded = [[NSString alloc]
                               initWithData:nsdataFromBase64String encoding:NSUTF8StringEncoding];
    
    return base64Decoded;
}

/*
- (void)showRouteFromSelfToCoordinate:(CLLocationCoordinate2D)coord {
    b_mapViewController = [[UIViewController alloc] init];
    b_mapView = [[BMKMapView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    b_mapView.delegate = self;
    [b_mapView setMapType:BMKMapTypeStandard];
    [b_mapViewController.view addSubview:b_mapView];
    
    CLLocationCoordinate2D from, to;
    
    BOOL showRoute = NO;
    //my location
    if ([storeList getCurrentLongitude] != 0 && [storeList getCurrentLatitude] != 0) {
        BMKPointAnnotation* myannotation = [[BMKPointAnnotation alloc] init];
        NSDictionary* convertedCoord = BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake([storeList getCurrentLatitude], [storeList getCurrentLongitude]), BMK_COORDTYPE_GPS);
        from = CLLocationCoordinate2DMake([[self base64decode:[convertedCoord objectForKey:@"y"]] doubleValue], [[self base64decode:[convertedCoord objectForKey:@"x"]] doubleValue]);
        myannotation.coordinate = from;
        myannotation.title = @"我";
        [b_mapView addAnnotation:myannotation];
        showRoute = YES;
    }
    
    //destination
    NSDictionary* convertedCoord = BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(coord.latitude, coord.longitude), BMK_COORDTYPE_GPS);
    to = CLLocationCoordinate2DMake([[self base64decode:[convertedCoord objectForKey:@"y"]] doubleValue], [[self base64decode:[convertedCoord objectForKey:@"x"]] doubleValue]);
    BMKPointAnnotation* destannotation = [[BMKPointAnnotation alloc] init];
    destannotation.coordinate = to;
    destannotation.title = storeDetailsPassed.title;
    [b_mapView addAnnotation:destannotation];
    
    //route
    if (showRoute) {
        
    }
    
    END_LOADING
    
    NSLog(@"%f, %f", coord.longitude, coord.latitude);
    NSLog(@"%f, %f", [storeList getCurrentLongitude], [storeList getCurrentLatitude]);
    NSLog(@"%f, %f", to.longitude, to.latitude);
    
    //set show region
    if (showRoute) {
        [b_mapView setRegion:BMKCoordinateRegionMake(CLLocationCoordinate2DMake((to.latitude + from.latitude) / 2.0,
                                                                                (to.longitude + from.longitude) / 2.0),
                                                     BMKCoordinateSpanMake(1.2 * ABS(to.latitude - from.latitude),
                                                                           1.2 * ABS(to.longitude - from.longitude)))];
    } else {
        [b_mapView setRegion:BMKCoordinateRegionMake(to, BMKCoordinateSpanMake(0.05, 0.05))];
    }
    
    [self.navigationController pushViewController:b_mapViewController animated:YES];
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation {
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        if ([[(BMKPointAnnotation*)annotation title] isEqualToString:@"我"]) {
            BMKPinAnnotationView *newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"meA"];
            newAnnotationView.pinColor = BMKPinAnnotationColorGreen;
            return newAnnotationView;
        } else {
            BMKPinAnnotationView *newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"destinationA"];
            newAnnotationView.pinColor = BMKPinAnnotationColorRed;
            return newAnnotationView;
        }
    }
    return nil;
}
 */

- (void)backToStores {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
