//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "rootTabViewController.h"
#import "data.h"
#import "AppDelegate.h"

//static int lastItemTag = 0;
static UINavigationController *storeListNavController = nil;

@interface rootTabViewController ()

@property (strong, atomic) UIViewController *mainStoreView;

@end

@implementation rootTabViewController

+ (void)setStoreListNavController:(UINavigationController*)navController {
    storeListNavController = navController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.mainStoreView = nil;
    
    //清理过期缓存
    [[SDImageCache sharedImageCache] cleanDisk];
    
    //清除所有缓存
    if (CLEAR_IMAGE_CACHE)
        [[SDImageCache sharedImageCache] clearDisk];
    
    //lastItemTag = 0;
    
    self.delegate = self;
    [self.tabBar setTintColor:COFFEE_MORE_DARK];
    //[self.tabBar setTranslucent:NO];
    
    //自定义item
    /*
    NSArray *itemImageNames = @[]; //4 images
    NSArray *itemSelectedImageNames = @[]; //4 images
    for (int i = 0; i < 4; i++) {
        UITabBarItem *item = [self.tabBar.items objectAtIndex:i];
        item.image = [[UIImage imageNamed:itemImageNames[i]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        item.selectedImage = [[UIImage imageNamed:itemSelectedImageNames[i]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
     */
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.selectedIndex = lastItemTag;
}
 */

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    //每个分栏跳转回根页面
    for (UINavigationController *cv in self.viewControllers) {
        [cv popToRootViewControllerAnimated:NO];
    }
    
    //判断是否需要刷新店家列表
    if (viewController.tabBarItem.tag == 0 && (((storeList*)[AppDelegate getStoreListController]).mall != nil || ((storeList*)[AppDelegate getStoreListController]).showOnlyCollected)) {
        [(storeList*)[AppDelegate getStoreListController] setMall:nil];
        [(storeList*)[AppDelegate getStoreListController] setShowOnlyCollected:NO];
        [(storeList*)[AppDelegate getStoreListController] setNeedReloadStoreList:YES];
        storeListNavController = [storeListNavController initWithRootViewController:[AppDelegate getStoreListController]];
    }
}

/*
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if (item.tag != 1)
        lastItemTag = (int)item.tag;
    else if (UI_JUMP_USE_DISPATCH) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.mainStoreView == nil)
                self.mainStoreView = [self.storyboard instantiateViewControllerWithIdentifier:@"storeRootView"];
            [self presentViewController:self.mainStoreView animated:NO completion:nil];
        });
    } else {
        if (self.mainStoreView == nil)
            self.mainStoreView = [self.storyboard instantiateViewControllerWithIdentifier:@"storeRootView"];
        [self presentViewController:self.mainStoreView animated:NO completion:nil];
    }

}
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
