//
//  VKLongPollServerController.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 30.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"


/*
 +1 	UNREAD 	сообщение не прочитано
 +2 	OUTBOX 	исходящее сообщение
 +4 	REPLIED 	на сообщение был создан ответ
 +8 	IMPORTANT 	помеченное сообщение
 +16 	CHAT 	сообщение отправлено через чат
 +32 	FRIENDS 	сообщение отправлено другом
 +64 	SPAM 	сообщение помечено как "Спам"
 +128 	DELЕTЕD 	сообщение удалено (в корзине)
 +256 	FIXED 	сообщение проверено пользователем на спам
 +512 	MEDIA 	сообщение содержит медиаконтент 
 */
typedef enum
{
    eVKFlag_UNREAD      = 1,
    eVKFlag_OUTBOX      = 1 << 1,
    eVKFlag_REPLIED     = 1 << 2,
    eVKFlag_IMPORTANT   = 1 << 3,
    eVKFlag_CHAT        = 1 << 4,
    eVKFlag_FRIENDS     = 1 << 5,
    eVKFlag_SPAM        = 1 << 6,
    eVKFlag_DELETED     = 1 << 7,
    eVKFlag_FIXED       = 1 << 8,
    eVKFlag_MEDIA       = 1 << 9,
    
} eVKFlag;


#pragma mark - VKLongPollUpdate interface
typedef enum 
{
    eVKLongPollUpdateType_msgDeleted = 0,
    eVKLongPollUpdateType_msgReadStateChanged,
    eVKLongPollUpdateType_msgNew,
    
    eVKLongPollUpdateType_userOnline,
    eVKLongPollUpdateType_userOffline,
    
    eVKLongPollUpdateType_multichatChanged,
    
    eVKLongPollUpdateType_chatTyping,
    eVKLongPollUpdateType_multichatTyping,
    
} eVKLongPollUpdateType;

@interface VKLongPollUpdate : NSObject 

@property(nonatomic,assign) eVKLongPollUpdateType type;
@property(nonatomic,retain) NSNumber* msgId;
@property(nonatomic,retain) NSNumber* userId;
@property(nonatomic,retain) NSNumber* chatId;

@end

#pragma mark - VKLongPollServerController interface
@interface VKLongPollServerController : NSObject

+ (VKLongPollServerController*)instance;

- (void)configWithParamsDictionary:(NSDictionary*)params;
- (void)connect;
- (void)configAndConnectWithDictionary:(NSDictionary *)params;

@end
