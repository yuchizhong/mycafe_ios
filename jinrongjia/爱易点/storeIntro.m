//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "storeIntro.h"
#import "data.h"

@interface storeIntro ()

@end

@implementation storeIntro

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.loadingLabel setHidden:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.loadingLabel setHidden:YES];
    [HTTPRequest alert:NETWORK_ERROR];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)collectStore {
    if ([user getCurrentID] == nil) {
        [HTTPRequest alert:@"您还没有登陆"];
        return;
    }
    if (!self.storeInfoPassed.collected) {
        //if not collected
        if ([user collectStore:self.storeInfoPassed.storeID]) {
            self.storeInfoPassed.collected = YES;
            UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"已收藏"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(collectStore)];
            [rightButton setEnabled:NO];
            [self.navigationItem setRightBarButtonItem:rightButton];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:self.storeInfoPassed.title];
    
    if (!self.storeInfoPassed.collected) {
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"收藏"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(collectStore)];
        [self.navigationItem setRightBarButtonItem:rightButton];
    } else {
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"已收藏"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(collectStore)];
        [rightButton setEnabled:NO];
        [self.navigationItem setRightBarButtonItem:rightButton];
    }
    
    [self.webView.scrollView setShowsVerticalScrollIndicator:NO];
    [self.webView.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.webView.scrollView setBackgroundColor:[UIColor clearColor]];
    
    [self.loadingLabel setHidden:NO];
    NSString *url = [NSString stringWithFormat:@"%@/images/store%d/home/index.html", SERVER_ADDRESS, self.storeInfoPassed.storeID];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    [self.webView loadData:data MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:url]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
