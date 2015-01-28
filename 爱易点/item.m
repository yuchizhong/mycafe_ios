//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "item.h"
#import "data.h"
#import "extra.h"
#import "storeList.h"

static int infoCellID;
static float purseValueMall;
static NSInteger transactionID;

@interface item ()

@property (atomic) BOOL firstShow;
@property (atomic) BOOL enlargedImg;
@property (atomic) CGRect imgOrigSize;

@end

@implementation item

- (IBAction)enlargeImg:(id)sender {
    self.imgOrigSize = self.foodImageView.frame;
    [UIView beginAnimations:@"ToggleViews" context:nil];
    [UIView setAnimationDuration:0.2];
    [self.foodImageView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.foodImageView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]];
    [UIView commitAnimations];
    [self.imgButtonSmall setEnabled:YES];
    self.enlargedImg = YES;
}

- (IBAction)enlittle:(id)sender {
    [UIView beginAnimations:@"ToggleViews" context:nil];
    [UIView setAnimationDuration:0.2];
    [self.foodImageView setFrame:self.imgOrigSize];
    [self.foodImageView setBackgroundColor:[UIColor clearColor]];
    [UIView commitAnimations];
    [self.imgButtonSmall setEnabled:NO];
    self.enlargedImg = NO;
}

- (IBAction)buyClicked:(id)sender {
    [self buy];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.desp == nil || [self.desp isEqualToString:@""])
        return self.notes.count;
    return self.notes.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *attribute = @{NSFontAttributeName:UI_TEXT_FONT, NSParagraphStyleAttributeName:paragraphStyle.copy};
    
    CGRect sizeTT = [@"测试文字" boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    float margin = (44 - sizeTT.size.height) / 2;
    
    float h = 0;
    if (indexPath.section == 0) {
        CGRect sizeT = [self.desp boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        h = sizeT.size.height + margin * 2;
    } else {
        CGRect sizeT = [[self.notes objectAtIndex:indexPath.section - 1] boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];

        h = sizeT.size.height + margin * 2;
    }
    if (h < 44) {
        return 44;
    }
    return h;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (USE_NIL_CELL_ID) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:nil];
    } else {
        NSString *TableSampleIdentifier = [NSString stringWithFormat:@"tableCellID%d", infoCellID];
        infoCellID++;
        
        cell = [tableView dequeueReusableCellWithIdentifier:
                TableSampleIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:TableSampleIdentifier];
        }
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *attribute = @{NSFontAttributeName:UI_TEXT_FONT, NSParagraphStyleAttributeName:paragraphStyle.copy};
    CGRect sizeTT = [@"测试文字" boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    float margin = (44 - sizeTT.size.height) / 2;
    
    if (indexPath.section == 0) {
        CGRect sizeT = [self.desp boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(16, margin, self.infoTable.frame.size.width - 32, sizeT.size.height)];
        [l setText:self.desp];
        [l setNumberOfLines:0];
        [l setLineBreakMode:NSLineBreakByCharWrapping];
        [l setTextAlignment:NSTextAlignmentLeft];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    } else {
        CGRect sizeT = [[self.notes objectAtIndex:indexPath.section - 1] boundingRectWithSize:CGSizeMake(self.infoTable.frame.size.width - 32, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(16, margin, self.infoTable.frame.size.width - 32, sizeT.size.height)];
        [l setText:[self.notes objectAtIndex:indexPath.section - 1]];
        [l setNumberOfLines:0];
        [l setLineBreakMode:NSLineBreakByCharWrapping];
        [l setTextAlignment:NSTextAlignmentLeft];
        [l setTextColor:[UIColor blackColor]];
        [l setFont:UI_TEXT_FONT];
        [cell addSubview:l];
    }
 
    return cell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.firstShow = YES;
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.navigationItem setTitle:@"商品信息"];
    
    infoCellID = 0;
    
    [self.foodImageView setContentMode:UIViewContentModeScaleAspectFit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //[self.view layoutSubviews];
    
    [self.foodTitle setNumberOfLines:0];
    [self.foodTitle setLineBreakMode:NSLineBreakByCharWrapping];
    
    //show info
    self.desp = [self.infoPassed objectForKey:@"description"];
    self.notes = [[[self.infoPassed objectForKey:@"note"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";；"]] mutableCopy];
    for (int i = (int)self.notes.count - 1; i >= 0; i--) {
        if ([self.notes objectAtIndex:i] == nil || [[self.notes objectAtIndex:i] isEqualToString:@""]) {
            [self.notes removeObjectAtIndex:i];
        }
    }
    
    [self.foodTitle setText:[self.infoPassed objectForKey:@"name"]];
    if ([[self.infoPassed objectForKey:@"name"] length] > 8)
        [self.foodTitle setFont:UI_TEXT_FONT];
    else
        [self.foodTitle setFont:UI_TITLE_FONT];
    
    NSString *priceString;
    if ([[self.infoPassed objectForKey:@"mall"] isEqualToString:@"credit"]) {
        priceString = [NSString stringWithFormat:@"%d分", [[self.infoPassed objectForKey:@"credit"] intValue]];
    } else if ([[self.infoPassed objectForKey:@"mall"] isEqualToString:@"cash"]) {
        priceString = [NSString stringWithFormat:@"￥%.2f", [[self.infoPassed objectForKey:@"price"] floatValue]];
    }
    [self.foodPrice setText: priceString];
    
    //set image
    //async load image
    UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(5, self.foodImageView.frame.size.height / 2.0 - 1, self.foodImageView.frame.size.width - 10, 2)];
    [loading setProgress:0.0];
    [loading setProgressViewStyle:UIProgressViewStyleDefault];
    [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
    [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
    [self.foodImageView addSubview:loading];
    NSString *url;
    if ([[self.infoPassed objectForKey:@"mall"] isEqualToString:@"credit"]) {
        url = [NSString stringWithFormat:@"%@/images/store%@/storemallimage/item%@/%@", SERVER_ADDRESS, [self.infoPassed objectForKey:@"store_id"], [self.infoPassed    objectForKey:@"item_id"], [self.infoPassed objectForKey:@"icon"]];
        if ([[self.infoPassed objectForKey:@"bDish"] isEqualToString:@"1"]) {
            url = [NSString stringWithFormat:@"%@/images/store%@/dishimage/dish%@/%@", SERVER_ADDRESS, [self.infoPassed objectForKey:@"store_id"], [self.infoPassed objectForKey:@"dishID"], [self.infoPassed objectForKey:@"icon"]];
        }
    } else if ([[self.infoPassed objectForKey:@"mall"] isEqualToString:@"cash"]) {
        url = [NSString stringWithFormat:@"%@/images/store%@/emallimage/item%@/%@", SERVER_ADDRESS, [self.infoPassed objectForKey:@"store_id"], [self.infoPassed    objectForKey:@"item_id"], [self.infoPassed objectForKey:@"icon"]];
    }
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [self.foodImageView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"noimage.png"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        float percentage = (float)receivedSize / (float)expectedSize;
        //update loading progress bar
        [loading setProgress:percentage];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        //dismiss loading progress bar
        [loading removeFromSuperview];
    }];
    
    //rounded button
    CALayer *l = [self.foodImageView layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:10.0];
    
    if (!self.beenPurchased) {
        [self.buyButton setHidden:NO];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGColorRef colorref = CGColorCreate(colorSpace,(CGFloat[]){ 1, 0, 0, 1 });
        if ([[self.infoPassed objectForKey:@"mall"] isEqualToString:@"credit"]) {
            [self.buyButton setTitle:@"兑换" forState:UIControlStateNormal];
        } else if ([[self.infoPassed objectForKey:@"mall"] isEqualToString:@"cash"]) {
            [self.buyButton setTitle:@"购买" forState:UIControlStateNormal];
        }
        [self.buyButton.layer setMasksToBounds:YES];
        [self.buyButton.layer setCornerRadius:5.0]; //设置矩形四个圆角半径
        [self.buyButton.layer setBorderWidth:1.0]; //边框宽度
        [self.buyButton.layer setBorderColor:colorref];//边框颜色
        CGColorSpaceRelease(colorSpace);
        CGColorRelease(colorref);
    } else {
        [self.buyButton setHidden:YES];
        UILabel *sequenceLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.controlView.frame.size.width, 35)];
        [sequenceLabel setTextAlignment:NSTextAlignmentLeft];
        [sequenceLabel setFont:[UIFont systemFontOfSize:16]];
        [sequenceLabel setTextColor:DARK_RED];
        [sequenceLabel setBackgroundColor:[UIColor clearColor]];
        if ([[self.infoPassed objectForKey:@"mall"] isEqualToString:@"credit"]) {
            [sequenceLabel setText:[NSString stringWithFormat:@"编号 %@%@", PREFIX_CREDIT_SEQ, [self.infoPassed objectForKey:@"transaction_id"]]];
        } else if ([[self.infoPassed objectForKey:@"mall"] isEqualToString:@"cash"]) {
            [sequenceLabel setText:[NSString stringWithFormat:@"编号 %@%@", PREFIX_CASH_SEQ, [self.infoPassed objectForKey:@"transaction_id"]]];
        }
        [self.controlView addSubview:sequenceLabel];
    }
    
    [self.infoTable setScrollsToTop:YES];
    [self.infoTable reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //[self.buyButton setFrame:CGRectMake(self.controlView.frame.size.width - 80, 0, 80, 35)];
}

- (void)buy {
    if ([user getCurrentID] == nil) {
        //request login
        UIViewController *goLoginController = [self.storyboard instantiateViewControllerWithIdentifier:@"loginRoot"];
        [self presentViewController:goLoginController animated:YES completion:nil];
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"购买" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [alertView setTag:100];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100 && buttonIndex == 1) {
        //send purchase request
        //parameters: mall, store_id, item_id, username
        NSMutableDictionary *info = [self.infoPassed mutableCopy];
        [info setValue:[user getCurrentID] forKey:@"user_name"];
        [info setValue:APP_PLATFORM forKey:@"platform"];
        [info setValue:@"0" forKey:@"tableID"];
        NSInteger purchase_result = [user purchaseMallItem:info];
        transactionID = purchase_result;
        if (purchase_result >= 0) {
            if ([[self.infoPassed objectForKey:@"mall"] isEqualToString:@"credit"]) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"兑换成功" message:@"您可以在消费记录中查看" delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil];
                [alertView show];
            } else { //ask to pay
                purseValueMall = [user getPurseMoney];
                float purseValue = purseValueMall;
                NSString *purseStr = nil;
                if (purseValueMall < [[self.infoPassed objectForKey:@"price"] floatValue]) {
                    purseStr = PURSE_INSUF_FUND;
                } else {
                    purseStr = PURSE_FUND_PAY;
                }
                
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"付款" message:[NSString stringWithFormat:@"请选择付款方式\n金额：￥%.2f", [[self.infoPassed objectForKey:@"price"] floatValue]] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:purseStr, PING_PAYMENT_OPTION, nil];
                alert.tag = 20;
                [alert show];
            }
        }
    } else if (alertView.tag == 20) {
        //dismiss loading
        [HTTPRequest end_loading];
        NSMutableDictionary *payInfo = [self.infoPassed mutableCopy];
        [payInfo setObject:[NSString stringWithFormat:@"%d", transactionID] forKey:@"transaction_id"];
        [payInfo setObject:[user getCurrentID] forKey:@"username"];
        switch (buttonIndex) {
            case 1: //UniCafe钱包付款
                [user payByPurseFor:payInfo];
                break;
                
            case 2:
                [user payWithChannel:@"alipay" andInfo:payInfo onViewController:self];
                break;
                
            case 3:
                [user payWithChannel:@"wx" andInfo:payInfo onViewController:self];
                break;
                
            case 4:
                [user payWithChannel:@"upmp" andInfo:payInfo onViewController:self];
                break;
                
            default:
                break;
        }
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if (alertView.tag == 20) {
        if (purseValueMall < [[self.infoPassed objectForKey:@"price"] floatValue])
            return NO;
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
