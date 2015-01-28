//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "HTTPRequest.h"
#import "data.h"

static HTTPRequest *instance = nil;
static NSOperationQueue *queue = nil;
static NSLock *global_lock = nil;
static int networing = 0;
//static int hub_count = 0;

@interface MyConnection : NSURLConnection

@property (atomic) BOOL finished;
@property (atomic) NSMutableData *recdata;

+ (MyConnection*)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate;

@end

@implementation MyConnection

+ (MyConnection*)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate {
    MyConnection *con = [[MyConnection alloc] initWithRequest:request delegate:delegate];
    [con setFinished:NO];
    [con setRecdata:nil];
    return con;
}

@end

@implementation HTTPRequest

+ (NSOperationQueue*)getNetworkQueue {
    if (queue == nil)
        queue = [[NSOperationQueue alloc] init];
    return queue;
}

+ (NSString*)stringFromDictionary:(NSDictionary*)data {
    NSString* s = @"";
    if (data == nil || data.count == 0) {
        return s;
    }
    BOOL first = YES;
    for (NSString* key in data) {
        if (first) {
            s = [s stringByAppendingString:[NSString stringWithFormat:@"%@=%@", key, [data objectForKey:key]]];
            first = NO;
            continue;
        }
        s = [s stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", key, [data objectForKey:key]]];
    }
    return s;
}

- (void)timedOut:(NSTimer*)timer {
    NSURLConnection *con = [timer userInfo];
    if (![(MyConnection*)con finished]) {
        [con cancel];
        [(MyConnection*)con setRecdata:nil];
        [(MyConnection*)con setFinished:YES];
        networing--;
    }
}

#pragma mark wrapper

+ (NSData*)syncGet:(NSString*)page withData:(NSDictionary*)data {
    if (instance == nil) {
        instance = [[HTTPRequest alloc]init];
    }
    return [instance _syncGet:page withData:data];
}

+ (NSData*)syncPost:(NSString*)page withData:(NSDictionary*)data {
    if (instance == nil) {
        instance = [[HTTPRequest alloc]init];
    }
    return [instance _syncPost:page withData:data];
}

+ (NSData*)syncPost:(NSString*)page withRawData:(NSData*)data {
    if (instance == nil) {
        instance = [[HTTPRequest alloc]init];
    }
    return [instance _syncPost:page withRawData:data];
}

#pragma mark USURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    ((MyConnection*)connection).recdata = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [((MyConnection*)connection).recdata appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    [(MyConnection*)connection setFinished:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    ((MyConnection*)connection).recdata = nil;
    [(MyConnection*)connection setFinished:YES];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}

#pragma mark sync methods

- (NSData*)_syncGet:(NSString*)page withData:(NSDictionary*)data {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *url;
    NSString *content; //get from data
    if (data == nil || data.count == 0) {
        url = [NSString stringWithFormat:@"%@/%@", SERVER_ADDRESS, page];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [request setURL:[NSURL URLWithString:url]];
    } else {
        content = [HTTPRequest stringFromDictionary:data];
        url = [NSString stringWithFormat:@"%@/%@?%@", SERVER_ADDRESS, page, content];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [request setURL:[NSURL URLWithString:url]];
    }
    [request setTimeoutInterval:NETWORK_TIMEOUT];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    
    //send request
    if (LOG_NETWORK)
        NSLog(@"TO: %@", url);
    
    /*
    NSError *error = nil;
    NSData *recdata = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
     */
    /////////////////////////////////////////////////////////////
    networing++;
    NSData *r = nil;
    //use standard connection and delegate
    MyConnection *con = [MyConnection connectionWithRequest:request delegate:self];
    
    [NSTimer scheduledTimerWithTimeInterval:NETWORK_TIMEOUT target:self selector:@selector(timedOut:) userInfo:con repeats:NO];
    
    while (![con finished]) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    if (con.recdata != nil && [con.recdata length] > 0) {
        r = [con.recdata copy];
    }
    networing--;
    /////////////////////////////////////////////////////////////
    
    if (LOG_NETWORK)
        NSLog(@"BACK: %@", [HTTPRequest stringFromData:r]);
    
    return r;
}

- (NSData*)_syncPost:(NSString*)page withData:(NSDictionary*)data {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *content = [HTTPRequest stringFromDictionary:data]; //get from data
    //content = [content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *sendData = [content dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@/%@", SERVER_ADDRESS, page];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    //NSString *contentLength = [NSString stringWithFormat:@"%d", (int)[sendData length]];
    //[request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:sendData];
    [request setTimeoutInterval:NETWORK_TIMEOUT];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    
    /////////////////////////////////////////////////////////////
    NSData *r = nil;
    //use standard connection and delegate
    MyConnection *con = [MyConnection connectionWithRequest:request delegate:self];
    
    [NSTimer scheduledTimerWithTimeInterval:NETWORK_TIMEOUT target:self selector:@selector(timedOut:) userInfo:con repeats:NO];
    
    while (![con finished]) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    if (con.recdata != nil && [con.recdata length] > 0) {
        r = [con.recdata copy];
    }
    /////////////////////////////////////////////////////////////
    
    return r;
}

- (NSData*)_syncPost:(NSString*)page withRawData:(NSData*)data {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *url = [NSString stringWithFormat:@"%@/%@", SERVER_ADDRESS, page];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    //NSString *contentLength = [NSString stringWithFormat:@"%d", (int)[data length]];
    //[request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    [request setTimeoutInterval:NETWORK_TIMEOUT];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    
    if (LOG_NETWORK_POST)
        NSLog(@"TO: %@ | %@", url, [HTTPRequest stringFromData:data]);
    
    /////////////////////////////////////////////////////////////
    NSData *r = nil;
    //use standard connection and delegate
    networing++;
    MyConnection *con = [MyConnection connectionWithRequest:request delegate:self];
    
    [NSTimer scheduledTimerWithTimeInterval:NETWORK_TIMEOUT target:self selector:@selector(timedOut:) userInfo:con repeats:NO];
    
    while (![con finished]) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    if (con.recdata != nil && [con.recdata length] > 0) {
        r = [con.recdata copy];
    }
    networing--;
    /////////////////////////////////////////////////////////////
    
    if (LOG_NETWORK_POST)
        NSLog(@"BACK: %@", [HTTPRequest stringFromData:r]);
    
    return r;
}

#pragma mark async methods

+ (void)asyncGet:(NSString*)page withData:(NSDictionary*)data onCompletion:(void (^)(NSData* recvdata)) handler {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *content; //get from data
    if (data == nil || data.count == 0) {
        NSString *url = [NSString stringWithFormat:@"%@/%@", SERVER_ADDRESS, page];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [request setURL:[NSURL URLWithString:url]];
    } else {
        content = [self stringFromDictionary:data];
        NSString *url = [NSString stringWithFormat:@"%@/%@?%@", SERVER_ADDRESS, page, content];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [request setURL:[NSURL URLWithString:url]];
    }
    [request setTimeoutInterval:NETWORK_TIMEOUT];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];

    //[request setHTTPMethod:@"GET"];
    //NSString *contentLength = [NSString stringWithFormat:@"%d", (int)[content length]];
    //[request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    //[request setHTTPBody:[content dataUsingEncoding:NSUTF8StringEncoding]];

    if (queue == nil)
        queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *recvdata, NSError *error) {
        if (error == nil)
            handler(recvdata);
        else
            handler(nil);
    }];
}

+ (void)asyncPost:(NSString*)page withData:(NSDictionary*)data onCompletion:(void (^)(NSData* recvdata)) handler {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *content = [self stringFromDictionary:data]; //get from data
    //content = [content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *sendData = [content dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url = [NSString stringWithFormat:@"%@/%@", SERVER_ADDRESS, page];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    //NSString *contentLength = [NSString stringWithFormat:@"%d", (int)[sendData length]];
    //[request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:sendData];
    [request setTimeoutInterval:NETWORK_TIMEOUT];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    
    if (queue == nil)
        queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *recvdata, NSError *error) {
        if (error == nil)
            handler(recvdata);
        else
            handler(nil);
    }];
}

+ (void)asyncPost:(NSString*)page withRawData:(NSData*)data onCompletion:(void (^)(NSData* recvdata)) handler {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];

    NSString *url = [NSString stringWithFormat:@"%@/%@", SERVER_ADDRESS, page];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    //NSString *contentLength = [NSString stringWithFormat:@"%d", (int)[data length]];
    //[request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    [request setTimeoutInterval:NETWORK_TIMEOUT];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    
    if (queue == nil)
        queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *recvdata, NSError *error) {
        if (error == nil)
            handler(recvdata);
        else
            handler(nil);
    }];
}

//other services

+ (NSString*)stringFromData:(NSData*)originalData {
    if (originalData == nil) {
        return nil;
    }
    NSString *r = [[NSString alloc] initWithData:originalData encoding:NSUTF8StringEncoding];
    return r;
}

+ (NSData*)dataFromString:(NSString*)originalString {
    NSData *r = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    return r;
}

//image

+ (UIImage*)imageFromData:(NSData*)originalData {
    UIImage *r = [UIImage imageWithData:originalData];
    return r;
}

+ (UIImage*)cropToSquare:(UIImage*)originalImage {
    if (originalImage == nil)
        return nil;
    
    float w = originalImage.size.width;
    float h = originalImage.size.height;
    float minimum = MIN(w, h);
    CGRect rect;
    if (w == h) {
        return originalImage;
    } else if (minimum == h) {
        rect = CGRectMake(w / 2.0 - minimum / 2.0, 0, minimum, minimum);
    } else {
        rect = CGRectMake(0, h / 2.0 - minimum / 2.0, minimum, minimum);
    }
    CGImageRef imageRef = CGImageCreateWithImageInRect([originalImage CGImage], rect);
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return img;
}

+ (UIImage*)cropToSize:(UIImage*)originalImage toSize:(CGSize)size {
    if (originalImage == nil)
        return nil;
    
    float originalRatio = originalImage.size.width / originalImage.size.height;
    float newRatio = size.width / size.height;
    CGRect rect;
    if (newRatio == originalRatio) {
        return originalImage;
    } else if (newRatio > originalRatio) {
        float newHeight = originalImage.size.width / newRatio;
        rect = CGRectMake(0, originalImage.size.height / 2.0 - newHeight / 2.0, originalImage.size.width, newHeight);
    } else {
        float newWidth = originalImage.size.height * newRatio;
        rect = CGRectMake(originalImage.size.width / 2.0 - newWidth / 2.0, 0, newWidth, originalImage.size.height);
    }
    CGImageRef imageRef = CGImageCreateWithImageInRect([originalImage CGImage], rect);
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return img;
}

+ (UIAlertView*)_alert:(NSString*)text {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:text delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
    return alert;
}

+ (void)alert:(NSString*)text {
    [self performSelectorOnMainThread:@selector(_alert:) withObject:text waitUntilDone:YES];
}

+ (void)begin_loading {
    //hub_count++;
    [self performSelectorOnMainThread:@selector(hudShow) withObject:nil waitUntilDone:YES];
    //[self performSelectorOnMainThread:@selector(hudShow) withObject:nil waitUntilDone:YES];
}

+ (void)end_loading {
    //hub_count--;
    //if (hub_count <= 0) {
    //    hub_count = 0;
    [self performSelectorOnMainThread:@selector(hudHide) withObject:nil waitUntilDone:YES];
        //[self performSelectorOnMainThread:@selector(hudHide) withObject:nil waitUntilDone:YES];
    //}
}

+ (void)hudShow {
    [KVNProgress showWithStatus:@"Loading..."];
}

+ (void)hudHide {
    dispatch_main_after(0.1f, ^{
        [KVNProgress dismiss];
    });
}

static void dispatch_main_after(NSTimeInterval delay, void (^block)(void))
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        block();
    });
}

+ (void)g_lock {
    //begin critical section
    if (global_lock == nil)
        global_lock = [[NSLock alloc]init];
    [global_lock lock];
}

+ (void)g_unlock {
    //end critical section
    if (global_lock == nil) {
        NSLog(@"FATAL: unlocking a nil lock");
    } else {
        [global_lock unlock];
    }
}

@end
