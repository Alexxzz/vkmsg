//
//  VKApi.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "VKPhotoAttachment.h"

typedef enum
{
    eVKFriendsOrder_name = 0,
    eVKFriendsOrder_hints,
    
} eVKFriendsOrder;

@interface VKApi : NSObject
{
    
}

//Logging in
+ (void)logInWithLogin:(NSString*)login 
          withPassword:(NSString*)password 
               success:(void(^)())success 
               failure:(void(^)(NSError* error, NSString* errorDesc))failure;

+ (void)setOnlineSuccess:(void(^)())success
                 failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

//Notifications
+ (void)registerDeviceWithPushToken:(NSString*)token
                        deviceModel:(NSString*)model
                      systemVersion:(NSString*)sysVer
                             noText:(BOOL)noText
                            success:(void(^)())success
                            failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

//Getting friends
+ (void)getFriendsListCount:(NSUInteger)count 
                     offset:(NSUInteger)offset
                      order:(eVKFriendsOrder)order
                    success:(void(^)(NSArray* friends))success 
                    failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)getLastActivityForUserId:(NSNumber*)Id
                         success:(void(^)(BOOL online, NSDate* lastActivity))success 
                         failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)getFriendsWithIds:(NSArray*)ids
                  success:(void(^)(NSArray* friends))success
                  failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)importContacts:(NSArray*)contacts
               success:(void(^)())success
               failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)getSuggestionContactsSuccess:(void(^)())success
                             failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)getFriendsByPhones:(NSArray*)phones
                   Success:(void(^)(NSArray* friends))success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

//Add/delete friends, get requests
+ (void)addFriendWithId:(NSNumber*)Id
               withText:(NSString*)text
                success:(void(^)())success
                failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)deleteFriendWithId:(NSNumber*)Id
                   success:(void(^)())success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)getFriendsRequestsWithOffset:(NSUInteger)offset
                               count:(NSUInteger)count
                        loadMessages:(BOOL)loadMsgs
                loadOutgoingRequests:(BOOL)outgoing
                             success:(void(^)(NSArray* respons))success
                             failure:(void(^)(NSError* error, NSDictionary* errDict))failure;
                            
//Messages
+ (void)getDialogsListCount:(NSUInteger)count
                     offset:(NSUInteger)offset
                    success:(void(^)(NSArray* messages ,NSInteger count))success 
                    failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)getMessagesHistoryForId:(NSNumber*)Id
                          count:(NSUInteger)count
                         offset:(NSUInteger)offset
                        success:(void(^)(NSArray* messages, NSInteger count))success 
                        failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)sendDialogMessageToUser:(NSNumber*)uid 
                        message:(NSString*)msg
                     attachment:(VKPhotoAttachment*)attachment
                            lat:(CGFloat)lat
                            lon:(CGFloat)lon
                        success:(void(^)(NSString* msgId))success
                        failure:(void(^)(NSError* error, NSDictionary* errDict))failure;
+ (void)sendDialogMessageToUser:(NSNumber*)uid 
                        message:(NSString*)msg
                     attachment:(VKPhotoAttachment*)attachment
                            lat:(CGFloat)lat
                            lon:(CGFloat)lon
                      capchaKey:(NSString*)key
                      capchaSid:(NSString*)sid
                        success:(void(^)(NSString* msgId))success
                        failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)sendTypingActivityForDialogWithUserId:(NSNumber*)uid
                                      success:(void(^)())success
                                      failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)markAsReadMessages:(NSArray*)mids
                   success:(void(^)())success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

+ (void)getMessageWithId:(NSNumber*)mid
                 success:(void(^)(VKMessage *msg))success
                 failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

//Photo attachment
+ (void)getMessagesUploadServerSuccess:(void(^)(NSString* url))success
                               failure:(void(^)(NSError* error, NSDictionary* errDict))failure;
+ (void)saveMessagesPhotoFromServer:(NSString*)server
                              photo:(NSString*)photo
                               hash:(NSString*)hash
                            success:(void(^)(VKPhotoAttachment* attachment))success
                            failure:(void(^)(NSError* error, NSDictionary* errDict))failure;
+ (void)uploadImage:(UIImage*)image
            success:(void(^)(VKPhotoAttachment *attachment))success
            failure:(void(^)(NSError* error, NSDictionary* errDict))failure;
+ (void)getAttachmentsForMessage:(VKMessage*)msg
                         success:(void(^)())success
                         failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

//Video
+ (void)getVideoUrlWithVid:(NSNumber*)vid
                   forUser:(NSNumber*)uid
                   success:(void(^)(NSDictionary* urls))success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

//Long poll server
+ (void)getLongPollServerParamsSuccess:(void(^)(NSDictionary* params))success
                               failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

//Test
+ (void)testCaptchaSuccess:(void(^)(NSDictionary* params))success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure;

@end
 