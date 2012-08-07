//
//  VKApi.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKApi.h"
#import "VKHelper.h"
#import "VKStorage.h"
#import "VKMessage.h"
#import "JSONKit.h"

#define kApiUrl @"https://api.vk.com/method/"

#define kDirectLoginUrl @"https://api.vk.com/"
#define kAppId @"2855155"
#define kAppSecret @"5448ab16da2dd786edf"
#define kAttachmentUploadPath @"upload.php"

@implementation VKApi

#pragma mark - Utils
+ (NSString*)strArrayFromArrayOfNumsOrStr:(NSArray*)array
{  
    NSMutableString* res = [[NSMutableString new] autorelease];
    NSString* strVal = nil;
    for (id val in array)
    {
        if ([val isKindOfClass:[NSNumber class]] == YES)
            strVal = [val stringValue];
        else if ([val isKindOfClass:[NSString class]] == YES)
            strVal = val;
        
        if ([res length] == 0)
            [res appendString:strVal];
        else
            [res appendFormat:@",%@", strVal];
    }
    
    return [[res copy] autorelease];
}

#pragma mark - Logging in
+ (void)logInWithLogin:(NSString*)login 
          withPassword:(NSString*)password 
               success:(void(^)())success 
               failure:(void(^)(NSError* error, NSString* errorDesc))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kDirectLoginUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"oauth/token" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              @"password", @"grant_type",
                                                              kAppId, @"client_id",
                                                              kAppSecret, @"client_secret",                                                        
                                                              login, @"username",
                                                              password, @"password",
                                                              @"friends, messages, photos, video", @"scope",
                                                              nil]];
    NSLog(@"logInWithLogin: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                        NSLog(@"JSON: %@", JSON);
                                                        
                                                        NSString* token = [JSON valueForKey:@"access_token"];
                                                        NSString* userId = [JSON valueForKey:@"user_id"];
                                                        
                                                        Storage.appToken = token; 
                                                        Storage.user = [VKUser userWithId:userId];
                                                        [Storage store];
                                                        
                                                        if (success != nil)
                                                            success();
                                                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                        NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                        
                                                        NSString* errorMsg = [JSON valueForKey:@"error_description"];
                                                        
                                                        if (failure != nil)
                                                            failure(error, errorMsg);
                                                    }] start];
}

+ (void)setOnlineSuccess:(void(^)())success
                 failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"account.setOnline" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              Storage.user.uid, @"uid",
                                                              nil]];
    NSLog(@"setOnline: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success();
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

#pragma mark - Notifications
+ (void)registerDeviceWithPushToken:(NSString*)token
                        deviceModel:(NSString*)model
                      systemVersion:(NSString*)sysVer
                             noText:(BOOL)noText
                            success:(void(^)())success
                            failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"account.registerDevice" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              Storage.user.uid, @"uid",
                                                              token, @"token",
                                                              nil]];
    NSLog(@"registerDevice: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success();
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

#pragma mark - Friends list
+ (void)getFriendsListCount:(NSUInteger)count 
                     offset:(NSUInteger)offset
                      order:(eVKFriendsOrder)order
                    success:(void(^)(NSArray* friends))success 
                    failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSString* countStr = [[NSNumber numberWithUnsignedInteger:count] stringValue];
    NSString* offsetStr = [[NSNumber numberWithUnsignedInteger:offset] stringValue];
    
    NSString* orderStr = nil;
    if (order == eVKFriendsOrder_name)
        orderStr = @"name";
    else
        orderStr = @"hints";
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"friends.get" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              Storage.user.uid, @"uid",
                                                              countStr, @"count",
                                                              offsetStr, @"offset",
                                                              orderStr, @"order",
                                                              @"first_name, last_name, online, photo_rec", @"fields",
                                                              nil]];
    NSLog(@"getFriendsList: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {
                                                             NSMutableArray* friends = [NSMutableArray arrayWithCapacity:[JSON count]];
                                                             for (NSDictionary* userDict in resp)
                                                             {
                                                                 VKUser* friend = [VKUser userWithDictionary:userDict];
                                                                 [friends addObject:friend];
                                                             }
                                                             
                                                             if (success != nil)
                                                                 success([[friends copy] autorelease]);                                                             
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)getLastActivityForUserId:(NSNumber*)uid
                         success:(void(^)(BOOL online, NSDate* lastActivity))success 
                         failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"messages.getLastActivity" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:                                                              
                                                              Storage.appToken, @"access_token",
                                                              uid, @"uid",
                                                              nil]];
    NSLog(@"getLastActivity: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {           
                                                             NSNumber* onlineNum = [resp valueForKey:@"online"];
                                                             BOOL online = [onlineNum boolValue];
                                                             
                                                             NSNumber* lastActivityNum = [resp valueForKey:@"time"];
                                                             NSDate* lastActivity = [NSDate dateWithTimeIntervalSince1970:[lastActivityNum intValue]];
                                                             
                                                             if (success != nil)
                                                                 success(online, lastActivity);
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)getFriendsWithIds:(NSArray*)uids
                  success:(void(^)(NSArray* friends))success 
                  failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSString* uidsStr = [self strArrayFromArrayOfNumsOrStr:uids];
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"users.get" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:                                                              
                                                              Storage.appToken, @"access_token",
                                                              uidsStr, @"uids",
                                                              @"first_name, last_name, online, photo_rec, contacts", @"fields",
                                                              nil]];
    NSLog(@"users.get: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {
                                                             NSMutableArray* friends = [NSMutableArray arrayWithCapacity:[JSON count]];
                                                             for (NSDictionary* userDict in resp)
                                                             {
                                                                 VKUser* friend = [VKUser userWithDictionary:userDict];
                                                                 [friends addObject:friend];
                                                             }
                                                             
                                                             if (success != nil)
                                                                 success([[friends copy] autorelease]);                                                             
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)importContacts:(NSArray*)contacts
               success:(void(^)())success
               failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSString* contactsStr = [self strArrayFromArrayOfNumsOrStr:contacts];
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"account.importContacts" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:                                                              
                                                              Storage.appToken, @"access_token",
                                                              contactsStr, @"contacts",
                                                              nil]];
    NSLog(@"account.importContacts: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success();                                                             
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)getSuggestionContactsSuccess:(void(^)())success
                             failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"friends.getSuggestions" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:                                                              
                                                              Storage.appToken, @"access_token",
                                                              @"contacts", @"filter",
                                                              nil]];
    NSLog(@"friends.getSuggestions: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success();                                                             
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)getFriendsByPhones:(NSArray*)phones
                   Success:(void(^)(NSArray* friends))success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSString* phonesStr = [self strArrayFromArrayOfNumsOrStr:phones];
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"friends.getByPhones" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:                                                              
                                                              Storage.appToken, @"access_token",
                                                              Storage.user.uid, @"uid",
                                                              phonesStr, @"phones",
                                                              nil]];
    NSLog(@"friends.getByPhones: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             NSMutableArray* friends = [NSMutableArray arrayWithCapacity:[JSON count]];
                                                             for (NSDictionary* userDict in resp)
                                                             {
                                                                 VKUser* friend = [VKUser userWithDictionary:userDict];
                                                                 [friends addObject:friend];
                                                             }
                                                             
                                                             if (success != nil)
                                                                 success([[friends copy] autorelease]);                                                              
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

#pragma mark - Add/delete friends, get requests
+ (void)addFriendWithId:(NSNumber*)uid
               withText:(NSString*)text
                success:(void(^)())success
                failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"friends.add" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:                                                              
                                                              Storage.appToken, @"access_token",
                                                              uid, @"uid",
                                                              (text != nil ? text : @""), @"text",
                                                              nil]];
    NSLog(@"friends.add: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success();
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)deleteFriendWithId:(NSNumber*)uid
                   success:(void(^)())success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"friends.delete" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:                                                              
                                                              Storage.appToken, @"access_token",
                                                              uid, @"uid",
                                                              nil]];
    NSLog(@"friends.delete: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success();
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)getFriendsRequestsWithOffset:(NSUInteger)offset
                               count:(NSUInteger)count
                        loadMessages:(BOOL)loadMsgs
                loadOutgoingRequests:(BOOL)outgoing
                             success:(void(^)(NSArray* respons))success
                             failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSString* offsetStr = [[NSNumber numberWithInt:offset] stringValue];
    NSString* countStr = [[NSNumber numberWithInt:count] stringValue];
    NSString* loadMsgsStr = [[NSNumber numberWithBool:loadMsgs] stringValue];
    NSString* outOstr = [[NSNumber numberWithBool:outgoing] stringValue];
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"friends.getRequests" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:                                                              
                                                              Storage.appToken, @"access_token",
                                                              offsetStr, @"offset",
                                                              countStr, @"count",
                                                              loadMsgsStr, @"need_messages",
                                                              outOstr, @"out",
                                                              nil]];
    NSLog(@"friends.getRequests: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success(resp);
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

#pragma mark - Messages
+ (void)getDialogsListCount:(NSUInteger)count
                     offset:(NSUInteger)offset
                    success:(void(^)(NSArray* messages ,NSInteger count))success 
                    failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSString* countStr = [[NSNumber numberWithUnsignedInteger:count] stringValue];
    NSString* offsetStr = [[NSNumber numberWithUnsignedInteger:offset] stringValue];
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"messages.getDialogs" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              countStr, @"count",
                                                              offsetStr, @"offset",
                                                              nil]];
    NSLog(@"getDialogsList: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {
                                                             NSInteger count = 0;
                                                             NSMutableArray* messages = [NSMutableArray arrayWithCapacity:[JSON count]];
                                                             for (id messageDict in resp)
                                                             {
                                                                 if ([messageDict isKindOfClass:[NSNumber class]])
                                                                 {
                                                                     count = [messageDict intValue];
                                                                 }
                                                                 
                                                                 if ([messageDict isKindOfClass:[NSDictionary class]])
                                                                 {                                                                 
                                                                     VKMessage* message = [VKMessage messageWithDictionary:messageDict];
                                                                     [messages addObject:message];
                                                                 }
                                                             }
                                                             
                                                             if (success != nil && failure != nil)
                                                                 success([[messages copy] autorelease], count);
                                                         }                                                         
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)getMessagesHistoryForId:(NSNumber*)Id
                          count:(NSUInteger)count
                         offset:(NSUInteger)offset
                        success:(void(^)(NSArray* messages, NSInteger count))success 
                        failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSString* countStr = [[NSNumber numberWithUnsignedInteger:count] stringValue];
    NSString* offsetStr = [[NSNumber numberWithUnsignedInteger:offset] stringValue];
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"messages.getHistory" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              Id, @"uid",
                                                              countStr, @"count",
                                                              offsetStr, @"offset",
                                                              nil]];
    NSLog(@"getHistory: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {
                                                             NSInteger count = 0;
                                                             NSMutableArray* messages = [NSMutableArray arrayWithCapacity:[JSON count]];
                                                             for (NSDictionary* messageDict in resp)
                                                             {
                                                                 if ([messageDict isKindOfClass:[NSNumber class]])
                                                                     count = [(NSNumber*)messageDict intValue];
                                                                 
                                                                 if ([messageDict isKindOfClass:[NSDictionary class]])
                                                                 {                                                                 
                                                                     VKMessage* message = [VKMessage messageWithDictionary:messageDict];
                                                                     [messages addObject:message];
                                                                 }
                                                             }
                                                             
                                                             if (success != nil)
                                                                 success([[messages reverseObjectEnumerator] allObjects], count);   
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                         
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)sendDialogMessageToUser:(NSNumber*)uid 
                        message:(NSString*)msg
                     attachment:(VKPhotoAttachment*)attachment
                            lat:(CGFloat)lat
                            lon:(CGFloat)lon
                        success:(void(^)(NSString* msgId))success
                        failure:(void(^)(NSError* error, NSDictionary* errDict))failure;
{
    [self sendDialogMessageToUser:uid 
                          message:msg 
                       attachment:attachment
                              lat:lat
                              lon:lon
                        capchaKey:nil 
                        capchaSid:nil 
                          success:success 
                          failure:failure];
}
+ (void)sendDialogMessageToUser:(NSNumber*)uid 
                        message:(NSString*)msg
                     attachment:(VKPhotoAttachment*)attachment
                            lat:(CGFloat)lat
                            lon:(CGFloat)lon
                      capchaKey:(NSString*)key
                      capchaSid:(NSString*)sid
                        success:(void(^)(NSString* msgId))success
                        failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 Storage.appToken, @"access_token",
                                 uid, @"uid",
                                 @"1", @"type",
                                 nil];
    if (key != nil && sid != nil)
    {
        [dict setValue:key forKey:@"key"];
        [dict setValue:sid forKey:@"sid"];
    }
    
    if (msg != nil && [msg length] > 0)
        [dict setValue:msg forKey:@"message"];
    
    if (attachment != nil && attachment.id != nil)
        [dict setValue:attachment.id forKey:@"attachment"];
    
    if (lat != 0.f && lon != 0.f)
    {
        [dict setValue:[NSNumber numberWithFloat:lat] forKey:@"lat"];
        [dict setValue:[NSNumber numberWithFloat:lon] forKey:@"long"];
    }
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"messages.send" 
                                                  parameters:dict];
    NSLog(@"sendDialogMessageToUser: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSString* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success(resp);
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)testCaptchaSuccess:(void(^)(NSDictionary* params))success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"captcha.force" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              nil]];
    NSLog(@"getLongPollServerParamsSuccess: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success(resp);
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)sendTypingActivityForDialogWithUserId:(NSNumber*)uid
                                      success:(void(^)())success
                                      failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"messages.setActivity" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              uid, @"uid",
                                                              @"typing", @"type",
                                                              nil]];
    NSLog(@"setActivity: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success();
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)markAsReadMessages:(NSArray*)mids
                   success:(void(^)())success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSString* midsStr = [self strArrayFromArrayOfNumsOrStr:mids];
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"messages.markAsRead" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              Storage.user.uid, @"uid",
                                                              midsStr, @"mids",
                                                              nil]];
    NSLog(@"markAsRead: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success();
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)getMessageWithId:(NSNumber*)mid
                 success:(void(^)(VKMessage *msg))success
                 failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"messages.getById" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              Storage.user.uid, @"uid",
                                                              mid, @"mid",
                                                              nil]];
    NSLog(@"getById: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {
                                                             NSDictionary* msgDict = [resp lastObject];
                                                             VKMessage* message = [VKMessage messageWithDictionary:msgDict];
                                                             
                                                             if (success != nil)
                                                                 success(message); 
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                         
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

#pragma mark - Photo attachment
+ (void)getMessagesUploadServerSuccess:(void(^)(NSString* url))success
                               failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"photos.getMessagesUploadServer" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              nil]];
    NSLog(@"getMessagesUploadServer: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {      
                                                             NSString* url = [resp valueForKey:@"upload_url"];
                                                             if (success != nil)
                                                                 success(url);
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)saveMessagesPhotoFromServer:(NSString*)server
                              photo:(NSString*)photo
                               hash:(NSString*)hash
                            success:(void(^)(VKPhotoAttachment* attachment))success
                            failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"photos.saveMessagesPhoto" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              server, @"server",
                                                              photo, @"photo",
                                                              hash, @"hash",
                                                              nil]];
    NSLog(@"saveMessagesPhoto: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {      
                                                             VKPhotoAttachment* att = [VKPhotoAttachment photoAttachmentWithDictionary:[resp lastObject]];
                                                             if (success != nil)
                                                                 success(att);
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

+ (void)uploadImage:(UIImage*)image
            success:(void(^)(VKPhotoAttachment* att))success
            failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    [self getMessagesUploadServerSuccess:^(NSString *url) {
        NSArray* components = [url componentsSeparatedByString:kAttachmentUploadPath];
        if ([components count] != 2)
        {
            if (failure != nil)
                failure(nil, nil);
        }
        NSString* baseUrlStr = [components objectAtIndex:0];
        
        NSArray* paramsArray = [[components objectAtIndex:1] componentsSeparatedByString:@"&"];
        NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:[paramsArray count]];
        for (NSString* paramPair in paramsArray)
        {
            NSArray* keyVal = [paramPair componentsSeparatedByString:@"="];
            if ([keyVal count] != 2)
                continue;
            
            NSString* key = [keyVal objectAtIndex:0];
            NSString* value = [keyVal objectAtIndex:1];
            
            if ([key hasPrefix:@"?"])
                key = [key stringByReplacingOccurrencesOfString:@"?" withString:@""];
            
            [params setValue:value forKey:key];
        }
        
        NSURL* baseUrl = [NSURL URLWithString:baseUrlStr];
        AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:baseUrl] autorelease];
        NSData *imageData = UIImagePNGRepresentation(image);
        NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" 
                                                                             path:kAttachmentUploadPath 
                                                                       parameters:params 
                                                        constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
                                                            [formData appendPartWithFileData:imageData
                                                                                        name:@"photo" 
                                                                                    fileName:@"photo.png" 
                                                                                    mimeType:@"image/png"];
                                                        }];
        
        AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSData* data = responseObject;
            NSDictionary* dict = [data objectFromJSONData];
            
            [self saveMessagesPhotoFromServer:[dict valueForKey:@"server"] 
                                        photo:[dict valueForKey:@"photo"]  
                                         hash:[dict valueForKey:@"hash"]  
                                      success:^(VKPhotoAttachment *attachment) {                                          
                                          if (success != nil)
                                              success(attachment);
                                      } failure:^(NSError *error, NSDictionary *errDict) {
                                          if (failure != nil)
                                              failure(error, errDict);
                                      }];
        } 
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             if (failure != nil)
                                                 failure(error, nil);
                                         }];
        [operation start];
    } failure:^(NSError *error, NSDictionary *errDict) {
        if (failure != nil)
            failure(error, errDict);
    }];
}
+ (void)getAttachmentsForMessage:(VKMessage*)msg
                         success:(void(^)())success
                         failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    [self getMessageWithId:msg.mid 
                   success:^(VKMessage *msg_) {                       
                       if (msg_ != nil)
                       {
                           msg.attachment = msg_.attachment;
                           msg.attachments = msg_.attachments;
                           msg.geo = msg_.geo;
                           if (success != nil)
                               success();
                       }
                       else
                       {
                           if (failure != nil)
                               failure(nil, nil);
                       }
    } failure:^(NSError *error, NSDictionary *errDict) {
        if (failure != nil)
            failure(error, errDict);
    }];
}

#pragma mark - Video
+ (void)getVideoUrlWithVid:(NSNumber*)vid
                   forUser:(NSNumber*)uid
                   success:(void(^)(NSDictionary* urls))success
                   failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    NSString* videos = [NSString stringWithFormat:@"%@_%@", [uid stringValue], [vid stringValue]];
    
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"video.get" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              videos, @"videos",
                                                              nil]];
    NSLog(@"video.get: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSArray* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {      
                                                             NSDictionary* video = [resp lastObject];
                                                             if ([video isKindOfClass:[NSDictionary class]] == NO)
                                                             {
                                                                 failure(nil, nil);
                                                             }
                                                             else 
                                                             {
                                                                 NSDictionary* res = [video valueForKey:@"files"];
                                                                 if (success != nil)
                                                                     success(res);
                                                             }                                                             
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

#pragma mark - Long poll
+ (void)getLongPollServerParamsSuccess:(void(^)(NSDictionary* params))success
                               failure:(void(^)(NSError* error, NSDictionary* errDict))failure
{
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kApiUrl]];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@"messages.getLongPollServer" 
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              Storage.appToken, @"access_token",
                                                              Storage.user.uid, @"uid",
                                                              nil]];
    NSLog(@"getLongPollServerParamsSuccess: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSDictionary* resp = [JSON valueForKey:@"response"];
                                                         if (resp != nil)
                                                         {                                                             
                                                             if (success != nil)
                                                                 success(resp);
                                                         }
                                                         else
                                                         {
                                                             NSDictionary* error = [JSON valueForKey:@"error"];
                                                             if (error != nil && failure != nil)
                                                                 failure(nil, error);
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         
                                                         if (failure != nil)
                                                             failure(error, JSON);
                                                     }] start];
}

@end
