//
//  VKPhotoAttachment.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 17.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKPhotoAttachment.h"

@implementation VKPhotoAttachment

@synthesize id, pid, aid, owner_id, src, src_big, src_small, created, height, width, src_xbig, text, src_xxbig, access_key;

+ (id)photoAttachmentWithDictionary:(NSDictionary*)dict
{
    return [super objectWithDictionary:dict];
}

- (void)dealloc
{
    self.id = nil; 
    self.pid = nil; 
    self.aid = nil; 
    self.owner_id = nil; 
    self.src = nil;
    self.src_big = nil; 
    self.src_small = nil;
    self.created = nil;
    self.height = nil;
    self.width = nil;
    self.src_xbig = nil;
    self.src_xxbig = nil;
    self.text = nil;
    self.access_key = nil;
    
    [super dealloc];
}

@end
