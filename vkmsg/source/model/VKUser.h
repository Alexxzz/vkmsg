//
//  VKUser.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKObject.h"

@interface VKUser : VKObject

@property(nonatomic, retain) NSNumber* uid;
@property(nonatomic, retain) NSString* first_name;
@property(nonatomic, retain) NSString* last_name;
@property(nonatomic, retain) NSString* photo;
@property(nonatomic, retain) NSString* photo_rec;
@property(nonatomic, retain) NSNumber* online;
@property(nonatomic, retain) NSString* mobile_phone;
@property(nonatomic, retain) NSString* home_phone;
@property(nonatomic, retain) NSNumber* phone;

+ (id)userWithId:(NSString*)Id;
+ (id)userWithDictionary:(NSDictionary*)dict;

@end
