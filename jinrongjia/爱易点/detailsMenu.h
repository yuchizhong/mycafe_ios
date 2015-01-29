//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "data.h"

@interface detailsMenu : UIViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
    BOOL followScroll;
}

@property (strong, nonatomic) IBOutlet UITableView *foodTable;
@property (strong, nonatomic) IBOutlet UITableView *catagoryTable;
@property (strong, nonatomic) IBOutlet UIImageView *topimage;
@property (atomic, strong) any_store *storeInfo;
@property (strong, atomic) UIView *selectedBack;

@property (atomic, strong) NSMutableArray *catagories;
@property (atomic, strong) NSMutableArray *menuOriginal;
@property (atomic, strong) NSMutableArray *menu;
@property (atomic, strong) NSMutableArray *menuByCataAndDefault;
@property (atomic, strong) NSMutableArray *menuByCataAndName;
@property (atomic, strong) NSMutableArray *menuByCataAndPopularity;

@property (atomic) BOOL showOnlyDiscount;

@property (atomic) BOOL giftMode;

-(void)setStoreDetailInfo:(any_store*)sinfo;
+(void)askForReset;

@end


