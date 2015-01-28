//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "data.h"
#import "CustomIOS7AlertView.h"

@interface preorderConfirm : UIViewController<CustomIOS7AlertViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *typeLabel;
@property (strong, nonatomic) IBOutlet UILabel *confirmTitle;
@property (strong, nonatomic) IBOutlet UISegmentedControl *typeSwitch;
@property (strong, nonatomic) IBOutlet UILabel *numPeopleLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UIView *blankNumPeopleView;
@property (strong, nonatomic) IBOutlet UIDatePicker *timePicker;

- (IBAction)confirmPay:(id)sender;

@end
