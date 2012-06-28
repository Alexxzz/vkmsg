//
//  VKLongPollServerController.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 30.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKLongPollServerController.h"
#import "VKMessage.h"
#import "VKApi.h"
#import "VKDialogContainer.h"

#define kKeyKey @"key"
#define kServerKey @"server"
#define kTsKey @"ts"
#define kWaitTimeOutStr @"25"

@interface VKLongPollServerController()

@property(nonatomic,retain) NSString* key;
@property(nonatomic,retain) NSString* server;
@property(nonatomic,retain) NSString* ts;

@end

@implementation VKLongPollServerController

@synthesize key, server, ts;

#pragma mark - singeltone methods
static VKLongPollServerController* instance = nil;
+ (void)initialize
{
    [super initialize];
    
    if (instance == nil)
        instance = [VKLongPollServerController new];
}

+ (VKLongPollServerController*)instance
{
    return instance;
}

- (id)retain
{ 
    return instance;
}
- (id)autorelease
{
    return instance;
}
- (oneway void)release
{
}

- (id)copy
{
    return instance;
}

#pragma mark - init
- (void)configWithParamsDictionary:(NSDictionary*)params
{
    self.key = [params valueForKey:kKeyKey];
    self.server = [params valueForKey:kServerKey];
    self.ts = [params valueForKey:kTsKey];
}

- (void)getAttachmentForMessage:(VKMessage*)msg
{
    [VKApi getAttachmentsForMessage:msg 
                            success:^{                                
                                NSDictionary* infoDict = [NSDictionary dictionaryWithObject:msg forKey:@"message"];
                                [[NSNotificationCenter defaultCenter] postNotificationName:kVKNotificationMessageAttachmentsReady 
                                                                                    object:nil 
                                                                                  userInfo:infoDict];
                            } failure:^(NSError *error, NSDictionary *errDict) {
                                
                            }];
}

/*
 0,$message_id,0 -- удаление сообщения с указанным local_id
 1,$message_id,$flags -- замена флагов сообщения (FLAGS:=$flags)
 2,$message_id,$mask[,$user_id] -- установка флагов сообщения (FLAGS|=$mask)
 3,$message_id,$mask[,$user_id] -- сброс флагов сообщения (FLAGS&=~$mask)
 4,$message_id,$flags,$from_id,$timestamp,$subject,$text,$attachments -- добавление нового сообщения
 8,-$user_id,0 -- друг $user_id стал онлайн
 9,-$user_id,$flags -- друг $user_id стал оффлайн ($flags равен 0, если пользователь покинул сайт (например, нажал выход) и 1, если оффлайн по таймауту (например, статус away))
 51,$chat_id,$self -- один из параметров (состав, тема) беседы $chat_id были изменены. $self - были ли изменения вызываны самим пользователем
 61,$user_id,$flags -- пользователь $user_id начал набирать текст в диалоге. событие должно приходить раз в ~5 секунд при постоянном наборе текста. $flags = 1
 62,$user_id,$chat_id -- пользователь $user_id начал набирать текст в беседе $chat_id.
 */
- (VKLongPollUpdate*)newMessage:(NSArray*)update
{
    VKLongPollUpdate* res = [VKLongPollUpdate new];
    
    //4,$message_id,$flags,$from_id,$timestamp,$subject,$text,$attachments 
    NSNumber* messageId = [update objectAtIndex:1];
    NSNumber* flagsNum = [update objectAtIndex:2];
    NSNumber* from_id = [update objectAtIndex:3];
    NSNumber* timestamp = [update objectAtIndex:4];
    NSString* subject = [update objectAtIndex:5];
    NSString* text = [update objectAtIndex:6];
    
    NSInteger flags = [flagsNum intValue];
    
    //Create message
    VKMessage* newMsg = [VKMessage new];
    newMsg.uid = from_id;
    newMsg.mid = messageId;
    newMsg.title = subject;
    newMsg.date = [timestamp stringValue];
    newMsg.body = text;
    BOOL unread = (flags & eVKFlag_UNREAD);
    newMsg.read_state = [NSNumber numberWithBool:!unread];
    BOOL out_ = (flags & eVKFlag_OUTBOX);
    newMsg.out = [NSNumber numberWithBool:out_];
    
    //Add message to storage
    VKDialogContainer* messages = [Storage.dialogs objectForKey:from_id];
    if (messages == nil)
    {
        messages = [[VKDialogContainer new] autorelease];
        [Storage.dialogs setObject:messages forKey:from_id];
    }
    [messages addMessage:newMsg];
    
    //Get attachment
    if ([update count] > 7 && [[update objectAtIndex:7] count] > 0)
        [self getAttachmentForMessage:newMsg];
    
    //Update dialogs list
    VKMessage* dlgMessage = nil;
    for (VKMessage* msg in Storage.dialogList)
    {
        if ([msg.uid isEqualToNumber:from_id])
        {
            dlgMessage = msg;
            break;
        }
    }  
    NSMutableArray* mutDialogsList = [Storage.dialogList mutableCopy];
    if (dlgMessage != nil)
        [mutDialogsList removeObject:dlgMessage];
    [mutDialogsList insertObject:newMsg atIndex:0];
    Storage.dialogList = [[mutDialogsList copy] autorelease];
    [mutDialogsList release];
    
    //Config update
    res.userId = from_id;
    res.msgId = messageId;
    res.type = eVKLongPollUpdateType_msgNew;

    [newMsg release];
    
    return res;
}

// 61,$user_id,$flags -- пользователь $user_id начал набирать текст в диалоге. событие должно приходить раз в ~5 секунд при постоянном наборе текста. $flags = 1
- (VKLongPollUpdate*)typingInDialog:(NSArray*)update
{
    VKLongPollUpdate* res = [VKLongPollUpdate new];
    
    NSNumber* userId = [update objectAtIndex:1];    
    res.userId = userId;
    res.type = eVKLongPollUpdateType_chatTyping;
    
    return [res autorelease];
}

/*
 1,$message_id,$flags -- замена флагов сообщения (FLAGS:=$flags)
 2,$message_id,$mask[,$user_id] -- установка флагов сообщения (FLAGS|=$mask)
 3,$message_id,$mask[,$user_id] -- сброс флагов сообщения (FLAGS&=~$mask)
 */
- (VKLongPollUpdate*)changeFlagsForUpdate:(NSArray*)update
{
    VKLongPollUpdate* res = [VKLongPollUpdate new];
    
    NSNumber* actionType = [update objectAtIndex:0];
    NSNumber* messageId = [update objectAtIndex:1];
    NSNumber* maskFlag = [update objectAtIndex:2];
    
    NSNumber* userId = nil;
    if ([update count] == 4)
        userId = [update objectAtIndex:3];
    
    NSInteger maskFlagInt = [maskFlag integerValue];
    NSInteger actionTypeInt = [actionType intValue];
    
    VKMessage* msg = [Storage messageWithId:messageId];
    if (msg != nil)
    {
        if (maskFlagInt & eVKFlag_UNREAD)
        {
            res.type = eVKLongPollUpdateType_msgReadStateChanged;
            
            switch (actionTypeInt) 
            {
                case 1:
                    msg.read_state = maskFlag;
                    break;
                    
                case 2:
                    msg.read_state = [NSNumber numberWithBool:NO];
                    break;
                    
                case 3:
                    msg.read_state = [NSNumber numberWithBool:YES];
                    break;
            }
        }
    }
    
    res.msgId = messageId;
    res.userId = userId;
    
    return [res autorelease];
}

// 8,-$user_id,0 -- друг $user_id стал онлайн
- (VKLongPollUpdate*)friendCameOnline:(NSArray*)update
{
    VKLongPollUpdate* res = [VKLongPollUpdate new];
    
    NSNumber* userId = [update objectAtIndex:1];
    NSInteger uidInt = -[userId intValue];
    userId = [NSNumber numberWithInt:uidInt];
    VKUser* usr = [Storage userWithId:userId];
    if (usr != nil)
        usr.online = [NSNumber numberWithBool:YES];
    
    res.type = eVKLongPollUpdateType_userOnline;
    res.userId = userId;
    
    return [res autorelease];
}

//9,-$user_id,$flags -- друг $user_id стал оффлайн ($flags равен 0, если пользователь покинул сайт (например, нажал выход) и 1, если оффлайн по таймауту (например, статус away))
- (VKLongPollUpdate*)friendCameOffline:(NSArray*)update
{
    VKLongPollUpdate* res = [VKLongPollUpdate new];
    
    NSNumber* userId = [update objectAtIndex:1];
    NSInteger uidInt = -[userId intValue];
    userId = [NSNumber numberWithInt:uidInt];
    VKUser* usr = [Storage userWithId:userId];
    if (usr != nil)
        usr.online = [NSNumber numberWithBool:NO];
    
    res.type = eVKLongPollUpdateType_userOffline;
    res.userId = userId;
    
    return [res autorelease];
}

- (VKLongPollUpdate*)parseUpdate:(NSArray*)update
{
    VKLongPollUpdate* res = nil;
    
    NSNumber* msgType = [update objectAtIndex:0];
    NSLog(@"msgType: %d", [msgType intValue]);
    
    switch ([msgType intValue]) 
    {
        case 0:
            break;
            
        case 1:
        case 2:
        case 3:
            res = [self changeFlagsForUpdate:update];
            break;
            
        case 4:
            res = [[self newMessage:update] autorelease];            
            break;
            
        case 8:
            res = [self friendCameOnline:update];
            break;
            
        case 9:
            res = [self friendCameOffline:update];
            break;
            
        case 51:
            break;
            
        case 61:
            res = [self typingInDialog:update];            
            break;
            
        case 62:
            break;
            
        default:
            break;
    }
    
    return res;
}

- (void)parseUpdates:(NSArray*)updates
{
    if (updates == nil || [updates count] == 0)
    {
        NSLog(@"no updates");
        return;
    }
    
    NSMutableArray* longPollUpdates = [NSMutableArray arrayWithCapacity:[updates count]];
    for (NSArray* update in updates) 
    {
        NSLog(@"parsing update: %@", update);
        VKLongPollUpdate* longPollUpdate = [self parseUpdate:update];
        if (longPollUpdate != nil)
            [longPollUpdates addObject:longPollUpdate];
    }
    
    NSDictionary* userInfoDict = [NSDictionary dictionaryWithObject:longPollUpdates 
                                                             forKey:kVKLongPollUpdatesKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kVKNotificationLongPollUpdates 
                                                        object:nil 
                                                      userInfo:userInfoDict];
}

- (void)connect
{     
    NSURL* url = [NSURL URLWithString:[@"http://" stringByAppendingString:self.server]];
    AFHTTPClient* httpClient = [AFHTTPClient clientWithBaseURL:url];
    NSMutableURLRequest* req = [httpClient requestWithMethod:@"GET" 
                                                        path:@""
                                                  parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              @"a_check", @"act",
                                                              self.key, kKeyKey,
                                                              self.ts, kTsKey,
                                                              kWaitTimeOutStr, @"wait",
                                                              @"2", @"mode",
                                                              nil]];
    [req setTimeoutInterval:[kWaitTimeOutStr doubleValue]+10];
    
    NSLog(@"URL: %@", req.URL);
    
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:req 
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                         NSLog(@"JSON: %@", JSON);
                                                         
                                                         NSString* failed = [JSON valueForKey:@"failed"];
                                                         if (failed != nil)//Error
                                                         {
                                                             [VKApi getLongPollServerParamsSuccess:^(NSDictionary *params) {
                                                                 [[VKLongPollServerController instance] configAndConnectWithDictionary:params];
                                                             } failure:^(NSError *error, NSDictionary* errDict) {
                                                                 
                                                             }];                                                             
                                                         }
                                                         else//Ok
                                                         {
                                                             self.ts = [JSON valueForKey:kTsKey];
                                                             
                                                             NSArray* updates = [JSON valueForKey:@"updates"];
                                                             [self parseUpdates:updates];
                                                             
                                                             dispatch_async(dispatch_get_main_queue(), ^{                                                             
                                                                 [self connect]; 
                                                             }); 
                                                         }
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                         NSLog(@"error: %@\r\nJSON:%@", error, JSON);
                                                         dispatch_async(dispatch_get_main_queue(), ^{                                                             
                                                             [self connect]; 
                                                         }); 
                                                     }] start];
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
}

- (void)configAndConnectWithDictionary:(NSDictionary *)params
{
    [self configWithParamsDictionary:params];
    [self connect];
}

@end

#pragma mark - VKLongPollUpdate class
@implementation VKLongPollUpdate
@synthesize type, msgId, userId, chatId;

- (void)dealloc
{
    self.msgId = nil;
    self.chatId = nil;
    self.userId = nil;
    
    [super dealloc];
}

@end
