//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface evalView : UIViewController<UITextFieldDelegate>

@property (atomic, strong) NSString *storeID;
@property (atomic, strong) NSString *storeName;

@property (strong, nonatomic) IBOutlet UILabel *ratingLabel;
@property (strong, atomic) IBOutlet UIButton *evalButton;

- (IBAction)doEval:(id)sender;

@end

