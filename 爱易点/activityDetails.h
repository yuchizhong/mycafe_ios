//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface activityDetails : UIViewController<UITextFieldDelegate, UIAlertViewDelegate, UIWebViewDelegate>

@property (atomic, strong) NSDictionary *activityInfo;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingLabel;

@property (nonatomic) BOOL hideEnrollButton;

+(NSInteger)storeIDforCollect;
+(void)askInstanceForCollection;

@end

