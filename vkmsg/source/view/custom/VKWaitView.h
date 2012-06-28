//
//  VKWaitView.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 29.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VKWaitView : UIViewController
{
    IBOutlet UIActivityIndicatorView* _activityView;
    
    UIWindow* _window;
    UIWindow* _mainWindow;
}

- (void)showWaitingView;
- (void)hideWaitingView;

@end
