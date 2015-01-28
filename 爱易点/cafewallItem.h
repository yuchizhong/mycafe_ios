//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "areaPicker.h"
#import "data.h"
#import "AppDelegate.h"
#import "MJRefresh.h"

#define WALL_ITEM_CELL_HEIGHT 44
#define FOOD_INFO_HEIGHT WALL_ITEM_CELL_HEIGHT * 3

@interface cafeWallItem : UITableViewController<UIAlertViewDelegate>

-(void)setWallItemDetailInfo:(NSDictionary*)info;

@end

