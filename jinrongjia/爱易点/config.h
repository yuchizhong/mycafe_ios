//
//  config.h
//  爱易点
//
//  Created by unicorechina on 2014-10-07.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#ifndef ____config_h
#define ____config_h

#define app_version     1.0 //用于检测app是否为最新版
#define app_store_id    @"26"

#ifdef __OPTIMIZE__     //release
#   define NSLog(...) {}
#   define DEBUG_MODE NO
#   define LEAVE_STORE_WAIT 600000.0 //1 minute
#   define use_production_server YES //always use production server
#else                   //debug
#   define NSLog(...) NSLog(__VA_ARGS__)
#   define DEBUG_MODE YES
#   define LEAVE_STORE_WAIT 600000.0 //1 hour
#   define use_production_server YES //depend on test case
#endif

//设置购物车角标
#define REFRESH_VALUE_BADGE(__value__) ((BBBadgeBarButtonItem*)[foodList cartButton]).badgeValue = __value__;

//设置导航栏风格
#define SET_NAVBAR \
[self.navigationController.navigationBar setTintColor:[UIColor whiteColor]]; \
self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]}; \
[self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"empty.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)] forBarMetrics:UIBarMetricsDefault]; \
self.navigationController.navigationBar.shadowImage = [UIImage new]; \
[self.navigationController.navigationBar setTranslucent:NO];


//搜索过滤选项
//店家列表
#define SHOW_FILTER_OPTIONS             NO
#define FILTER_COLUMNS_NAMES            @[@"AREA", @"AREA2", @"AREA3"]              //服务器接口参数
#define INIT_FILTER_COLUMNS             @[@[@"附近", @"北京"], @[@"附近"], @[@"附近"]] //初始列表
//活动列表
#define SHOW_ACTIVITY_FILTER_OPTIONS    NO
#define FILTER_COLUMNS_ACTIVITY_NAMES   FILTER_COLUMNS_NAMES
#define INIT_FILTER_COLUMNS_ACTIVITY    INIT_FILTER_COLUMNS

#define USE_BAIDU_MAP                   NO

//Ping++
#define PING_PAYMENT_OPTION /*@"支付宝支付", @"微信支付", @"银联支付",*/
#define PING_URL_SCHEME     @"没有支付"

//APP KEY
#define BAIDU_MAP_KEY       @"没有"
#define WEIXIN_APPID        @"jinrongjiacafewx"

//simulate iBeacon
#define SIMULATE_BEACON     NO
#define SIMULATE_BEACON_2   YES //use beacon 2 if SIMULATE_BEACON == YES

#define ALWAYS_AUTH         YES //location updates: always/whenInUse

#define DISABLE_UNPAID      YES

//通达同步图片下载数量
#define MAX_CONCURRENT_IMAGE_DOWNLOAD 10

#define PAY_OPTION_BEFORE   0
#define PAY_OPTION_ANY      1
#define PAY_OPTION_LATER    2
#define PAY_BEFORE_SHOW_CANCEL_BUTTON NO

//模块编号，用于支付返回时刷新
#define MODULE_NORMAL           1
#define MODULE_PREORDER         2
#define MODULE_PURSE            3
#define MODULE_MALL_CASH        4
#define MODULE_MALL_ACTIVITY    5
#define MODULE_CAFE_WALL        6

//tableview不重用单元
#define USE_NIL_CELL_ID         YES
//启动时清空下载图片缓存
#define CLEAR_IMAGE_CACHE       NO
#define UI_JUMP_USE_DISPATCH    NO

#define BACKGROUND_DISCOVERY    YES
#define RECOMMAND_DISCOVERY     NO

//GET
//log网络交互
#define LOG_NETWORK             NO //GET
#define LOG_NETWORK_POST        NO //POST
//网络最大延迟等待
#define NETWORK_TIMEOUT         10.0
//失败重试间隔
#define NETWORK_RETRY_WAIT      0.5

//log SQL语句
#define LOG_SQL NO
//每条语句自动COMMIT
#define SQL_AUTO_COMMIT NO
//SQL NULL
#define SQL_NULL_STRING @"NULL_OBJECT_NULL"
//iOS = 0
#define APP_PLATFORM @"0"

#define TITLE_CREDIT @"积分商城"
#define TITLE_CASH @"本店商城"
#define TITLE_ACTIVITY @"活动"
#define TITLE_GROUPON @"团购"

#define PREFIX_CREDIT_SEQ @"#"
#define PREFIX_CASH_SEQ @"#"

#define TEST_SERVER_ADDRESS                   @"https://182.92.130.225"
#define PRODUCTION_SERVER_ADDRESS             @"https://182.92.130.225"
#define PRODUCTION_SERVER_ADDRESS_NOT_SECURE  @"https://182.92.130.225"

#define SERVER_ADDRESS use_production_server ? PRODUCTION_SERVER_ADDRESS : TEST_SERVER_ADDRESS

#define SERVER_STORE_ID                         @"store_id.php"
#define SERVER_STORE_NOTIFICATION               @"notification.php"
#define SERVER_STORE_MAINPAGE                   @"store_mainpage.php"
#define SERVER_STORE_MENU                       @"store_menu.php"
#define SERVER_STORE_PUT_ORDER                  @"store_order.php"
#define SERVER_STORE_PREORDER                   @"store_preorder.php"
#define SERVER_MAP_REQUEST                      @"map.php"
#define SERVER_MAP_REQUEST_ALL                  @"allmap.php"
#define SERVER_STORE_REQUEST                    @"all_store.php"
#define SERVER_ACTIVITY_REQUEST                 @"all_activity.php"
#define SERVER_LOGIN                            @"login.php"
#define SERVER_QQ_MATCH                         @"qqmatch.php"
#define SERVER_CUSTOMER_GET_ORDER               @"customer_get_order.php"
#define SERVER_CUSTOMER_GET_PREORDER            @"customer_get_preorder.php"
#define SERVER_GET_SHOULD_PAY                   @"get_pay.php"
#define SERVER_GET_SERVICE                      @"get_service.php"
#define SERVER_GET_NOTIFICATION                 @"get_notification.php"
#define SERVER_GET_CURRENT_HISTORY_ORDER        @"get_history_orders.php"
#define SERVER_GET_SINGLE_ORDER_HISTORY         @"get_history_order_one.php"
#define SERVER_GET_SINGLE_PREORDER_HISTORY      @"get_history_preorder_one.php"
#define SERVER_GET_PURSE_MONEY                  @"get_purse_money.php"
#define SERVER_GET_CREDIT                       @"get_credit.php"
#define SERVER_MALL_ORDER                       @"mall_order.php"
#define SERVER_COLLECT_STORE                    @"collect.php"
#define SERVER_EVALUATE_STORE                   @"store_comment.php"
#define SERVER_PINGPP_PAY                       @"pay.php"

#define SERVER_SUBMIT_USERINFO                  @"submit_userinfo.php"
#define SERVER_CAFE_WALL                        @"cafe_wall.php"
#define SERVER_CAFE_WALL_GET                    @"cafe_wall_get.php"
#define SERVER_CAFE_WALL_SUBMIT                 @"cafe_wall_submit.php"

#define NETWORK_ERROR   @"连接服务器失败，请检查网络"
#define COLLECT         @"收藏"
#define UNCOLLECT       @"取消收藏"
#define PURSE_FUND_PAY [NSString stringWithFormat:@"钱包付款(余额￥%.2f)", purseValue]
#define PURSE_INSUF_FUND [NSString stringWithFormat:@"钱包余额不足(余额￥%.2f)", purseValue]

//UI
#define NUM_STORE_ROWS_PER_PAGE 20

#define STATUS_BAR_NOTIFICATION_ALWAYS_SHOW NO
#define STATUS_BAR_NOTIFICATION_DISMISS_AFTER 5.0
#define STATUS_BAR_NOTIFICATION_STYLE_NAME @"mystyle"

#define UI_PROGRESS_TRACK_COLOR     [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1]
#define UI_PROGRESS_TINT_COLOR      [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1]
#define UI_TABLE_BACKGROUND_COLOR   [UIColor colorWithRed:0.968627 green:0.968627 blue:0.968627 alpha:1]

#define UI_STORE_TABLE_CELL_HEIGHT self.view.frame.size.width * 0.36
#define UI_ACTIVITY_TABLE_CELL_HEIGHT   115
#define UI_CAFE_WALL_TABLE_CELL_HEIGHT  100
#define UI_HISTORY_ORDER_CELL_HEIGHT    60

//food list table
#define UI_TABLE_CELL_HEIGHT    80
#define UI_TABLE_BUTTON_WIDTH   21
#define UI_TABLE_COUNT_WIDTH    32
#define UI_TABLE_PRICE_WIDTH    60

//文本
#define UI_TYPE_TITLE       1
#define UI_TYPE_TEXT        0

#define UI_TITLE_HEIGHT     25
#define UI_TEXT_HEIGHT      20

#define UI_TITLE_FONT   [UIFont systemFontOfSize:18]
#define UI_TEXT_FONT    [UIFont systemFontOfSize:14]
#define FONT15          [UIFont systemFontOfSize:15]
#define FONT16          [UIFont systemFontOfSize:16]
#define FONT17          [UIFont systemFontOfSize:17]

//控件
#define UI_PAGECONTROL_HEIGHT 37

#define UI_HORIZON_IMAGE_HEIGHT self.mainView.frame.size.width * 70.0 / 300.0
#define UI_HORIZON_IMAGE_MARGIN 5

#define UI_CUBE_IMAGE_SIZE self.mainView.frame.size.width * 70.0 / 300.0
#define UI_CUBE_IMAGE_MARGIN 5

#define COFFEE_LIGHT            [UIColor colorWithRed:237.0/255.0   green:233.0/255.0   blue:232.0/255.0    alpha:1]
#define COFFEE_GRAY             [UIColor colorWithRed:52.0/255.0    green:37.0/255.0    blue:28.0/255.0     alpha:1]
#define COFFEE_NORMAL           [UIColor colorWithRed:171.0/255.0   green:99.0/255.0    blue:49.0/255.0     alpha:1]
#define COFFEE_DARK             [UIColor colorWithRed:98.0/255.0    green:62.0/255.0    blue:48.0/255.0     alpha:1]
#define COFFEE_MORE_DARK        [UIColor colorWithRed:74.0/255.0    green:44.0/255.0    blue:27.0/255.0     alpha:1]
#define COFFEE_VERY_DARK        [UIColor colorWithRed:63.0/255.0    green:31.0/255.0    blue:17.0/255.0     alpha:1]
#define COFFEE_NOT_VERY_DARK    [UIColor colorWithRed:66.0/255.0    green:54.0/255.0    blue:48.0/255.0     alpha:1]
#define COFFEE_DARKEST          [UIColor colorWithRed:32.0/255.0    green:12.0/255.0    blue:5.0/255.0      alpha:1]

#define NOTIFICATION_COLOR      [UIColor colorWithRed:0.0/255.0     green:0.0/255.0     blue:0.0/255.0      alpha:1]
#define DDARK_RED               [UIColor colorWithRed:210.0/255.0   green:30.0/255.0    blue:20.0/255.0     alpha:1]
#define DARK_RED                [UIColor colorWithRed:220.0/255.0   green:50.0/255.0    blue:30.0/255.0     alpha:1]
#define PINK_RED                [UIColor colorWithRed:230.0/255.0   green:67.0/255.0    blue:90.0/255.0     alpha:1]
#define BLUE                    [UIColor colorWithRed:42.0/255.0    green:98.0/255.0    blue:170.0/255.0    alpha:1]

#define FILTER_OPTION_BACKGROUND COFFEE_NOT_VERY_DARK

#endif
