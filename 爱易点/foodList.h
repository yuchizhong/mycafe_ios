//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "data.h"

@interface foodList : UIViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
    BOOL followScroll;
}

@property (strong, nonatomic) IBOutlet UITableView *foodTable;
@property (strong, nonatomic) IBOutlet UITableView *catagoryTable;
@property (strong, nonatomic) IBOutlet UIImageView *topimage;
@property (strong, atomic) UIView *selectedBack;

@property (atomic, strong) NSMutableArray *catagories;
@property (atomic, strong) NSMutableArray *menu;
@property (atomic, strong) NSMutableArray *menuByCataAndDefault;
@property (atomic, strong) NSMutableArray *menuByCataAndName;
@property (atomic, strong) NSMutableArray *menuByCataAndPopularity;

-(void)addToCart:(id)sender;
-(void)removeFromCart:(id)sender;

+(void)askForReset;

-(void)refresh;

+(BBBadgeBarButtonItem*)cartButton;

@end
