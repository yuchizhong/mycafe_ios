//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "areaPicker.h"
#import "data.h"
#import "storeList.h"

static storeList *parentView;

@interface areaPicker ()


@end

@implementation areaPicker

- (void)setParentViewController:(UIViewController*)parent; {
    parentView = (storeList*)parent;
}

/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHidden:YES];
    [parentView pickerDone];
}
 */

@end
