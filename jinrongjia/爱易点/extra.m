//
//  MenuViewController.m
//  SlideToDo
//
//  Created by Brandon King on 4/20/13.
//  Copyright (c) 2013 King's Cocoa. All rights reserved.
//

#import "extra.h"
#import "ECSlidingViewController.h"

static int foodIDPassed;
static foodInfo *foodInfoPassed;
static BOOL reg;
static BOOL returnFromLogin = NO;

@interface extra()

@end

static int i = 0;
static int type = 0;

@implementation extra

+ (void)setFoodInfo:(foodInfo*)finfo {
    foodInfoPassed = finfo;
}

+ (foodInfo*)getFoodInfo {
    return foodInfoPassed;
}

+ (void)setFoodID:(int)fid {
    foodIDPassed = fid;
}

+ (int)getFoodID {
    return foodIDPassed;
}

+ (void)setReg:(BOOL)ifReg {
    reg = ifReg;
}

+ (int)getReg {
    return reg;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (returnFromLogin) {
        returnFromLogin = NO;
        if ([user getCurrentID] != nil)
            [self pay];
    }
}

- (void)bout:(id)sender {
    for (UIView *v in ((UIButton*)sender).subviews) {
        if (v.tag == -100) {
            [(UIImageView*)v setFrame:CGRectMake(20, 10, 50, 50)];
            return;
        }
    }
}

- (void)bin:(id)sender {
    for (UIView *v in ((UIButton*)sender).subviews) {
        if (v.tag == -100) {
            [(UIImageView*)v setFrame:CGRectMake(25, 15, 40, 40)];
            return;
        }
    }
}

- (UIButton*)addButton:(NSString*)title {
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [addButton setFrame:CGRectMake(5, 25 + i * 95, 90, 90)];
    [addButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    //[addButton setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    //[addButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [addButton setBackgroundColor:[UIColor clearColor]];
    [addButton setTitle:title forState:UIControlStateNormal];
    //[addButton setTitle:@"+" forState:UIControlStateHighlighted];
    //[addButton setTitle:@"+" forState:UIControlStateSelected];
    [addButton setContentVerticalAlignment:UIControlContentVerticalAlignmentBottom];
    [addButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [addButton.layer setMasksToBounds:YES];
    [addButton.layer setCornerRadius:5.0]; //设置矩形四个圆角半径
    [addButton.layer setBorderWidth:1.0]; //边框宽度
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorref = CGColorCreate(colorSpace,(CGFloat[]){ 1, 0, 0, 1 });
    [addButton.layer setBorderColor:colorref];//边框颜色
    CGColorSpaceRelease(colorSpace);
    CGColorRelease(colorref);
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"e%d.png", i]]];
    [imgView setTag:-100];
    [imgView setFrame:CGRectMake(20, 10, 50, 50)];
    [addButton addSubview:imgView];
    
    [addButton addTarget:self action:@selector(bin:) forControlEvents:UIControlEventTouchDown];
    [addButton addTarget:self action:@selector(bout:) forControlEvents:UIControlEventTouchUpInside];
    [addButton addTarget:self action:@selector(bout:) forControlEvents:UIControlEventTouchCancel];
    [addButton addTarget:self action:@selector(bin:) forControlEvents:UIControlEventTouchDragEnter];
    [addButton addTarget:self action:@selector(bout:) forControlEvents:UIControlEventTouchDragExit];
    
    [addButton setTag:i];
    
    [self.sView setContentSize:CGSizeMake(100, 25 + i * 95 + 150)];
    [self.sView addSubview:addButton];
    i++;
    
    return addButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.slidingViewController setAnchorRightRevealAmount:100.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    //button
    UIButton *b = [self addButton:@"呼叫"];
    [b addTarget:self action:@selector(normalCall:) forControlEvents:UIControlEventTouchUpInside];
    
    b = [self addButton:@"加水"];
    [b addTarget:self action:@selector(normalCall:) forControlEvents:UIControlEventTouchUpInside];
    
    b = [self addButton:@"餐具"];
    [b addTarget:self action:@selector(normalCall:) forControlEvents:UIControlEventTouchUpInside];
    
    b = [self addButton:@"纸巾"];
    [b addTarget:self action:@selector(normalCall:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *payButton = [self addButton:@"结账"];
    [payButton addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
}

- (void)normalCall:(id)sender {
    type = (int)((UIButton*)sender).tag;
    [self call];
}

- (void)call {
    if ([store getTableNum] == 0) {
        //输入桌号
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"输入桌号" message:@"请输入桌号" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
        [alert setTag:100];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [alert show];
    } else {
        [store callService:type];
    }
}

- (void)pay {
    if ([store getTableNum] == 0) {
        //输入桌号
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"输入桌号" message:@"请输入桌号" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
        [alert setTag:110];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [alert show];
        return;
    }
    
    //get total from server
    float total = [orderInfo getPayTotalOnline];
    NSString *msg = [NSString stringWithFormat:@"请选择付款方式\n总金额：%.2f元", total];
    UIAlertView *alert;
    if (total == -2) {
        [extra setReg:NO];
        returnFromLogin = YES;
        UIViewController *goLoginController = [self.storyboard instantiateViewControllerWithIdentifier:@"loginRoot"];
        [self presentViewController:goLoginController animated:YES completion:nil];
        //alert = [[UIAlertView alloc]initWithTitle:@"没有登录" message:@"您还没有登录，请登录后再试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    } else if (total == -1)
        alert = [[UIAlertView alloc]initWithTitle:@"网络错误" message:NETWORK_ERROR delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    else if (total == 0)
        alert = [[UIAlertView alloc]initWithTitle:@"没有未付款" message:@"您的未付金额为零" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    else {
        alert = [[UIAlertView alloc]initWithTitle:@"付款" message:msg delegate:self cancelButtonTitle:@"稍后付款" otherButtonTitles:@"通过有你咖啡付款", @"当面付款", nil];
        alert.tag = 20;
    }
    [alert show];
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if (alertView.tag == 20) {
        return NO;
    }
    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 20) {
        switch (buttonIndex) {
            case 1:
                //调用支付宝
                break;
                
            case 2:
                [store callService:10];
                break;
                
            default:
                break;
        }
    } else if (alertView.tag == 100 && buttonIndex != 0) {
        NSString *tableNumStr = [alertView textFieldAtIndex:0].text;
        int tableNum = [tableNumStr intValue];
        if (tableNum == 0) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"桌号应为非零数字" delegate:self cancelButtonTitle:@"返回" otherButtonTitles:nil];
            [alert show];
            return;
        }
        [store setTableNum:tableNum];
        
        [self call];
    } else if (alertView.tag == 110 && buttonIndex != 0) {
        NSString *tableNumStr = [alertView textFieldAtIndex:0].text;
        int tableNum = [tableNumStr intValue];
        if (tableNum == 0) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"桌号应为非零数字" delegate:self cancelButtonTitle:@"返回" otherButtonTitles:nil];
            [alert show];
            return;
        }
        [store setTableNum:tableNum];
        
        [self pay];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
