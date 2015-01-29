//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "creditMallList.h"
#import "data.h"
#include "storeDetails.h"
#include "item.h"

static NSArray *mallItems = nil;
static int cellID = 0;

@interface creditMallList ()

@property (atomic) NSInteger usingThreads;

@end

@implementation creditMallList

- (void)setStoreID:(int)sid {
    storeID = sid;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (storeID == 0)
        storeID = [storeDetails getPassedStoreDetails].storeID;
    if (self.mall == nil || [self.mall isEqualToString:@""]) {
        self.mall = @"credit";
    }
    
    [self.navigationItem setTitle:[store getMallTitle:self.mall]];
    
    self.usingThreads = 0;
    mallItems = nil;
    if ([user getCurrentID] != nil) {
        [NSThread detachNewThreadSelector:@selector(loadCredits) toTarget:self withObject:nil];
    }
    
    [self.tableView reloadData];
}

- (NSArray*)loadMall {
    [self.navigationItem setRightBarButtonItem:nil];
    if ([self.mall isEqualToString:@"credit"]) {
        int creditAvail = 0;
        
        NSData *recvDataB = [HTTPRequest syncPost:@"select.php" withRawData:
                             [HTTPRequest dataFromString:[NSString stringWithFormat:@"SELECT credit FROM user_login, stores, credit WHERE user_login.username='%@' AND stores.storeID='%d' AND user_login.userID=credit.user_id AND stores.chain_id=credit.chain_id", [user getCurrentID], storeID]]];
        if (recvDataB == nil) {
            return nil;
        }
        NSError *errorB;
        NSDictionary *jsonRootB = [NSJSONSerialization JSONObjectWithData:recvDataB options:kNilOptions error:&errorB];
        if (errorB != nil || jsonRootB == nil) {
            return nil;
        }
        NSArray *listInJSONB = [jsonRootB objectForKey:@"list"];
        if (listInJSONB.count > 0) {
            creditAvail = [[[listInJSONB objectAtIndex:0] objectForKey:@"credit"] intValue];
        }
        
        //load credit
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%d分", creditAvail]
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:nil];
        //[rightButton setEnabled:NO];
        [self.navigationItem setRightBarButtonItem:rightButton];
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    
    NSString *query = nil;
    if ([self.mall isEqualToString:@"credit"]) {
        query = [NSString stringWithFormat:@"SELECT * FROM creditMall WHERE store_id='%d'", storeID];
    } else if ([self.mall isEqualToString:@"cash"]) {
        query = [NSString stringWithFormat:@"SELECT * FROM cashMall WHERE store_id='%d'", storeID];
    }
    NSData *recvData = [HTTPRequest syncPost:@"select.php" withRawData:
                        [HTTPRequest dataFromString:query]];
    if (recvData == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}

- (void)loadCredits {
    if (self.usingThreads > 0) {
        return;
    }
    self.usingThreads++;
    while (mallItems == nil) {
        mallItems = [self loadMall];
        if (mallItems == nil) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
        }
    }
    [self.tableView reloadData];
    self.usingThreads--;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ITEM_CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (mallItems == nil || mallItems.count == 0)
        return 1;
    return mallItems.count / 2 + mallItems.count % 2;
}

- (void)buttonClicked:(id)sender {
    int index = ((UIButton*)sender).tag;
    //jump to details view
    item *itemView = [self.storyboard instantiateViewControllerWithIdentifier:@"mallItem"];
    NSMutableDictionary *infoPassed_original = [[mallItems objectAtIndex:index] mutableCopy];
    [infoPassed_original setObject:self.mall forKey:@"mall"];
    itemView.infoPassed = infoPassed_original;
    [self.navigationController pushViewController:itemView animated:YES];
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
    
    if (mallItems == nil || mallItems.count == 0) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, ITEM_CELL_HEIGHT)];
        [l setText:@"加载中..."];
        if (mallItems != nil && mallItems.count == 0) {
            [l setText:@"没有商品"];
        }
        [l setTextAlignment:NSTextAlignmentCenter];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    } else {
        int row = indexPath.row * 2;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundColor:[UIColor clearColor]];
        [button setFrame:CGRectMake(0, 0, tableView.frame.size.width / 2, ITEM_CELL_HEIGHT)];
        
        UIImageView *roundedView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, button.frame.size.width - 20, ITEM_CELL_HEIGHT - 50)];
        UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(10, roundedView.frame.size.height / 2 - 1, roundedView.frame.size.width - 20, 2)];
        [loading setProgress:0.0];
        [loading setProgressViewStyle:UIProgressViewStyleDefault];
        [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
        [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
        [roundedView addSubview:loading];
        NSString *url;
        if ([self.mall isEqualToString:@"credit"]) {
            url = [NSString stringWithFormat:@"%@/images/store%@/storemallimage/item%@/%@", SERVER_ADDRESS, [[mallItems objectAtIndex:row] objectForKey:@"store_id"], [[mallItems objectAtIndex:row] objectForKey:@"item_id"], [[mallItems objectAtIndex:row] objectForKey:@"icon"]];
            if ([[[mallItems objectAtIndex:row] objectForKey:@"bDish"] isEqualToString:@"1"]) {
                url = [NSString stringWithFormat:@"%@/images/store%@/dishimage/dish%@/%@", SERVER_ADDRESS, [[mallItems objectAtIndex:row] objectForKey:@"store_id"], [[mallItems objectAtIndex:row] objectForKey:@"dishID"], [[mallItems objectAtIndex:row] objectForKey:@"icon"]];
            }
        } else if ([self.mall isEqualToString:@"cash"]) {
            url = [NSString stringWithFormat:@"%@/images/store%@/emallimage/item%@/%@", SERVER_ADDRESS, [[mallItems objectAtIndex:row] objectForKey:@"store_id"], [[mallItems objectAtIndex:row] objectForKey:@"item_id"], [[mallItems objectAtIndex:row] objectForKey:@"icon"]];
        }
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [roundedView setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            float percentage = (float)receivedSize / (float)expectedSize;
            //update loading progress bar
            [loading setProgress:percentage];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            //dismiss loading progress bar
            [loading removeFromSuperview];
        }];
        [roundedView setContentMode:UIViewContentModeScaleAspectFit];
        [button addSubview:roundedView];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, ITEM_CELL_HEIGHT - 40, button.frame.size.width, 25)];
        [titleLabel setText:[[mallItems objectAtIndex:row] objectForKey:@"name"]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setTextColor:[UIColor blackColor]];
        [titleLabel setFont:[UIFont systemFontOfSize:15]];
        [button addSubview:titleLabel];
        
        UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, ITEM_CELL_HEIGHT - 15, button.frame.size.width, 10)];
        if ([self.mall isEqualToString:@"credit"])
            [priceLabel setText:[NSString stringWithFormat:@"%d分", [[[mallItems objectAtIndex:row] objectForKey:@"credit"] intValue]]];
        else
            [priceLabel setText:[NSString stringWithFormat:@"￥%.2f", [[[mallItems objectAtIndex:row] objectForKey:@"price"] floatValue]]];
        [priceLabel setTextAlignment:NSTextAlignmentCenter];
        [priceLabel setTextColor:[UIColor redColor]];
        [priceLabel setFont:UI_TEXT_FONT];
        [button addSubview:priceLabel];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, ITEM_CELL_HEIGHT, tableView.frame.size.width / 2.0, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width / 2.0, 0);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell addSubview:imageView];
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width / 2.0, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width / 2.0, 0);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell addSubview:imageView];
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(tableView.frame.size.width / 2.0, 0, 0.5, ITEM_CELL_HEIGHT)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), 0, ITEM_CELL_HEIGHT);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell addSubview:imageView];
        
        [button setTag:row];
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:button];
        
        row++;
        if (mallItems.count <= row) {
            return cell;
        }
        
        UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
        [button2 setBackgroundColor:[UIColor clearColor]];
        [button2 setFrame:CGRectMake(tableView.frame.size.width / 2, 0, tableView.frame.size.width / 2, ITEM_CELL_HEIGHT)];
        
        UIImageView *roundedView2 = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, button.frame.size.width - 20, ITEM_CELL_HEIGHT - 50)];
        UIProgressView *loading2 = [[UIProgressView alloc] initWithFrame:CGRectMake(10, roundedView.frame.size.height / 2 - 1, roundedView.frame.size.width - 20, 2)];
        [loading2 setProgress:0.0];
        [loading2 setProgressViewStyle:UIProgressViewStyleDefault];
        [loading2 setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
        [loading2 setProgressTintColor:UI_PROGRESS_TINT_COLOR];
        [roundedView2 addSubview:loading2];
        if ([self.mall isEqualToString:@"credit"]) {
            url = [NSString stringWithFormat:@"%@/images/store%@/storemallimage/item%@/%@", SERVER_ADDRESS, [[mallItems objectAtIndex:row] objectForKey:@"store_id"], [[mallItems objectAtIndex:row] objectForKey:@"item_id"], [[mallItems objectAtIndex:row] objectForKey:@"image"]];
            if ([[[mallItems objectAtIndex:row] objectForKey:@"bDish"] isEqualToString:@"1"]) {
                url = [NSString stringWithFormat:@"%@/images/store%@/dishimage/dish%@/%@", SERVER_ADDRESS, [[mallItems objectAtIndex:row] objectForKey:@"store_id"], [[mallItems objectAtIndex:row] objectForKey:@"dishID"], [[mallItems objectAtIndex:row] objectForKey:@"icon"]];
            }
        } else if ([self.mall isEqualToString:@"cash"]) {
            url = [NSString stringWithFormat:@"%@/images/store%@/emallimage/item%@/%@", SERVER_ADDRESS, [[mallItems objectAtIndex:row] objectForKey:@"store_id"], [[mallItems objectAtIndex:row] objectForKey:@"item_id"], [[mallItems objectAtIndex:row] objectForKey:@"icon"]];
        }
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        [roundedView2 setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            float percentage = (float)receivedSize / (float)expectedSize;
            //update loading progress bar
            [loading2 setProgress:percentage];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            //dismiss loading progress bar
            [loading2 removeFromSuperview];
        }];
        [roundedView2 setContentMode:UIViewContentModeScaleAspectFit];
        [button2 addSubview:roundedView2];
        
        UILabel *titleLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(0, ITEM_CELL_HEIGHT - 40, button.frame.size.width, 25)];
        [titleLabel2 setText:[[mallItems objectAtIndex:row] objectForKey:@"name"]];
        [titleLabel2 setTextAlignment:NSTextAlignmentCenter];
        [titleLabel2 setTextColor:[UIColor blackColor]];
        [titleLabel2 setFont:[UIFont systemFontOfSize:15]];
        [button2 addSubview:titleLabel2];
        
        UILabel *priceLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(0, ITEM_CELL_HEIGHT - 15, button.frame.size.width, 10)];
        if ([self.mall isEqualToString:@"credit"])
            [priceLabel2 setText:[NSString stringWithFormat:@"%d分", [[[mallItems objectAtIndex:row] objectForKey:@"credit"] intValue]]];
        else
            [priceLabel2 setText:[NSString stringWithFormat:@"￥%.2f", [[[mallItems objectAtIndex:row] objectForKey:@"price"] floatValue]]];
        [priceLabel2 setTextAlignment:NSTextAlignmentCenter];
        [priceLabel2 setTextColor:[UIColor redColor]];
        [priceLabel2 setFont:UI_TEXT_FONT];
        [button2 addSubview:priceLabel2];
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(tableView.frame.size.width / 2.0, ITEM_CELL_HEIGHT, tableView.frame.size.width / 2.0, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width / 2.0, 0);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell addSubview:imageView];
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(tableView.frame.size.width / 2.0, 0, tableView.frame.size.width / 2.0, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width / 2.0, 0);   //终点坐标
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        imageView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell addSubview:imageView];
        
        [button2 setTag:row];
        [button2 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:button2];
        
        return cell;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, ITEM_CELL_HEIGHT, tableView.frame.size.width, 0.5)];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
