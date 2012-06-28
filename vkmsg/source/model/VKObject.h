//
//  VKObject.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VKObject : NSObject<NSCoding>

+ (id)objectWithDictionary:(NSDictionary*)dict;

@end
