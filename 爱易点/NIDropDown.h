//
//  NIDropDown.h
//  NIDropDown
//
//  Created by Bijesh N on 12/28/12.
//  Copyright (c) 2012 Nitor Infotech. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NIDropDown;
@protocol NIDropDownDelegate
- (void) niDropDownDelegateMethod:(NIDropDown *)sender withIndex:(NSInteger)index;
@end 

@interface NIDropDown : UIView <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) id <NIDropDownDelegate> delegate;
@property(nonatomic, strong) UIButton *btnSender;

-(id)init;

-(void)hideDropDown:(UIButton *)b;
-(id)showDropDown:(UIButton *)b withHeight:(CGFloat *)height andArray:(NSArray *)arr;
@end
