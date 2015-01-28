//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#define NUM_PAGES 3

#import <UIKit/UIKit.h>

@interface launchInstrcutions : UIViewController<UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIPageControl *indicators;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end

