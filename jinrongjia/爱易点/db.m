#import "db.h"
#import "config.h"

static sqlite3 *database = nil;

@implementation db

+ (BOOL)isRunning {
    if (database == nil)
        return NO;
    return YES;
}

+ (BOOL)lock {
    if (SQL_AUTO_COMMIT)
        return YES;
    return [self _exec:@"BEGIN TRANSACTION"];
}

+ (BOOL)commit {
    if (SQL_AUTO_COMMIT)
        return YES;
    return [self _exec:@"COMMIT"];
}

+ (BOOL)rollback {
    if (SQL_AUTO_COMMIT)
        return YES;
    return [self _exec:@"ROLLBACK"];
}

+ (void)close {
    if (database != nil) {
        sqlite3_close(database);
        database = nil;
    }
}

+ (BOOL)open {
    if (database != nil)
        return YES;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *database_path = [documents stringByAppendingPathComponent:@"database.sqlite"];
    
    if (sqlite3_open([database_path UTF8String], &database) != SQLITE_OK) {
        return NO;
    }
    return YES;
}

+ (BOOL)insertToTable:(NSString*)table withValues:(NSArray*)values {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"INSERT INTO %@ VALUES (", table];
    for (int i = 0; i < values.count; i++) {
        NSString *value = [values objectAtIndex:i];
        if (i > 0) { //insert comma
            [sql appendString:@","];
        }
        if ([value isEqualToString:SQL_NULL_STRING]) {
            [sql appendString:@"NULL"];
        } else {
            [sql appendString:[NSString stringWithFormat:@"\'%@\'", value]];
        }
    }
    [sql appendString:@")"];
    return [self _exec:sql];
}

+ (BOOL)deleteFromTable:(NSString*)table withKeysAndValues:(NSDictionary*)pairs {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE ", table];
    if (pairs == nil || pairs.count == 0) {
        sql = [NSMutableString stringWithFormat:@"DELETE FROM %@", table];
    }
    for (int i = 0; i < pairs.count; i++) {
        NSString *key = [[pairs allKeys] objectAtIndex:i];
        NSString *value = [pairs objectForKey:key];
        if (i > 0) { //insert comma
            [sql appendString:@" AND "];
        }
        [sql appendString:[NSString stringWithFormat:@"%@=", key]];
        if ([value isEqualToString:SQL_NULL_STRING]) {
            [sql appendString:@"NULL"];
        } else {
            [sql appendString:[NSString stringWithFormat:@"\'%@\'", value]];
        }
    }
    return [self _exec:sql];
}

+ (NSArray*)selectInTable:(NSString*)table withKeysAndValues:(NSDictionary*)pairs orderBy:(NSString*)order {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@ WHERE ", table];
    if (pairs == nil || pairs.count == 0) {
        sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@", table];
    }
    for (int i = 0; i < pairs.count; i++) {
        NSString *key = [[pairs allKeys] objectAtIndex:i];
        NSString *value = [pairs objectForKey:key];
        if (i > 0) { //insert comma
            [sql appendString:@" AND "];
        }
        [sql appendString:[NSString stringWithFormat:@"%@=", key]];
        if ([value isEqualToString:SQL_NULL_STRING]) {
            [sql appendString:@"NULL"];
        } else {
            [sql appendString:[NSString stringWithFormat:@"\'%@\'", value]];
        }
    }
    if (order != nil && ![order isEqualToString:@""]) {
        [sql appendFormat:@" ORDER BY %@", order];
    }
    if (LOG_SQL)
        NSLog(@"%@", sql);
    
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, nil) == SQLITE_OK) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int count = sqlite3_column_count(statement);
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            for (int i = 0; i < count; i++) {
                NSString *title = [[NSString alloc] initWithCString:(char *)sqlite3_column_name(statement, i) encoding:NSUTF8StringEncoding];
                NSString *str = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, i) encoding:NSUTF8StringEncoding];
                [dic setObject:str forKey:title];
            }
            [arr addObject:dic];
        }
        sqlite3_finalize(statement);
        return arr;
    } else {
        sqlite3_finalize(statement);
        return nil;
    }
}

+ (NSArray*)select:(NSString*)sql {
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, nil) == SQLITE_OK) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int count = sqlite3_column_count(statement);
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            for (int i = 0; i < count; i++) {
                NSString *title = [[NSString alloc] initWithCString:(char *)sqlite3_column_name(statement, i) encoding:NSUTF8StringEncoding];
                NSString *str = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, i) encoding:NSUTF8StringEncoding];
                [dic setObject:str forKey:title];
            }
            [arr addObject:dic];
        }
        sqlite3_finalize(statement);
        return arr;
    } else {
        sqlite3_finalize(statement);
        return nil;
    }
}

+ (BOOL)_exec:(NSString *)sql {
    char *err;
    if (LOG_SQL)
        NSLog(@"%@", sql);
    if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        return NO;
    }
    return YES;
}

@end