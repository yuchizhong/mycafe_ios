//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "loginView.h"
#import "data.h"
#import "extra.h"
#import "resetPW.h"

static int infoCellID;

static UITextField *accountText;
static UITextField *passwordText;

@interface loginView ()

@end

@implementation loginView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    SET_NAVBAR
    
    if ([extra getReg]) {
        UIViewController *regView = [self.storyboard instantiateViewControllerWithIdentifier:@"registerView"];
        [self.navigationController pushViewController:regView animated:NO];
    }
    
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
    return 2;
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
    
    
    switch (indexPath.row) {
        case 0:
            accountText = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.infoTable.frame.size.width - 20, 50)];
            accountText.textAlignment = NSTextAlignmentLeft;
            accountText.clearButtonMode = YES;
            accountText.delegate = self;
            accountText.keyboardType = UIKeyboardTypeNumberPad;
            accountText.placeholder = @"请输入手机号";
            [cell addSubview:accountText];
            break;
            
        default:
            passwordText = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.infoTable.frame.size.width - 20, 50)];
            passwordText.textAlignment = NSTextAlignmentLeft;
            passwordText.clearButtonMode = YES;
            passwordText.delegate = self;
            passwordText.secureTextEntry = YES;
            passwordText.placeholder = @"请输入密码";
            [cell addSubview:passwordText];
            break;
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

- (void)confirmLogin {
    if (accountText.text.length == 0) {
        [HTTPRequest alert:@"请输入手机号"];
        return;
    } else if (accountText.text.length != 11) {
        [HTTPRequest alert:@"手机号应为11位"];
        return;
    } else if (![[accountText.text substringToIndex:1] isEqualToString:@"1"]) {
        [HTTPRequest alert:@"手机号首位数字应为1"];
        return;
    } else if (passwordText.text.length == 0) {
        [HTTPRequest alert:@"请输入密码"];
        return;
    }
    BOOL ret = [user loginWithID:accountText.text andPassword:passwordText.text];
    if (ret) {
        [self dismissAll];
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

- (IBAction)goRegister:(id)sender {
    UIViewController *regView = [self.storyboard instantiateViewControllerWithIdentifier:@"registerView"];
    [self.navigationController pushViewController:regView animated:YES];
}

- (IBAction)goResetPW:(id)sender {
    UIViewController *regView = [self.storyboard instantiateViewControllerWithIdentifier:@"resetPWView"];
    [self.navigationController pushViewController:regView animated:YES];
}

@end
