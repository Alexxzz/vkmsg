//
//  VKDialogContainer.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 28.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKDialogContainer.h"

#define kLoadMoreSectionKey @"0loadMoreSectionKey"
#define kHeaderSectionHeight 26.f
#define kLoadMoreSectionHeight 30.f
#define kDateFormatStr @"d MMMM"

@implementation VKDialogContainer

@synthesize count = _count;
@synthesize onLoadMoreButtonTarget, onLoadMoreButtonSelector;
@synthesize offset;

+ (CGFloat)sectionHeaderHeight
{
    return kHeaderSectionHeight;
}

+ (CGFloat)loadMoreSectionHeight
{
    return kLoadMoreSectionHeight;
}

- (NSString*)dateStrFromDate:(NSDate*)date
{
    NSString* res = [_dateFormatter stringFromDate:date];
    
    return res;
}

- (void)preInit
{
    _dateFormatter = [NSDateFormatter new];
    _dateFormatter.dateFormat = kDateFormatStr;
    
    _sectionsDict = [NSMutableDictionary new];
    _sectionsKeys = [NSMutableArray new];
}


- (id)init
{
    self = [super init];
    if (self != nil)
    {
        [self preInit];
    }
    
    return self;
}

- (id)initWithMessagesArray:(NSArray*)messages count:(NSInteger)count
{
    self = [super init];
    if (self != nil)
    {
        [self preInit];
        
        _count = count;
        
        [self addMessages:messages];
    }
    
    return self;
}

- (void)dealloc
{
    [_sectionsDict release];
    [_sectionsKeys release];
    [_dateFormatter release];
    
    [super dealloc];
}

- (void)addLoadMoreSection
{
    if (_sectionsKeys != nil && [[_sectionsKeys objectAtIndex:0] isEqualToString:kLoadMoreSectionKey] == NO)
        [_sectionsKeys insertObject:kLoadMoreSectionKey 
                            atIndex:0];
}

- (void)removeLoadMoreSection
{
    if ([_sectionsKeys count] > 1 && [[_sectionsKeys objectAtIndex:0] isEqualToString:kLoadMoreSectionKey] == YES)
        [_sectionsKeys removeObjectAtIndex:0];
}

- (void)addMessage:(VKMessage*)message
{
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[message.date integerValue]];
    NSString* key = [self dateStrFromDate:date];
    
    NSMutableArray* messages = [_sectionsDict valueForKey:key];
    if (messages == nil)
    {
        messages = [[NSMutableArray new] autorelease];
        [_sectionsDict setValue:messages forKey:key];
        
        [_sectionsKeys addObject:key];
    }
    
    [messages addObject:message]; 
}

- (void)addMessages:(NSArray*)messages
{
    for (VKMessage* msg in messages)
    {
        if ([msg isKindOfClass:[VKMessage class]])
            [self addMessage:msg];
    }
    
    if (self.offset >= self.count)
        [self removeLoadMoreSection];
    else if (_count > kInitialMsgCount)
        [self addLoadMoreSection];
    
    //Sort sections by date
    [_sectionsKeys sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate* date1 = [_dateFormatter dateFromString:obj1];
        NSDate* date2 = [_dateFormatter dateFromString:obj2];
        
        return [date1 compare:date2];
    }];
    
    //Sort messages by date
    for (NSMutableArray* arra in [_sectionsDict objectEnumerator])
    {
        [arra sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            VKMessage* msg1 = obj1;
            VKMessage* msg2 = obj2;
            
            return [msg1.date compare:msg2.date];
        }];
    }
}

- (NSIndexPath*)indexPathForMessage:(VKMessage*)msg;
{
    NSIndexPath* res = nil;
    
    if (msg != nil)
    {
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:[msg.date integerValue]];
        NSString* key = [self dateStrFromDate:date];
        NSMutableArray* messages = [_sectionsDict valueForKey:key];
        NSInteger row = [messages indexOfObject:msg];
        NSInteger section = [_sectionsKeys indexOfObject:key];
        
        if (row != NSNotFound && section != NSNotFound)
            res = [NSIndexPath indexPathForRow:row inSection:section];
    }
    
    return res;
}

- (NSInteger)sectionsCount
{
    return [_sectionsKeys count];
}

- (NSInteger)messagesCountForSection:(NSInteger)section
{
    if (section >= [_sectionsKeys count] || section < 0)
        return 0;
    
    NSString* key = [_sectionsKeys objectAtIndex:section];
    NSArray* messages = [_sectionsDict valueForKey:key];
    
    return [messages count];
}

- (void)onLoadMoreButton
{
    if (onLoadMoreButtonSelector != nil && onLoadMoreButtonTarget != nil && [onLoadMoreButtonTarget respondsToSelector:onLoadMoreButtonSelector])
        [onLoadMoreButtonTarget performSelector:onLoadMoreButtonSelector];
}

- (UIView*)headerViewForSection:(NSInteger)section
{
    if (section > [_sectionsKeys count] || section < 0)
        return nil;
    
    NSString* key = [_sectionsKeys objectAtIndex:section];
    if ([key isEqualToString:kLoadMoreSectionKey])
    {
        UIView* headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kLoadMoreSectionHeight)] autorelease];
        headerView.autoresizingMask = UIViewAutoresizingNone;
        headerView.backgroundColor = [UIColor clearColor];
        
        UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button setTitle:kStrLoadMore 
                forState:UIControlStateNormal];
        [button sizeToFit];
        [button addTarget:self 
                   action:@selector(onLoadMoreButton) 
         forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchDown];
        
        CGRect frame = button.frame;
        frame.size.width = 300;
        frame.origin.x = 10.f;
        frame.origin.y = 5.f;
        button.frame = frame;
        
        [headerView addSubview:button];
        
        return headerView;
    }
    else
    {
        UIView* headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderSectionHeight)] autorelease];
        headerView.backgroundColor = [UIColor clearColor];
        UILabel* titleLabel = [[UILabel new] autorelease];
        
        titleLabel.textAlignment = UITextAlignmentCenter;    
        titleLabel.font = [UIFont boldSystemFontOfSize:13.f];
        titleLabel.textColor = [UIColor colorWithRed:166.f/255.f 
                                               green:175.f/255.f 
                                                blue:188.f/255.f 
                                               alpha:1.f];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.shadowColor = [UIColor whiteColor];
        titleLabel.shadowOffset = CGSizeMake(0, 1);
        
        titleLabel.text = key;
        [titleLabel sizeToFit];
        titleLabel.center = headerView.center;
        
        [headerView addSubview:titleLabel];
        
        return headerView;
    }
    
    return nil;
}

- (VKMessage*)messageForIndexPath:(NSIndexPath*)idxPath
{
    VKMessage* res = nil;
    
    NSInteger section = idxPath.section;
    NSInteger row = idxPath.row;
    
    if (section < [_sectionsKeys count] && section >= 0)
    {
        NSString* key = [_sectionsKeys objectAtIndex:section];
        NSArray* messages = [_sectionsDict valueForKey:key];
        
        if (row < [messages count] && row >= 0)
            res = [messages objectAtIndex:row];
    }
    
    return res;
}

- (VKMessage*)messageWithId:(NSNumber*)mid
{
    VKMessage* res = nil;
    
    for (NSArray* arra in [_sectionsDict objectEnumerator])
    {
        for  (VKMessage* msg in arra)
        {
            if ([msg.mid isEqualToNumber:mid])
            {
                res = msg;
                break;
            } 
        }
    }
    
    return res;
}

@end
