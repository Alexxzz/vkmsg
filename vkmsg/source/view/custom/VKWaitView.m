//
//  VKWaitView.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 29.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKWaitView.h"
#import "AppDelegate.h"

@implementation VKWaitView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [_window release], _window = nil;
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

#pragma mark - Methods
- (void)showWaitingView
{
    _mainWindow = [AppDel window];
    
    _window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 20, 320, 460)];
    _window.hidden = NO;
    _window.windowLevel = UIWindowLevelStatusBar;
    _window.backgroundColor = [UIColor clearColor];
    [_window addSubview:self.view];
    
    [_window makeKeyAndVisible];
}
- (void)hideWaitingView
{
    [_window release], _window = nil;
    
    [_mainWindow makeKeyWindow];
}

@end
