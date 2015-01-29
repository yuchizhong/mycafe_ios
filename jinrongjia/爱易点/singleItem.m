//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "singleItem.h"
#import "data.h"
#import "extra.h"
#import "storeList.h"
#import "wallSendInfo.h"

static int infoCellID;

@interface singleItem ()

@property (atomic) BOOL firstShow;
@property (atomic) BOOL enlargedImg;
@property (atomic) CGRect imgOrigSize;

@end

@implementation singleItem

- (void)setNewFood:(foodInfo *)foodIN {
    if (foodIN == nil) {
        return;
    }
    self.food = foodIN;
    
    self.desp = self.food.mainDescription;
    self.notes = [[self.food.note componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";；"]] mutableCopy];
    for (int i = (int)self.notes.count - 1; i >= 0; i--) {
        if ([self.notes objectAtIndex:i] == nil || [[self.notes objectAtIndex:i] isEqualToString:@""]) {
            [self.notes removeObjectAtIndex:i];
        }
    }
    
    [self.foodTitle setText:self.food.title];
    if (self.food.title.length > 12)
        [self.foodTitle setFont:[UIFont systemFontOfSize:10]];
    else if (self.food.title.length > 10)
        [self.foodTitle setFont:[UIFont systemFontOfSize:13]];
    else if (self.food.title.length > 8)
        [self.foodTitle setFont:UI_TEXT_FONT];
    else
        [self.foodTitle setFont:UI_TITLE_FONT];
    
    NSString *priceString = [NSString stringWithFormat:@"￥%.2f", [self.food getPrice]];
    [self.foodPrice setText: priceString];
    
    [self.upLabel setText:[[self.food.addition componentsSeparatedByString:@":"] objectAtIndex:0]];
    
    if (self.food.scoreToEarn > 0 && !self.giftMode) {
        [self.scoreLabel setText:[NSString stringWithFormat:@"+%d积分", self.food.scoreToEarn]];
    } else {
        [self.scoreLabel setText:@""];
    }
    
    //set image
    //async load image
    if (!self.firstShow) {
        UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(5, self.foodImageView.frame.size.height / 2.0 - 1, self.foodImageView.frame.size.width - 10, 2)];
        [loading setProgress:0.0];
        [loading setProgressViewStyle:UIProgressViewStyleDefault];
        [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
        [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
        [self.foodImageView addSubview:loading];
        NSString *url;
        if (foodId <= 0)
            url = [NSString stringWithFormat:@"%@/%@/dishimage/dish%d/%@", SERVER_ADDRESS, [NSString stringWithFormat:@"images/store%d", -foodId], [self.food getID], self.food.image];
        else
            url = [NSString stringWithFormat:@"%@/%@/dishimage/dish%d/%@", SERVER_ADDRESS, [store getCurrentStoreFolder], [self.food getID], self.food.image];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self.foodImageView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"noimage.png"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            float percentage = (float)receivedSize / (float)expectedSize;
            //update loading progress bar
            [loading setProgress:percentage];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            //dismiss loading progress bar
            [loading removeFromSuperview];
        }];
    }
    
    //rounded button
    CALayer *l = [self.foodImageView layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:10.0];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorref = CGColorCreate(colorSpace,(CGFloat[]){ 98.0/255.0, 62.0/255.0, 48.0/255.0, 1 });
    for (UIView *v in self.controlView.subviews) {
        [v removeFromSuperview];
    }
    if (foodId > 0 && !self.firstShow) {
        float button_size = 30;
        self.countLabel = [[UILabel alloc] initWithFrame:CGRectMake(button_size, 0, self.controlView.frame.size.width - 2 * button_size, self.controlView.frame.size.height)];
        [self.countLabel setFont:[UIFont systemFontOfSize:22]];
        [self.countLabel setTextAlignment:NSTextAlignmentCenter];
        [self.countLabel setTextColor:[UIColor blackColor]];
        [self.countLabel setText:[NSString stringWithFormat:@"%d", [orderInfo getCountForFood:[self.food getID]]]];
        [self.countLabel setHidden:YES];
        [self.controlView addSubview:self.countLabel];
        
        self.addButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.addButton setFrame:CGRectMake(self.controlView.frame.size.width - button_size, 0, button_size, button_size)];
        [self.addButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.addButton setBackgroundColor:[UIColor clearColor]];
        [self.addButton setBackgroundImage:[UIImage imageNamed:@"add.png"] forState:UIControlStateNormal];
        [self.addButton setTitle:@"" forState:UIControlStateNormal];
        [self.addButton.titleLabel setFont:[UIFont systemFontOfSize:28]];
        [self.addButton addTarget:self action:@selector(addToCart) forControlEvents:UIControlEventTouchUpInside];
        [self.addButton setTag:[self.food getID]];
        /*
        [self.addButton setTitleEdgeInsets:UIEdgeInsetsMake(-2.2, 0.3, 0, 0)];
        [self.addButton.layer setMasksToBounds:YES];
        [self.addButton.layer setCornerRadius:button_size / 2.0]; //设置矩形四个圆角半径
        [self.addButton.layer setBorderWidth:1.0]; //边框宽度
        [self.addButton.layer setBorderColor:colorref];//边框颜色
         */
        [self.controlView addSubview:self.addButton];
        
        self.subButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.subButton setFrame:CGRectMake(0, 0, button_size, button_size)];
        [self.subButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.subButton setBackgroundColor:[UIColor clearColor]];
        [self.subButton setBackgroundImage:[UIImage imageNamed:@"sub.png"] forState:UIControlStateNormal];
        [self.subButton setTitle:@"" forState:UIControlStateNormal];
        [self.subButton.titleLabel setFont:[UIFont systemFontOfSize:28]];
        [self.subButton addTarget:self action:@selector(removeFromCart) forControlEvents:UIControlEventTouchUpInside];
        [self.subButton setTag:[self.food getID]];
        /*
        [self.subButton setTitleEdgeInsets:UIEdgeInsetsMake(-2.5, 1.2, 0, 0)];
        [self.subButton.layer setMasksToBounds:YES];
        [self.subButton.layer setCornerRadius:button_size / 2.0]; //设置矩形四个圆角半径
        [self.subButton.layer setBorderWidth:1.0]; //边框宽度
        [self.subButton.layer setBorderColor:colorref];//边框颜色
         */
        [self.subButton setHidden:YES];
        [self.controlView addSubview:self.subButton];
        
        if ([orderInfo getCountForFood:[self.food getID]] > 0) {
            [self.subButton setHidden:NO];
            [self.countLabel setHidden:NO];
        }
    }
    
    //gift mode
    if (foodId <= 0 && !self.firstShow && self.giftMode) {
        float button_size = 30;
        self.giftButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.giftButton setFrame:CGRectMake(self.controlView.frame.size.width - 80, 0, 80, button_size)];
        [self.giftButton setTitleColor:COFFEE_DARK forState:UIControlStateNormal];
        [self.giftButton setBackgroundColor:[UIColor clearColor]];
        [self.giftButton setTitle:@"赠送" forState:UIControlStateNormal];
        [self.giftButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [self.giftButton addTarget:self action:@selector(giftFood:) forControlEvents:UIControlEventTouchUpInside];
        [self.giftButton setTag:[self.food getID]];
        
        [self.giftButton.layer setMasksToBounds:YES];
        [self.giftButton.layer setCornerRadius:4.0]; //设置矩形四个圆角半径
        [self.giftButton.layer setBorderWidth:1.0]; //边框宽度
        [self.giftButton.layer setBorderColor:colorref];//边框颜色
        
        [self.controlView addSubview:self.giftButton];
    }
    
    CGColorSpaceRelease(colorSpace);
    CGColorRelease(colorref);
    
    /*
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [backButton setFrame:CGRectMake(0, self.view.bounds.size.height - 99, self.view.frame.size.width, 52)];
    [backButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [backButton setBackgroundColor:[UIColor clearColor]];
    [backButton setTitle:@"返回" forState:UIControlStateNormal];
    [backButton.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [backButton addTarget:self action:@selector(dismissThis) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *backLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 1, 50, 49)];
    [backLabel setBackgroundColor:[UIColor clearColor]];
    [backLabel setTextAlignment:NSTextAlignmentLeft];
    [backLabel setTextColor:[UIColor redColor]];
    [backLabel setFont:[UIFont systemFontOfSize:22]];
    [backLabel setText:@"《"];
    [backButton addSubview:backLabel];
    
    //draw line
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, backButton.frame.size.width, 1)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1, 0, 0, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), backButton.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [backButton addSubview:imageView];
    
    [self.view addSubview:backButton];
     */
    
    [self.infoTable setScrollsToTop:YES];
    [self.infoTable reloadData];
}

- (void)giftFood:(id)sender {
    NSInteger giftFoodID = ((UIButton*)sender).tag;
    //jump to cafeWall info input view
    wallSendInfo *cafeWallSendViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"wallSendInfo"];
    [cafeWallSendViewController setGiftFoodID:giftFoodID];
    [self.navigationController pushViewController:cafeWallSendViewController animated:YES];
}

- (IBAction)enlargeImg:(id)sender {
    self.imgOrigSize = self.foodImageView.frame;
    [UIView beginAnimations:@"ToggleViews" context:nil];
    [UIView setAnimationDuration:0.2];
    [self.foodImageView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.foodImageView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]];
    [UIView commitAnimations];
    [self.imgButtonSmall setEnabled:YES];
    self.enlargedImg = YES;
}

- (IBAction)enlittle:(id)sender {
    [UIView beginAnimations:@"ToggleViews" context:nil];
    [UIView setAnimationDuration:0.2];
    [self.foodImageView setFrame:self.imgOrigSize];
    [self.foodImageView setBackgroundColor:[UIColor clearColor]];
    [UIView commitAnimations];
    [self.imgButtonSmall setEnabled:NO];
    self.enlargedImg = NO;
}

- (void)setFoodID {
    foodId = [extra getFoodID];
    if (foodId <= 0)
        return;
    if ([store getIndexForFoodID:foodId] < 0 || [store getIndexForFoodID:foodId] >= [store getMenu].count) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [self setNewFood:(foodInfo*)[[store getMenu] objectAtIndex:[store getIndexForFoodID:foodId]]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.desp == nil || [self.desp isEqualToString:@""])
        return self.notes.count;
    return self.notes.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *attribute = @{NSFontAttributeName:UI_TEXT_FONT, NSParagraphStyleAttributeName:paragraphStyle.copy};
    
    CGRect sizeTT = [@"测试文字" boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    float margin = (44 - sizeTT.size.height) / 2;
    
    float h = 0;
    if (indexPath.section == 0) {
        CGRect sizeT = [self.desp boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        h = sizeT.size.height + margin * 2;
    } else {
        CGRect sizeT = [[self.notes objectAtIndex:indexPath.section - 1] boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];

        h = sizeT.size.height + margin * 2;
    }
    if (h < 44) {
        return 44;
    }
    return h;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (USE_NIL_CELL_ID) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:nil];
    } else {
        NSString *TableSampleIdentifier = [NSString stringWithFormat:@"tableCellID%d", infoCellID];
        infoCellID++;
        
        cell = [tableView dequeueReusableCellWithIdentifier:
                TableSampleIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:TableSampleIdentifier];
        }
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *attribute = @{NSFontAttributeName:UI_TEXT_FONT, NSParagraphStyleAttributeName:paragraphStyle.copy};
    CGRect sizeTT = [@"测试文字" boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    float margin = (44 - sizeTT.size.height) / 2;
    
    if (indexPath.section == 0) {
        CGRect sizeT = [self.desp boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(16, margin, self.infoTable.frame.size.width - 32, sizeT.size.height)];
        [l setText:self.desp];
        [l setNumberOfLines:0];
        [l setLineBreakMode:NSLineBreakByCharWrapping];
        [l setTextAlignment:NSTextAlignmentLeft];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    } else {
        CGRect sizeT = [[self.notes objectAtIndex:indexPath.section - 1] boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(16, margin, self.infoTable.frame.size.width - 32, sizeT.size.height)];
        [l setText:[self.notes objectAtIndex:indexPath.section - 1]];
        [l setNumberOfLines:0];
        [l setLineBreakMode:NSLineBreakByCharWrapping];
        [l setTextAlignment:NSTextAlignmentLeft];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    }
 
    return cell;
}


- (void)removeFromCart {
    int c = [orderInfo removeFood:[self.food getID] withCount:1];
    NSString *countStr = [NSString stringWithFormat:@"%d", c];
    [self.countLabel setText:countStr];
    
    if ([orderInfo getCountForFood:[self.food getID]] > 0) {
        [self.subButton setHidden:NO];
        [self.countLabel setHidden:NO];
    } else {
        [self.subButton setHidden:YES];
        [self.countLabel setHidden:YES];
    }
    
    [self reloadCartBadge];
}

- (void)addToCart {
    int c = [orderInfo addFood:[self.food getID] withCount:1];
    NSString *countStr = [NSString stringWithFormat:@"%d", c];
    [self.countLabel setText:countStr];
    
    if ([orderInfo getCountForFood:[self.food getID]] > 0) {
        [self.subButton setHidden:NO];
        [self.countLabel setHidden:NO];
    } else { //应该不会发生
        [self.subButton setHidden:YES];
        [self.countLabel setHidden:YES];
    }
    
    [self reloadCartBadge];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.firstShow = YES;
    [self.navigationItem setTitle:@"菜品信息"];
    
    infoCellID = 0;
    
    [self.foodImageView setContentMode:UIViewContentModeScaleAspectFit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.infoTable setBackgroundColor:COFFEE_LIGHT];
    
    [self.foodTitle setNumberOfLines:0];
    [self.foodTitle setLineBreakMode:NSLineBreakByCharWrapping];
    
    [self.navigationItem.backBarButtonItem setTitle:@"返回"];
    self.enlargedImg = NO;
    [self.imgButtonSmall setEnabled:NO];
    [self.foodImageView setBackgroundColor:[UIColor clearColor]];
    
    [self setFoodID];
    if (foodId <= 0) {
        [self setNewFood:[extra getFoodInfo]];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.firstShow){
        self.firstShow = NO;
        [self setFoodID];
        if (foodId <= 0) {
            [self setNewFood:[extra getFoodInfo]];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (foodId > 0) {
        [orderInfo saveOrder];
    }
    self.enlargedImg = NO;
    [self.imgButtonSmall setEnabled:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
