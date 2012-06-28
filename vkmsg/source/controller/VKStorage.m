//
//  VKStorage.m
//  vk
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKStorage.h"
#import "VKDialogContainer.h"

#define kAppTokenKey @"appToken"

@interface VKStorage()
- (void)restore;
@end

@implementation VKStorage

@synthesize user, friends, dialogList, dialogs, favourites;

#pragma mark - singeltone methods
static VKStorage* storageInstance = nil;

+ (void)initialize
{
    [super initialize];
    
    if (storageInstance == nil)
        storageInstance = [VKStorage new];
}

+ (VKStorage*)storage
{
    return storageInstance;
}

- (id)retain
{ 
    return storageInstance;
}
- (id)autorelease
{
    return storageInstance;
}
- (oneway void)release
{
    
}

- (id)copy
{
    return storageInstance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self restore];
    }
    return self;
}
- (void)dealloc
{
    self.appToken = nil;
    self.friends = nil;
    self.dialogList = nil;
    self.dialogs = nil;
    self.favourites = nil;
    
    [super dealloc];
}

#pragma mark - instance methods
- (void)setAppToken:(NSString *)appToken
{
    if ([appToken isEqualToString:_appToken] == NO)
    {
        [_appToken release];
        _appToken = [appToken retain];
        
        [[NSUserDefaults standardUserDefaults] setValue:_appToken forKey:kAppTokenKey];
    }
}

- (NSString*)appToken
{
    return _appToken;
}

#pragma mark - getting data
- (VKUser*)userWithId:(NSNumber*)uid
{
    for (VKUser* user_ in friends)
    {
        if ([uid isEqualToNumber:user_.uid] == YES)
            return user_;
    }
    
    return nil;
}

- (VKMessage*)messageWithId:(NSNumber*)mid
{
    VKMessage* res = nil;
    
    for (VKDialogContainer* dialog in [dialogs objectEnumerator])
    {
        res = [dialog messageWithId:mid];
        if (res != nil)
            break;
    }
    
    return res;
}

#pragma mark - Favourites
- (void)storeFavs
{
    @synchronized(self.favourites)
    {
        NSString* filePathFav = [VKHelper pathForStorage:eVKStorages_fav];
        BOOL succsess = [NSKeyedArchiver archiveRootObject:favourites 
                                                    toFile:filePathFav];
        
        if (succsess == NO)
            NSLog(@"favourites succsess == NO");
    }
}

- (void)addToFavsUid:(NSNumber*)uid
{
    if ([self isFavouriteUid:uid] == NO)
    {
        if (self.favourites == nil)
            self.favourites = [NSMutableArray array];
        
        [self.favourites addObject:uid];
        [self storeFavs];
    }
}

- (void)removeFromFav:(NSNumber*)uid
{
    if ([self isFavouriteUid:uid] == YES)
    {
        [self.favourites removeObject:uid];
        [self storeFavs];
    }
}

- (BOOL)isFavouriteUid:(NSNumber*)uid
{
    return [self.favourites containsObject:uid];
}

#pragma mark - storing\restoring
- (void)store
{
    //User
    NSString* filePath = [VKHelper pathForStorage:eVKStorages_user];
    BOOL succsess = [NSKeyedArchiver archiveRootObject:user 
                                                toFile:filePath];
    if (succsess == NO)
        NSLog(@"user succsess == NO");
    
    //Favourites

}

- (void)restore
{
    //User
    NSString* filePath = [VKHelper pathForStorage:eVKStorages_user];
    self.user = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    
    //Token
    _appToken = [[NSUserDefaults standardUserDefaults] valueForKey:kAppTokenKey];
    
    //Favourites
    NSString* filePathFav = [VKHelper pathForStorage:eVKStorages_fav];
    self.favourites = [NSKeyedUnarchiver unarchiveObjectWithFile:filePathFav];
}

@end
