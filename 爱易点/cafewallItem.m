//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "cafewallItem.h"

#define T_COLOR [UIColor blackColor]
#define T_COLOR_SUB [UIColor colorWithWhite:0 alpha:0.75]
#define T_COLOR_SUB_2 [UIColor colorWithWhite:0 alpha:0.65]

#define GET_ROW 4

static int cellID = 0;

@interface cafeWallItem ()

@property (strong, atomic) NSDictionary *wallItemInfo;

@end

@implementation cafeWallItem

- (void)beginLoading {
    BEGIN_LOADING
}

- (void)endLoading {
    END_LOADING
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setWallItemDetailInfo:(NSDictionary*)info {
    self.wallItemInfo = info;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.wallItemInfo == nil) {
        return 0;
    }
    if (indexPath.row == 0) {
        return 30;
    }
    if (indexPath.row == 1) {
        return FOOD_INFO_HEIGHT;
    }
    if (indexPath.row == 2) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        NSDictionary *attribute = @{NSFontAttributeName:UI_TEXT_FONT, NSParagraphStyleAttributeName:paragraphStyle.copy};
        
        CGRect sizeTT = [@"测试文字" boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        float margin = (WALL_ITEM_CELL_HEIGHT - sizeTT.size.height) / 2;
        
        float h = 0;
            CGRect sizeT = [[self.wallItemInfo objectForKey:@"message"] boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
            h = sizeT.size.height + margin * 2;
        if (h < WALL_ITEM_CELL_HEIGHT + 10) {
            return WALL_ITEM_CELL_HEIGHT + 10;
        }
        return h + 10;
    }
    return WALL_ITEM_CELL_HEIGHT;
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
    
    float lineY = WALL_ITEM_CELL_HEIGHT;
    if (indexPath.row == 0) {
        lineY = -0.5;
    }
    if (indexPath.row == 1) {
        lineY = FOOD_INFO_HEIGHT;
    }
    
    float margin = 10;
    if (indexPath.row == 0) {
        UILabel *activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 10, self.view.frame.size.width - 2 * margin, 20)];
        [activityLabel setText:[NSString stringWithFormat:@"%@分享了", [self.wallItemInfo objectForKey:@"customerName"]]];
        [activityLabel setTextAlignment:NSTextAlignmentLeft];
        [activityLabel setFont:[UIFont systemFontOfSize:16]];
        [activityLabel setTextColor:T_COLOR];
        [cell addSubview:activityLabel];
    } else if (indexPath.row == 1) {
        //add image
        //round corner image
        UIImageView *roundedView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, FOOD_INFO_HEIGHT - 20, FOOD_INFO_HEIGHT - 20)];
        UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(10, roundedView.frame.size.height / 2 - 1, roundedView.frame.size.width - 20, 2)];
        [loading setProgress:0.0];
        [loading setProgressViewStyle:UIProgressViewStyleDefault];
        [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
        [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
        [roundedView addSubview:loading];
        NSString *url = [NSString stringWithFormat:@"%@/%@/dishimage/dish%@/%@", SERVER_ADDRESS, [store getCurrentStoreFolder], [self.wallItemInfo objectForKey:@"dishID"], [self.wallItemInfo objectForKey:@"picPath"]];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        //[[SDImageCache sharedImageCache] clearDisk];
        [roundedView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"noimage.png"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            float percentage = (float)receivedSize / (float)expectedSize;
            //update loading progress bar
            [loading setProgress:percentage];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            //dismiss loading progress bar
            [loading removeFromSuperview];
        }];
        [roundedView setContentMode:UIViewContentModeScaleAspectFill];
        CALayer *l = [roundedView layer];
        [l setMasksToBounds:YES];
        [l setCornerRadius:6.0];
        roundedView.frame = CGRectMake(10, 10, FOOD_INFO_HEIGHT - 20, FOOD_INFO_HEIGHT - 20);
        [cell addSubview:roundedView];
        
        //food name
        UILabel *foodNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(FOOD_INFO_HEIGHT, 10, self.view.frame.size.width - FOOD_INFO_HEIGHT - margin, 18)];
        [foodNameLabel setText:[self.wallItemInfo objectForKey:@"dishName"]];
        [foodNameLabel setTextAlignment:NSTextAlignmentLeft];
        [foodNameLabel setFont:[UIFont boldSystemFontOfSize:16]];
        [foodNameLabel setTextColor:T_COLOR];
        [cell addSubview:foodNameLabel];
        
        //food description
        if ([self.wallItemInfo objectForKey:@"description"] != [NSNull null] && ![[self.wallItemInfo objectForKey:@"description"] isEqualToString:@""]) {
            UILabel *foodDespLabel = [[UILabel alloc] initWithFrame:CGRectMake(FOOD_INFO_HEIGHT, 10 + 18, self.view.frame.size.width - FOOD_INFO_HEIGHT - margin, FOOD_INFO_HEIGHT - 10 - 10 - 18)];
            [foodDespLabel setText:[self.wallItemInfo objectForKey:@"description"]];
            [foodDespLabel setNumberOfLines:0];
            [foodDespLabel setLineBreakMode:NSLineBreakByCharWrapping];
            [foodDespLabel setTextAlignment:NSTextAlignmentLeft];
            [foodDespLabel setFont:[UIFont systemFontOfSize:14]];
            [foodDespLabel setTextColor:T_COLOR];
            [cell addSubview:foodDespLabel];
        }
    } else if (indexPath.row == 2) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        NSDictionary *attribute = @{NSFontAttributeName:UI_TEXT_FONT, NSParagraphStyleAttributeName:paragraphStyle.copy};
        
        CGRect sizeTT = [@"测试文字" boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        float margin = (WALL_ITEM_CELL_HEIGHT - sizeTT.size.height) / 2;
        
        float h = 0;
        CGRect sizeT = [[self.wallItemInfo objectForKey:@"message"] boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        h = sizeT.size.height + margin * 2;
        if (h < WALL_ITEM_CELL_HEIGHT + 10) {
            h = WALL_ITEM_CELL_HEIGHT + 10;
        } else {
            h += 10;
        }
        
        lineY = h;
        
        UILabel *activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 0, self.view.frame.size.width - 2 * margin, h)];
        [activityLabel setText:[NSString stringWithFormat:@"留言\n%@", [self.wallItemInfo objectForKey:@"message"]]];
        [activityLabel setNumberOfLines:0];
        [activityLabel setLineBreakMode:NSLineBreakByCharWrapping];
        [activityLabel setTextAlignment:NSTextAlignmentLeft];
        [activityLabel setTextColor:T_COLOR];
        [activityLabel setFont:[UIFont systemFontOfSize:16]];
        [cell addSubview:activityLabel];
    } else if (indexPath.row == 3) {
        NSMutableString *timeStr = [[self.wallItemInfo objectForKey:@"post_date"] mutableCopy];
        [timeStr insertString:@"日" atIndex:8];
        [timeStr insertString:@"月" atIndex:6];
        [timeStr insertString:@"年" atIndex:4];
        //timeStr = [[timeStr substringFromIndex:2] mutableCopy];
        [timeStr appendString:@" "];
        [timeStr appendString:[self.wallItemInfo objectForKey:@"post_time"]];

        
        UILabel *activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 0, self.view.frame.size.width - 2 * margin, WALL_ITEM_CELL_HEIGHT)];
        [activityLabel setText:@"发布时间"];
        [activityLabel setTextAlignment:NSTextAlignmentLeft];
        [activityLabel setTextColor:T_COLOR];
        [activityLabel setFont:[UIFont systemFontOfSize:16]];
        [cell addSubview:activityLabel];
        
        UILabel *activityLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(margin, 0, self.view.frame.size.width - 2 * margin, WALL_ITEM_CELL_HEIGHT)];
        [activityLabel2 setText:[NSString stringWithFormat:@"%@", timeStr]];
        [activityLabel2 setTextAlignment:NSTextAlignmentRight];
        [activityLabel2 setTextColor:T_COLOR];
        [activityLabel2 setFont:[UIFont systemFontOfSize:16]];
        [cell addSubview:activityLabel2];
    } else if (indexPath.row == GET_ROW) {
        UILabel *activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, WALL_ITEM_CELL_HEIGHT)];
        [activityLabel setText:@"GET"];
        [activityLabel setTextAlignment:NSTextAlignmentCenter];
        [activityLabel setTextColor:[UIColor whiteColor]];
        [activityLabel setFont:[UIFont boldSystemFontOfSize:19]];
        [activityLabel setBackgroundColor:COFFEE_VERY_DARK];
        [cell addSubview:activityLabel];
    }
    
    if (indexPath.row != GET_ROW && lineY >= 0) {
        //draw line
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, lineY, tableView.frame.size.width, 0.5)];
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
        
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    return cell;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100 && buttonIndex == 1) {
        if ([store getCafeWallCoffee:[[self.wallItemInfo objectForKey:@"postID"] integerValue]]) {
            [HTTPRequest alert:@"领取成功"];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == GET_ROW) {
        if ([user getCurrentID] != nil && [[self.wallItemInfo objectForKey:@"tel"] isEqualToString:[user getCurrentID]]) {
            [HTTPRequest alert:@"您不能领取自己发布的咖啡"];
        } else {
            UIAlertView *aview = [[UIAlertView alloc] initWithTitle:@"确认领取" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
            [aview setTag:100];
            [aview show];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
