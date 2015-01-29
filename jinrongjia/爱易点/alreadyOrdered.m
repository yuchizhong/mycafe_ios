//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "alreadyOrdered.h"
#import "data.h"

static NSArray *orderList = nil;
static int cellID = 0;
static float totalToPay;
static float purseValue;

@interface alreadyOrdered ()

@property (atomic) NSInteger usingThreads;

@end

@implementation alreadyOrdered

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    SET_NAVBAR
}

- (void)payOnline {
    totalToPay = [orderInfo getPayTotalOnline];
    purseValue = [user getPurseMoney];
    NSString *purseStr = nil;
    if (purseValue < totalToPay) {
        purseStr = PURSE_INSUF_FUND;
    } else {
        purseStr = PURSE_FUND_PAY;
    }
    
    if ([store payOption] != PAY_OPTION_LATER) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"付款 - %.2f", totalToPay] message:@"请选择付款方式" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:purseStr, PING_PAYMENT_OPTION, nil];
        alert.delegate = self;
        alert.tag = 20;
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 20) {
        switch (buttonIndex) {
            case 1: //UniCafe钱包付款
                [user payByPurseForAmount:totalToPay];
                break;
                
            case 2:
                [user payWithChannel:@"alipay" andAmount:totalToPay onViewController:self];
                break;
                
            case 3:
                [user payWithChannel:@"wx" andAmount:totalToPay onViewController:self];
                break;
                
            case 4:
                [user payWithChannel:@"upmp" andAmount:totalToPay onViewController:self];
                break;
                
            default:
                break;
        }
    }
    if (buttonIndex != 0) {
        [self backDismiss];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if (alertView.tag == 20) {
        if (purseValue < totalToPay)
            return NO;
    }
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UINavigationItem *item = self.navigationItem;
    
    [item setTitle:@"未付账单"];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(backDismiss)];
    [item setLeftBarButtonItem:leftButton];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"在线付款"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(payOnline)];
    if ([store payOption] == PAY_OPTION_LATER) {
        [rightButton setTitle:@"需要面付"];
    }
    [rightButton setEnabled:NO];
    [item setRightBarButtonItem:rightButton];
    
    [orderInfo saveOrder];
    
    orderList = nil;
    if ([user getCurrentID] != nil) {
        [NSThread detachNewThreadSelector:@selector(loadCurrentHistory) toTarget:self withObject:nil];
    }
    
    [self.tableView reloadData];
}

- (void)loadCurrentHistory {
    if (self.usingThreads > 0) {
        return;
    }
    self.usingThreads++;
    float totalV = 0.0;
    while (orderList == nil) {
        totalV = [orderInfo getPayTotalOnline];
        if (totalV < 0) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
            continue;
        }
        orderList = [user getHistoryOrdersFromCurrentStore];
        if (orderList == nil) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
        }
    }
    
    UINavigationItem *item = self.navigationItem;
    [item setTitle:[NSString stringWithFormat:@"未付 - 共￥%.2f", totalV]];
    if (orderList.count > 0 && [store payOption] != PAY_OPTION_LATER) {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    [self.tableView reloadData];
    self.usingThreads--;
}

- (void)backDismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
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
        int foodIDFromData = [[[orderList objectAtIndex:indexPath.row] objectForKey:@"dishID"] intValue];
        foodInfo *finfo = [[store getMenu] objectAtIndex:[store getIndexForFoodID:foodIDFromData]];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 20, 44 / 2.0)];
        [titleLabel setText:[NSString stringWithFormat:@"%@", finfo.title]];
        [titleLabel setTextAlignment:NSTextAlignmentLeft];
        [titleLabel setTextColor:[UIColor blackColor]];
        [titleLabel setFont:[UIFont systemFontOfSize:15]];
        [cell addSubview:titleLabel];
        
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 44 / 2.0, tableView.frame.size.width - 20, 44 / 2.0)];
        NSMutableString *timeStr = [[[orderList objectAtIndex:indexPath.row] objectForKey:@"time"] mutableCopy];
        [timeStr insertString:@"日" atIndex:8];
        [timeStr insertString:@"月" atIndex:6];
        [timeStr insertString:@"年" atIndex:4];
        timeStr = [[timeStr substringFromIndex:2] mutableCopy];
        [timeLabel setText:[NSString stringWithFormat:@"%@单 %@号桌 %@", [[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"], [[orderList objectAtIndex:indexPath.row] objectForKey:@"tableID"], timeStr]];
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
        
        UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 210, 44 / 2.0, 200, 44 / 2.0)];
        [priceLabel setText:[NSString stringWithFormat:@"%d x %.2f元", [(NSString*)[[orderList objectAtIndex:indexPath.row] objectForKey:@"quantity"] intValue], [finfo getPrice]]];
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
    
    if (orderList == nil || orderList.count == 0)
        return cell;
    
    BOOL redLine = indexPath.row != 0 && [[[orderList objectAtIndex:indexPath.row] objectForKey:@"orderID"] intValue] != [[[orderList objectAtIndex:indexPath.row - 1] objectForKey:@"orderID"] intValue];
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0.5)];
    if (redLine)
        [imageView setFrame:CGRectMake(0, 0, tableView.frame.size.width, 1.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
    if (redLine)
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);
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
