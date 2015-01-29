//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "config.h"
#import "db.h"
#import "KVNProgress.h"
#import "DOPDropDownMenu.h"

#define BEGIN_LOADING [HTTPRequest begin_loading];
#define END_LOADING [HTTPRequest end_loading];
#define GLOBAL_LOCK [HTTPRequest g_lock];
#define GLOBAL_UNLOCK [HTTPRequest g_unlock];

@interface HTTPRequest : NSObject<NSURLConnectionDelegate>

+(NSData*)syncGet:(NSString*)page withData:(NSDictionary*)data;
+(NSData*)syncPost:(NSString*)page withData:(NSDictionary*)data;
+(NSData*)syncPost:(NSString*)page withRawData:(NSData*)data;

+(void)asyncGet:(NSString*)page withData:(NSDictionary*)data onCompletion:(void (^)(NSData* recvdata)) handler;
+(void)asyncPost:(NSString*)page withData:(NSDictionary*)data onCompletion:(void (^)(NSData* recvdata)) handler;
+(void)asyncPost:(NSString*)page withRawData:(NSData*)data onCompletion:(void (^)(NSData* recvdata)) handler;

+(NSString*)stringFromData:(NSData*)originalData;
+(NSData*)dataFromString:(NSString*)originalString;
+(UIImage*)imageFromData:(NSData*)originalData;

+(UIImage*)cropToSquare:(UIImage*)originalImage;
+(UIImage*)cropToSize:(UIImage*)originalImage toSize:(CGSize)size;

//show alertView with one line text
+(void)alert:(NSString*)text;

+(void)begin_loading;
+(void)end_loading;
+(void)g_lock;
+(void)g_unlock;

+(NSOperationQueue*)getNetworkQueue;

@end
