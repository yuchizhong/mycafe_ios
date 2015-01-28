//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "creditList.h"
#import "data.h"

static NSArray *credits = nil;
static int cellID = 0;

@interface creditList ()

@property (atomic) NSInteger usingThreads;

@end

@implementation creditList

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.usingThreads = 0;
    credits = nil;
    if ([user getCurrentID] != nil) {
        [NSThread detachNewThreadSelector:@selector(loadCredits) toTarget:self withObject:nil];
    }
    
    [self.tableView reloadData];
}

- (NSArray*)getCreditList {
    NSData *recvData = [HTTPRequest syncPost:@"select.php" withRawData:
                        [HTTPRequest dataFromString:[NSString stringWithFormat:@"SELECT credit, level_name, chain_name FROM credit, creditLevel, chain, user_login WHERE user_login.username='%@' AND user_login.userID=credit.user_id AND credit.chain_id=chain.chain_id AND credit.chain_id=creditLevel.chain_id AND credit.member_level=creditLevel.member_level", [user getCurrentID]]]];
    if (recvData == nil) {
        return nil;
    }
    NSError *error;
    NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:recvData options:kNilOptions error:&error];
    if (error != nil || jsonRoot == nil) {
        return nil;
    }
    NSArray *listInJSON = [jsonRoot objectForKey:@"list"];
    return listInJSON;
}

- (void)loadCredits {
    if (self.usingThreads > 0) {
        return;
    }
    self.usingThreads++;
    while (credits == nil) {
        credits = [self getCreditList];
        if (credits == nil) {
            [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
        }
    }
    [self.tableView reloadData];
    self.usingThreads--;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (credits == nil || credits.count == 0)
        return 1;
    return credits.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (USE_NIL_CELL_ID) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:nil];
    } else {
        NSString *TableSampleIdentifier = [NSString stringWithFormat:@"tableCellID%d", cellID];
        cellID++;
        
        cell = [tableView dequeueReusableCellWithIdentifier:
                TableSampleIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:TableSampleIdentifier];
        }
    }
    
    if (credits == nil || credits.count == 0) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 44)];
        [l setText:@"加载中..."];
        if (credits != nil && credits.count == 0) {
            [l setText:@"没有积分记录"];
        }
        [l setTextAlignment:NSTextAlignmentCenter];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    } else {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 20, 44)];
        [titleLabel setText:[[credits objectAtIndex:indexPath.row] objectForKey:@"chain_name"]];
        [titleLabel setTextAlignment:NSTextAlignmentLeft];
        [titleLabel setTextColor:[UIColor blackColor]];
        [titleLabel setFont:[UIFont systemFontOfSize:15]];
        [cell addSubview:titleLabel];
        
        UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 210, 0, 200, 44)];
        [priceLabel setText:[NSString stringWithFormat:@"%@ 剩余%d分", [[credits objectAtIndex:indexPath.row] objectForKey:@"level_name"], [[[credits objectAtIndex:indexPath.row] objectForKey:@"credit"] intValue]]];
        [priceLabel setTextAlignment:NSTextAlignmentRight];
        [priceLabel setTextColor:[UIColor redColor]];
        [priceLabel setFont:UI_TEXT_FONT];
        [cell addSubview:priceLabel];
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 44, tableView.frame.size.width, 0.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell addSubview:imageView];
    
    if (credits == nil || credits.count == 0)
        return cell;
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.8, 0.8, 0.8, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell addSubview:imageView];
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
