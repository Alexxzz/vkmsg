//
//  VKMapVC.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 31.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKMapVC.h"

@implementation VKMapVC

@synthesize attachmentCoordinate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.attachmentCoordinate = kCLLocationCoordinate2DInvalid;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
         return nil;
         
    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        MKPinAnnotationView* pinView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation 
                                                                       reuseIdentifier:nil] autorelease];
        pinView.animatesDrop = YES;
        
        return pinView;
    }
    
    return nil;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (CLLocationCoordinate2DIsValid(self.attachmentCoordinate))
    {
        _mapView.region = MKCoordinateRegionMake(self.attachmentCoordinate, MKCoordinateSpanMake(0.003, 0.003));
        
        MKPointAnnotation* annotation = [MKPointAnnotation new];
        annotation.coordinate = self.attachmentCoordinate;
        [_mapView addAnnotation:annotation];
        [annotation release];
    }
    
    self.navigationItem.title = @"Map";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
