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

@interface cafeWall : UIViewController<UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

@property (strong, atomic) IBOutlet UITableView *storeTable;

@property (strong, atomic) NSMutableArray *filterOptionList;
@property (strong, atomic) NSMutableArray *selectedFilterOptions;

-(void)refresh;
+(cafeWall*)getInstance;

@end

