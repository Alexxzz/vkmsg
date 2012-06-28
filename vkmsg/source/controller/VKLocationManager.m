//
//  VKLocationManager.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 24.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKLocationManager.h"

@implementation VKLocationManager 

@synthesize lastLocation = _lastLocation;

#pragma mark - Singeltone stuff
static VKLocationManager* instance = nil;
+ (void)initialize
{
    [super initialize];
    
    if (instance == nil)
        instance = [VKLocationManager new];
}

- (id)retain
{
    return instance;
}
- (void)dealloc
{
    _locationManager.delegate = nil;
    [_locationManager release], _locationManager = nil;
    
    [_lastLocation release];
    
    [super dealloc];
}
- (id)autorelease
{
    return instance;
}
- (oneway void)release
{ }
- (id)copy
{
    return instance;
}

+ (VKLocationManager*)instance
{
    return instance;
}

#pragma mark - Init/Dealloc
- (id)init
{
    self = [super init];
    if (self != nil)
    {
        
    }
    
    return self;
}

#pragma mark - Instance methods
- (void)getLocationSuccess:(void(^)(CLLocation* location))success
                   failure:(void(^)(NSError* error))failure
{
    _success = [success copy];
    _failure = [failure copy];
    
    if (_locationManager == nil)
    {
        _locationManager = [CLLocationManager new];
        _locationManager.delegate = self;
    }
    
    [_locationManager startUpdatingLocation];
}


#pragma mark - CLLocationDelegate methods
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // make sure the old and new coordinates are different
    if ((oldLocation.coordinate.latitude != newLocation.coordinate.latitude) &&
        (oldLocation.coordinate.longitude != newLocation.coordinate.longitude) && 
        newLocation.horizontalAccuracy < 1000.f)//check accuracy
    {
        NSTimeInterval locTi = -[newLocation.timestamp timeIntervalSinceNow];
        if (locTi < 60 * 60 * 24)//check date
        {
            [_lastLocation release];
            _lastLocation = [newLocation retain];
            
            if (_success != nil)
            {
                _success(_lastLocation);                
                [_success release], _success = nil;
            }
            
            [_locationManager stopUpdatingLocation];
        }
    }    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (_failure != nil)
    {
        _failure(error);
        [_failure release], _failure = nil;
        
        [_locationManager stopUpdatingLocation];
    }
}

#pragma mark - Google maps helper
+ (NSURL*)getURLForGoogleMapsWithLocation:(CLLocationCoordinate2D)coord withSize:(CGSize)size
{
    CGFloat scale = 1.f;
    NSString* pinSize = @"small";
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        scale = [[UIScreen mainScreen] scale];        
        size = CGSizeMake(size.width * scale, size.height * scale);
        if (scale > 1.f)
            pinSize = @"medium";
    }
    
    NSInteger width = [[NSNumber numberWithFloat:size.width] intValue];
    NSInteger height = [[NSNumber numberWithFloat:size.height] intValue];
    
    NSString* urlFormat = @"http://maps.google.com/maps/api/staticmap?center=%f,%f&zoom=13&size=%ix%i&markers=color:blue%%7Csize:%@%%7C%f,%f&sensor=true";
    NSString* urlStr = [NSString stringWithFormat:urlFormat, coord.latitude, coord.longitude, width, height, pinSize, coord.latitude, coord.longitude];
    
    return [NSURL URLWithString:urlStr];
}

@end
