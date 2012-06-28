//
//  VKMapVC.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 31.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface VKMapVC : UIViewController<MKMapViewDelegate>
{
    IBOutlet MKMapView* _mapView;
}
@property(nonatomic,assign) CLLocationCoordinate2D attachmentCoordinate;

@end
