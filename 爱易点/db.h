//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@interface db : NSObject

+(BOOL)lock;
+(BOOL)commit;
+(BOOL)rollback;
+(BOOL)open;
+(void)close;

+(BOOL)isRunning;

+(BOOL)insertToTable:(NSString*)table withValues:(NSArray*)values;
+(BOOL)deleteFromTable:(NSString*)table withKeysAndValues:(NSDictionary*)pairs;
+(NSArray*)selectInTable:(NSString*)table withKeysAndValues:(NSDictionary*)pairs orderBy:(NSString*)order;
+(NSArray*)select:(NSString*)sql;
+(BOOL)_exec:(NSString *)sql;

@end
