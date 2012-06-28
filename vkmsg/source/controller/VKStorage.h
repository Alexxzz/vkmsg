//
//  VKStorage.h
//  vk
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKUser.h"
#import "VKMessage.h"

@interface VKStorage : NSObject
{
    NSString* _appToken;
}

@property(nonatomic, retain) NSString* appToken;
@property(nonatomic, retain) VKUser* user;
@property(nonatomic, retain) NSArray* friends;
@property(nonatomic, retain) NSArray* dialogList;
@property(nonatomic, retain) NSMutableDictionary* dialogs;
@property(nonatomic, retain) NSMutableArray* favourites;

+ (VKStorage*)storage;

- (void)store;

- (VKUser*)userWithId:(NSNumber*)uid;
- (VKMessage*)messageWithId:(NSNumber*)mid;

- (void)addToFavsUid:(NSNumber*)uid;
- (void)removeFromFav:(NSNumber*)uid;
- (BOOL)isFavouriteUid:(NSNumber*)uid;
- (void)storeFavs;

@end
