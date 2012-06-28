//
//  VKDialogContainer.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 28.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKMessage.h"

@interface VKDialogContainer : NSObject 
{
    NSMutableDictionary* _sectionsDict;
    NSMutableArray* _sectionsKeys;
    NSDateFormatter* _dateFormatter;
}
@property(nonatomic,readonly) NSInteger count;
@property(nonatomic,assign) NSInteger offset;
@property(nonatomic,assign) SEL onLoadMoreButtonSelector;
@property(nonatomic,assign) id onLoadMoreButtonTarget;

+ (CGFloat)sectionHeaderHeight;
+ (CGFloat)loadMoreSectionHeight;

- (id)initWithMessagesArray:(NSArray*)messages count:(NSInteger)count;

- (void)addMessage:(VKMessage*)message;
- (void)addMessages:(NSArray*)messages;

- (NSInteger)sectionsCount;
- (NSInteger)messagesCountForSection:(NSInteger)section;

- (UIView*)headerViewForSection:(NSInteger)section;

- (VKMessage*)messageForIndexPath:(NSIndexPath*)idxPath;
- (VKMessage*)messageWithId:(NSNumber*)mid;

- (NSIndexPath*)indexPathForMessage:(VKMessage*)msg;

@end