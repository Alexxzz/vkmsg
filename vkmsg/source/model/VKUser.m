//
//  VKUser.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKUser.h"

@implementation VKUser

@synthesize uid, first_name, last_name, photo, photo_rec, online, mobile_phone, home_phone, phone;

+ (id)userWithId:(NSString*)Id
{
    VKUser* res = [VKUser new];
    if (res)
    {
        res.uid = [NSNumber numberWithInt:[Id integerValue]];
    }
    
    return [res autorelease];
}

+ (id)userWithDictionary:(NSDictionary*)dict
{    
    return [super objectWithDictionary:dict];
}

- (void)dealloc
{
    self.uid = nil; 
    self.first_name = nil; 
    self.last_name = nil; 
    self.photo = nil; 
    self.online = nil;
    self.photo_rec = nil;
    self.mobile_phone = nil;
    self.home_phone = nil;
    self.phone = nil;
    
    [super dealloc];
}

@end
