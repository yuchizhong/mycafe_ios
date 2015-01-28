//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "wallSendInfo.h"
#import "data.h"
#import "AppDelegate.h"
#import "cafewall.h"

static float purseValue;

@interface wallSendInfo ()

@property (atomic) float wallTotal;
@property (atomic) NSInteger wallOrderID;

@end

@implementation wallSendInfo

@synthesize foodImage;
@synthesize foodTitle;
@synthesize foodDescription;
@synthesize messageBox;
@synthesize lowerAgeBox;
@synthesize upperAgeBox;
@synthesize genderSwitch;
@synthesize giftFoodID;
@synthesize wallTotal;
@synthesize wallOrderID;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [lowerAgeBox setKeyboardType:UIKeyboardTypeNumberPad];
    [upperAgeBox setKeyboardType:UIKeyboardTypeNumberPad];
    
    foodInfo *finfo = (foodInfo*)[[store getMenu] objectAtIndex:[store getIndexForFoodID:giftFoodID]];
    [foodTitle setText:finfo.title];
    [foodDescription setText:finfo.mainDescription];
    
    //load food image
    //round corner image
    UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(5, foodImage.frame.size.height / 2 - 1, foodImage.frame.size.width - 10, 2)];
    [loading setProgress:0.0];
    [loading setProgressViewStyle:UIProgressViewStyleDefault];
    [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
    [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
    [foodImage addSubview:loading];
    NSString *url = [NSString stringWithFormat:@"%@/%@/dishimage/dish%d/%@", SERVER_ADDRESS, [store getCurrentStoreFolder], giftFoodID, finfo.image];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //[[SDImageCache sharedImageCache] clearDisk];
    [foodImage setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"noimage.png"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        float percentage = (float)receivedSize / (float)expectedSize;
        //update loading progress bar
        [loading setProgress:percentage];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        //dismiss loading progress bar
        [loading removeFromSuperview];
    }];
    [foodImage setContentMode:UIViewContentModeScaleAspectFit];
    CALayer *l = [foodImage layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:3.0];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [messageBox resignFirstResponder];
    [lowerAgeBox resignFirstResponder];
    [upperAgeBox resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)confirm {
    NSInteger gender   = [genderSwitch selectedSegmentIndex];
    NSInteger lowerAge = [[lowerAgeBox text] integerValue];
    NSInteger upperAge = [[upperAgeBox text] integerValue];
    
    if ([lowerAgeBox text] == nil || [[lowerAgeBox text] isEqualToString:@""])
        lowerAge = 0;
    if ([upperAgeBox text] == nil || [[upperAgeBox text] isEqualToString:@""])
        upperAge = 0;
    
    //submit
    NSInteger orderID = [store submitCafeWallOrder:giftFoodID withMessage:messageBox.text lowerAge:lowerAge upperAge:upperAge gender:gender];
    //promote payment if success
    if (orderID >= 0) {
        /*
        [HTTPRequest alert:@"发布成功"];
        [self.navigationController popToRootViewControllerAnimated:YES];
        [[cafeWall getInstance] refresh];
         */
        
        [self preparePaymentForOrderID:orderID];
    }
}

- (void)preparePaymentForOrderID:(NSInteger)orderID {
    BEGIN_LOADING
    
    foodInfo *finfo = (foodInfo*)[[store getMenu] objectAtIndex:[store getIndexForFoodID:giftFoodID]];
    float totalToPay = [finfo getPrice];
    
    purseValue = [user getPurseMoneyAsync];
    NSString *purseStr = nil;
    if (purseValue < totalToPay) {
        purseStr = PURSE_INSUF_FUND;
    } else {
        purseStr = PURSE_FUND_PAY;
    }
    
    END_LOADING
    
    //传递postID
    wallOrderID = orderID;
    
    CustomIOS7AlertView *alert = [[CustomIOS7AlertView alloc]init];
    UIView *infoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 300, 115)];
    [infoView setBackgroundColor:[UIColor clearColor]];
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 40)];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setText:@"支付"];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [infoView addSubview:titleLabel];
    UILabel *infoLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 35, 300, 70)];
    [infoLabel setTextAlignment:NSTextAlignmentCenter];
    [infoLabel setNumberOfLines:0];
    [infoLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [infoLabel setFont:[UIFont systemFontOfSize:13]];
    [infoLabel setText:[NSString stringWithFormat:@"金额：￥%.2f", totalToPay]];
    [infoLabel setBackgroundColor:[UIColor clearColor]];
    [infoView addSubview:infoLabel];
    [alert setContainerView:infoView];
    [alert setButtonTitles:@[purseStr, PING_PAYMENT_OPTION, @"取消"]];
    alert.delegate = self;
    if (purseValue < totalToPay)
        alert.disableFirstButton = YES;
    alert.tag = 21;
    [alert show];
} 

- (void)customIOS7dialogButtonTouchUpInside:(id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (((CustomIOS7AlertView*)alertView).tag == 21) {
        foodInfo *finfo = (foodInfo*)[[store getMenu] objectAtIndex:[store getIndexForFoodID:giftFoodID]];
        float totalToPay = [finfo getPrice];

        BOOL success = NO;
        BOOL canPopToRootViewController = NO;
        
        switch (buttonIndex) {
            case 0: //UniCafe钱包付款
                success = [user payByPurseForWallPost:wallOrderID ofAmount:totalToPay];
                canPopToRootViewController = YES;
                break;
                
            case 1:
                success = [user payWallPost:wallOrderID byChannel:@"alipay" ofAmount:totalToPay onViewContoller:self];
                break;
                
            case 2:
                success = [user payWallPost:wallOrderID byChannel:@"wx" ofAmount:totalToPay onViewContoller:self];
                break;
                /*
                 case 3:
                 success = [user payWithChannel:@"upmp" andAmount:totalToPay onViewController:self];
                 break;
                 */
            default:
                break;
        }
        if (success && canPopToRootViewController) {
            [self.navigationController popToRootViewControllerAnimated:YES];
            [[cafeWall getInstance] refresh];
        } else if (success) {
            [AppDelegate setPayingModule:MODULE_CAFE_WALL];
        }
    }
    [alertView close];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 201 && buttonIndex == 1) {
        [self confirm];
    }
}

- (IBAction)submitWall:(id)sender {
    NSInteger gender   = [genderSwitch selectedSegmentIndex];
    NSInteger lowerAge = [[lowerAgeBox text] integerValue];
    NSInteger upperAge = [[upperAgeBox text] integerValue];
    
    if ([lowerAgeBox text] == nil || [[lowerAgeBox text] isEqualToString:@""])
        lowerAge = 0;
    if ([upperAgeBox text] == nil || [[upperAgeBox text] isEqualToString:@""])
        upperAge = 0;
    
    //check input
    if (lowerAge < 0) {
        [HTTPRequest alert:@"年龄下限不能小于0"];
        return;
    }
    if (upperAge > 150) {
        [HTTPRequest alert:@"年龄上限太大"];
        return;
    }
    if (lowerAge > 0 && upperAge > 0 && lowerAge > upperAge) {
        [HTTPRequest alert:@"年龄下限不能大于上限"];
        return;
    }
    
    NSMutableString *msgBody = [[NSMutableString alloc] initWithString:@""];
    if (gender == 0) {
        [msgBody appendFormat:@"性别：不限\n"];
    } else {
        [msgBody appendFormat:@"性别：%@\n", gender == 1 ? @"仅限男士" : @"仅限女士"];
    }
    [msgBody appendFormat:@"年龄：%@ - %@", lowerAge == 0 ? @"不限" : [NSString stringWithFormat:@"%d岁", lowerAge],
                                         upperAge == 0 ? @"不限" : [NSString stringWithFormat:@"%d岁", upperAge]];
    
    UIAlertView *cv = [[UIAlertView alloc] initWithTitle:@"信息确认" message:msgBody delegate:self cancelButtonTitle:@"再看看" otherButtonTitles:@"确认并支付", nil];
    [cv setTag:201];
    [cv show];
}

@end
