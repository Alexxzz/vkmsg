//
//  VKLocationManager.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 24.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKObject.h"
#import <CoreLocation/CoreLocation.h>

@interface VKLocationManager : VKObject<CLLocationManagerDelegate>
{
    CLLocationManager* _locationManager;
    CLLocation* _lastLocation;
    
    void(^_success)(CLLocation*);
    void(^_failure)(NSError* error);
}
@property(nonatomic,readonly) CLLocation* lastLocation;

+ (VKLocationManager*)instance;

+ (NSURL*)getURLForGoogleMapsWithLocation:(CLLocationCoordinate2D)coord withSize:(CGSize)size;

- (void)getLocationSuccess:(void(^)(CLLocation* location))success
                   failure:(void(^)(NSError* error))failure;

@end
