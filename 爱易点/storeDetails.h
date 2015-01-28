//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "data.h"
#import "storeList.h"

@interface storeDetails : UIViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITextFieldDelegate, BMKMapViewDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *image;
@property (strong, nonatomic) IBOutlet UILabel *storetitle;
@property (strong, nonatomic) IBOutlet UILabel *stars;
@property (strong, nonatomic) IBOutlet UILabel *price;
@property (strong, nonatomic) IBOutlet UITableView *infotable;
@property (strong, nonatomic) IBOutlet UILabel *supportLabel;
@property (strong, nonatomic) IBOutlet UIImageView *supportIcon;
@property (strong, nonatomic) IBOutlet UIButton *collect;

-(IBAction)doCollect:(id)sender;

+(any_store*)getPassedStoreDetails;

@end

