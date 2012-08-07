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
//App/user info
@property(nonatomic, retain) NSString* appToken;
@property(nonatomic, retain) VKUser* user;
@property(nonatomic, retain) NSString* pushToken;
//Friends
@property(nonatomic, retain) NSArray* friends;
@property(nonatomic, assign) NSInteger friendsCount;
@property(nonatomic, assign) NSInteger friendsTotalCount;
//Dialogs
@property(nonatomic, retain) NSArray* dialogList;
@property(nonatomic, assign) NSInteger dialogsCount;
@property(nonatomic, assign) NSInteger dialogsTotalCount;
@property(nonatomic, retain) NSMutableDictionary* dialogs;
//Favs
@property(nonatomic, retain) NSMutableArray* favourites;
//Requests
@property(nonatomic, retain) NSMutableArray* requests;
@property(nonatomic, assign) NSInteger requestsCount;

+ (VKStorage*)storage;

- (void)store;

- (VKUser*)userWithId:(NSNumber*)uid;
- (VKMessage*)messageWithId:(NSNumber*)mid;

- (void)addToFavsUid:(NSNumber*)uid;
- (void)removeFromFav:(NSNumber*)uid;
- (BOOL)isFavouriteUid:(NSNumber*)uid;
- (void)storeFavs;

@end
