//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "historyOrder.h"
#import "data.h"
#import "historyOrderSingle.h"

static NSArray *orderList = nil;
static NSMutableArray *orderListNow = nil;
static int cellID = 0;

@interface historyOrder ()

@property (atomic) NSInteger usingThreads;

@end

@implementation historyOrder

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.navigationItem setTitle:@"历史点单"];
    
    orderListNow = [[NSMutableArray alloc] init];
    
    /////////////////load once///////////////////////////////////////
    
    [orderInfo saveOrder];
    
    orderList = nil;
    if ([user getCurrentID] != nil && (self.historyType == TYPE_NORMAL || self.historyType == TYPE_PREORDER)) {
        [NSThread detachNewThreadSelector:@selector(loadHistory) toTarget:self withObject:nil];
    }
    
    //load database
    if (self.historyType == TYPE_OFFLINE) {
        [orderListNow removeAllObjects];
        NSArray *orderNowTemp = [db selectInTable:@"orders" withKeysAndValues:nil orderBy:@"placeID DESC"];
        NSString *sameStoreID = @"";
        NSString *sameStoreName = @"";
        float totalPrice = 0;
        for (NSDictionary *dic in orderNowTemp) {
            if ([[dic objectForKey:@"store"] isEqualToString:sameStoreID]) {
                totalPrice += [(NSString*)[dic objectForKey:@"quantity"] intValue] * [(NSString*)[dic objectForKey:@"price"] floatValue];
            } else {
                if (![sameStoreID isEqualToString:@""]) {
                    NSDictionary *dicIn = [NSDictionary dictionaryWithObjectsAndKeys:sameStoreID, @"storeID", sameStoreName, @"store", [NSString stringWithFormat:@"%.2f", totalPrice], @"total", nil];
                    [orderListNow addObject:dicIn];
                }
                sameStoreID = [dic objectForKey:@"store"];
                sameStoreName = [dic objectForKey:@"storeName"];
                totalPrice = [(NSString*)[dic objectForKey:@"quantity"] intValue] * [(NSString*)[dic objectForKey:@"price"] floatValue];
            }
        }
        if (![sameStoreID isEqualToString:@""]) {
            NSDictionary *dicIn = [NSDictionary dictionaryWithObjectsAndKeys:sameStoreID, @"storeID", sameStoreName, @"store", [NSString stringWithFormat:@"%.2f", totalPrice], @"total", nil];
            [orderListNow addObject:dicIn];
        }
    }
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    switch (self.historyType) {
        case TYPE_OFFLINE:
            [self.navigationItem setTitle:@"未提交的点单"];
            break;
            
        case TYPE_NORMAL:
            [self.navigationItem setTitle:@"店内点单记录"];
            break;
            
        case TYPE_PREORDER:
            [self.navigationItem setTitle:@"预订记录"];
            break;
            
        default:
            break;
    }
}

- (void)loadHistory {
    if (self.usingThreads > 0) {
        return;
    }
    self.usingThreads++;
    while (orderList == nil) {
        if (self.historyType == TYPE_PREORDER)
            orderList = [user getHistoryPreorders];
        else
            orderList = [user getHistoryOrders];
        if (orderList == nil) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
        }
    }
    [self.tableView reloadData];
    self.usingThreads--;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UI_HISTORY_ORDER_CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.historyType == TYPE_OFFLINE) {
        if (orderListNow.count == 0)
            return 1;
        return orderListNow.count;
    } else if (self.historyType == TYPE_NORMAL || self.historyType == TYPE_PREORDER) {
        if (orderList == nil || orderList.count == 0)
            return 1;
        return orderList.count;
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
    
    if (self.historyType == TYPE_OFFLINE) {
        if (orderListNow.count == 0) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, UI_HISTORY_ORDER_CELL_HEIGHT)];
            [l setText:@"没有点单"];
            [l setTextAlignment:NSTextAlignmentCenter];
            [l setTextColor:[UIColor blackColor]];
            [l setFont:UI_TEXT_FONT];
            [cell addSubview:l];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return cell;
        }
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 3, tableView.frame.size.width - 20, UI_HISTORY_ORDER_CELL_HEIGHT / 2.0)];
        [titleLabel setText:[[orderListNow objectAtIndex:indexPath.row] objectForKey:@"store"]];
        [titleLabel setTextAlignment:NSTextAlignmentLeft];
        [titleLabel setTextColor:[UIColor blackColor]];
        [titleLabel setFont:UI_TITLE_FONT];
        [cell addSubview:titleLabel];
        
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, UI_HISTORY_ORDER_CELL_HEIGHT / 2.0, tableView.frame.size.width - 20, UI_HISTORY_ORDER_CELL_HEIGHT / 2.0)];
        /*
        NSMutableString *timeStr = [[[orderListNow objectAtIndex:indexPath.row] objectForKey:@"time"] mutableCopy];
        [timeStr insertString:@"日" atIndex:8];
        [timeStr insertString:@"月" atIndex:6];
        [timeStr insertString:@"年" atIndex:4];
         */
        [timeLabel setText:@"未下单"/*timeStr*/];
        [timeLabel setTextAlignment:NSTextAlignmentLeft];
        [timeLabel setTextColor:[UIColor grayColor]];
        [timeLabel setFont:UI_TEXT_FONT];
        [cell addSubview:timeLabel];
        
        UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 210, 0, 200, UI_HISTORY_ORDER_CELL_HEIGHT)];
        [priceLabel setText:[NSString stringWithFormat:@"￥%.0f", [(NSString*)[[orderListNow objectAtIndex:indexPath.row] objectForKey:@"total"] floatValue]]];
        [priceLabel setTextAlignment:NSTextAlignmentRight];
        [priceLabel setTextColor:[UIColor blackColor]];
        [priceLabel setFont:UI_TEXT_FONT];
        [cell addSubview:priceLabel];
    } else {
        if (orderList == nil || orderList.count == 0) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, UI_HISTORY_ORDER_CELL_HEIGHT)];
            [l setText:@"加载中..."];
            if (orderList != nil && orderList.count == 0) {
                [l setText:@"没有点单"];
            }
            if ([user getCurrentID] == nil) {
                [l setText:@"您还没有登录"];
            }
            [l setTextAlignment:NSTextAlignmentCenter];
            [l setTextColor:[UIColor blackColor]];
            [l setFont:UI_TEXT_FONT];
            [cell addSubview:l];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return cell;
        }
    
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 3, tableView.frame.size.width - 20, UI_HISTORY_ORDER_CELL_HEIGHT / 2.0)];
        [titleLabel setText:[[orderList objectAtIndex:indexPath.row] objectForKey:@"store"]];
        [titleLabel setTextAlignment:NSTextAlignmentLeft];
        [titleLabel setTextColor:[UIColor blackColor]];
        [titleLabel setFont:UI_TITLE_FONT];
        [cell addSubview:titleLabel];
    
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, UI_HISTORY_ORDER_CELL_HEIGHT / 2.0, tableView.frame.size.width - 20, UI_HISTORY_ORDER_CELL_HEIGHT / 2.0)];
        NSMutableString *timeStr = [[[orderList objectAtIndex:indexPath.row] objectForKey:@"time"] mutableCopy];
        [timeStr insertString:@"日" atIndex:8];
        [timeStr insertString:@"月" atIndex:6];
        [timeStr insertString:@"年" atIndex:4];
        timeStr = [[timeStr substringFromIndex:2] mutableCopy];
        if (self.historyType == TYPE_NORMAL) {
            [timeLabel setText:[NSString stringWithFormat:@"%@单 %@号桌 %@",
                                [[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"],
                                [[orderList objectAtIndex:indexPath.row] objectForKey:@"tableID"],
                                timeStr]];
        } else { //PREORDER / OFFLINE
            [timeLabel setText:[NSString stringWithFormat:@"%@单 %@",
                                [[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"],
                                timeStr]];
        }
        [timeLabel setTextAlignment:NSTextAlignmentLeft];
        [timeLabel setTextColor:[UIColor grayColor]];
        [timeLabel setFont:UI_TEXT_FONT];
        [cell addSubview:timeLabel];
        
        /*
        UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 210, 3, 200, UI_HISTORY_ORDER_CELL_HEIGHT / 2.0)];
        NSString *statusStr = [orderInfo statusStringForPayed:[[[orderList objectAtIndex:indexPath.row] objectForKey:@"payed"] intValue]
                                                 andOrderFlag:[[[orderList objectAtIndex:indexPath.row] objectForKey:@"printed"] intValue]
                                                 andFetchFlag:[[[orderList objectAtIndex:indexPath.row] objectForKey:@"fetched"] intValue]];
        [status setText:statusStr];
        [status setTextAlignment:NSTextAlignmentRight];
        [status setTextColor:[UIColor redColor]];
        [status setFont:UI_TEXT_FONT];
        [cell addSubview:status];
         */
        
        UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 210, UI_HISTORY_ORDER_CELL_HEIGHT / 2.0, 200, UI_HISTORY_ORDER_CELL_HEIGHT / 2.0)];
        [priceLabel setText:[NSString stringWithFormat:@"￥%.0f", [(NSString*)[[orderList objectAtIndex:indexPath.row] objectForKey:@"total"] floatValue]]];
        [priceLabel setTextAlignment:NSTextAlignmentRight];
        [priceLabel setTextColor:[UIColor blackColor]];
        [priceLabel setFont:UI_TEXT_FONT];
        [cell addSubview:priceLabel];
    }
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, UI_HISTORY_ORDER_CELL_HEIGHT, tableView.frame.size.width, 0.5)];
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
    if (self.historyType == TYPE_OFFLINE && orderListNow != nil && orderListNow.count != 0) {
        historyOrderSingle *storeHistory = [self.storyboard instantiateViewControllerWithIdentifier:@"historyOrderSingle"];
        [storeHistory setNewStoreIDOffine:[[orderListNow objectAtIndex:indexPath.row] objectForKey:@"storeID"]
                                  andName:[[orderListNow objectAtIndex:indexPath.row] objectForKey:@"store"]];
        [self.navigationController pushViewController:storeHistory animated:YES];
    } else if ((self.historyType == TYPE_NORMAL || self.historyType == TYPE_PREORDER) && orderList != nil && orderList.count != 0) {
        historyOrderSingle *storeHistory = [self.storyboard instantiateViewControllerWithIdentifier:@"historyOrderSingle"];
        if (self.historyType == TYPE_PREORDER) {
            [storeHistory setIsPreorder:YES];
        }
        [storeHistory setNewStoreID:[[orderList objectAtIndex:indexPath.row] objectForKey:@"storeID"]
                            andName:[[orderList objectAtIndex:indexPath.row] objectForKey:@"store"]
                         andOrderID:[(NSString*)[[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"] intValue]];
        [self.navigationController pushViewController:storeHistory animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
