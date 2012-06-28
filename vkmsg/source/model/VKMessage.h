//
//  VKMessage.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 22.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "VKObject.h"

@interface VKMessage : VKObject

@property(nonatomic,retain) NSNumber* mid;
@property(nonatomic,retain) NSNumber* uid;
@property(nonatomic,retain) NSString* date;
@property(nonatomic,retain) NSNumber* read_state;
@property(nonatomic,retain) NSNumber* out;
@property(nonatomic,retain) NSString* title;
@property(nonatomic,retain) NSString* body;
@property(nonatomic,retain) NSString* fwd_messages;
@property(nonatomic,retain) NSString* chat_id;
@property(nonatomic,retain) NSString* chat_active;
@property(nonatomic,retain) NSString* users_count;
@property(nonatomic,retain) NSString* admin_id;
@property(nonatomic,retain) NSNumber* from_id;

@property(nonatomic,retain) NSArray* attachments;
@property(nonatomic,retain) NSDictionary* attachment;

@property(nonatomic,retain) NSDictionary* geo;

+ (id)messageWithDictionary:(NSDictionary*)dict;

- (BOOL)isOut;

- (BOOL)hasLocation;
- (CLLocationCoordinate2D)coordinate;

@end
