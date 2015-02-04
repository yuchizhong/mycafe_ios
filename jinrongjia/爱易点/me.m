//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "me.h"
#import "data.h"
#import "extra.h"
#import "storeList.h"
#import "purchased.h"

#define CELL_HEIGHT 40

static int infoCellID;

@interface me ()

@property (atomic, strong) UILabel *purseMoney;
@property (atomic) NSInteger usingThreads;
@property (atomic) BOOL shouldShowNavbar;
@property (atomic) BOOL stopMovingStatusBar;

@end

@implementation me

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.shouldShowNavbar = YES;
    self.stopMovingStatusBar = NO;
    
    SET_NAVBAR
    
    infoCellID = 0;
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.infoTable setBackgroundColor:[UIColor clearColor]];
    
    self.purseMoney = [[UILabel alloc] init];
    [self.purseMoney setTextAlignment:NSTextAlignmentRight];
    [self.purseMoney setTextColor:[UIColor grayColor]];
    [self.purseMoney setFont:UI_TEXT_FONT];
    self.usingThreads = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.purseMoney setText:@"加载中"];
    [self.infoTable reloadData];
    //当前不需要显示钱包余额
    [NSThread detachNewThreadSelector:@selector(loadMoney) toTarget:self withObject:nil];
    self.stopMovingStatusBar = NO;
    if (self.infoTable.contentOffset.y > self.infoTable.frame.size.width * 0.618 && !self.stopMovingStatusBar)
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    else if (!self.stopMovingStatusBar)
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.shouldShowNavbar)
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.shouldShowNavbar = YES;
    self.stopMovingStatusBar = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

- (void)loadMoney {
    if (self.usingThreads > 0)
        return;
    self.usingThreads++;
    NSInteger m = -1;
    while (m < 0) {
        m = [user getCreditForStoreIDAsync:app_store_id];
    }
    [self.purseMoney setText:[NSString stringWithFormat:@"剩余%ld分", m]];
    self.usingThreads--;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([user getCurrentID] == nil)
        return 3;
    else
        return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([user getCurrentID] == nil) {
        switch (section) {
            case 0:
                return 1;
                break;
                
            case 1:
                return 0;
                break;
                
            case 2: //登陆
                return 2;
                break;
                
            case 3:
                return 0;
                break;
                
            default:
                return 0;
                break;
        }
    } else {
        switch (section) {
            case 0:
                return 1;
                break;
                
            case 1: //历史
                return 0;
                break;
                
            case 2: //钱包，积分
                return 1;
                break;
                
            case 3: //收藏，商城
                return 0;
                break;
                
            case 4: //登出
                return 2;
                break;
                
            case 5:
                return 0;
                break;
                
            default:
                return 0;
                break;
        }
    }
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0 || ([user getCurrentID] != nil && section == 2))
        return 40;
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return self.infoTable.frame.size.width * 0.618;
    }
    return CELL_HEIGHT;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y > self.infoTable.frame.size.width * 0.618 && !self.stopMovingStatusBar)
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    else if (!self.stopMovingStatusBar)
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
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
        UIImageView *imageV = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.infoTable.frame.size.width, self.infoTable.frame.size.width * 0.618)];
        
        [imageV setImage:[UIImage imageNamed:@"user_background.png"]];
        [imageV setContentMode:UIViewContentModeScaleAspectFill];
        [imageV setClipsToBounds:YES];
        
        //userImageView = imageV;
        [cell addSubview:imageV];
        
        //add circle portrait
        NSString *username = [user getCurrentUser];
        if (username == nil)
            username = @"未登录";
        
        float portraitSize = self.infoTable.frame.size.width * 0.618 * 0.5;
        UIImageView *portraitView = [[UIImageView alloc] initWithFrame:CGRectMake((self.infoTable.frame.size.width - portraitSize) / 2.0, (self.infoTable.frame.size.width * 0.618 - portraitSize) / 2.0, portraitSize, portraitSize)];
        NSString *userImage = nil;
        if (userImage != nil) {
            [portraitView setImageWithURL:[NSURL URLWithString:userImage] placeholderImage:[UIImage imageNamed:@"nouser.png"] options:SDWebImageRetryFailed];
        } else {
            [portraitView setImage:[UIImage imageNamed:@"nouser.png"]];
        }
        CALayer *layer = [portraitView layer];
        [layer setMasksToBounds:YES];
        [layer setCornerRadius:portraitSize / 2.0];
        [layer setBorderWidth:3.0];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGColorRef colorref = CGColorCreate(colorSpace,(CGFloat[]){1, 1, 1, 0.8});
        [layer setBorderColor:colorref]; //边框颜色
        [cell addSubview:portraitView];
        CGColorSpaceRelease(colorSpace);
        CGColorRelease(colorref);
        
        //add user nickname
        float nameLabelY = (self.infoTable.frame.size.width * 0.618 - portraitSize) / 2.0 + portraitSize;
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.infoTable.frame.size.width / 2 - 150, nameLabelY, 300, self.infoTable.frame.size.width * 0.6 - nameLabelY)];
        if ([username isEqualToString:@"未登录"])
            [nameLabel setText:username];
        else
            [nameLabel setText:[NSString stringWithFormat:@"%@", username]];
        [nameLabel setTextAlignment:NSTextAlignmentCenter];
        [nameLabel setTextColor:[UIColor whiteColor]];
        [nameLabel setFont:[UIFont systemFontOfSize:18]];
        [cell addSubview:nameLabel];
    } else if ([user getCurrentID] == nil) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.infoTable.frame.size.width, CELL_HEIGHT)];
        [l setTextAlignment:NSTextAlignmentCenter];
        [l setTextColor:COFFEE_VERY_DARK];
        [l setFont:UI_TEXT_FONT_BOLD];
        if (indexPath.section == 2 && indexPath.row == 0) {
            [l setText:@"登录"];
        } else if (indexPath.section == 2 && indexPath.row == 1) {
            [l setText:@"注册"];
        } else if (indexPath.section == 3 && indexPath.row == 0) {
            [l setText:@"声明与条款"];
        }
        [cell addSubview:l];
    } else {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.infoTable.frame.size.width, CELL_HEIGHT)];
        [l setTextAlignment:NSTextAlignmentCenter];
        [l setTextColor:COFFEE_VERY_DARK];
        [l setFont:UI_TEXT_FONT_BOLD];
        if (indexPath.section == 1 && indexPath.row == 0) {
            [l setText:@"消费记录"];
        } else if (indexPath.section == 2 && indexPath.row == 0) {
            [l setText:@"我的积分"];
            [l setFrame:CGRectMake(16, 0, 150, CELL_HEIGHT)];
            [l setTextAlignment:NSTextAlignmentLeft];
            
            //add value label
            [self.purseMoney setFrame:CGRectMake(self.infoTable.frame.size.width - 156, 0, 140, CELL_HEIGHT)];
            [self.purseMoney setTextAlignment:NSTextAlignmentRight];
            [cell addSubview:self.purseMoney];
        } else if (indexPath.section == 3 && indexPath.row == 0) {
            [l setText:@"我的收藏"];
        } else if (indexPath.section == 3 && indexPath.row == 1) {
            [l setText:@"商城"];
        } else if (indexPath.section == 4 && indexPath.row == 0) {
            [l setText:@"修改昵称"];
        } else if (indexPath.section == 4 && indexPath.row == 1) {
            [l setText:@"登出"];
        } else if (indexPath.section == 5 && indexPath.row == 0) {
            [l setText:@"声明与条款"];
        }
        [cell addSubview:l];
    }
    
    
    //draw separator line
    if (indexPath.section > 0) {
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, CELL_HEIGHT, tableView.frame.size.width, 0.5)];
        UIGraphicsBeginImageContext(imageView.frame.size);
        [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
        CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 171.0/255.0, 99.0/255.0, 49.0/255.0, 1.0);  //颜色
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
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 171.0/255.0, 99.0/255.0, 49.0/255.0, 1.0);  //颜色
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
    if ([user getCurrentID] == nil) {
        if (indexPath.section == 2 && indexPath.row == 0) {
            //登陆
            [self pushLoginView:NO];
        } else if (indexPath.section == 2 && indexPath.row == 1) {
            //注册
            [self pushLoginView:YES];
        } else if (indexPath.section == 3 && indexPath.row == 0) {
            UIViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"declarations"];
            [self.navigationController pushViewController:v animated:YES];
        }
    } else {
        if (indexPath.section == 1 && indexPath.row == 0) {
            //历史点单
            UIViewController *historyOrderController = [self.storyboard instantiateViewControllerWithIdentifier:@"historyType"];
            [self.navigationController pushViewController:historyOrderController animated:YES];
        } else if (indexPath.section == 2 && indexPath.row == 0) {
            //积分
            UIViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"purse"];
            [self.navigationController pushViewController:v animated:YES];
        } else if (indexPath.section == 3 && indexPath.row == 0) {
            //收藏
            storeList *v = (storeList*)[AppDelegate getStoreListController];
            [v setMall:nil];
            [v setShowOnlyCollected:YES];
            [v setNeedReloadStoreList:YES];
            [self.navigationController pushViewController:v animated:YES];
        } else if (indexPath.section == 3 && indexPath.row == 1) {
            //商城
            storeList *v = (storeList*)[AppDelegate getStoreListController];
            [v setMall:@"cash"];
            [v setShowOnlyCollected:NO];
            [v setNeedReloadStoreList:YES];
            [self.navigationController pushViewController:v animated:YES];
        } else if (indexPath.section == 4 && indexPath.row == 0) {
            //修改昵称
            UIAlertView *changeName = [[UIAlertView alloc] initWithTitle:@"修改昵称" message:@"请输入新昵称：" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            changeName.tag = 1001;
            [changeName setAlertViewStyle:UIAlertViewStylePlainTextInput];
            //[[changeName textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDefault];
            [changeName show];
        } else if (indexPath.section == 4 && indexPath.row == 1) {
            //登出
            UIAlertView *logoutConfirm = [[UIAlertView alloc] initWithTitle:@"登出" message:@"您确认要登出么？" delegate:self cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
            logoutConfirm.tag = 1000;
            [logoutConfirm show];
        } else if (indexPath.section == 5 && indexPath.row == 0) {
            UIViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"declarations"];
            [self.navigationController pushViewController:v animated:YES];
        }
    }
    
    [self.infoTable deselectRowAtIndexPath:indexPath animated:YES];
    [self.infoTable reloadData];
}

- (void)pushLoginView:(BOOL)reg {
    if (reg) //register
        [extra setReg:YES];
    else
        [extra setReg:NO];
    self.shouldShowNavbar = NO;
    UIViewController *goLoginController = [self.storyboard instantiateViewControllerWithIdentifier:@"loginRoot"];
    [self presentViewController:goLoginController animated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1000 && buttonIndex == 1) {
        [user logOut];
        [self.infoTable reloadData];
    }
    if (alertView.tag == 1001 && buttonIndex == 1) {
        if ([alertView textFieldAtIndex:0].text.length == 0) {
            [HTTPRequest alert:@"昵称不能为空"];
            return;
        }
        [user changeNickname:[alertView textFieldAtIndex:0].text];
        [self.infoTable reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
