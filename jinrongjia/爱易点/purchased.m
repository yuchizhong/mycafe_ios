//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "purchased.h"
#import "data.h"
#import "item.h"
#import "activityDetails.h"

static NSArray *purchasedItems = nil;
static int cellID = 0;

@interface purchased ()

@property (atomic) NSInteger usingThreads;

@end

@implementation purchased

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.mall == nil || [self.mall isEqualToString:@""]) {
        self.mall = @"cash";
    }
    
    [self.navigationItem setTitle:[NSString stringWithFormat:@"消费记录 %@", [store getMallTitle:self.mall]]];
    
    self.usingThreads = 0;
    purchasedItems = nil;
    if ([user getCurrentID] != nil) {
        [NSThread detachNewThreadSelector:@selector(loadPurchasedItemList) toTarget:self withObject:nil];
    }
    
    [self.tableView reloadData];
}

- (NSArray*)getPurchasedItemsList {
    NSString *query = nil;
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    if ([self.mall isEqualToString:@"credit"]) {
        query = [NSString stringWithFormat:@"SELECT * FROM stores, creditMall, creditTransaction, user_login \
                 WHERE user_login.username='%@' AND \
                 creditTransaction.status<>0 AND \
                 user_login.userID=creditTransaction.user_id AND \
                 creditTransaction.store_id=stores.storeID AND \
                 creditTransaction.store_id=creditMall.store_id AND \
                 creditTransaction.item_id=creditMall.item_id \
                 ORDER BY transaction_id DESC", [user getCurrentID]];
    } else if ([self.mall isEqualToString:@"cash"]) {
        query = [NSString stringWithFormat:@"SELECT * FROM stores, cashMall, cashTransaction, user_login \
                 WHERE user_login.username='%@' AND \
                 cashTransaction.status<>0 AND \
                 user_login.userID=cashTransaction.user_id AND \
                 cashTransaction.store_id=stores.storeID AND \
                 cashTransaction.store_id=cashMall.store_id AND \
                 cashTransaction.item_id=cashMall.item_id \
                 ORDER BY transaction_id DESC", [user getCurrentID]];
    } else if ([self.mall isEqualToString:@"activity"]) {
        query = [NSString stringWithFormat:@"SELECT * FROM stores, activity, activityTransaction, user_login \
                 WHERE user_login.username='%@' AND \
                 activityTransaction.status<>0 AND \
                 user_login.userID=activityTransaction.user_id AND \
                 activityTransaction.store_id=stores.storeID AND \
                 activityTransaction.store_id=activity.store_id AND \
                 activityTransaction.activity_id=activity.activity_id \
                 ORDER BY transaction_id DESC", [user getCurrentID]];
    } else if ([self.mall isEqualToString:@"refill"]) {
        query = [NSString stringWithFormat:@"SELECT * FROM payment, user_login \
                 WHERE user_login.username='%@' AND \
                 payment.pay_status='payed' AND \
                 user_login.userID=payment.userID AND \
                 payment.mall='refill' \
                 ORDER BY paymentID DESC", [user getCurrentID]];
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

- (void)loadPurchasedItemList {
    if (self.usingThreads > 0) {
        return;
    }
    self.usingThreads++;
    while (purchasedItems == nil) {
        purchasedItems = [self getPurchasedItemsList];
        if (purchasedItems == nil) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
        }
    }
    [self.tableView reloadData];
    self.usingThreads--;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return PURCHASED_CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (purchasedItems == nil || purchasedItems.count == 0)
        return 1;
    return purchasedItems.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int index = indexPath.row;
    
    if (purchasedItems == nil || purchasedItems.count == 0) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    //jump to details view
    if ([self.mall isEqualToString:@"refill"]) {
        //do nothing
    } else if ([self.mall isEqualToString:@"activity"]) {
        activityDetails *activityDetialsForSingleStore = [self.storyboard instantiateViewControllerWithIdentifier:@"activityDetails"];
        [activityDetialsForSingleStore setActivityInfo:[purchasedItems objectAtIndex:index]];
        [activityDetialsForSingleStore setHideEnrollButton:YES];
        [self.navigationController pushViewController:activityDetialsForSingleStore animated:YES];
    } else {
        item *itemView = [self.storyboard instantiateViewControllerWithIdentifier:@"mallItem"];
        [itemView setBeenPurchased:YES];
        NSMutableDictionary *infoPassed_original = [[purchasedItems objectAtIndex:index] mutableCopy];
        [infoPassed_original setObject:self.mall forKey:@"mall"];
        itemView.infoPassed = infoPassed_original;
        [self.navigationController pushViewController:itemView animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    
    if (purchasedItems == nil || purchasedItems.count == 0) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, PURCHASED_CELL_HEIGHT)];
        [l setText:@"加载中..."];
        if (purchasedItems != nil && purchasedItems.count == 0) {
            [l setText:@"没有消费记录"];
            if ([self.mall isEqualToString:@"refill"]) {
                [l setText:@"没有充值记录"];
            }
        }
        [l setTextAlignment:NSTextAlignmentCenter];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell addSubview:l];
    } else {
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 150, PURCHASED_CELL_HEIGHT / 2)];
        if ([self.mall isEqualToString:@"refill"])
            [titleLabel setText:[NSString stringWithFormat:@"通过%@支付", [[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"channel"]]];
        else
            [titleLabel setText:[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"name"]];
        [titleLabel setTextAlignment:NSTextAlignmentLeft];
        [titleLabel setTextColor:[UIColor blackColor]];
        [titleLabel setFont:[UIFont systemFontOfSize:18]];
        [cell addSubview:titleLabel];
        
        NSMutableString *timeStr = [[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"date"] mutableCopy];
        [timeStr insertString:@"日" atIndex:8];
        [timeStr insertString:@"月" atIndex:6];
        [timeStr insertString:@"年" atIndex:4];
        //timeStr = [[timeStr substringFromIndex:2] mutableCopy];
        [timeStr appendString:@" "];
        [timeStr appendString:[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"time"]];
        
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, PURCHASED_CELL_HEIGHT * 3 / 4, tableView.frame.size.width - 20, PURCHASED_CELL_HEIGHT / 4)];
        [timeLabel setText:timeStr];
        [timeLabel setTextAlignment:NSTextAlignmentLeft];
        [timeLabel setTextColor:[UIColor grayColor]];
        [timeLabel setFont:UI_TEXT_FONT];
        [cell addSubview:timeLabel];
        
        UILabel *storeTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, PURCHASED_CELL_HEIGHT * 0.55, tableView.frame.size.width - 200, PURCHASED_CELL_HEIGHT / 4)];
        [storeTitleLabel setText:[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"storeName"]];
        [storeTitleLabel setTextAlignment:NSTextAlignmentLeft];
        [storeTitleLabel setTextColor:[UIColor blackColor]];
        [storeTitleLabel setFont:[UIFont systemFontOfSize:14]];
        [cell addSubview:storeTitleLabel];
        
        UILabel *sequenceLabel = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 150, 0, 140, PURCHASED_CELL_HEIGHT / 2)];
        if ([self.mall isEqualToString:@"credit"])
            [sequenceLabel setText:[NSString stringWithFormat:@"%@%@", PREFIX_CREDIT_SEQ, [[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"transaction_id"]]];
        else if ([self.mall isEqualToString:@"cash"])
            [sequenceLabel setText:[NSString stringWithFormat:@"%@%@", PREFIX_CASH_SEQ, [[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"transaction_id"]]];
        else if ([self.mall isEqualToString:@"refill"])
            [sequenceLabel setText:[NSString stringWithFormat:@"%@%@", PREFIX_CASH_SEQ, [[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"paymentID"]]];
        else
            [sequenceLabel setText:[NSString stringWithFormat:@"%@%@", @"#", [[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"transaction_id"]]];
        [sequenceLabel setTextAlignment:NSTextAlignmentRight];
        [sequenceLabel setTextColor:DARK_RED];
        [sequenceLabel setFont:FONT15];
        [cell addSubview:sequenceLabel];
        
        NSString *status = nil;
        switch ([[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"status"] intValue]) {
            case 0:
                status = @"未支付";
                break;
                
            case 1:
                status = @"已支付 未使用";
                break;
                
            case 2:
                status = @"已使用";
                break;
                
            default:
                status = @"未知状态";
                break;
        }
        UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 200, PURCHASED_CELL_HEIGHT * 3 / 4, 190, PURCHASED_CELL_HEIGHT / 4)];
        if ([self.mall isEqualToString:@"credit"])
            [priceLabel setText:[NSString stringWithFormat:@"%d分 %@", [[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"credit"] intValue], status]];
        else if ([self.mall isEqualToString:@"cash"])
            [priceLabel setText:[NSString stringWithFormat:@"￥%.2f %@", [[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"price"] floatValue], status]];
        else if ([self.mall isEqualToString:@"refill"])
            [priceLabel setText:[NSString stringWithFormat:@"%.2f元", [[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"amount"] floatValue]]];
        else if ([self.mall isEqualToString:@"activity"]) {
            switch ([[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"approve_status"] intValue]) {
                case 0:
                    status = @"等待批准";
                    break;
                    
                case 1:
                    status = @"已批准";
                    break;
                    
                case 2:
                    status = @"不批准";
                    break;
                    
                default:
                    status = @"未知状态";
                    break;
            }
            [priceLabel setText:[NSString stringWithFormat:@"￥%.2f %@", [[[purchasedItems objectAtIndex:indexPath.row] objectForKey:@"price"] floatValue], status]];
        }
        [priceLabel setTextAlignment:NSTextAlignmentRight];
        [priceLabel setTextColor:[UIColor grayColor]];
        [priceLabel setBackgroundColor:[UIColor clearColor]];
        [priceLabel setFont:UI_TEXT_FONT];
        [cell addSubview:priceLabel];
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
    
    if ([self.mall isEqualToString:@"refill"]) {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, PURCHASED_CELL_HEIGHT, tableView.frame.size.width, 0.5)];
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
    
    if (purchasedItems == nil || purchasedItems.count == 0)
        return cell;
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0.5)];
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
