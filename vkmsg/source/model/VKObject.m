//
//  VKObject.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKObject.h"
#import <objc/runtime.h>

@implementation VKObject

/* NSCoder functions taken from: 
 * http://davedelong.com/blog/2009/04/13/aspect-oriented-programming-objective-c
 */
- (id) initWithCoder:(NSCoder *)decoder 
{
	if ([super respondsToSelector:@selector(initWithCoder:)] && ![self isKindOfClass:[super class]]) 
		self = [super performSelector:@selector(initWithCoder:) withObject:decoder];
	else
		self = [super init];
    
	if (self == nil) 
    { 
        return nil; 
    }
    
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
	unsigned int numIvars = 0;
	Ivar * ivars = class_copyIvarList([self class], &numIvars);
	for(int i = 0; i < numIvars; i++) 
    {
		Ivar thisIvar = ivars[i];
		NSString * key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];
        
		id value = [decoder decodeObjectForKey:key];        
		if (value == nil) 
            value = [NSNumber numberWithFloat:0.0];
        
		[self setValue:value forKey:key];
	}
    
	if (numIvars > 0)
        free(ivars);
    
	[pool drain];
    
	return self;
}
- (void) encodeWithCoder:(NSCoder *)encoder 
{
	if ([super respondsToSelector:@selector(encodeWithCoder:)] && ![self isKindOfClass:[super class]]) {
		[super performSelector:@selector(encodeWithCoder:) withObject:encoder];
	}
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	unsigned int numIvars = 0;
	Ivar * ivars = class_copyIvarList([self class], &numIvars);
	for (int i = 0; i < numIvars; i++) {
		Ivar thisIvar = ivars[i];
		NSString * key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];
		id value = [self valueForKey:key];
		[encoder encodeObject:value forKey:key];
	}
	if (numIvars > 0) { free(ivars); }
	[pool drain];
}

+ (id)objectWithDictionary:(NSDictionary*)dict
{
    Class class = [self class]; 
    id res = class_createInstance(class, 0);
    
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

@end
