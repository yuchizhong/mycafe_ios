//
//  ViewController.m
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import "cart.h"
#import "data.h"
#import "singleItem.h"
#import "foodList.h"
#import "extra.h"
#import "storeList.h"
#import "CustomIOS7AlertView.h"

static BOOL returnFromLogin = NO;
static int cartCellID;
static float totalToPay;
static float purseValue;
static NSInteger creditValue;
static float creditToCent;

static cart *instance = nil;

@interface cart ()

@property (atomic) NSInteger usingThreads;
@property (atomic, strong) NSString *showOrderID;

@end

@implementation cart

+ (cart*)getInstance {
   return instance;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
   [textField resignFirstResponder];
   return YES;
}

- (void)reLoadForm {
   [self.foodTable reloadData];
   float _totalvalue = [orderInfo getTotalValue];
   if (_totalvalue == 0) {
      REFRESH_VALUE_BADGE(nil);
   } else {
      NSString *s = [NSString stringWithFormat:@"￥%.0f", _totalvalue];
      REFRESH_VALUE_BADGE(s);
   }
   if (_totalvalue == 0.0) {
      [self.navigationItem setTitle:[NSString stringWithFormat:@"购物车"/*, [store getCurrentStoreName]*/]];
   } else {
      [self.navigationItem setTitle:[NSString stringWithFormat:@"购物车 ￥%.2f", _totalvalue/*, [store getCurrentStoreName]*/]];
   }
}

- (void)askToPay:(BOOL)tableNumAvailable andTotal:(float)total {
   BEGIN_LOADING
   purseValue = [user getPurseMoneyAsync];
   NSString *purseStr = nil;
   if (purseValue < totalToPay) {
      purseStr = PURSE_INSUF_FUND;
   } else {
      purseStr = PURSE_FUND_PAY;
   }
   
   NSString *creditStr = nil;
   creditToCent = [store creditToCentRatio]; //多少credit对应1分钱
   float creditNeeded = totalToPay * 100 * creditToCent;
   if ([store creditCanPay]) {
      creditValue = [user getCreditForStoreIDAsync:[store getCurrentStoreID]];  //credit余额
      if (creditValue < creditNeeded) {
         creditStr = [NSString stringWithFormat:@"积分付:需%.0f，现有%d", creditNeeded, creditValue];
      } else {
         creditStr = [NSString stringWithFormat:@"积分付:需%.0f，现有%d", creditNeeded, creditValue];
      }
   }
   
   END_LOADING
   
   if (tableNumAvailable) {
      if ([store payOption] == PAY_OPTION_BEFORE) {
         if (PAY_BEFORE_SHOW_CANCEL_BUTTON) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"下单成功" message:[NSString stringWithFormat:@"未付金额：￥%.2f\n您的单号：%@\n您的桌号：%d", total, self.showOrderID, [store getTableNum]] delegate:self cancelButtonTitle:@"取消（付款后才能下单）" otherButtonTitles:purseStr, /*PING_PAYMENT_OPTION,*/ nil];
            alert.tag = 20;
            [alert show];
         } else {
            CustomIOS7AlertView *alert = [[CustomIOS7AlertView alloc]init];
            UIView *infoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 300, 115)];
            [infoView setBackgroundColor:[UIColor clearColor]];
            UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 40)];
            [titleLabel setTextAlignment:NSTextAlignmentCenter];
            [titleLabel setText:@"下单成功"];
            [titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
            [titleLabel setBackgroundColor:[UIColor clearColor]];
            [infoView addSubview:titleLabel];
            UILabel *infoLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 35, 300, 70)];
            [infoLabel setTextAlignment:NSTextAlignmentCenter];
            [infoLabel setNumberOfLines:0];
            [infoLabel setLineBreakMode:NSLineBreakByCharWrapping];
            [infoLabel setFont:[UIFont systemFontOfSize:13]];
            [infoLabel setText:[NSString stringWithFormat:@"未付金额：￥%.2f\n您的单号：%@\n您的桌号：%d", total, self.showOrderID, [store getTableNum]]];
            [infoLabel setBackgroundColor:[UIColor clearColor]];
            [infoView addSubview:infoLabel];
            [alert setContainerView:infoView];
            if ([store creditCanPay]) {
               [alert setButtonTitles:@[purseStr, creditStr, /*PING_PAYMENT_OPTION,*/ @"取消"]];
            } else {
               [alert setButtonTitles:@[purseStr, /*PING_PAYMENT_OPTION,*/ @"取消"]];
            }
            alert.delegate = self;
            if (purseValue < totalToPay)
               alert.disableFirstButton = YES;
            if (creditValue < creditNeeded && [store creditCanPay])
               alert.disableSecondButton = YES;
            alert.tag = 21;
            [alert show];
         }
      } else if ([store payOption] == PAY_OPTION_ANY) {
         UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"下单成功" message:[NSString stringWithFormat:@"未付金额：￥%.2f\n您的单号：%@\n您的桌号：%d", total, self.showOrderID, [store getTableNum]] delegate:self cancelButtonTitle:@"自己联系服务员支付" otherButtonTitles:purseStr, /*PING_PAYMENT_OPTION,*/ nil];
         alert.tag = 20;
         [alert show];
      } else {
         UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"下单成功" message:[NSString stringWithFormat:@"未付总金额：￥%.2f\n请稍后与服务员联系以支付\n您的单号：%@\n您的桌号：%d", total, self.showOrderID, [store getTableNum]] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
         alert.tag = 20;
         [alert show];
      }
   } else {
      if ([store payOption] == PAY_OPTION_BEFORE) {
         if (PAY_BEFORE_SHOW_CANCEL_BUTTON) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"下单成功" message:[NSString stringWithFormat:@"未付金额：￥%.2f\n您的单号：%@", total, self.showOrderID] delegate:self cancelButtonTitle:@"取消（付款后才能下单）" otherButtonTitles:purseStr, /*PING_PAYMENT_OPTION,*/ nil];
            alert.tag = 20;
            [alert show];
         } else {
            CustomIOS7AlertView *alert = [[CustomIOS7AlertView alloc]init];
            UIView *infoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 300, 115)];
            [infoView setBackgroundColor:[UIColor clearColor]];
            UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 40)];
            [titleLabel setTextAlignment:NSTextAlignmentCenter];
            [titleLabel setText:@"下单成功"];
            [titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
            [titleLabel setBackgroundColor:[UIColor clearColor]];
            [infoView addSubview:titleLabel];
            UILabel *infoLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 35, 300, 70)];
            [infoLabel setTextAlignment:NSTextAlignmentCenter];
            [infoLabel setNumberOfLines:0];
            [infoLabel setLineBreakMode:NSLineBreakByCharWrapping];
            [infoLabel setFont:[UIFont systemFontOfSize:13]];
            [infoLabel setText:[NSString stringWithFormat:@"未付金额：￥%.2f\n您的单号：%@\n餐点做好后会通知您到前台取餐", total, self.showOrderID]];
            [infoLabel setBackgroundColor:[UIColor clearColor]];
            [infoView addSubview:infoLabel];
            [alert setContainerView:infoView];
            if ([store creditCanPay]) {
               [alert setButtonTitles:@[purseStr, creditStr, /*PING_PAYMENT_OPTION,*/ @"取消"]];
            } else {
               [alert setButtonTitles:@[purseStr, /*PING_PAYMENT_OPTION,*/ @"取消"]];
            }                alert.delegate = self;
            if (purseValue < totalToPay)
               alert.disableFirstButton = YES;
            if (creditValue < creditNeeded && [store creditCanPay])
               alert.disableSecondButton = YES;
            alert.tag = 21;
            [alert show];
         }
      } else if ([store payOption] == PAY_OPTION_ANY) {
         UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"下单成功" message:[NSString stringWithFormat:@"请选择付款方式\n未付总金额：￥%.2f\n餐点做好后会通知您到前台取餐\n您的单号：%@", total, self.showOrderID] delegate:self cancelButtonTitle:@"自己联系服务员支付" otherButtonTitles:purseStr, /*PING_PAYMENT_OPTION,*/ nil];
         alert.tag = 20;
         [alert show];
      } else {
         UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"下单成功" message:[NSString stringWithFormat:@"未付总金额：￥%.2f\n请稍后与服务员联系以支付\n餐点做好后会通知您到前台取餐\n您的单号：%@", total, self.showOrderID] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
         alert.tag = 20;
         [alert show];
      }
   }
}

- (void)customIOS7dialogButtonTouchUpInside:(id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
   if (((CustomIOS7AlertView*)alertView).tag == 21) {
      BOOL success = NO;
      BOOL canClearOrder = NO;
      if ([store creditCanPay]) {
         switch (buttonIndex) {
            case 0: //UniCafe钱包付款
               success = [user payByPurseForAmount:totalToPay];
               canClearOrder = YES;
               break;
               
            case 1: //积分支付
               success = [user payByCreditForTotalCredit:(NSInteger)(totalToPay * 100 * creditToCent)];
               canClearOrder = YES;
               break;
               
            /*
            case 2:
               success = [user payWithChannel:@"alipay" andAmount:totalToPay onViewController:self];
               break;
               
            case 3:
               success = [user payWithChannel:@"wx" andAmount:totalToPay onViewController:self];
               break;
            
            case 4:
               success = [user payWithChannel:@"upmp" andAmount:totalToPay onViewController:self];
               break;
               */
            default:
               break;
         }
      } else {
         switch (buttonIndex) {
            case 0: //UniCafe钱包付款
               success = [user payByPurseForAmount:totalToPay];
               canClearOrder = YES;
               break;
               
            /*
            case 1:
               success = [user payWithChannel:@"alipay" andAmount:totalToPay onViewController:self];
               break;
               
            case 2:
               success = [user payWithChannel:@"wx" andAmount:totalToPay onViewController:self];
               break;
            
            case 3:
               success = [user payWithChannel:@"upmp" andAmount:totalToPay onViewController:self];
               break;
               */
               
            default:
               break;
         }
      }
      if (success && canClearOrder) {
         [[orderInfo getOrder] removeAllObjects];
         [orderInfo saveOrder];
         //kick
         [self.navigationController popToRootViewControllerAnimated:YES];
      } else if (success) {
         [AppDelegate setPayingModule:MODULE_NORMAL];
      }
   }
   [alertView close];
   [self viewWillAppear:NO];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
   if (alertView.tag == 200 && buttonIndex == 1) {
      [[orderInfo getOrder] removeAllObjects];
      [orderInfo saveOrder];
      [self reLoadForm];
   }
   if (alertView.tag == 11 && buttonIndex == 1) {
      //提交失败
      float total = [self confirm];
      if (total < 0) {
         //ERROR
         return;
      }
      totalToPay = total;
      /*
      if ([store needNoTableNum]) {
         [self askToPay:NO andTotal:total];
      } else {
         [self askToPay:YES andTotal:total];
      }
       */
   }
   if (alertView.tag == 10 && buttonIndex == 1) {
      NSString *tableNumStr = [alertView textFieldAtIndex:0].text;
      int tableNum = [tableNumStr intValue];
      if (tableNum == 0) {
         UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"桌号错误" message:@"桌号应为非零数字" delegate:self cancelButtonTitle:@"返回" otherButtonTitles:nil];
         [alert show];
         return;
      }
      [store setTableNum:tableNum];
      
      //提交失败
      float total = [self confirm];
      if (total < 0) {
         return;
      }
      totalToPay = total;
      
      //提交成功，提示付款
      //[self askToPay:YES andTotal:total];
   }
   if (alertView.tag == 20) {
      BOOL success = NO;
      switch (buttonIndex) {
         case 1: //UniCafe钱包付款
            success = [user payByPurseForAmount:totalToPay];
            break;
            
         case 2:
            success = [user payWithChannel:@"alipay" andAmount:totalToPay onViewController:self];
            break;
            
         case 3:
            success = [user payWithChannel:@"wx" andAmount:totalToPay onViewController:self];
            break;
            
         case 4:
            success = [user payWithChannel:@"upmp" andAmount:totalToPay onViewController:self];
            break;
            
         default:
            break;
      }
      if (success) {
         [[orderInfo getOrder] removeAllObjects];
         [orderInfo saveOrder];
      }
      [self viewWillAppear:NO];
   }
   if (alertView.tag == 21) {
      BOOL success = NO;
      switch (buttonIndex) {
         case 0: //UniCafe钱包付款
            success = [user payByPurseForAmount:totalToPay];
            break;
            
         case 1:
            success = [user payWithChannel:@"alipay" andAmount:totalToPay onViewController:self];
            break;
            
         case 2:
            success = [user payWithChannel:@"wx" andAmount:totalToPay onViewController:self];
            break;
            
         case 3:
            success = [user payWithChannel:@"upmp" andAmount:totalToPay onViewController:self];
            break;
            
         default:
            break;
      }
      if (success) {
         [[orderInfo getOrder] removeAllObjects];
         [orderInfo saveOrder];
      }
      [self viewWillAppear:NO];
   }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
   if (alertView.tag == 20 || alertView.tag == 21) {
      if (purseValue < totalToPay)
         return NO;
   }
   return YES;
}

- (void)confirm_prepare {
   if ([user getCurrentID] == nil) {
      [extra setReg:NO];
      returnFromLogin = YES;
      //login
      UIViewController *goLoginController = [self.storyboard instantiateViewControllerWithIdentifier:@"loginRoot"];
      [self presentViewController:goLoginController animated:YES completion:nil];
      return;
   }
   
   UIAlertView *alert;
   NSString *msg = [NSString stringWithFormat:@"本单金额:%.2f\n请输入您的桌号", [orderInfo getTotalValue]];
   if ([orderInfo getOrder].count == 0)
      alert = [[UIAlertView alloc]initWithTitle:@"没有点单" message:@"您还没有点菜" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
   else if ([store getTableNum] == 0 && ![store needNoTableNum] && ![store preorder_mode]) {
      alert = [[UIAlertView alloc]initWithTitle:@"下单确认" message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
      [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
      [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
      alert.tag = 10;
   } else if (![store preorder_mode]) {
      alert = [[UIAlertView alloc]initWithTitle:@"下单确认" message:[NSString stringWithFormat:@"本单金额:%.2f\n本店需要自行取餐，餐点做好后会通知您", [orderInfo getTotalValue]] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
      alert.tag = 11;
   } else { //preorder mode
      UIViewController *preorderView = [self.storyboard instantiateViewControllerWithIdentifier:@"preorderConfirm"];
      [self.navigationController pushViewController:preorderView animated:YES];
   }
   [alert show];
}

- (float)confirm {
   NSString *feedback = [store submitOrder];
   if (feedback == nil) {
      return -1;
   } else {
      NSArray *ar = [feedback componentsSeparatedByString:@":"];
      self.showOrderID = [ar objectAtIndex:0];
      
      /*
       UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"下单成功" message:[NSString stringWithFormat:@"您的点单已提交，请等候上菜\n您的单号：%@", feedback] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
       alert.tag = 5;
       [alert show];
       */
      
      //clear after payment
      /*
       [[orderInfo getOrder] removeAllObjects];
       [orderInfo saveOrder];
       */
      [self viewWillAppear:NO];
      return [[ar objectAtIndex:1] floatValue];
   }
}

- (void)clearAll {
   UIAlertView *alert;
   alert = [[UIAlertView alloc]initWithTitle:@"清空" message:@"确定清空购物车？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
   alert.tag = 200;
   [alert show];
}

- (void)showOrders {
   UIViewController *alreadyOrdered = [self.storyboard instantiateViewControllerWithIdentifier:@"alreadyOrdered"];
   [self presentViewController:alreadyOrdered animated:YES completion:nil];
}

- (void)backToMenu {
   [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad {
   [super viewDidLoad];
   // Do any additional setup after loading the view, typically from a nib.
   
   SET_NAVBAR
   
   instance = self;
   [self.foodTable setBackgroundColor:COFFEE_LIGHT];
   [storeList registerOrderView:self];
   
   cartCellID = 0;
   self.usingThreads = 0;
   
   UINavigationItem *item = self.navigationItem;
   
   [item setTitle:@"购物车"];
   
   /*
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"菜单"
    style:UIBarButtonItemStyleBordered
    target:self
    action:@selector(backToMenu)];
    */
   /*
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"清空"
    style:UIBarButtonItemStylePlain
    target:self
    action:@selector(clearAll)];
    */
   
   UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                 target:self
                                                 action:@selector(clearAll)];
   [item setRightBarButtonItem:clearButton];
   
   //[item setLeftBarButtonItem:backButton];
   
   //[self.navigationController.navigationBar setTranslucent:YES];
   //self.navigationController.navigationBar.shadowImage = [UIImage new];
   
   [self.foodTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)refresh {
   /*
   UINavigationItem *item = self.navigationItem;
   
   if ([store supportAiyidian] || [store preorder_mode]) {
      UIBarButtonItem *rightButton;
      if ([store inStore] || [store preorder_mode]) {
         NSString *placeOrderStr = @"下单";
         if ([store preorder_mode] && [store preorder_option_allowed] == 1)
            placeOrderStr = @"预订";
         else if ([store preorder_mode] && [store preorder_option_allowed] == 2)
            placeOrderStr = @"预订/外带";
         else if ([store preorder_mode] && [store preorder_option_allowed] == 0) {
            [self.navigationController popViewControllerAnimated:YES];
            [HTTPRequest alert:@"抱歉，此店暂时无法外带"];
         }
         rightButton = [[UIBarButtonItem alloc] initWithTitle:placeOrderStr
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(confirm_prepare)];
      } else if (![store preorder_mode]) {
         rightButton = [[UIBarButtonItem alloc] initWithTitle:@"店外"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:nil];
         [rightButton setEnabled:NO];
      }
      
      if (!DISABLE_UNPAID && [user getCurrentID] != nil && [store inStore]) {
         UIBarButtonItem *rightButton2 = [[UIBarButtonItem alloc] initWithTitle:@"未付"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(showOrders)];
         
         [rightButton2 setEnabled:NO];
         [item setRightBarButtonItems:[NSArray arrayWithObjects:rightButton, rightButton2, nil]];
      } else {
         [item setRightBarButtonItem:rightButton];
      }
   } else {
      UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"不支持有你咖"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:nil];
      [rightButton setEnabled:NO];
      [item setRightBarButtonItem:rightButton];
   }
    */
   
   /*
    if (self.tabBarController.selectedIndex == 2) {
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
    [self.navigationController.navigationBar setTranslucent:YES];
    }
    */
   
   if (returnFromLogin) {
      returnFromLogin = NO;
      if ([user getCurrentID] != nil)
         [self confirm_prepare];
   }
   [self reLoadForm];
   
   if ([user getCurrentID] != nil) {
      [NSThread detachNewThreadSelector:@selector(loadCurrentHistory) toTarget:self withObject:nil];
   }
}

- (void)viewWillAppear:(BOOL)animated {
   [super viewWillAppear:animated];
   [self.navigationItem.backBarButtonItem setTitle:@"返回"];
   [self refresh];
   [self reLoadForm];
}

- (void)loadCurrentHistory {
   if (self.usingThreads > 0) {
      return;
   }
   self.usingThreads++;
   float totalV = -1.0;
   while (totalV < 0) {
      totalV = [orderInfo getPayTotalOnline];
      if (totalV < 0) {
         [NSThread sleepForTimeInterval:NETWORK_RETRY_WAIT];
      }
   }
   
   if ([self.navigationItem.rightBarButtonItems count] > 1) {
      if (totalV > 0) {
         [(UIBarButtonItem*)[self.navigationItem.rightBarButtonItems objectAtIndex:1] setTitle:[NSString stringWithFormat:@"未付￥%.0f", totalV]];
         [(UIBarButtonItem*)[self.navigationItem.rightBarButtonItems objectAtIndex:1] setEnabled:YES];
      } else {
         [(UIBarButtonItem*)[self.navigationItem.rightBarButtonItems objectAtIndex:1] setTitle:@"无未付"];
         [(UIBarButtonItem*)[self.navigationItem.rightBarButtonItems objectAtIndex:1] setEnabled:NO];
      }
   }
   
   self.usingThreads--;
}

- (void)viewWillDisappear:(BOOL)animated {
   [super viewWillDisappear:animated];
   [orderInfo saveOrder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
   if ([orderInfo getOrder].count > 0) {
      return [orderInfo getOrder].count;
   }
   return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
   if (indexPath.row == [orderInfo getOrder].count) {
      return UI_TABLE_CELL_HEIGHT * 0.618;
   }
   return UI_TABLE_CELL_HEIGHT;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
   return @"删除";
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
   //don't show
   return UITableViewCellEditingStyleNone;
   //return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
   if (editingStyle == UITableViewCellEditingStyleDelete) {
      int foodId = [((orderInfo*)[[orderInfo getOrder] objectAtIndex:indexPath.row]) getID];
      [orderInfo removeFood:foodId withCount:[orderInfo getCountForFood:foodId]];
      [self.foodTable deleteRowsAtIndexPaths:[NSMutableArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
      
      [self reLoadForm];
   }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   NSInteger rightRow = [indexPath row];
   
   if (rightRow == [orderInfo getOrder].count) {
      [self clearAll];
   } else {
      singleItem *itemView = [storeList getItemDetailVC]; // [self.storyboard instantiateViewControllerWithIdentifier:@"itemDetails"];
      int showID = [((orderInfo*)[[orderInfo getOrder] objectAtIndex:rightRow]) getID];
      [itemView setGiftMode:NO];
      [extra setFoodID:showID];
      
      //[self presentViewController:itemView animated:YES completion:nil];
      [self.navigationController pushViewController:itemView animated:YES];
   }
   
   [self.foodTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   NSUInteger row = [indexPath row];
   
   int rightRow = (int)row;
   
   UITableViewCell *cell = nil;
   if (USE_NIL_CELL_ID) {
      cell = [[UITableViewCell alloc]
              initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:nil];
   } else {
      NSString *TableSampleIdentifier = [NSString stringWithFormat:@"tableCellID%d", cartCellID];
      cartCellID++;
      
      cell = [tableView dequeueReusableCellWithIdentifier:
              TableSampleIdentifier];
      if (cell == nil) {
         cell = [[UITableViewCell alloc]
                 initWithStyle:UITableViewCellStyleDefault
                 reuseIdentifier:TableSampleIdentifier];
      }
   }
   
   if (indexPath.row == [orderInfo getOrder].count) {
      UILabel *clearLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, UI_TABLE_CELL_HEIGHT * 0.618)];
      [clearLabel setFont:UI_TITLE_FONT];
      [clearLabel setTextAlignment:NSTextAlignmentCenter];
      [clearLabel setBackgroundColor:COFFEE_DARK];
      [clearLabel setTextColor:[UIColor whiteColor]];
      [clearLabel setText:@"清空"];
      [cell addSubview:clearLabel];
   } else {
      int foodId = [((orderInfo*)[[orderInfo getOrder] objectAtIndex:rightRow]) getID];
      foodInfo *finfo = (foodInfo*)[[store getMenu] objectAtIndex:[store getIndexForFoodID:foodId]];
      
      float button_size = UI_TABLE_BUTTON_WIDTH, text_width = UI_TABLE_COUNT_WIDTH;
      
      UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(78, 10, tableView.frame.size.width - 10 - 78, 18)];
      [labelTitle setFont:[UIFont systemFontOfSize:16]];
      [labelTitle setTextAlignment:NSTextAlignmentLeft];
      [labelTitle setTextColor:[UIColor blackColor]];
      [labelTitle setText:finfo.title];
      [cell addSubview:labelTitle];
      
      float gapOffset = 2.0;
      
      UILabel *labelprice = [[UILabel alloc] initWithFrame:CGRectMake(78, 28 + gapOffset, UI_TABLE_PRICE_WIDTH, 15)];
      [labelprice setFont:[UIFont systemFontOfSize:15]];
      [labelprice setTextAlignment:NSTextAlignmentLeft];
      [labelprice setTextColor:[UIColor redColor]];
      NSString *priceString = [NSString stringWithFormat:@"￥%.2f", [finfo getPrice]];
      [labelprice setText:priceString];
      [labelprice sizeToFit];
      [cell addSubview:labelprice];
      
      if (finfo.originalPrice != 0 && finfo.originalPrice > [finfo getPrice]) {
         UILabel *orilabelprice = [[UILabel alloc] initWithFrame:CGRectMake(labelprice.frame.origin.x + labelprice.frame.size.width + 5, 31 + gapOffset, UI_TABLE_PRICE_WIDTH, 12)];
         [orilabelprice setFont:[UIFont systemFontOfSize:12]];
         [orilabelprice setTextAlignment:NSTextAlignmentLeft];
         [orilabelprice setTextColor:[UIColor grayColor]];
         [orilabelprice setText: [NSString stringWithFormat:@"￥%.2f", finfo.originalPrice]];
         [orilabelprice sizeToFit];
         [cell addSubview:orilabelprice];
         
         //add line
         UIImageView *imageViewLine = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, orilabelprice.frame.size.width, orilabelprice.frame.size.height)];
         UIGraphicsBeginImageContext(CGSizeMake(imageViewLine.frame.size.width, imageViewLine.frame.size.height));
         [imageViewLine.image drawInRect:CGRectMake(0, 0, imageViewLine.frame.size.width, imageViewLine.frame.size.height)];
         CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
         CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 0.7);  //线宽
         CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
         CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.2, 0.2, 0.2, 1.0);  //颜色
         CGContextBeginPath(UIGraphicsGetCurrentContext());
         CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, imageViewLine.frame.size.height / 2);  //起点坐标
         CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), imageViewLine.frame.size.width, imageViewLine.frame.size.height / 2);   //终点坐标
         CGContextStrokePath(UIGraphicsGetCurrentContext());
         imageViewLine.image=UIGraphicsGetImageFromCurrentImageContext();
         UIGraphicsEndImageContext();
         [orilabelprice addSubview:imageViewLine];
      }
      
      UILabel *labeladd = [[UILabel alloc] initWithFrame:CGRectMake(78 + 17 - 1, 55, 35, 15)];
      [labeladd setFont:[UIFont systemFontOfSize:14]];
      [labeladd setTextAlignment:NSTextAlignmentLeft];
      [labeladd setTextColor:[UIColor colorWithWhite:0.55 alpha:1]];
      [labeladd setText:[[finfo.addition componentsSeparatedByString:@":"] objectAtIndex:0]];
      [labeladd sizeToFit];
      [cell addSubview:labeladd];
      
      UIImageView *upImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star.png"]];
      [upImage setFrame:CGRectMake(78, labeladd.frame.origin.y, labeladd.frame.size.height - 2, labeladd.frame.size.height - 1)];
      [cell addSubview:upImage];
      
      if (/* DISABLES CODE */ (NO) && finfo.scoreToEarn > 0) {
         UILabel *labelscore = [[UILabel alloc] initWithFrame:CGRectMake(labeladd.frame.origin.x + labeladd.frame.size.width + 5, 56, 60, 15)];
         [labelscore setFont:[UIFont systemFontOfSize:13]];
         [labelscore setTextAlignment:NSTextAlignmentLeft];
         [labelscore setTextColor:COFFEE_VERY_DARK];
         [labelscore setText:[NSString stringWithFormat:@"+%d积分", finfo.scoreToEarn]];
         [cell addSubview:labelscore];
      }
      
      int foodCount = [orderInfo getCountForFood:foodId];
      //right side
      UIButton *addButtonB = [UIButton buttonWithType:UIButtonTypeRoundedRect];
      [addButtonB setFrame:CGRectMake(tableView.frame.size.width - 10 - button_size, 0, button_size + 20, UI_TABLE_CELL_HEIGHT)];
      [addButtonB setBackgroundColor:[UIColor clearColor]];
      [addButtonB setTitle:@"" forState:UIControlStateNormal];
      [addButtonB setTag:foodId];
      [addButtonB addTarget:self action:@selector(addToCart:) forControlEvents:UIControlEventTouchDown];
      [cell addSubview:addButtonB];
      
      UIButton *addButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
      [addButton setFrame:CGRectMake(tableView.frame.size.width - 10 - button_size, 70 - button_size /*(80 - button_size) / 2*/, button_size, button_size)];
      [addButton setBackgroundColor:[UIColor clearColor]];
      [addButton setBackgroundImage:[UIImage imageNamed:@"add.png"] forState:UIControlStateNormal];
      [addButton addTarget:self action:@selector(addToCart:) forControlEvents:UIControlEventTouchDown];
      [addButton setTag:foodId];
      [cell addSubview:addButton];
      if (foodCount > 0) {
         UIButton *subButtonB = [UIButton buttonWithType:UIButtonTypeRoundedRect];
         [subButtonB setFrame:CGRectMake(tableView.frame.size.width - 10 - 2 * button_size - text_width - 10, 0, button_size + 20, UI_TABLE_CELL_HEIGHT)];
         [subButtonB setBackgroundColor:[UIColor clearColor]];
         [subButtonB setTag:foodId];
         [subButtonB setTitle:@"" forState:UIControlStateNormal];
         [subButtonB addTarget:self action:@selector(removeFromCart:) forControlEvents:UIControlEventTouchDown];
         [cell addSubview:subButtonB];
         
         UIButton *subButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
         [subButton setFrame:CGRectMake(tableView.frame.size.width - 10 - 2 * button_size - text_width, 70 - button_size /*(80 - button_size) / 2*/, button_size, button_size)];
         [subButton setBackgroundImage:[UIImage imageNamed:@"sub.png"] forState:UIControlStateNormal];
         [subButton setBackgroundColor:[UIColor clearColor]];
         [subButton addTarget:self action:@selector(removeFromCart:) forControlEvents:UIControlEventTouchDown];
         [subButton setTag:foodId];
         [cell addSubview:subButton];
         
         UILabel *labelcount = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 10 - button_size - text_width, 70 - button_size, text_width, button_size)];
         [labelcount setFont:[UIFont systemFontOfSize:18]];
         [labelcount setTextAlignment:NSTextAlignmentCenter];
         [labelcount setTextColor:[UIColor blackColor]];
         NSString *countStr = [NSString stringWithFormat:@"%d", foodCount];
         [labelcount setText:countStr];
         [cell addSubview:labelcount];
      }
      
      //add image
      //round corner image
      UIImageView *roundedView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 60, 60)];
      UIProgressView *loading = [[UIProgressView alloc] initWithFrame:CGRectMake(10, roundedView.frame.size.height / 2 - 1, roundedView.frame.size.width - 20, 2)];
      [loading setProgress:0.0];
      [loading setProgressViewStyle:UIProgressViewStyleDefault];
      [loading setTrackTintColor:UI_PROGRESS_TRACK_COLOR];
      [loading setProgressTintColor:UI_PROGRESS_TINT_COLOR];
      [roundedView addSubview:loading];
      NSString *url = [NSString stringWithFormat:@"%@/%@/dishimage/dish%d/%@", SERVER_ADDRESS, [store getCurrentStoreFolder], foodId, finfo.image];
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
      roundedView.frame = CGRectMake(10, 10, 60, 60);
      [cell addSubview:roundedView];
   }
   
   //draw line
   UIImageView *imageView;
   if (indexPath.row != 0) {
      imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0.5)];
      UIGraphicsBeginImageContext(imageView.frame.size);
      [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
      CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
      CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 15.0);  //线宽
      CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
      CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.99, 0.99, 0.99, 1.0);  //颜色
      CGContextBeginPath(UIGraphicsGetCurrentContext());
      CGContextMoveToPoint(UIGraphicsGetCurrentContext(), 0, 0);  //起点坐标
      CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), tableView.frame.size.width, 0);   //终点坐标
      CGContextStrokePath(UIGraphicsGetCurrentContext());
      imageView.image=UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      [cell addSubview:imageView];
   }
   
   float lineY = UI_TABLE_CELL_HEIGHT - 0.5;
   if (indexPath.row == [orderInfo getOrder].count) {
      lineY = UI_TABLE_CELL_HEIGHT * 0.618 - 0.5;
   }
   imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, lineY, tableView.frame.size.width, 0.5)];
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
   
   return cell;
}

-(void)addToCart:(id)sender {
   int foodid = (int)((UIButton*)sender).tag;
   [orderInfo addFood:foodid withCount:1];
   [self reLoadForm];
}

-(void)removeFromCart:(id)sender {
   int foodid = (int)((UIButton*)sender).tag;
   [orderInfo removeFood:foodid withCount:1];
   [self reLoadForm];
}

- (void)didReceiveMemoryWarning {
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

@end
