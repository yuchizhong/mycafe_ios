//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TYPE_OFFLINE 0
#define TYPE_NORMAL 1
#define TYPE_PREORDER 2

@interface historyOrder : UITableViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

@property (nonatomic) NSInteger historyType;

@end

