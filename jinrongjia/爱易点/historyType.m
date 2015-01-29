//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "historyType.h"
#import "data.h"
#import "historyOrder.h"
#import "purchased.h"

static int cellID = 0;

@interface historyType ()

@end

@implementation historyType

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
} 

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem setTitle:@"消费记录"];
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else if (section == 1) {
        return 3;
    }
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    return v;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    return v;
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
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 20, 44)];
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    [titleLabel setTextColor:COFFEE_VERY_DARK];
    [titleLabel setFont:UI_TEXT_FONT];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [titleLabel setText:@"未提交的点单"];
                    break;
                    
                case 1:
                    [titleLabel setText:@"点餐记录"];
                    break;
                    
                default:
                    [titleLabel setText:@"预订记录"];
                    break;
            }
            break;
            
        case 1:
            switch (indexPath.row) {
                case 0:
                    [titleLabel setText:@"积分商城消费"];
                    break;
                    
                case 1:
                    [titleLabel setText:@"现金商城消费"];
                    break;
                    
                default:
                    [titleLabel setText:@"活动报名记录"];
                    break;
            }
            break;
            
        default:
            [titleLabel setText:@"充值记录"];
            break;
    }
    
    [cell addSubview:titleLabel];
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 44, tableView.frame.size.width, 0.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 171.0/255.0, 99.0/255.0, 49.0/255.0, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell addSubview:imageView];
    
    imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0.5)];
    UIGraphicsBeginImageContext(imageView.frame.size);
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 171.0/255.0, 99.0/255.0, 49.0/255.0, 1.0);  //颜色
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    imageView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell addSubview:imageView];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    purchased *v;
    historyOrder *o;
    switch (indexPath.section) {
        case 0:
            o = [self.storyboard instantiateViewControllerWithIdentifier:@"historyOrders"];
            [o setHistoryType:indexPath.row];
            [self.navigationController pushViewController:o animated:YES];
            break;
            
        case 1:
            switch (indexPath.row) {
                case 0:
                    v = [self.storyboard instantiateViewControllerWithIdentifier:@"purchased"];
                    [v setMall:@"credit"];
                    [self.navigationController pushViewController:v animated:YES];
                    break;
                    
                case 1:
                    v = [self.storyboard instantiateViewControllerWithIdentifier:@"purchased"];
                    [v setMall:@"cash"];
                    [self.navigationController pushViewController:v animated:YES];
                    break;
                    
                default:
                    v = [self.storyboard instantiateViewControllerWithIdentifier:@"purchased"];
                    [v setMall:@"activity"];
                    [self.navigationController pushViewController:v animated:YES];
                    break;
            }
            break;
            
        default:
            v = [self.storyboard instantiateViewControllerWithIdentifier:@"purchased"];
            [v setMall:@"refill"];
            [self.navigationController pushViewController:v animated:YES];
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
