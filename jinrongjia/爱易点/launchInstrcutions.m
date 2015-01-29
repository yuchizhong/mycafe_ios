//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "launchInstrcutions.h"
#import "config.h"

@interface launchInstrcutions ()

@end

@implementation launchInstrcutions

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int page = scrollView.contentOffset.x / self.view.frame.size.width;
    if (page < NUM_PAGES) {
        [self.indicators setCurrentPage:page];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self.view setBackgroundColor:COFFEE_DARK];
    [self.scrollView setBackgroundColor:[UIColor clearColor]];
    
    [self.indicators setNumberOfPages:NUM_PAGES];
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width * NUM_PAGES, self.view.frame.size.height)];
    
    //add images
    for (int i = 0; i < NUM_PAGES; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * i, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        [imageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"launch%d.png", i + 1]]];
        [self.scrollView addSubview:imageView];
    }
    
    //add a start button
    float buttonHeight = 35, buttonWidth = 100;
    UIButton *okay = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width * (NUM_PAGES - 1) + self.view.frame.size.width / 2 - buttonWidth / 2, self.view.frame.size.height - 110, buttonWidth, buttonHeight)];
    [okay setTitle:@"开始使用" forState:UIControlStateNormal];
    [okay setBackgroundColor:[UIColor clearColor]];
    [okay setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];;
    [okay.titleLabel setFont:UI_TEXT_FONT];
    
    [okay.layer setMasksToBounds:YES];
    [okay.layer setCornerRadius:4.0];
    [okay.layer setBorderWidth:1.0];
    [okay.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    [okay addTarget:self action:@selector(dismissInstructions) forControlEvents:UIControlEventTouchDown];
    
    [self.scrollView addSubview:okay];
}

- (void)dismissInstructions {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
