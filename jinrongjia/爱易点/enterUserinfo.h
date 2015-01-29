//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface enterUserinfo : UIViewController<UIAlertViewDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *infoTable;
@property (strong, nonatomic) IBOutlet UILabel *whyNeedUserinfo;

-(IBAction)dismissUserinfo:(id)sender;
-(IBAction)confirmUserinfo:(id)sender;

@end

