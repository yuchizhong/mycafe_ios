//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomIOS7AlertView.h"

@interface cart : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UITextFieldDelegate, CustomIOS7AlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *foodTable;

-(void)addToCart:(id)sender;
-(void)removeFromCart:(id)sender;

-(void)refresh;

-(void)askToPay:(BOOL)tableNumAvailable andTotal:(float)total;

+(cart*)getInstance;

@end

