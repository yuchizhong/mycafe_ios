//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "evalView.h"
#import "data.h"
#import "storeList.h"

@interface evalView ()

@property (atomic) NSInteger rating;
@property (atomic) BOOL rated;

@end

@implementation evalView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.rating = 0;
    self.rated = NO;
    
    /*
    [self.evalButton.layer setMasksToBounds:YES];
    [self.evalButton.layer setCornerRadius:4.0]; //设置矩形四个圆角半径
     */
    
    [self.navigationItem setTitle:[NSString stringWithFormat:@"评价 %@", self.storeName]];
    
    //add 5 buttons
    for (int i = 0; i < 5; i++) {
        UIButton *star = [UIButton buttonWithType:UIButtonTypeCustom];
        [star setFrame:CGRectMake(self.view.frame.size.width - 5 - 30 * (i + 1), 64 + 5, 30, 30)];
        [star setBackgroundColor:[UIColor clearColor]];
        [star setTitle:@"" forState:UIControlStateNormal];
        [star setImage:[storeList getStarImageHalfed] forState:UIControlStateNormal];
        [star setTag:5 - i];
        [star addTarget:self action:@selector(chooseRating:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:star];
    }
}

- (void)chooseRating:(id)sender {
    int chosen = ((UIButton*)sender).tag;
    for (int i = 1; i <= 5; i++) {
        for (UIView *v in self.view.subviews) {
            if (v.tag > 0 && v.tag == i) {
                if (i <= chosen)
                    [((UIButton*)v) setImage:[storeList getStarImage] forState:UIControlStateNormal];
                else
                    [((UIButton*)v) setImage:[storeList getStarImageHalfed] forState:UIControlStateNormal];
            }
        }
    }
    self.rating = chosen;
}

- (void)dismissEvalView {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doEval:(id)sender {
    if (self.rated) {
        [HTTPRequest alert:@"请勿重复评价"];
        return;
    }
    if (self.rating == 0) {
        [HTTPRequest alert:@"请先选择评分等级"];
        return;
    }
    if ([user evaluteStore:self.storeID rating:self.rating comment:@""]) {
        self.rated = YES;
        [HTTPRequest alert:@"评论成功！"];
    }
}

@end
