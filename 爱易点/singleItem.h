//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "data.h"

@interface singleItem : UIViewController<UITableViewDataSource, UITableViewDelegate> {
    int foodId;
}

@property (strong, atomic) foodInfo *food;
@property (strong, nonatomic) IBOutlet UIImageView *foodImageView;
@property (strong, nonatomic) IBOutlet UILabel *foodTitle;
@property (strong, nonatomic) IBOutlet UILabel *foodPrice;
@property (strong, nonatomic) IBOutlet UITableView *infoTable;
@property (strong, nonatomic) IBOutlet UIView *controlView;
@property (strong, nonatomic) IBOutlet UILabel *upLabel;
@property (strong, nonatomic) IBOutlet UIButton *imgButton;
@property (strong, nonatomic) IBOutlet UIButton *imgButtonSmall;
@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;

-(void)setFoodID;
-(void)addToCart;
-(void)removeFromCart;
-(void)setNewFood:(foodInfo *)foodIN;
- (IBAction)enlargeImg:(id)sender;
- (IBAction)enlittle:(id)sender;

@property(atomic, strong) UILabel *countLabel;
@property(atomic, strong) UIButton *addButton;
@property(atomic, strong) UIButton *subButton;
@property(atomic, strong) UIButton *giftButton;
@property(atomic, strong) NSString *desp;
@property(atomic, strong) NSMutableArray *notes;

@property (atomic) BOOL giftMode;

@end

