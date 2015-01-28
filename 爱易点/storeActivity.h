//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "areaPicker.h"
#import "data.h"
#import "AppDelegate.h"
#import "MJRefresh.h"
//#import "NIDropDown.h"

@interface storeActivity : UIViewController<UITableViewDelegate, UITableViewDataSource, /*UIPickerViewDelegate, UIPickerViewDataSource,*/ UIAlertViewDelegate, DOPDropDownMenuDataSource, DOPDropDownMenuDelegate>

@property (strong, atomic) IBOutlet UITableView *storeTable;
@property (strong, nonatomic) IBOutlet areaPicker *pickerView;
@property (strong, atomic) IBOutlet UIPickerView *areaPickerRoll;
//@property (strong, nonatomic) IBOutlet UIView *toolbarView;

@property (strong, atomic) NSMutableArray *filterOptionList;
@property (strong, atomic) NSMutableArray *selectedFilterOptions;

@property (atomic) BOOL showOnlyCollected;

//-(void)pickerDone;

+(UIImage*)getStarImage;
+(UIImage*)getStarImageHalfed;

@end

