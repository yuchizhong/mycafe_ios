//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomIOS7AlertView.h"

@interface wallSendInfo : UIViewController<UIAlertViewDelegate, UITextFieldDelegate, CustomIOS7AlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *foodImage;
@property (strong, nonatomic) IBOutlet UILabel *foodTitle;
@property (strong, nonatomic) IBOutlet UILabel *foodDescription;

@property (strong, nonatomic) IBOutlet UITextView *messageBox;
@property (strong, nonatomic) IBOutlet UITextField *lowerAgeBox;
@property (strong, nonatomic) IBOutlet UITextField *upperAgeBox;
@property (strong, nonatomic) IBOutlet UISegmentedControl *genderSwitch;

-(IBAction)submitWall:(id)sender;

@property (atomic) NSInteger giftFoodID;

@end

