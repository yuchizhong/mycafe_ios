//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#define ENABLE_COMMENT NO

#import "historyOrderSingle.h"
#import "data.h"
#import "evalView.h"

static NSArray *orderList = nil;
static int cellID = 0;

@interface historyOrderSingle ()

@property (atomic) NSInteger usingThreads;

@end

@implementation historyOrderSingle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)setNewStoreIDOffine:(NSString*)sid andName:(NSString*)sname {
    local = YES;
    orderCount = 0;
    orderID = -1;
    self.storeID = sid;
    self.storeName = sname;
    
    UINavigationItem *item = self.navigationItem;
    
    [item setTitle:[NSString stringWithFormat:@"%@", sname]];
    
    [self.navigationItem.backBarButtonItem setTitle:@"返回"];
    
    orderList = nil;
    //load order from local database
    if (![db lock])
        NSLog(@"LOCK FAILED");
    orderList = [db selectInTable:@"orders" withKeysAndValues:[NSDictionary dictionaryWithObjectsAndKeys:self.storeID, @"store", nil] orderBy:@"placeID"];
    if (orderList == nil) {
        NSLog(@"SELECT FAILED");
        if (![db rollback])
            NSLog(@"ROLLBACK FAILED");
    } else {
        if (![db commit])
            NSLog(@"COMMIT FAILED");
    }
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)jumpEvalution {
    evalView *ev= [self.storyboard instantiateViewControllerWithIdentifier:@"evaluateStore"];
    [ev setStoreID:self.storeID];
    [ev setStoreName:self.storeName];
    [self.navigationController pushViewController:ev animated:YES];
}

- (void)setNewStoreID:(NSString*)sid andName:(NSString*)sname andOrderID:(int)oid {
    local = NO;
    orderCount = 0;
    orderID = -1;
    orderID_in = oid;
    self.storeID = sid;
    self.storeName = sname;
    
    UINavigationItem *item = self.navigationItem;
    
    [item setTitle:[NSString stringWithFormat:@"历史-%@", sname]];
    
    [self.navigationItem.backBarButtonItem setTitle:@"返回"];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"评价"
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(jumpEvalution)];
    if (ENABLE_COMMENT)
        [self.navigationItem setRightBarButtonItem:rightButton];
    
    orderList = nil;
    [NSThread detachNewThreadSelector:@selector(loadSingleHistory) toTarget:self withObject:nil];
    
    [self.tableView reloadData];
}

- (void)loadSingleHistory {
    if (self.usingThreads > 0) {
        return;
    }
    self.usingThreads++;
    while (orderList == nil) {
        if (self.isPreorder)
            orderList = [user getHistoryPreordersFromStore:self.storeID andOrderID:orderID_in];
        else
            orderList = [user getHistoryOrdersFromStore:self.storeID andOrderID:orderID_in];
        if (orderList == nil) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
        }
    }
    
    [self.tableView reloadData];
    self.usingThreads--;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (orderList == nil || orderList.count == 0)
        return 1;
    return orderList.count;
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
    
    if (orderList == nil || orderList.count == 0) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 44)];
        [l setText:@"加载中..."];
        if (orderList != nil && orderList.count == 0) {
            [l setText:@"没有点单"];
        }
        [l setTextAlignment:NSTextAlignmentCenter];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    } else {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 20, 44 / 2.0)];
        [titleLabel setText:[NSString stringWithFormat:@"%@", [[orderList objectAtIndex:indexPath.row] objectForKey:@"dishName"]]];
        [titleLabel setTextAlignment:NSTextAlignmentLeft];
        [titleLabel setTextColor:[UIColor blackColor]];
        [titleLabel setFont:[UIFont systemFontOfSize:15]];
        if (local) {
            [titleLabel setFrame:CGRectMake(10, 0, tableView.frame.size.width - 20, 44)];
            [titleLabel setFont:[UIFont systemFontOfSize:16]];
        }
        [cell addSubview:titleLabel];
        
        if (!local) {
            UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 44 / 2.0, tableView.frame.size.width - 20, 44 / 2.0)];
            NSMutableString *timeStr = [[[orderList objectAtIndex:indexPath.row] objectForKey:@"time"] mutableCopy];
            [timeStr insertString:@"日" atIndex:8];
            [timeStr insertString:@"月" atIndex:6];
            [timeStr insertString:@"年" atIndex:4];
            timeStr = [[timeStr substringFromIndex:2] mutableCopy];
            [timeLabel setText:[NSString stringWithFormat:@"单号%@ %@", [[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"], timeStr]];
            [timeLabel setTextAlignment:NSTextAlignmentLeft];
            [timeLabel setTextColor:[UIColor grayColor]];
            [timeLabel setFont:UI_TEXT_FONT];
            [cell addSubview:timeLabel];
            
            UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 210, 0, 200, 44 / 2.0)];
            NSString *statusStr = [orderInfo statusStringForPayed:[[[orderList objectAtIndex:indexPath.row] objectForKey:@"payed"] intValue]
                                                     andOrderFlag:[[[orderList objectAtIndex:indexPath.row] objectForKey:@"printed"] intValue]
                                                     andFetchFlag:[[[orderList objectAtIndex:indexPath.row] objectForKey:@"fetched"] intValue]];
            [status setText:statusStr];
            [status setTextAlignment:NSTextAlignmentRight];
            [status setTextColor:[UIColor redColor]];
            [status setFont:UI_TEXT_FONT];
            [cell addSubview:status];
        } else {
            UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 210, 0, 200, 44 / 2.0)];
            [status setText:@"未提交"];
            [status setTextAlignment:NSTextAlignmentRight];
            [status setTextColor:[UIColor redColor]];
            [status setFont:UI_TEXT_FONT];
            [cell addSubview:status];
        }
        
        UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 210, 44 / 2.0, 200, 44 / 2.0)];
        if (!local)
            [priceLabel setText:[NSString stringWithFormat:@"%d x %.0f元", [(NSString*)[[orderList objectAtIndex:indexPath.row] objectForKey:@"quantity"] intValue], [[[orderList objectAtIndex:indexPath.row] objectForKey:@"price"] floatValue]]];
        else
            [priceLabel setText:[NSString stringWithFormat:@"%d x %.0f元", [(NSString*)[[orderList objectAtIndex:indexPath.row] objectForKey:@"quantity"] intValue], [[[orderList objectAtIndex:indexPath.row] objectForKey:@"price"] floatValue]]];
        [priceLabel setTextAlignment:NSTextAlignmentRight];
        [priceLabel setTextColor:[UIColor blackColor]];
        [priceLabel setFont:UI_TEXT_FONT];
        [cell addSubview:priceLabel];
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 44, tableView.frame.size.width, 0.5)];
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
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0.5)];
    if (!local && !(orderList == nil || orderList.count == 0) && orderCount > 0 && orderID != [[[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"] intValue])
        [imageView setFrame:CGRectMake(0, 0, tableView.frame.size.width, 1.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
    if (!local && !(orderList == nil || orderList.count == 0) && orderCount > 0 && orderID != [[[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"] intValue])
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell addSubview:imageView];
    
    if (!local && !(orderList == nil || orderList.count == 0) && orderID != [[[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"] intValue]) {
        orderID = [[[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"] intValue];
        orderCount++;
    }
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
