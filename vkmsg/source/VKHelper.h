//
//  VKHelper.h
//  vk
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define AppDel ((AppDelegate*)[[UIApplication sharedApplication] delegate])
#define Storage [VKStorage storage]

#define kInitialMsgCount 20
#define kInitialDlgCount 20
#define kInitialRequestsCount 20
#define kInitialFriendsCount 100

#import <UIKit/UIKit.h>
#import "VKStorage.h"

typedef enum 
{
    eVKStorages_user = 0,
    eVKStorages_friends,
    eVKStorages_fav
} eVKStorages;

@interface VKHelper : NSObject

+ (NSString*)documentsDirectory;
+ (NSString*)pathForStorage:(NSUInteger)storageId;

+ (void)showErrorMessage:(NSString*)msg;

+ (NSString*)formatedElapsedTimeFromDate:(NSDate*)date detailed:(BOOL)detailed;
+ (NSString*)hhmmFromDate:(NSDate*)date;

+ (NSString*)decodeFromPercentEscapeString:(NSString*)string;

+ (void)addGradient:(UIButton*)button;

+ (NSString*)deviceModel;
+ (NSString*)systemVersion;

@end
