//
//  MenuViewController.h
//  SlideToDo
//
//  Created by Brandon King on 4/20/13.
//  Copyright (c) 2013 King's Cocoa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "data.h"

@interface extra : UIViewController<UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *sView;

//额外储存信息
+(void)setFoodID:(int)fid;
+(int)getFoodID;
+(void)setFoodInfo:(foodInfo*)finfo;
+(foodInfo*)getFoodInfo;

//弹出登陆框时设置是否是注册
+(void)setReg:(BOOL)ifReg;
+(int)getReg;

@end
