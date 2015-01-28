//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "enterUserinfo.h"
#import "data.h"

@interface enterUserinfo ()

@property (strong, atomic) UITextField* birth_year;
@property (strong, atomic) UITextField* birth_month;
@property (strong, atomic) UISegmentedControl *genderSwitch;

@end

@implementation enterUserinfo

@synthesize birth_year;
@synthesize birth_month;
@synthesize genderSwitch;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]
                             initWithStyle:UITableViewCellStyleDefault
                             reuseIdentifier:nil];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 180, 44)];
    [title setTextAlignment:NSTextAlignmentLeft];
    [title setTextColor:COFFEE_VERY_DARK];
    [cell addSubview:title];
    switch (indexPath.row) {
        case 0:
            [title setText:@"出生年月"];
            [cell addSubview:birth_year];
            [cell addSubview:birth_month];
            break;
            
        case 1:
            [title setText:@"性别"];
            [cell addSubview:genderSwitch];
            break;
            
        default:
            break;
    }
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.99, 0.99, 0.99, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell addSubview:imageView];
    
    UIImageView *imageViewBottom = [[UIImageView alloc]initWithFrame:CGRectMake(0, 44, tableView.frame.size.width, 0.5)];
    UIGraphicsBeginImageContext(imageViewBottom.frame.size);
    [imageViewBottom.image drawInRect:CGRectMake(0, 0, imageViewBottom.frame.size.width, imageViewBottom.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageViewBottom.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell addSubview:imageViewBottom];

    return cell;
}

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
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    //width: 115
    birth_year = [[UITextField alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 10 - 40 - 10 - 65, 7, 65, 30)];
    [birth_year setBackgroundColor:COFFEE_LIGHT];
    [birth_year setTextColor:COFFEE_VERY_DARK];
    [birth_year setKeyboardType:UIKeyboardTypeNumberPad];
    [birth_year setPlaceholder:@"1990"];
    
    birth_month = [[UITextField alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 10 - 40, 7, 40, 30)];
    [birth_month setBackgroundColor:COFFEE_LIGHT];
    [birth_month setTextColor:COFFEE_VERY_DARK];
    [birth_month setKeyboardType:UIKeyboardTypeNumberPad];
    [birth_month setPlaceholder:@"12"];
    
    genderSwitch = [[UISegmentedControl alloc]initWithItems:@[@"男士", @"女士"]];
    [genderSwitch setFrame:CGRectMake(self.view.frame.size.width - 10 - 115, (float)(44 - 29) / 2.0, 115, 29)];
    [genderSwitch setTintColor:COFFEE_VERY_DARK];
    [genderSwitch setSelectedSegmentIndex:0];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [birth_year resignFirstResponder];
    [birth_month resignFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissUserinfo:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)confirm {
    NSInteger year = [[birth_year text] integerValue];
    NSInteger month = [[birth_month text] integerValue];
    NSInteger gender = [genderSwitch selectedSegmentIndex];
    
    if ([user submitUserinfo:year andBirthMonth:month andGender:gender]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 101 && buttonIndex == 1) {
        [self confirm];
    }
}

- (IBAction)confirmUserinfo:(id)sender {
    NSInteger year = [[birth_year text] integerValue];
    NSInteger month = [[birth_month text] integerValue];
    
    //check input
    if (!(year >= 1900 && year <= 2015)) {
        [HTTPRequest alert:@"出生年份不正确\n出生年份应为1900年至今的4位数字"];
        return;
    }
    if (!(month >= 1 && month <= 12)) {
        [HTTPRequest alert:@"出生月份不正确\n出生年份应为1-12"];
        return;
    }
    
    UIAlertView *cv = [[UIAlertView alloc] initWithTitle:@"信息确认" message:@"输入后将不可更改，请确认信息正确无误" delegate:self cancelButtonTitle:@"稍后" otherButtonTitles:@"确认并提交", nil];
    [cv setTag:101];
    [cv show];
}

@end
