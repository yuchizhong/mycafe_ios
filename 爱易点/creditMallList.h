//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ITEM_CELL_HEIGHT 120

@interface creditMallList : UITableViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UIAlertViewDelegate> {
    int storeID;
}

@property (atomic, strong) NSString *mall;

-(void)setStoreID:(int)sid;

@end
