//
//  ViewController.h
//  爱易点
//
//  Created by unicorechina on 2014-08-28.
//  Copyright (c) 2014 unicorechina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "HTTPRequest.h"
#import <CommonCrypto/CommonDigest.h> 
#import <sqlite3.h>
#import "JDStatusBarNotification.h"
#import "BBBadgeBarButtonItem.h"
#import <Social/Social.h>
#import "WeixinSessionActivity.h"
#import "WeixinTimelineActivity.h"

//test
//中餐
#define MAJOR1 55210
#define MINOR1 12203
//西餐
#define MAJOR2 922
#define MINOR2 58789

//广式茶餐厅
#define MAJOR3 88888
#define MINOR3 88888

@interface beacon : NSObject

@property(atomic) NSInteger major;
@property(atomic) NSInteger minor;

-(beacon*)initWithMajor:(NSInteger)ma andMinor:(NSInteger)mi;

@end

@interface user : NSObject/*<TencentSessionDelegate>*/

+(BOOL)start;
+(NSString*)getServerAddress;

+(NSDictionary*)getUserInfo;
+(BOOL)gotUserinfo;
+(BOOL)submitUserinfo:(NSInteger)birthyear andBirthMonth:(NSInteger)birthmonth andGender:(NSInteger)gender;

+(BOOL)registerWithID:(NSString*)ID andPassword:(NSString*)pass andVerficationCode:(NSString*)code;
+(BOOL)resetPWWithID:(NSString*)ID andPassword:(NSString*)pass andVerficationCode:(NSString*)code;
+(BOOL)sendVerficationCodeTo:(NSString*)tel;
+(BOOL)loginWithID:(NSString*)ID andPassword:(NSString*)pass;
+(BOOL)logOut;
+(NSString*)getCurrentID;
+(NSString*)getIDbyUUID;
+(void)setPushToken:(NSString*)t;
+(void)startGetID;

+(void)handleNotification;

+(void)changeNickname:(NSString*)newName;
+(NSString*)getCurrentUser;

//payment
+(float)getPurseMoney;
+(float)getPurseMoneyAsync; //不显示HUD
+(NSInteger)getCreditForStoreID:(NSString*)c_StoreID;
+(NSInteger)getCreditForStoreIDAsync:(NSString*)c_StoreID; //不显示HUD

//店内点餐/预订
+(BOOL)payWithChannel:(NSString*)channel andAmount:(float)amt onViewController:(UIViewController*)vc;
+(BOOL)payByPurseForAmount:(float)amt;
+(BOOL)payByCreditForTotalCredit:(NSInteger)totalCredit;

//充值
+(BOOL)addMoneyToPurseWithChannel:(NSString*)channel andAmount:(float)amt onViewController:(UIViewController*)vc;

//付款底层
+(BOOL)payByPurseFor:(NSDictionary*)dict;
+(BOOL)payWithChannel:(NSString*)channel andInfo:(NSDictionary*)dict onViewController:(UIViewController*)vc;

//咖啡墙付款
+(BOOL)payByPurseForWallPost:(NSInteger)postID ofAmount:(float)amt;
+(BOOL)payWallPost:(NSInteger)postID byChannel:(NSString*)channel ofAmount:(float)amt onViewContoller:(UIViewController*)vc;

//商城购买
+(NSInteger)purchaseMallItem:(NSDictionary*)info;

+(BOOL)collectStore:(int)c_storeID;
+(BOOL)unCollectStore:(int)c_storeID;

+(BOOL)evaluteStore:(NSString*)e_storeID rating:(int)r comment:(NSString*)comment;

+(void)shareText:(NSString*)text withDescription:(NSString*)desp andImage:(UIImage*)image withURL:(NSString*)url onViewController:(UIViewController*)vc;

/*
//tencent
+(void)startTencentAuth;

+(void)requestLogin;
+(void)requestLogout;

+(NSString*)getCurrentUserImage;

+(void)requestToServerMatch;
+(void)requestFromServerMatch;
 */

+(NSArray*)getHistoryOrders;
+(NSArray*)getHistoryPreorders;
+(NSArray*)getHistoryOrdersFromCurrentStore;
+(NSArray*)getHistoryOrdersFromStore:(NSString*)sid andOrderID:(int)oid;
+(NSArray*)getHistoryPreordersFromStore:(NSString*)sid andOrderID:(int)oid;

@end

@interface any_store : NSObject {
    int storeID;
    BOOL support;
    BOOL whiteName;
    float rating;
    float avgPrice;
    double longitude;
    double latitude;
}

@property(atomic, strong) NSString *title;
@property(atomic, strong) NSString *province;
@property(atomic, strong) NSString *city;
@property(atomic, strong) NSString *district;
@property(atomic, strong) NSString *address;
@property(atomic, strong) NSString *tel;
@property(atomic, strong) NSString *imageName;
@property(atomic, strong) NSMutableArray *notes;

@property(atomic) BOOL wifi;
@property(atomic) BOOL credit;
@property(atomic) BOOL cash;
@property(atomic) BOOL activity;
@property(atomic) BOOL groupon;
@property(atomic) BOOL discount;
@property(atomic) BOOL homepage;
@property(atomic) BOOL collected;
@property(atomic) NSInteger preorder;

-(void)setStoreID:(int)sid;
-(int)storeID;
-(BOOL)support;
-(float)rating;
-(float)avgPrice;
-(BOOL)whiteName;
-(double)longitude;
-(double)latitude;

-(any_store*)initWithTitle:(NSString*)title andID:(int)ID andAddress:(NSString*)address withTel:(NSString*)phoneNumber support:(BOOL)spt withRating:(float)r andAvgPrice:(float)ap andImage:(NSString*)image;
-(void)addNote:(NSString*)note;
-(void)setWhiteName:(BOOL)wn;
-(void)setLongitude:(double)lo andLatitude:(double)la;

+(NSArray*)getProvinces;
+(NSArray*)getCitiesInProvince:(NSString*)province;
+(NSArray*)getDistrictInCity:(NSString*)city inProvince:(NSString*)province;
+(NSArray*)getAllAreas;
+(NSMutableArray*)getStoresInProvince:(NSString*)province andCity:(NSString*)city andDistrict:(NSString*)district andLo:(double)lo andLa:(double)la haveMall:(NSString*)mall numRecords:(int)nrows onlyCollected:(BOOL)collected options:(NSArray*)options;
+(NSMutableArray*)getActivitiesInProvince:(NSString*)province andCity:(NSString*)city andDistrict:(NSString*)district andLo:(double)lo andLa:(double)la numRecords:(int)nrows onlyCollected:(BOOL)collected options:(NSArray*)options;

@end

@interface store : NSObject

+(NSString*)getMallTitle:(NSString*)mall;
+(NSString*)getStoreIDForMajor:(int)major andMinor:(int)minor;
+(BOOL)storeChanged:(int)major andMinor:(int)minor;
+(BOOL)setCurrentStoreMajor:(int)major andMinor:(int)minor;
+(BOOL)setCurrentStore:(NSString*)tempStoreID;
+(void)setForceReloadStore:(BOOL)force;
+(void)forceReloadStore;
//+(void)reloadCurrentStore;
+(void)callService:(int)type;
+(BOOL)supportAiyidian;
+(BOOL)needNoTableNum;
+(BOOL)inStore;
+(BOOL)whiteLabel;
+(int)payOption;
+(BOOL)creditCanPay;
+(float)creditToCentRatio;

+(void)set_preorder_mode:(BOOL)p_mode;
+(BOOL)preorder_mode;
+(int)preorder_option_allowed;
+(int)preorder_minutes_after_now;

+(NSMutableArray*)getMenuOfStore:(NSString*)sid;
+(NSMutableArray*)getCatagorisOfMenu:(NSMutableArray*)m;

+(NSMutableArray*)getMenuSortedByCatagoriesAndNameOfMenu:(NSMutableArray*)m;
+(NSMutableArray*)getMenuSortedByCatagoriesAndPopularityOfMenu:(NSMutableArray*)m;
+(NSMutableArray*)getMenuSortedByCatagoriesAndDefaultOfMenu:(NSMutableArray*)m;

+(NSMutableArray*)getMenubyCatagory:(NSString*)filterCatagory ofMenu:(NSMutableArray*)m;
+(NSMutableArray*)getMenubyCatagorySortedByName:(NSString*)filterCatagory ofMenu:(NSMutableArray*)m;
+(NSMutableArray*)getMenubyCatagorySortedByPopularity:(NSString*)filterCatagory ofMenu:(NSMutableArray*)m;

+(int)getIndexForFoodID:(int)theFoodID inMenu:(NSMutableArray*)m;

//store
+(NSString*)getCurrentStoreID;
+(NSString*)getCurrentStoreName;
+(NSString*)getCurrentStoreFolder;
//+(NSString*)getCurrentStoreWelcomeMessage;
+(NSString*)getStoreNotificationByMajor:(int)major andMinor:(int)minor;
+(void)setTableNum:(int)num;
+(int)getTableNum;

//main page, in array of items
+(NSArray*)getCurrentStoreMainPage;

//menu
+(NSMutableArray*)getMenu; //array of foodInfo
+(NSMutableArray*)getCatagories;

+(NSMutableArray*)getMenuSortedByCatagoriesAndName;
+(NSMutableArray*)getMenuSortedByCatagoriesAndPopularity;
+(NSMutableArray*)getMenuSortedByCatagoriesAndDefault;

+(NSMutableArray*)getMenubyCatagory:(NSString*)filterCatagory;
+(NSMutableArray*)getMenubyCatagorySortedByName:(NSString*)filterCatagory;
+(NSMutableArray*)getMenubyCatagorySortedByPopularity:(NSString*)filterCatagory;

+(int)getFoodIDForFoodName:(NSString*)name;
+(NSString*)getFoodNameForFoodID:(int)ID;
+(int)getIndexForFoodID:(int)theFoodID;

//order
+(NSString*)submitOrder;
+(NSString*)submitPreorder:(int)type withNumPeople:(int)numPeople atDate:(NSString*)date andTime:(NSString*)time;

+(void)openStoreWifi;
+(BOOL)needStoreWifi;

+(NSMutableArray*)getCafeWall;
+(BOOL)getCafeWallCoffee:(NSInteger)pid;
+(NSInteger)submitCafeWallOrder:(NSInteger)foodID withMessage:(NSString*)msg lowerAge:(NSInteger)lower upperAge:(NSInteger)upper gender:(int)gender;

@end


@interface foodInfo : NSObject {
    float price;
    int ID;
}

@property(atomic, strong) NSString *title;
@property(atomic, strong) NSString *catagory;
@property(atomic, strong) NSString *image;
@property(atomic, strong) NSString *mainDescription;
@property(atomic, strong) NSString *note;
@property(atomic, strong) NSString *addition;
@property(atomic, strong) UIImage *loadedImage;
@property(atomic) NSInteger scoreToEarn;
@property(atomic) float originalPrice;

-(foodInfo*)initWithName:(NSString *)name andPrice:(float)p image:(NSString *)image catagory:(NSString *)cata desp:(NSString *)desp1 desp2:(NSString *)desp2 desp3:(NSString *)desp3 withId:(int)newID;
-(float)getPrice;
-(int)getID;
-(void)setID:(int)newID;

@end


@interface orderInfo : NSObject {
    int ID;
    int orderCount;
}

+(NSMutableArray*)getOrder;
+(void)checkOrder;
+(void)saveOrder;
+(int)getCountForFood:(int)foodID;
+(int)addFood:(int)foodID withCount:(int)count;
+(int)removeFood:(int)foodID withCount:(int)count;
+(float)getTotalValue;
+(int)getTotalCredit;
+(float)getPayTotalOnline;

-(int)getID;
-(void)setID:(int)newID;
-(int)getCount;
-(void)setCount:(int)newCount;

-(orderInfo*)initWithID:(int)foodID andCount:(int)count;

+(NSString*)statusStringForPayed:(int)payFlag andOrderFlag:(int)orderFlag andFetchFlag:(int)fetchFlag;

@end
