//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "resetPW.h"
#import "data.h"

static int infoCellID;

static UITextField *accountText;
static UITextField *verificationText;
static UITextField *passwordText;
static UITextField *passwordText2;
static UIButton *getVerfButton;
static NSTimer *retryTimer = nil;
static int retryTime = 0;

@interface resetPW ()

@end

@implementation resetPW

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    SET_NAVBAR
    
    infoCellID = 0;
    
    UINavigationItem *item = self.navigationItem;
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(dismissAll)];
    [item setLeftBarButtonItem:leftButton];

    
    [self.view setBackgroundColor:UI_TABLE_BACKGROUND_COLOR];
    [self.infoTable setBackgroundColor:UI_TABLE_BACKGROUND_COLOR];
    
    CALayer *l = [self.loginButton layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:6.0];
    
    //[user requestFromServerMatch];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.infoTable reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    return v;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *TableSampleIdentifier = [NSString stringWithFormat:@"tableCellID%d", infoCellID];
    infoCellID++;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:
                             TableSampleIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:TableSampleIdentifier];
    }
    
    
    if (indexPath.row == 0) {
        accountText = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.infoTable.frame.size.width - 110, 50)];
        accountText.textAlignment = NSTextAlignmentLeft;
        accountText.clearButtonMode = YES;
        accountText.delegate = self;
        accountText.keyboardType = UIKeyboardTypeNumberPad;
        accountText.placeholder = @"请输入手机号";
        [cell addSubview:accountText];
        
        getVerfButton = [[UIButton alloc] initWithFrame:CGRectMake(self.infoTable.frame.size.width - 100, 10, 90, 30)];
        getVerfButton.titleLabel.font = [UIFont systemFontOfSize:16];
        if (retryTime == 0)
            [getVerfButton setTitle:@"获取验证码" forState:UIControlStateNormal];
        else {
            [getVerfButton setTitle:[NSString stringWithFormat:@"%d秒后重试", retryTime] forState:UIControlStateNormal];
            [getVerfButton setEnabled:NO];
        }
        [getVerfButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [getVerfButton setBackgroundColor:[UIColor orangeColor]];
        [getVerfButton addTarget:self action:@selector(sendCode) forControlEvents:UIControlEventTouchUpInside];
        CALayer *l = [getVerfButton layer];
        [l setMasksToBounds:YES];
        [l setCornerRadius:6.0];
        [cell addSubview:getVerfButton];
    } else {
        switch (indexPath.row) {
            case 1:
                verificationText = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.infoTable.frame.size.width - 20, 50)];
                verificationText.textAlignment = NSTextAlignmentLeft;
                verificationText.clearButtonMode = YES;
                verificationText.delegate = self;
                verificationText.keyboardType = UIKeyboardTypeNumberPad;
                verificationText.placeholder = @"验证码";
                [cell addSubview:verificationText];
                break;
                
            case 2:
                passwordText = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.infoTable.frame.size.width - 20, 50)];
                passwordText.textAlignment = NSTextAlignmentLeft;
                passwordText.clearButtonMode = YES;
                passwordText.delegate = self;
                passwordText.secureTextEntry = YES;
                passwordText.placeholder = @"请输入密码";
                [cell addSubview:passwordText];
                break;
                
            default:
                passwordText2 = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.infoTable.frame.size.width - 20, 50)];
                passwordText2.textAlignment = NSTextAlignmentLeft;
                passwordText2.clearButtonMode = YES;
                passwordText2.delegate = self;
                passwordText2.secureTextEntry = YES;
                passwordText2.placeholder = @"请重新输入密码";
                [cell addSubview:passwordText2];
                break;
        }
    }
    
    
    //draw separator line
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 50, tableView.frame.size.width, 0.5)];
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

- (void)confirmLogin { //register
    if (accountText.text.length == 0) {
        [HTTPRequest alert:@"请先输入手机号"];
        return;
    } else if (accountText.text.length != 11) {
        [HTTPRequest alert:@"手机号应为11位"];
        return;
    } else if (passwordText.text.length == 0) {
        [HTTPRequest alert:@"请输入密码"];
        return;
    } else if (![passwordText.text isEqualToString:passwordText2.text]) {
        [HTTPRequest alert:@"两次输入的密码不一致"];
        return;
    }
    BOOL ret = [user resetPWWithID:accountText.text andPassword:passwordText.text andVerficationCode:verificationText.text];
    if (ret) {
        [self dismissAll];
    }
}

- (void)sendCode {
    if ([accountText.text isEqualToString:@""]) {
        [HTTPRequest alert:@"请先输入手机号"];
    } else if (accountText.text.length != 11) {
        [HTTPRequest alert:@"手机号应为11位"];
    } else {
        BOOL ret = [user sendVerficationCodeTo:accountText.text];
        if (ret) {
            [getVerfButton setTitle:@"60秒后重试" forState:UIControlStateNormal];
            [getVerfButton setEnabled:NO];
            retryTime = 60;
            if (retryTimer == nil || ![retryTimer isValid])
                retryTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeTick) userInfo:nil repeats:YES];
        }
    }
}

- (void)timeTick {
    retryTime--;
    [getVerfButton setTitle:[NSString stringWithFormat:@"%d秒后重试", retryTime] forState:UIControlStateNormal];
    if (retryTime == 0) {
        [retryTimer invalidate];
        [getVerfButton setTitle:@"重新发送" forState:UIControlStateNormal];
        [getVerfButton setEnabled:YES];
    }
}

- (void)dismissAll {
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

- (IBAction)goLogin:(id)sender {
    [self confirmLogin];
}

@end
