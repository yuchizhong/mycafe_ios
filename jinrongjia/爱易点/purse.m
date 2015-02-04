//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "purse.h"
#import "data.h"
#import "extra.h"
#import "AppDelegate.h"

static int infoCellID;
static NSString *payMethodJump;
static purse *instance = nil;

@interface purse ()

@property (atomic, strong) UILabel *purseMoney;
@property (atomic) NSInteger usingThreads;

@end

@implementation purse

+ (purse*)getInstance {
    return instance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    instance = self;
    infoCellID = 0;
        
    [self.view setBackgroundColor:UI_TABLE_BACKGROUND_COLOR];
    [self.infoTable setBackgroundColor:UI_TABLE_BACKGROUND_COLOR];
    
    self.purseMoney = [[UILabel alloc] init];
    [self.purseMoney setTextAlignment:NSTextAlignmentLeft];
    [self.purseMoney setTextColor:[UIColor blackColor]];
    [self.purseMoney setFont:[UIFont boldSystemFontOfSize:18]];
    self.usingThreads = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.purseMoney setText:@"加载中..."];
    [self.infoTable reloadData];
    [NSThread detachNewThreadSelector:@selector(loadMoney) toTarget:self withObject:nil];
}

- (void)loadMoney {
    if (self.usingThreads > 0)
        return;
    self.usingThreads++;
    NSInteger m = -1;
    while (m < 0) {
        m = [user getCreditForStoreIDAsync:app_store_id/*getPurseMoneyAsync*/];
    }
    [self.purseMoney setText:[NSString stringWithFormat:@"剩余积分：%ld分", m]];
    self.usingThreads--;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
            break;
            
        case 1: //付款方式
            return 2; //3 channels, ignore upmp
            break;
            
        default:
            return 0;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    return v;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) { //付款方式
        UIView *v = [[UIView alloc] init];
        v.backgroundColor = [UIColor clearColor];
        UILabel *cz = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 100, 30)];
        [cz setText:@"积分可用来结账或购买活动"];
        [cz setFont:[UIFont boldSystemFontOfSize:15]];
        [cz setTextAlignment:NSTextAlignmentLeft];
        [cz setTextColor:[UIColor darkGrayColor]];
        [v addSubview:cz];
        return v;
    }
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return 20;
    }
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return self.infoTable.frame.size.width * 0.3;
    }
    return 60;
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
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        //add image
        UIImageView *imageV = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.infoTable.frame.size.width, self.infoTable.frame.size.width * 0.3)];
        
        [imageV setImage:[UIImage imageNamed:@"purse_bg.png"]];
        //[imageV setContentMode:UIViewContentModeScaleAspectFill];
        
        //userImageView = imageV;
        [cell addSubview:imageV];
        
        [self.purseMoney setFrame:CGRectMake(10, 0, self.infoTable.frame.size.width - 20, self.infoTable.frame.size.width * 0.3)];
        [cell addSubview:self.purseMoney];
    } else if (indexPath.section == 1) {
        NSString *payMethod = nil;
        switch (indexPath.row) {
            case 0:
                payMethod = [NSString stringWithFormat:@"方法一：到金融家咖啡厅前台充值\n地址：%@", J_LOCATION] /*@"支付宝支付"*/;
                break;
                
            case 1:
                payMethod = [NSString stringWithFormat:@"方法二：支付宝汇款至%@，并打电话至金融家咖啡厅前台充值，前台电话：%@", J_ALIPAY_ACCOUNT, J_PHONE] /*@"微信支付"*/;
                break;
                
                /*
            case 2:
                payMethod = @"银联支付";
                break;
                 */
            default:
                break;
        }
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.infoTable.frame.size.width - 20, 60)];
        [l setText:payMethod];
        [l setNumberOfLines:0];
        [l setLineBreakMode:NSLineBreakByCharWrapping];
        [l setTextAlignment:NSTextAlignmentLeft];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    } else if (indexPath.section == 2) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.infoTable.frame.size.width - 20, 60)];
        [l setText:@"银行汇款"];
        [l setTextAlignment:NSTextAlignmentLeft];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    }
    
    //draw separator line
    if (indexPath.section > 0) {
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 44, tableView.frame.size.width, 0.5)];
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
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.infoTable deselectRowAtIndexPath:indexPath animated:YES];
    return;
    
    if (indexPath.section == 1) {
        NSString *payMethodDesp = nil;
        switch (indexPath.row) {
            case 0:
                payMethodJump = @"alipay";
                payMethodDesp = @"支付宝";
                break;
                
            case 1:
                payMethodJump = @"wx";
                payMethodDesp = @"微信";
                break;
                
            case 2:
                payMethodJump = @"upmp";
                payMethodDesp = @"银联";
                break;
                
            default:
                break;
        }
        
        //输入金额
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"付款" message:[NSString stringWithFormat:@"您选择了%@支付\n请输入充值金额", payMethodDesp] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"充值", nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
        alert.tag = 100;
        [alert show];
    }
    
    [self.infoTable deselectRowAtIndexPath:indexPath animated:YES];
    [self.infoTable reloadData];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100 && buttonIndex == 1) {
        NSString *numStr = [alertView textFieldAtIndex:0].text;
        float total = [numStr floatValue];
        if (total == 0.0 || (total * 100 - (int)(total * 100)) > 0) {
            UIAlertView *errorTotal = [[UIAlertView alloc]initWithTitle:@"输入错误" message:@"金额应为非零数字，小数点后最多两位" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [errorTotal show];
            return;
        }
        [AppDelegate setPayingModule:MODULE_PURSE];
        [user addMoneyToPurseWithChannel:payMethodJump andAmount:total onViewController:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
