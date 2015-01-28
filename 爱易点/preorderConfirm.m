//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#define MAX_NUM_PEOPLE 8
#define DEFAULT_NUM_PEOPLE 0

#import "preorderConfirm.h"
#import "IGLDropDownMenu.h"
#import "AppDelegate.h"

static float purseValue;
static NSInteger creditValue;
static float creditToCent;

@interface preorderConfirm () <IGLDropDownMenuDelegate>

@property (nonatomic, strong) IGLDropDownMenu *dropDownMenu;
@property (atomic) NSInteger numPeople;
@property (atomic) NSString *preorderID;
@property (atomic) float preorderTotal;

@end

@implementation preorderConfirm

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.dropDownMenu == nil) {
        NSMutableArray *dropdownItems = [[NSMutableArray alloc] init];
        for (int i = 1; i <= MAX_NUM_PEOPLE; i++) {
            IGLDropDownItem *item = [[IGLDropDownItem alloc] init];
            [item setText:[NSString stringWithFormat:@"%d位", i]];
            [dropdownItems addObject:item];
        }
        self.dropDownMenu = [[IGLDropDownMenu alloc] init];
        self.dropDownMenu.menuText = [NSString stringWithFormat:@"%d位", DEFAULT_NUM_PEOPLE];
        self.dropDownMenu.dropDownItems = dropdownItems;
        self.dropDownMenu.paddingLeft = 0;
        CGRect menuFrame = self.blankNumPeopleView.frame;
        [self.dropDownMenu setFrame:menuFrame];
        self.dropDownMenu.delegate = self;
        self.dropDownMenu.type = IGLDropDownMenuTypeNormal;
        self.dropDownMenu.gutterY = 0;
        [self.dropDownMenu reloadView];
        [self.view addSubview:self.dropDownMenu];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view layoutSubviews];
    
    self.numPeople = DEFAULT_NUM_PEOPLE;
    [self.confirmTitle setText:[NSString stringWithFormat:@"金额：￥%.2f", [orderInfo getTotalValue]]];
    
    //不能外带
    if ([store preorder_option_allowed] == 1) {
        [self.typeSwitch setEnabled:NO forSegmentAtIndex:1];
    }
    
    [self.timeLabel setText:[NSString stringWithFormat:@"时间（至少%d分钟后）：", [store preorder_minutes_after_now]]];
    NSDate *now = [NSDate date];
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:[store preorder_minutes_after_now] * 60]; //after 15 minutes
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setTimeZone:gmt];
    NSDateComponents *components = [gregorian components:NSUIntegerMax fromDate:now];
    [components setHour: 23];
    [components setMinute:59];
    [components setSecond: 59];
    NSDate *endDate = [gregorian dateFromComponents:components];
    [self.timePicker setMinimumDate:startDate];
    [self.timePicker setMaximumDate:endDate];
}

- (void)selectedItemAtIndex:(NSInteger)index {
    self.numPeople = index + 1;
}

- (void)pay {
    BEGIN_LOADING
    
    float totalToPay = self.preorderTotal;
    
    purseValue = [user getPurseMoneyAsync];
    NSString *purseStr = nil;
    if (purseValue < totalToPay) {
        purseStr = PURSE_INSUF_FUND;
    } else {
        purseStr = PURSE_FUND_PAY;
    }
    
    NSString *creditStr = nil;
    creditToCent = [store creditToCentRatio]; //多少credit对应1分钱
    float creditNeeded = totalToPay * 100 * creditToCent;
    if ([store creditCanPay]) {
        creditValue = [user getCreditForStoreIDAsync:[store getCurrentStoreID]];  //credit余额
        if (creditValue < creditNeeded) {
            creditStr = [NSString stringWithFormat:@"积分付:需%.0f，现有%d", creditNeeded, creditValue];
        } else {
            creditStr = [NSString stringWithFormat:@"积分付:需%.0f，现有%d", creditNeeded, creditValue];
        }
    }
    
    END_LOADING
    
    CustomIOS7AlertView *alert = [[CustomIOS7AlertView alloc]init];
    UIView *infoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 300, 115)];
    [infoView setBackgroundColor:[UIColor clearColor]];
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 40)];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setText:@"预订成功"];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [infoView addSubview:titleLabel];
    UILabel *infoLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 35, 300, 70)];
    [infoLabel setTextAlignment:NSTextAlignmentCenter];
    [infoLabel setNumberOfLines:0];
    [infoLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [infoLabel setFont:[UIFont systemFontOfSize:13]];
    [infoLabel setText:[NSString stringWithFormat:@"未付金额：￥%.2f\n您的预订单号：%@", self.preorderTotal, self.preorderID]];
    [infoLabel setBackgroundColor:[UIColor clearColor]];
    [infoView addSubview:infoLabel];
    [alert setContainerView:infoView];
    if ([store creditCanPay]) {
        [alert setButtonTitles:@[purseStr, creditStr, PING_PAYMENT_OPTION, @"取消"]];
    } else {
        [alert setButtonTitles:@[purseStr, PING_PAYMENT_OPTION, @"取消"]];
    }
    alert.delegate = self;
    if (purseValue < totalToPay)
        alert.disableFirstButton = YES;
    if (creditValue < creditNeeded && [store creditCanPay])
        alert.disableSecondButton = YES;
    alert.tag = 21;
    [alert show];
}

- (IBAction)confirmPay:(id)sender {
    int type = [self.typeSwitch selectedSegmentIndex]; //0 堂吃, 1 外带
    if (type == 0 && self.numPeople == 0) {
        [HTTPRequest alert:@"请选择人数"];
        return;
    }
    NSDate *selectedTime = [self.timePicker date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateStr = [dateFormatter stringFromDate:selectedTime];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *timeStr = [dateFormatter stringFromDate:selectedTime];
    
    //submit order
    NSString *feedback = [store submitPreorder:type withNumPeople:self.numPeople atDate:dateStr andTime:timeStr];
    if (feedback == nil) {
        //ERROR
        return;
    } else {
        NSArray *ar = [feedback componentsSeparatedByString:@":"]; //0 orderID, 1 total
        self.preorderID = [ar objectAtIndex:0];
        self.preorderTotal = [[ar objectAtIndex:1] floatValue];
    }
    
    //prepare payment
    [self pay];
}

- (void)customIOS7dialogButtonTouchUpInside:(id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (((CustomIOS7AlertView*)alertView).tag == 21) {
        float totalToPay = self.preorderTotal;
        BOOL success = NO;
        BOOL canCancelPreorderMode = NO;
        if ([store creditCanPay]) {
            switch (buttonIndex) {
                case 0: //UniCafe钱包付款
                    success = [user payByPurseForAmount:totalToPay];
                    canCancelPreorderMode = YES;
                    break;
                    
                case 1: //积分支付
                    success = [user payByCreditForTotalCredit:(NSInteger)(totalToPay * 100 * creditToCent)];
                    canCancelPreorderMode = YES;
                    break;
                    
                case 2:
                    success = [user payWithChannel:@"alipay" andAmount:totalToPay onViewController:self];
                    break;
                    
                case 3:
                    success = [user payWithChannel:@"wx" andAmount:totalToPay onViewController:self];
                    break;
                    /*
                case 4:
                    success = [user payWithChannel:@"upmp" andAmount:totalToPay onViewController:self];
                    break;
                    */
                default:
                    break;
            }
        } else {
            switch (buttonIndex) {
                case 0: //UniCafe钱包付款
                    success = [user payByPurseForAmount:totalToPay];
                    canCancelPreorderMode = YES;
                    break;
                    
                case 1:
                    success = [user payWithChannel:@"alipay" andAmount:totalToPay onViewController:self];
                    break;
                    
                case 2:
                    success = [user payWithChannel:@"wx" andAmount:totalToPay onViewController:self];
                    break;
                    /*
                case 3:
                    success = [user payWithChannel:@"upmp" andAmount:totalToPay onViewController:self];
                    break;
                    */
                default:
                    break;
            }
        }
        if (success && canCancelPreorderMode) {
            [store set_preorder_mode:NO];
            [[orderInfo getOrder] removeAllObjects];
            [orderInfo saveOrder];
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else if (success) {
            [AppDelegate setPayingModule:MODULE_PREORDER];
        }
    }
    [alertView close];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
