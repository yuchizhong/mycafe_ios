//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface historyOrderSingle : UITableViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
    int orderCount;
    int orderID;
    BOOL local;
    int orderID_in;
}

@property (strong, atomic) NSString *storeID;
@property (strong, atomic) NSString *storeName;

@property (nonatomic) BOOL isPreorder;

-(void)setNewStoreID:(NSString*)sid andName:(NSString*)sname andOrderID:(int)oid;
-(void)setNewStoreIDOffine:(NSString*)sid andName:(NSString*)sname;

@end
