//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

//底部分栏控制器

#import <UIKit/UIKit.h>

@interface rootTabViewController : UITabBarController<UITabBarControllerDelegate, UITabBarDelegate>

+(void)setStoreListNavController:(UINavigationController*)navController;

@end