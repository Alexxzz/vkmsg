//
//  VKMessage.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 22.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKMessage.h"
#import "VKHelper.h"

@implementation VKMessage

@synthesize mid, uid, date, read_state, out, title, body, fwd_messages, chat_id, chat_active, users_count, admin_id, from_id, attachments, attachment, geo;

+ (id)messageWithDictionary:(NSDictionary*)dict
{
    VKMessage* res = [VKMessage new];
    if (res)
    {
        for (NSString* key in [dict keyEnumerator])
        {
            id val = [dict valueForKey:key];
            @try {
                [res setValue:val forKey:key];
            }
            @catch (NSException *exception) {
                NSLog(@"exception: %@", exception);
                continue;
            }                
        }
    }
    
    return [res autorelease];
}

- (void)dealloc
{
    self.mid = nil; 
    self.uid = nil; 
    self.date = nil; 
    self.read_state = nil; 
    self.out = nil;
    self.title = nil; 
    self.body = nil;
    self.fwd_messages = nil; 
    self.chat_id = nil; 
    self.chat_active = nil; 
    self.users_count = nil; 
    self.admin_id = nil;
    self.from_id = nil;
    self.attachments = nil;
    self.attachment = nil;
    self.geo = nil;
    
    [super dealloc];
}

- (BOOL)isOut
{
    if (from_id != nil)
        return [from_id isEqualToNumber:Storage.user.uid];
    
    return [self.out boolValue];
}

- (void)setBody:(NSString *)body_
{
    if ([body_ isEqualToString:body] == NO)
    {
        [body autorelease];
        
        body_ = [body_ stringByReplacingOccurrencesOfString:@"&#33;" withString:@"!"];
        body = [[body_ stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"] retain];
    }
}

- (BOOL)hasLocation
{
    return (self.geo != nil);
}
- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D res = kCLLocationCoordinate2DInvalid;
    if ([self hasLocation] == YES)
    {
        NSString* locationStr = [self.geo valueForKey:@"coordinates"];
        NSArray* latLonArray = [locationStr componentsSeparatedByString:@" "];
        if ([latLonArray count] == 2)
        {
            CGFloat lat = [[latLonArray objectAtIndex:0] floatValue];
            CGFloat lon = [[latLonArray objectAtIndex:1] floatValue];
            res = CLLocationCoordinate2DMake(lat, lon);
        }
    }
    return res;
}

@end
