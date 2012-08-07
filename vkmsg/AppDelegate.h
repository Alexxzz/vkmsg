//
//  AppDelegate.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKLoginVC.h"
#import "VKWaitView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
{
    VKWaitView* _waitView;
}

@property(nonatomic, retain) UIWindow* window;
@property(nonatomic, retain) UITabBarController* mainTabBar;
@property(nonatomic, retain) VKLoginVC* loginVC;

- (void)showSignIn;
- (void)showMainUI;

- (void)showWaitingView;
- (void)hideWaitingView;

- (void)regDeviceAtApi;

@end
