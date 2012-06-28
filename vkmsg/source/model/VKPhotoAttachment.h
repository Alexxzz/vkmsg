//
//  VKPhotoAttachment.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 17.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKObject.h"

@interface VKPhotoAttachment : VKObject

@property(nonatomic,retain) NSString* aid;
@property(nonatomic,retain) NSNumber* height;
@property(nonatomic,retain) NSNumber* width;
@property(nonatomic,retain) NSString* id;
@property(nonatomic,retain) NSNumber* pid;
@property(nonatomic,retain) NSNumber* owner_id;
@property(nonatomic,retain) NSString* src;
@property(nonatomic,retain) NSString* src_big;
@property(nonatomic,retain) NSString* src_small;
@property(nonatomic,retain) NSString* src_xbig;
@property(nonatomic,retain) NSString* src_xxbig;
@property(nonatomic,retain) NSString* text;
@property(nonatomic,retain) NSString* created;
@property(nonatomic,retain) NSString* access_key;

+ (id)photoAttachmentWithDictionary:(NSDictionary*)dict;

@end
