//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "activityDetails.h"
#import "data.h"
#import "AppDelegate.h"

static NSInteger transactionID;
static float purseValueMall;
static NSInteger storeIDforCollect = 0;
static activityDetails *acdetailInstance = nil;

@interface activityDetails ()

@property (atomic) NSInteger usingThreads;

@end

@implementation activityDetails

+ (NSInteger)storeIDforCollect {
    return storeIDforCollect;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.loadingLabel setHidden:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.loadingLabel setHidden:YES];
    [HTTPRequest alert:NETWORK_ERROR];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    acdetailInstance = self;
    self.usingThreads = 0;
    
    if (!self.hideEnrollButton) {
        NSString *buttonText = nil;
        BOOL enableButton = NO;
        
        NSMutableString *deadlineTimeStr = [[self.activityInfo objectForKey:@"deadline_date"] mutableCopy];
        [deadlineTimeStr insertString:@"日" atIndex:8];
        [deadlineTimeStr insertString:@"月" atIndex:6];
        [deadlineTimeStr insertString:@"年" atIndex:4];
        //timeStr = [[timeStr substringFromIndex:2] mutableCopy];
        [deadlineTimeStr appendString:@" "];
        [deadlineTimeStr appendString:[self.activityInfo objectForKey:@"deadline_time"]];
        if ([self.activityInfo objectForKey:@"deadline_time"] != [NSNull null] && ![[self.activityInfo objectForKey:@"deadline_time"] isEqualToString:@""])
            [deadlineTimeStr appendString:[self.activityInfo objectForKey:@"deadline_time"]];
        else
            [deadlineTimeStr appendString:@"09:00"];
        
        NSMutableString *timeStr = [[self.activityInfo objectForKey:@"date"] mutableCopy];
        [timeStr insertString:@"日" atIndex:8];
        [timeStr insertString:@"月" atIndex:6];
        [timeStr insertString:@"年" atIndex:4];
        //timeStr = [[timeStr substringFromIndex:2] mutableCopy];
        [timeStr appendString:@" "];
        if ([self.activityInfo objectForKey:@"time"] != [NSNull null] && ![[self.activityInfo objectForKey:@"time"] isEqualToString:@""])
            [timeStr appendString:[self.activityInfo objectForKey:@"time"]];
        else
            [timeStr appendString:@"09:00"];
        
        NSDateFormatter* formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy年MM月dd日 HH:mm"];
        NSDate *acDate = [formater dateFromString:timeStr];
        NSDateFormatter* ddformater = [[NSDateFormatter alloc] init];
        [ddformater setDateFormat:@"yyyy年MM月dd日 HH:mm"];
        NSDate *ddDate = [formater dateFromString:deadlineTimeStr];
        if ([[NSDate date] compare:acDate] == NSOrderedDescending) {
            buttonText = @"已结束";
        } else if ([[NSDate date] compare:ddDate] == NSOrderedDescending) {
            buttonText = @"报名截止";
        } else if ([[self.activityInfo objectForKey:@"userEnrolled"] intValue] == 1) {
            buttonText = @"已报名";
        } else if ([[self.activityInfo objectForKey:@"max"] intValue] > 0 && [[self.activityInfo objectForKey:@"enrolled"] intValue] >= [[self.activityInfo objectForKey:@"max"] intValue]) {
            buttonText = @"名额已满";
        } else {
            buttonText = @"报名";
            enableButton = YES;
        }
        
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:buttonText
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(tryEnroll)];
        
        UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                       target:self
                                                                       action:@selector(shareActivity)];
        
        if (!enableButton) {
            [rightButton setEnabled:NO];
        }
        
        if (ENABLE_PAYMENT)
            [self.navigationItem setRightBarButtonItems:@[rightButton, shareButton]];
        else
            [self.navigationItem setRightBarButtonItem:shareButton];
    }
    
    [self.webView.scrollView setShowsVerticalScrollIndicator:NO];
    [self.webView.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.webView.scrollView setBackgroundColor:[UIColor whiteColor]];
    
    [NSThread detachNewThreadSelector:@selector(loadWebPage) toTarget:self withObject:nil];
    
    storeIDforCollect = [[self.activityInfo objectForKey:@"storeID"] integerValue];
}

- (void)loadWebPage {
    [self.loadingLabel setHidden:NO];
    
    NSString *url = [NSString stringWithFormat:@"%@/images/store%@/activities/activity%@/index.html", SERVER_ADDRESS, [self.activityInfo objectForKey:@"storeID"], [self.activityInfo objectForKey:@"activity_id"]];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    
    NSMutableString *header = [NSMutableString stringWithFormat:@"<hr noshade color=\"#000000\" />"];
    for (int i = 0; i < 10; i++) {
        NSString *title, *value;
        BOOL skip = NO;
        switch (i) {
            case 0:
                title = @"活动日期";
                value = [self.activityInfo objectForKey:@"date"];
                break;
                
            case 1:
                title = @"活动时间";
                if ([self.activityInfo objectForKey:@"time"] == [NSNull null] || [[self.activityInfo objectForKey:@"time"] isEqualToString:@""])
                    skip = YES;
                value = [self.activityInfo objectForKey:@"time"];
                break;
                
            case 2:
                title = @"活动结束时间";
                if ([self.activityInfo objectForKey:@"end_time"] == [NSNull null] || [[self.activityInfo objectForKey:@"end_time"] isEqualToString:@""])
                    skip = YES;
                value = [self.activityInfo objectForKey:@"end_time"];
                break;
                
            case 3:
                title = @"报名截止日期";
                value = [self.activityInfo objectForKey:@"deadline_date"];
                break;
                
            case 4:
                title = @"报名截止时间";
                if ([self.activityInfo objectForKey:@"deadline_time"] == [NSNull null] || [[self.activityInfo objectForKey:@"deadline_time"] isEqualToString:@""])
                    skip = YES;
                value = [self.activityInfo objectForKey:@"deadline_time"];
                break;
                
            case 5:
                title = @"活动具体地址";
                if ([self.activityInfo objectForKey:@"activity_addr"] == [NSNull null] || [[self.activityInfo objectForKey:@"activity_addr"] isEqualToString:@""])
                    skip = YES;
                value = [self.activityInfo objectForKey:@"activity_addr"];
                break;
                
            case 6:
                title = @"联系人";
                if ([self.activityInfo objectForKey:@"activity_contact"] == [NSNull null] || [[self.activityInfo objectForKey:@"activity_contact"] isEqualToString:@""])
                    skip = YES;
                value = [self.activityInfo objectForKey:@"activity_contact"];
                break;
                
            case 7:
                title = @"联系电话";
                if ([self.activityInfo objectForKey:@"activity_tel"] == [NSNull null] || [[self.activityInfo objectForKey:@"activity_tel"] isEqualToString:@""])
                    skip = YES;
                value = [self.activityInfo objectForKey:@"activity_tel"];
                break;
                
            case 8:
                title = @"其他信息";
                if ([self.activityInfo objectForKey:@"ac_desp"] == [NSNull null] || [[self.activityInfo objectForKey:@"ac_desp"] isEqualToString:@""])
                    skip = YES;
                value = [self.activityInfo objectForKey:@"ac_desp"];
                break;
                
            case 9:
                title = @"备注";
                if ([self.activityInfo objectForKey:@"note"] == [NSNull null] || [[self.activityInfo objectForKey:@"note"] isEqualToString:@""])
                    skip = YES;
                value = [self.activityInfo objectForKey:@"note"];
                break;
                
            default:
                skip = YES;
                break;
        }
        
        if (skip)
            continue;
        
        [header appendString:@"<p>"];
        [header appendFormat:@"%@：%@", title, value];
        [header appendString:@"</p>"];
    }
    NSMutableData *headerData = [[NSMutableData alloc]init];
    [headerData appendData:data];
    [headerData appendData:[HTTPRequest dataFromString:header]];
    [self.webView loadData:headerData MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:url]];
}

- (void)shareActivity {
    NSMutableString *timeStr = [[self.activityInfo objectForKey:@"date"] mutableCopy];
    [timeStr insertString:@"日" atIndex:8];
    [timeStr insertString:@"月" atIndex:6];
    [timeStr insertString:@"年" atIndex:4];
    //timeStr = [[timeStr substringFromIndex:2] mutableCopy];
    [timeStr appendString:@" "];
    [timeStr appendString:[self.activityInfo objectForKey:@"time"]];

    NSString *text = [NSString stringWithFormat:@"活动推荐：%@", [self.activityInfo objectForKey:@"name"]];
    NSString *desp = [NSString stringWithFormat:@"举办方：%@，时间：%@", [self.activityInfo objectForKey:@"storeName"], timeStr];
    NSString *url = [NSString stringWithFormat:@"%@/images/store%@/activities/activity%@/index.html", PRODUCTION_SERVER_ADDRESS_NOT_SECURE, [self.activityInfo objectForKey:@"storeID"], [self.activityInfo objectForKey:@"activity_id"]];
    [user shareText:text withDescription:desp andImage:nil withURL:url onViewController:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    storeIDforCollect = 0;
}

- (void)tryEnroll {
    if ([user getCurrentID] == nil) {
        //request login
        UIViewController *goLoginController = [self.storyboard instantiateViewControllerWithIdentifier:@"loginRoot"];
        [self presentViewController:goLoginController animated:YES completion:nil];
        return;
    }
    //check
    if ([[self.activityInfo objectForKey:@"max"] intValue] > 0 && [[self.activityInfo objectForKey:@"enrolled"] intValue] >= [[self.activityInfo objectForKey:@"max"] intValue]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"人数已满" message:@"对不起，本次活动名额已满" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil];
        [alert show];
        [HTTPRequest alert:@"对不起，本次活动名额已用完"];
    }
    
    if ([[self.activityInfo objectForKey:@"creditPrice"] integerValue] <= 0) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"报名" message:@"请确认是否报名" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
        alert.tag = 10;
        [alert show];
    } else {
        NSInteger creditValue = [user getCreditForStoreIDAsync:app_store_id];  //credit余额
        NSInteger creditNeeded = [[self.activityInfo objectForKey:@"creditPrice"] integerValue];
        if (creditValue >= creditNeeded) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"报名并积分" message:[NSString stringWithFormat:@"请确认是否报名并用积分支付\n需%ld分，现有%ld分", creditNeeded, creditValue] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
            alert.tag = 10;
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"积分不足" message:[NSString stringWithFormat:@"需%ld分，现有%ld分", creditNeeded, creditValue] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"充值说明", nil];
            alert.tag = -2;
            [alert show];
        }
    }
}

- (void)enroll {
    NSMutableDictionary *info = [self.activityInfo mutableCopy];
    [info setValue:[user getCurrentID] forKey:@"user_name"];
    [info setValue:[user getCurrentID] forKey:@"username"];
    [info setValue:@"activity" forKey:@"mall"];
    NSInteger purchase_result = [user purchaseMallItem:info];
    transactionID = purchase_result;
    if (purchase_result >= 0) {
        //pay
        [info setObject:[NSString stringWithFormat:@"%ld", transactionID] forKey:@"transaction_id"];
        
        if ([user payByCreditFor:info]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"报名成功" message:nil delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alertView show];
        }
        
        return;
        
        
        /*
        if ([[self.activityInfo objectForKey:@"price"] floatValue] == 0.0f) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"等待报名批准" message:@"免费活动需等待报名批准\n您可在消费记录中查看状态" delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alertView show];
        } else { //ask to pay
            purseValueMall = [user getPurseMoney];
            float purseValue = purseValueMall;
            NSString *purseStr = nil;
            if (purseValueMall < [[self.activityInfo objectForKey:@"price"] floatValue]) {
                purseStr = PURSE_INSUF_FUND;
            } else {
                purseStr = PURSE_FUND_PAY;
            }
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"付款" message:[NSString stringWithFormat:@"请选择付款方式\n金额：￥%.2f", [[self.activityInfo objectForKey:@"price"] floatValue]] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:purseStr, /*PING_PAYMENT_OPTION, nil];
            alert.tag = 20;
            [alert show];
        }
            */
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == -2 && buttonIndex == 1) {
        UIViewController *purseView = [self.storyboard instantiateViewControllerWithIdentifier:@"purse"];
        [self.navigationController pushViewController:purseView animated:YES];
    }
    if (alertView.tag == 10 && buttonIndex == 1) {
        [self enroll];
    }
    if (alertView.tag == 15 && buttonIndex == 1) {
        [self collectStore];
    }
    if (alertView.tag == 20) {
        //dismiss loading
        [HTTPRequest end_loading];
        NSMutableDictionary *payInfo = [self.activityInfo mutableCopy];
        [payInfo setObject:[NSString stringWithFormat:@"%ld", transactionID] forKey:@"transaction_id"];
        [payInfo setValue:@"activity" forKey:@"mall"];
        [payInfo setObject:[user getCurrentID] forKey:@"username"];
        switch (buttonIndex) {
            case 1: //UniCafe钱包付款
                if([user payByPurseFor:payInfo]) {
                    [self askForCollection];
                }
                break;
                
            /*
            case 2:
                [user payWithChannel:@"alipay" andInfo:payInfo onViewController:self];
                [AppDelegate setPayingModule:MODULE_MALL_ACTIVITY];
                break;
                
            case 3:
                [user payWithChannel:@"wx" andInfo:payInfo onViewController:self];
                [AppDelegate setPayingModule:MODULE_MALL_ACTIVITY];
                break;
                
            case 4:
                [user payWithChannel:@"upmp" andInfo:payInfo onViewController:self];
                [AppDelegate setPayingModule:MODULE_MALL_ACTIVITY];
                break;
             */
                
            default:
                break;
        }
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if (alertView.tag == 20) {
        if (purseValueMall < [[self.activityInfo objectForKey:@"price"] floatValue])
            return NO;
    }
    return YES;
}

+ (void)askInstanceForCollection {
    [acdetailInstance askForCollection];
}

- (void)askForCollection {
    return;
    
    //check if already collected
    if ([self.activityInfo objectForKey:@"collected"] != [NSNull null] && [[self.activityInfo objectForKey:@"collected"] isEqualToString:@"1"]) {
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"收藏" message:@"您想要收藏此店么？\n" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"收藏", nil];
    alert.tag = 15;
    [alert show];
}

- (void)collectStore {
    [user collectStore:[[self.activityInfo objectForKey:@"storeID"] intValue]];
}

- (void)dismissActivityDetailsView {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
