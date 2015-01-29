//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PURCHASED_CELL_HEIGHT self.view.frame.size.width * 0.24

@interface purchased : UITableViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UIAlertViewDelegate>

@property(atomic, strong) NSString *mall;

@end
