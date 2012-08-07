//
//  VKHelper.m
//  vk
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKHelper.h"
#import <QuartzCore/QuartzCore.h>
#import <sys/utsname.h>

@implementation VKHelper

#pragma mark - Paths
+ (NSString*)fileNameForStorage:(NSUInteger)storageId
{
    switch (storageId) 
    {            
        case eVKStorages_user:
            return @"user.dat";
            
        case eVKStorages_friends:
            return @"friends.dat";
            
        case eVKStorages_fav:
            return @"favourites.dat";
            
        default:
            return nil;
    }
}

+ (NSString*)documentsDirectory
{
    NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [dirs lastObject];
}

+ (NSString*)pathForStorage:(NSUInteger)storageId
{
    NSString* docDir = [self documentsDirectory];
    NSString* fileName = [self fileNameForStorage:storageId];
    
    return [docDir stringByAppendingPathComponent:fileName];
}

#pragma mark - Messages
+ (void)showErrorMessage:(NSString*)msg
{
    if (msg == nil || [msg length] == 0)
        return;
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:kStrAppTitle 
                                                    message:msg 
                                                   delegate:nil 
                                          cancelButtonTitle:kStrClose 
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#pragma mark - date
+ (BOOL)isTodayWithDate:(NSDate*)date
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:[NSDate date]];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}

+ (BOOL)isYesterdayWithDate:(NSDate*)date
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:[NSDate date]];
    
    return [comp1 day] == ([comp2 day] - 1) &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}

+ (NSString*)formatedElapsedTimeFromDate:(NSDate*)date detailed:(BOOL)detailed
{
    NSDateFormatter* format = [NSDateFormatter new];    
    NSTimeInterval tiDate = - [date timeIntervalSinceNow];
    
    BOOL isToday = [self isTodayWithDate:date];
    NSInteger hrs = (NSInteger)(tiDate / 3600);
    NSInteger mins = (NSInteger)((tiDate - hrs * 3600) / 60);
    if (hrs < 0) hrs = 0;
    if (mins < 0) mins = 0;
    
    NSString* res = nil;
    if (isToday)
    {
        if (hrs <= 0 && mins < 2)
        {
            res = kStrJustNow;
        }
        else
        {
            format.dateFormat = @"HH:mm";
            NSString* hhmm = [format stringFromDate:date];
            if (detailed == YES)
                res = [NSString stringWithFormat:@"%@ %@ %@", kStrToday, kStrAt, hhmm];
            else
                res = hhmm;
        }
    }
    else
    {
        if ([self isYesterdayWithDate:date])
        {
            res = kStrYesterday;
        }
        else
        {
            if (detailed == YES)
                format.dateFormat = @"d MMMM";
            else
                format.dateFormat = @"d MMM";
            
            res = [format stringFromDate:date];
        }
    }
    
    [format release];
    
    return res;
}

+ (NSString*)hhmmFromDate:(NSDate*)date
{
    NSString* res = nil;
    NSDateFormatter* format = [NSDateFormatter new];
    format.dateFormat = @"HH:mm";
    
    res = [format stringFromDate:date];
    
    [format release];
    
    return res;
}

// Decode a percent escape encoded string.
+ (NSString*)decodeFromPercentEscapeString:(NSString*)string 
{
    return [(NSString *)
    CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                            (CFStringRef) string,
                                                            CFSTR(""),
                                                            kCFStringEncodingUTF8) autorelease];
}

#pragma mark - 
+ (void)addGradient:(UIButton*)button 
{
    // Add Border
    CALayer *layer = button.layer;
    layer.cornerRadius = 8.0f;
    layer.masksToBounds = YES;
    layer.borderWidth = 1.0f;
    layer.borderColor = [UIColor colorWithWhite:0.5f alpha:0.2f].CGColor;
    
    // Add Shine
    CAGradientLayer *shineLayer = [CAGradientLayer layer];
    shineLayer.frame = layer.bounds;
    shineLayer.colors = [NSArray arrayWithObjects:
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         nil];
    shineLayer.locations = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.0f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.8f],
                            [NSNumber numberWithFloat:1.0f],
                            nil];
    [layer addSublayer:shineLayer];
}

#pragma mark - Device info
+ (NSString*)deviceModel
{
    struct utsname systemInfo;
    uname(&systemInfo);
	
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}
+ (NSString*)systemVersion
{
    NSString* res = nil;
    
    NSString* sysName = [[UIDevice currentDevice] systemName];
    NSString* sysVer = [[UIDevice currentDevice] systemVersion];
    
    res = [NSString stringWithFormat:@"%@ %@", sysName, sysVer];
    
    return res;
}

@end
