//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "data.h"

@interface item : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *foodImageView;
@property (strong, nonatomic) IBOutlet UILabel *foodTitle;
@property (strong, nonatomic) IBOutlet UILabel *foodPrice;
@property (strong, nonatomic) IBOutlet UITableView *infoTable;
@property (strong, nonatomic) IBOutlet UIView *controlView;
@property (strong, nonatomic) IBOutlet UIButton *imgButton;
@property (strong, nonatomic) IBOutlet UIButton *imgButtonSmall;
@property (strong, nonatomic) IBOutlet UIButton *buyButton;

-(IBAction)enlargeImg:(id)sender;
-(IBAction)enlittle:(id)sender;
- (IBAction)buyClicked:(id)sender;

@property (atomic, strong) NSDictionary *infoPassed;
@property(atomic, strong) NSString *desp;
@property(atomic, strong) NSMutableArray *notes;

@property(atomic) BOOL beenPurchased;

@end

