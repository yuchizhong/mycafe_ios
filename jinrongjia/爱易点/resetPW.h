//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface resetPW : UIViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITableView *infoTable;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
- (IBAction)goLogin:(id)sender;

@end

