//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "recommend.h"
#import "singleItem.h"
#import "data.h"
#import "foodList.h"
#import "cart.h"
#import "extra.h"
#import "storeList.h"

@interface recommend ()

@property (atomic) NSInteger usingThreads;
@property (atomic) NSInteger doneLoading;

@property (nonatomic, assign) ESTScanType scanType;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (atomic, strong) NSArray *beaconsArray;

@property (atomic, strong) UIAlertView *indicatorAlert;
@property (atomic, strong) CustomIOS7AlertView *indicatorAlert7;

@property (atomic, strong) NSArray *arr;

@end

@implementation recommend

- (void)selectFood:(id)sender {
    int foodID = (int)((UIButton*)sender).tag - 10000;
    
    singleItem *itemView = [storeList getItemDetailVC]; // [self.storyboard instantiateViewControllerWithIdentifier:@"itemDetails"];
    [extra setFoodID:foodID];
    
    [self presentViewController:itemView animated:YES completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.tag == 0)
        return;
    
    int page = scrollView.contentOffset.x / 320;
    UIPageControl *pageControl = [self getPageControlForPanel:scrollView];
    pageControl.currentPage = page;
}

- (void)scrollViewToPage:(int)pageNum forView:(UIScrollView*)sview {
    [sview setContentOffset:CGPointMake(320 * pageNum, 0) animated:YES];
}


- (UIScrollView*)addPanelWithWidth:(int)width andHeight:(int)height atY:(int)y {
    UIScrollView *scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake((self.mainView.frame.size.width - width) / 2.0, y, width, height)];
    scrollView.contentSize = CGSizeMake(width, height);
    scrollView.delegate = self;
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [scrollView setShowsVerticalScrollIndicator:NO];
    [scrollView setClipsToBounds:YES];
    
    [self.mainView addSubview:scrollView];
    
    return scrollView;
}

- (UIPageControl*)getPageControlForPanel:(UIScrollView*)scrollView {
    if (scrollView.tag == 0)
        return nil;
        
    UIPageControl *pageControl;
    for (int i = 0; i < self.mainView.subviews.count; i++) {
        if (((UIView*)[self.mainView.subviews objectAtIndex:i]).tag == scrollView.tag - 100)
            pageControl = [self.mainView.subviews objectAtIndex:i];
    }
    return pageControl;
}

- (UIScrollView*)addPanelWithNumPages:(int)numPages andHeight:(int)height atY:(int)y {
    UIScrollView *scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, y, self.mainView.frame.size.width, height)];
    if (numPages > 1)
        [scrollView setTag:100 + scrollviewID];
    scrollView.contentSize = CGSizeMake(self.mainView.frame.size.width * numPages, height);
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [scrollView setShowsVerticalScrollIndicator:NO];
    [scrollView setClipsToBounds:YES];
    
    if (numPages > 1) {
    float rgb = 210.0 / 255.0;
        UIPageControl *pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(0, y + height, self.mainView.frame.size.width, UI_PAGECONTROL_HEIGHT)];
        [pageControl setTag:scrollviewID];
        [pageControl setCurrentPageIndicatorTintColor:[UIColor redColor]];
        [pageControl setPageIndicatorTintColor:[UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0]];
        pageControl.defersCurrentPageDisplay = YES;
        pageControl.hidesForSinglePage = YES;
        pageControl.numberOfPages = numPages;
        [pageControl setHidesForSinglePage:YES];
        [pageControl setEnabled:NO];
        [self.mainView addSubview:pageControl];
    }
    
    [self.mainView addSubview:scrollView];
    
    if (numPages > 1)
        scrollviewID++;
    
    return scrollView;
}

- (UIButton*)createButtonWithImageName:(NSString*)name withPosition:(CGRect)posn withFoodID:(int)foodID {
    UIButton *b1 = [[UIButton alloc]initWithFrame:posn];
    
    //load image
    UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(10, posn.size.height / 2.0 - 1, posn.size.width - 20, 2)];
    
    [loading setProgress:0.0];
    [loading setProgressViewStyle:UIProgressViewStyleDefault];
    [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
    [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@", SERVER_ADDRESS, [store getCurrentStoreFolder], name];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:url] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        float percentage = (float)receivedSize / (float)expectedSize;
        //update loading progress bar
        [loading setProgress:percentage];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
        [loading removeFromSuperview];
        if (image != nil && finished) {
            UIImage *img = [HTTPRequest cropToSize:image toSize:posn.size];
            [b1 setBackgroundImage:img forState:UIControlStateNormal];
            [b1 setBackgroundImage:img forState:UIControlStateHighlighted];
            [b1 setBackgroundImage:img forState:UIControlStateSelected];
        }
    }];

    UIImage *img = [UIImage imageNamed:@"noimage.png"];
    img = [HTTPRequest cropToSize:img toSize:posn.size];
    [b1 setBackgroundImage:img forState:UIControlStateNormal];
    [b1 setBackgroundImage:img forState:UIControlStateHighlighted];
    [b1 setBackgroundImage:img forState:UIControlStateSelected];
    
    [b1 setTag:10000 + foodID];
    [b1 addTarget:self action:@selector(selectFood:) forControlEvents:UIControlEventTouchUpInside];
    
    [b1 addSubview:loading];
    
    //rounded button
    CALayer *l = [b1 layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:6.0];
    
    return b1;
}

- (UIButton*)createCubicButtonWithImageName:(NSString*)name withPosition:(CGRect)posn withFoodID:(int)foodID {
    UIButton *b1 = [[UIButton alloc]initWithFrame:posn];
    
    //load image
    UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(5, posn.size.height / 2.0 - 1, posn.size.width - 10, 2)];
    
    [loading setProgress:0.0];
    [loading setProgressViewStyle:UIProgressViewStyleDefault];
    [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
    [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@", SERVER_ADDRESS, [store getCurrentStoreFolder], name];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:url] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        float percentage = (float)receivedSize / (float)expectedSize;
        //update loading progress bar
        [loading setProgress:percentage];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
        [loading removeFromSuperview];
        if (image != nil && finished) {
            UIImage *img = [HTTPRequest cropToSquare:image];
            [b1 setBackgroundImage:img forState:UIControlStateNormal];
            [b1 setBackgroundImage:img forState:UIControlStateHighlighted];
            [b1 setBackgroundImage:img forState:UIControlStateSelected];
        }
    }];
    UIImage *img = [UIImage imageNamed:@"noimage.png"];
    img = [HTTPRequest cropToSquare:img];
    [b1 setBackgroundImage:img forState:UIControlStateNormal];
    [b1 setBackgroundImage:img forState:UIControlStateHighlighted];
    [b1 setBackgroundImage:img forState:UIControlStateSelected];
    
    [b1 setTag:10000 + foodID];
    [b1 addTarget:self action:@selector(selectFood:) forControlEvents:UIControlEventTouchUpInside];
    
    [b1 addSubview:loading];
    
    //rounded button
    CALayer *l = [b1 layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:6.0];
    
    return b1;
}

- (UIButton*)createButtonWithImageName:(NSString*)name andText:(NSString*)text withPosition:(CGRect)posn withFoodID:(int)foodID {
    UIButton *b1 = [[UIButton alloc] initWithFrame:posn];
    
    //load image
    UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(10, posn.size.height / 2.0 - 1, posn.size.width - 20, 2)];
    
    [loading setProgress:0.0];
    [loading setProgressViewStyle:UIProgressViewStyleDefault];
    [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
    [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@", SERVER_ADDRESS, [store getCurrentStoreFolder], name];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:url] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        float percentage = (float)receivedSize / (float)expectedSize;
        //update loading progress bar
        [loading setProgress:percentage];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
        [loading removeFromSuperview];
        if (image != nil && finished) {
            UIImage *img = [HTTPRequest cropToSize:image toSize:posn.size];
            [b1 setBackgroundImage:img forState:UIControlStateNormal];
            [b1 setBackgroundImage:img forState:UIControlStateHighlighted];
            [b1 setBackgroundImage:img forState:UIControlStateSelected];
        }
    }];
    
    UIImage *img = [UIImage imageNamed:@"noimage.png"];
    img = [HTTPRequest cropToSize:img toSize:posn.size];
    //reset frame in image size
    [b1 setBackgroundImage:img forState:UIControlStateNormal];
    [b1 setBackgroundImage:img forState:UIControlStateHighlighted];
    [b1 setBackgroundImage:img forState:UIControlStateSelected];
    //add text
    if (text != nil) {
        UILabel *subl = [[UILabel alloc]initWithFrame:CGRectMake(10, b1.frame.size.height - 28, b1.frame.size.width - 20, 30)];
        [subl setTextAlignment:NSTextAlignmentLeft];
        [subl setFont:UI_TEXT_FONT];
        [subl setTextColor:[UIColor whiteColor]];
        [subl setText:text];
        [subl setShadowColor:[UIColor grayColor]];
        [subl setShadowOffset:CGSizeMake(1, 1)];
        [b1 addSubview:subl];
    }
    
    [b1 setTag:10000 + foodID];
    [b1 addTarget:self action:@selector(selectFood:) forControlEvents:UIControlEventTouchUpInside];
    
    [b1 addSubview:loading];
    
    //rounded button
    CALayer *l = [b1 layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:6.0];
    
    return b1;
}

- (void)drawLine:(int)x andY:(int)y andWidth:(int)w onScrollView:(UIScrollView*)sv {
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(x, y, w, 0.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), 300, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [sv addSubview:imageView];
}

- (void)addCombination:(NSString*)title toScrollView:(UIScrollView*)scrollView withFood1:(int)foodID1 withFood2:(int)foodID2 withFood3:(int)foodID3 onPage:(int)pageNum atY:(int)y {
    float h = 60, singleFoodWidth = 50, foodGap = 5, margin = 10;
    UILabel *l1 =[[UILabel alloc] init];
    [l1 setTextAlignment:NSTextAlignmentLeft];
    [l1 setFont:[UIFont systemFontOfSize:16]];
    [l1 setText:title];
    [l1 setFrame:CGRectMake(320 * pageNum + margin, y /*y + h / 2.0 - 15*/, 100, h)];
    [scrollView addSubview:l1];
    
    [self drawLine:320 * pageNum + 9 andY:y andWidth:302 onScrollView:scrollView];
    [self drawLine:320 * pageNum + 9 andY:y + h andWidth:302 onScrollView:scrollView];

    UILabel *eq =[[UILabel alloc] init];
    [eq setTextAlignment:NSTextAlignmentLeft];
    [eq setFont:[UIFont systemFontOfSize:16]];
    [eq setText:@"="];
    [eq setFrame:CGRectMake(320 * pageNum + 120, y /*y + h / 2.0 - 15*/, 20, h)];
    [scrollView addSubview:eq];
    
    UIButton *food1Button = [self createButtonWithImageName:((foodInfo*)[[store getMenu] objectAtIndex:foodID1]).image withPosition:CGRectMake(320 + 320 * pageNum - margin -  3 * singleFoodWidth - 2 * foodGap, y + (h - singleFoodWidth) / 2.0, singleFoodWidth, singleFoodWidth) withFoodID:foodID1];
    UIButton *food2Button = [self createButtonWithImageName:((foodInfo*)[[store getMenu] objectAtIndex:foodID2]).image withPosition:CGRectMake(320 + 320 * pageNum - margin -  2 * singleFoodWidth - 1 * foodGap, y + (h - singleFoodWidth) / 2.0, singleFoodWidth, singleFoodWidth) withFoodID:foodID2];
    UIButton *food3Button = [self createButtonWithImageName:((foodInfo*)[[store getMenu] objectAtIndex:foodID3]).image withPosition:CGRectMake(320 + 320 * pageNum - margin -  singleFoodWidth, y + (h - singleFoodWidth) / 2.0, singleFoodWidth, singleFoodWidth) withFoodID:foodID3];
    [scrollView addSubview:food1Button];
    [scrollView addSubview:food2Button];
    [scrollView addSubview:food3Button];
}

- (float)addLabel:(NSString*)text toPanel:(UIScrollView*)panel onPage:(int)pageNum atY:(int)y textType:(int)type {
    UILabel *l1 =[[UILabel alloc] init];
    [l1 setTextAlignment:NSTextAlignmentCenter];
    
    if (type == UI_TYPE_TITLE) {
        [l1 setFont:UI_TITLE_FONT];
        [l1 setFrame:CGRectMake(panel.frame.size.width * pageNum, y, panel.frame.size.width, UI_TITLE_HEIGHT)];
    } else {
        [l1 setFont:UI_TEXT_FONT];
        [l1 setFrame:CGRectMake(panel.frame.size.width * pageNum, y, panel.frame.size.width, UI_TEXT_HEIGHT)];
    }
    
    [l1 setText:text];
    [panel addSubview:l1];
    if (type == UI_TYPE_TITLE) {
        return UI_TITLE_HEIGHT;
    } else {
        return UI_TEXT_HEIGHT;
    }
}

- (float)addHorizonButton:(UIScrollView*)scrollView onPage:(int)pageNum atY:(int)y image:(NSString*)image withText:(NSString*)text forFood:(NSString*)foodName {
    int fid = [store getFoodIDForFoodName:foodName];
    if (fid == -1) {
        return 0;
    }
    UIButton *b = [self createButtonWithImageName:image andText:text withPosition:CGRectMake(10 + scrollView.frame.size.width * pageNum, y + UI_HORIZON_IMAGE_MARGIN, scrollView.frame.size.width - 20, UI_HORIZON_IMAGE_HEIGHT) withFoodID:fid];
    [scrollView addSubview:b];
    return b.frame.size.height + UI_HORIZON_IMAGE_MARGIN;
}

- (float)addSpecials:(UIScrollView*)scrollViewSpecial withImage:(NSString*)image andFoodID:(int)ID at:(int)num {
    float buttonWidth = UI_CUBE_IMAGE_SIZE, buttonGap = UI_CUBE_IMAGE_MARGIN, boundary = 10;
    if (boundary * 2 + buttonGap * num + buttonWidth * num + buttonWidth > scrollViewSpecial.contentSize.width) {
        scrollViewSpecial.contentSize = CGSizeMake(boundary * 2 + buttonGap * num + buttonWidth * num + buttonWidth, scrollViewSpecial.contentSize.height);
    }
    if (image == nil)
        [scrollViewSpecial addSubview:[self createCubicButtonWithImageName:((foodInfo*)[[store getMenu] objectAtIndex:[store getIndexForFoodID:ID]]).image withPosition:CGRectMake(boundary + buttonGap * num + buttonWidth * num, buttonGap, buttonWidth, buttonWidth) withFoodID:ID]];
    else
        [scrollViewSpecial addSubview:[self createCubicButtonWithImageName:image withPosition:CGRectMake(boundary + buttonGap * num + buttonWidth * num, buttonGap, buttonWidth, buttonWidth) withFoodID:ID]];
    return UI_CUBE_IMAGE_SIZE + UI_CUBE_IMAGE_MARGIN * 2;
}

- (float)addSpecialText:(UIScrollView*)scrollViewSpecial andText:(NSString*)text at:(int)num andHeight:(int)h {
    float buttonWidth = UI_CUBE_IMAGE_SIZE, buttonGap = UI_CUBE_IMAGE_MARGIN, boundary = UI_CUBE_IMAGE_MARGIN;
    
    UILabel *l1 =[[UILabel alloc] init];
    [l1 setTextAlignment:NSTextAlignmentCenter];
    [l1 setFont:UI_TEXT_FONT];
    [l1 setFrame:CGRectMake(boundary + buttonGap * num + buttonWidth * num, buttonGap * 2 + buttonWidth + h, buttonWidth, UI_TEXT_HEIGHT)];
    [l1 setText:text];
    
    [scrollViewSpecial addSubview:l1];
    return UI_TEXT_HEIGHT;
}


- (float)processText:(NSArray*)content atHeight:(float)h {
    int i = 0;
    float totalHeight = 0.0;
    for (NSDictionary *item in content) {
        //create label
        if (i == 0)
            totalHeight += [self addLabel:[item objectForKey:@"text"] toPanel:self.mainView onPage:0 atY:h textType:UI_TYPE_TITLE];
        else
            totalHeight += [self addLabel:[item objectForKey:@"text"] toPanel:self.mainView onPage:0 atY:h + (i - 1) * UI_TEXT_HEIGHT + UI_TITLE_HEIGHT textType:UI_TYPE_TEXT];
        i++;
    }
    
    return totalHeight;
}

- (float)processHorizonView:(NSArray*)uispec atHeight:(float)h {
    float totalHeight = 0.0;
    
    //create scrollview
    UIScrollView *scrollView = [self addPanelWithNumPages:(int)uispec.count andHeight:5 atY:h];
    
    int pageNum = 0;
    for (NSDictionary *item in uispec) {
        float tempHeight = 0.0;
        NSString *type = [item objectForKey:@"type"];
        if (type == nil || [type isEqualToString:@""]) {
            type = @"horizon";
        }
        
        if ([type isEqualToString:@"horizon"]) {
            //add text
            int i = 0;
            float h2 = 0.0;
            NSArray *strings = [item objectForKey:@"text"];
            for (NSDictionary *dic in strings) {
                NSString *text = [dic objectForKey:@"text"];
                if (i == 0)
                    h2 += [self addLabel:text toPanel:scrollView onPage:pageNum atY:0 textType:UI_TYPE_TITLE];
                else
                    h2 += [self addLabel:text toPanel:scrollView onPage:pageNum atY:(i - 1) * UI_TEXT_HEIGHT + UI_TITLE_HEIGHT textType:UI_TYPE_TEXT];
                i++;
            }
            tempHeight += h2;
            
            //add image
            NSArray *imageItems = [item objectForKey:@"content"];
            for (NSDictionary *imagesItem in imageItems) {
                NSString *foodName = [imagesItem objectForKey:@"foodName"];
                NSString *imageName = [imagesItem objectForKey:@"image"];
                NSString *imageText = [imagesItem objectForKey:@"text"];
                //add button
                tempHeight += [self addHorizonButton:scrollView onPage:pageNum atY:tempHeight image:imageName withText:imageText forFood:foodName];
            }
        }
        
        if (tempHeight > totalHeight) {
            totalHeight = tempHeight;
        }
        
        pageNum++;
    }
    
    [scrollView setFrame:CGRectMake(0, h, self.mainView.frame.size.width, totalHeight)];
    if (uispec.count > 1) {
        [[self getPageControlForPanel:scrollView] setFrame:CGRectMake(0, h + totalHeight, self.mainView.frame.size.width, UI_PAGECONTROL_HEIGHT)];
        totalHeight += UI_PAGECONTROL_HEIGHT;
    }
    
    return totalHeight;
}

- (float)processCubeView:(NSArray*)uispec atHeight:(float)h {
    //create scrollview
    UIScrollView *scrollView = [self addPanelWithWidth:self.mainView.frame.size.width andHeight:5 atY:h];
    float totalHeight = 0.0;
    int i = 0;
    for (NSDictionary *item in uispec) {
        float tempHeight = 0.0;
        NSString *image = [item objectForKey:@"image"];
        if ([image isEqualToString:@""]) {
            image = nil;
        }
        NSString *foodName = [item objectForKey:@"foodName"];
        NSArray *strings = [item objectForKey:@"text"];
        //add button
        int fid = [store getFoodIDForFoodName:foodName];
        if (fid == -1)
            continue;
        tempHeight += [self addSpecials:scrollView withImage:image andFoodID:fid at:i];
        
        float h2 = 0.0;
        for (NSDictionary *dic in strings) {
            NSString *text = [dic objectForKey:@"text"];
            //add text
            h2 += [self addSpecialText:scrollView andText:text at:i andHeight:h2];
            
        }
        tempHeight += h2;
        
        if (tempHeight > totalHeight) {
            totalHeight = tempHeight;
        }
        
        i++;
    }
    
    [scrollView setFrame:CGRectMake(0, h, self.mainView.frame.size.width, totalHeight)];
    
    return totalHeight;
}

- (void)processMainPageJSON:(NSArray*)uispec {
    float height = 0.0;
    for (NSDictionary *item in uispec) {
        NSString *type = [item objectForKey:@"type"];
        NSArray *content = [item objectForKey:@"content"];
        float needHeight = 0.0;
        if ([type isEqualToString:@"text"]) {
            needHeight = [self processText:content atHeight:height];
        } else if ([type isEqualToString:@"horizon"]) {
            needHeight = [self processHorizonView:content atHeight:height];
        } else if ([type isEqualToString:@"cube"]) {
            needHeight = [self processCubeView:content atHeight:height];
        }
        height += needHeight;
    }
    height += 5;
    
    if (height > self.mainView.frame.size.height)
        [self.mainView setContentSize:CGSizeMake(self.mainView.frame.size.width, height)];
}

- (void)reloadStoreForMajor:(int)major andMinor:(int)minor {
    //self.indicatorAlert = [[UIAlertView alloc]initWithTitle:@"餐厅切换中..." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    //[self.indicatorAlert show];
    if ([store storeChanged:major andMinor:minor]) {
        beaconLocated = YES;
        self.arr = [NSArray arrayWithObjects:[NSNumber numberWithInt:major], [NSNumber numberWithInt:minor], nil];
    }
    if (beaconLocated)
        [NSThread detachNewThreadSelector:@selector(loadPageAsync) toTarget:self withObject:nil];
}

- (void)loadPageAsync {
    if (self.usingThreads > 0) {
        return;
    }
    self.usingThreads++;
    
    [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:NO];
    //[[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:NO];
    
    self.doneLoading = 0;
    while (self.doneLoading == 0) {
        int major = [(NSNumber*)[self.arr objectAtIndex:0] intValue], minor = [(NSNumber*)[self.arr objectAtIndex:1] intValue];
        
        //删除所有已有信息
        for (UIView *sv in self.mainView.subviews)
            [sv removeFromSuperview];
        scrollviewID = 1;
        
        UILabel *note = [[UILabel alloc] initWithFrame:self.view.frame];
        [note setTextAlignment:NSTextAlignmentCenter];
        [note setTextColor:[UIColor blackColor]];
        [note setFont:[UIFont systemFontOfSize:24]];
        [note setText:@"加载中..请稍后"];
        [self.mainView addSubview:note];
        
        [self.mainView setContentSize:CGSizeMake(self.mainView.frame.size.width, self.mainView.frame.size.height)];
        
        //加载信息
        if (![store setCurrentStoreMajor:major andMinor:minor]) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
            continue;
        }
        NSArray *json = [store getCurrentStoreMainPage];
        if (json == nil) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
            continue;
        }
        
        //show page
        NSLog(@"LOADING MAIN PAGE...");
        [self processMainPageJSON:json];
        
        [note removeFromSuperview];
        NSLog(@"STORE LOAD COMPLETED");
        
        self.doneLoading = 1;
        
        //done
        [self reloadCartBadge];
    }
    //[self.indicatorAlert dismissWithClickedButtonIndex:0 animated:YES];
    [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:YES];
    //[[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:YES];
    
    self.usingThreads--;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //default
    beaconLocated = NO;
    self.scanType = ESTScanTypeBeacon;
    scrollviewID = 1;
    
    //UI specs
    [self.mainView setClipsToBounds:YES];
    //self.tabBarController.tabBar.translucent = YES;
    [self.mainView setShowsHorizontalScrollIndicator:NO];
    [self.mainView setShowsVerticalScrollIndicator:NO];
}

-(void)viewDidAppear:(BOOL)animated {
    [self reloadCartBadge];
    
    if (RECOMMAND_DISCOVERY) {
        //beacons
        self.beaconManager = [[ESTBeaconManager alloc] init];
        self.beaconManager.delegate = self;
        self.region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                      identifier:@"UnicafeRegion"];
    
        if (self.scanType == ESTScanTypeBeacon)
            [self.beaconManager startRangingBeaconsInRegion:self.region];
        else
            [self.beaconManager startEstimoteBeaconsDiscoveryForRegion:self.region];
    
        //don't show alertview if already found one
        if (beaconLocated)
            return;
        
        //lock tabs
        [[[[self.tabBarController tabBar]items]objectAtIndex:1]setEnabled:NO];
        //[[[[self.tabBarController tabBar]items]objectAtIndex:2]setEnabled:NO];
    
        /*
        //show searching indicator
        self.indicatorAlert7 = [[CustomIOS7AlertView alloc] init];
        
        UIView *indView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 115)];
        UILabel *l1 =[[UILabel alloc] init];
        [l1 setTextAlignment:NSTextAlignmentCenter];
        [l1 setFont:[UIFont systemFontOfSize:18]];
        [l1 setText:@"正在搜索附近的餐厅..."];
        [l1 setFrame:CGRectMake(0, 0, 290, 60)];
        [indView addSubview:l1];
        //add a spinning activity indicator
        [self.indicatorAlert7 setContainerView:indView];
        [self.indicatorAlert7 setButtonTitles:nil];
        [self.indicatorAlert7 setUseMotionEffects:true];
        [self.indicatorAlert7 show];
         */
    
        /* test */
        if (SIMULATE_BEACON && DEBUG_MODE) {
            if (SIMULATE_BEACON_2)
                [self processBeacon:MAJOR2 andMinor:MINOR2];
            else
                [self processBeacon:MAJOR1 andMinor:MINOR1];
        
            //switch
            /*
            if (!USE_BEACON2)
             [self processBeacon:MAJOR2 andMinor:MINOR2];
             else
             [self processBeacon:MAJOR1 andMinor:MINOR1];
             */
        }
    }
    /*
     else if (storeChanged) {
        [self reloadStoreMainPage];
     }
     */
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.beaconManager stopRangingBeaconsInRegion:self.region];
    //[self.beaconManager stopEstimoteBeaconDiscovery];
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

- (void)processBeacon:(int)major andMinor:(int)minor {
    //stop beacon searching
    /*
     [self.beaconManager stopRangingBeaconsInRegion:self.region];
     [self.beaconManager stopEstimoteBeaconDiscovery];
     */
    
    //dismiss searching view
    /*
    if (!beaconLocated) {
        [self.indicatorAlert7 close];
        beaconLocated = YES;
    }
     */
    
    [self reloadStoreForMajor:major andMinor:minor];
}

- (void)onLocateBeacons:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region {
    if (/*beaconLocated || */beacons.count == 0)
        return;
    
    self.beaconsArray = beacons;
    NSLog(@"found %d beacons", (int)self.beaconsArray.count);
    
    //get nearest beacon
    int ma = 0, mi = 0;
    float dis = 999999.0;
    for (int i = 0; i < self.beaconsArray.count; i++) {
        ESTBeacon *beacon = [self.beaconsArray objectAtIndex:i];
        
        if (self.scanType == ESTScanTypeBeacon)
        {
            if (beacon.distance.floatValue > 0.0 && beacon.distance.floatValue < dis) {
                dis = beacon.distance.floatValue;
                ma = beacon.major.intValue;
                mi = beacon.minor.intValue;
            }
            NSLog(@"beacon: major %d, minor %d, distance %.2f", beacon.major.intValue, beacon.minor.intValue, beacon.distance.floatValue);
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"didRangeBeacons" message:@"不支持ESTScanTypeBluetooth" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
        }
    }
    
    if (dis > 999990.0) {
        return;
    }
    
    [self processBeacon:ma andMinor:mi];
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
