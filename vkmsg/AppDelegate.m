//
//  AppDelegate.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "AFNetworking.h"
#import "VKApi.h"
#import "VKLongPollServerController.h"
#import "VKAddressBook.h"
#import "VKHelper.h"

@interface AppDelegate()
- (void)showSignIn;
- (void)showMainUI;
@end

@implementation AppDelegate

@synthesize window, mainTabBar, loginVC;

- (void)dealloc
{
    self.mainTabBar = nil;
    self.loginVC = nil;
    self.window = nil;
    
    [_waitView release];
    
    [super dealloc];
}

#pragma mark - UIApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [VKAddressBook addressBook];
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:1024 * 1024 
                                                         diskCapacity:1024 * 1024 * 5 diskPath:nil];
	[NSURLCache setSharedURLCache:URLCache];
    [URLCache release];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    if (Storage.appToken == nil)
        [self showSignIn];
    else
        [self showMainUI];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

#pragma mark - UI
- (void)showSignIn
{   
    if (self.loginVC == nil)
        self.loginVC = [[VKLoginVC new] autorelease];
    
    self.window.rootViewController = self.loginVC;
    
    if (self.window.keyWindow == NO)
        [self.window makeKeyAndVisible];
}

- (void)getDialogs
{    
    [VKApi getDialogsListCount:kInitialDlgCount 
                        offset:0 
                       success:^(NSArray *messages, NSInteger count) {
                           Storage.dialogList = messages;
                           Storage.dialogsCount = kInitialDlgCount;
                           Storage.dialogsTotalCount = count;
                       } failure:^(NSError *error, NSDictionary* errDict) {
                           
                       }];
    
    Storage.dialogs = [NSMutableDictionary dictionary];
}

- (void)showMainUI
{    
    if (self.mainTabBar == nil)
    {
        NSArray* items = [[NSBundle mainBundle] loadNibNamed:@"VKMainVC" 
                                                       owner:self 
                                                     options:nil];
        for (id item in items)
        {
            if ([item isKindOfClass:[UITabBarController class]])
            {
                self.mainTabBar = item;
                break;
            }
        }
    }
    
    self.window.rootViewController = self.mainTabBar;
    
    if (self.window.keyWindow == NO)
        [self.window makeKeyAndVisible];
    
    [VKApi setOnlineSuccess:^{
        NSLog(@"set online");
    } failure:^(NSError *error, NSDictionary *errDict) {
        
    }];
    
    //Splash
    UIImageView* splash = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, 320, 460)];
    splash.image = [UIImage imageNamed:@"Default@2x.png"];
    [self.window addSubview:splash];
    
    [VKApi getFriendsListCount:kInitialFriendsCount 
                        offset:0 
                         order:eVKFriendsOrder_hints 
                       success:^(NSArray *friends) {
                           Storage.friends = friends;
                           
                           [splash removeFromSuperview];
                           [splash release];
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [self getDialogs];
                           });
                       } failure:^(NSError *error, NSDictionary* errDict) {
                           [splash removeFromSuperview];
                           [splash release];
                       }];
    
    [VKApi getLongPollServerParamsSuccess:^(NSDictionary *params) {
        [[VKLongPollServerController instance] configAndConnectWithDictionary:params];
    } failure:^(NSError *error, NSDictionary* errDict) {
        
    }];
}

#pragma mark - Waiting view
- (void)showWaitingView
{
    if (_waitView == nil)
        _waitView = [VKWaitView new];
    
    [_waitView showWaitingView];
}
- (void)hideWaitingView
{
    [_waitView hideWaitingView];
}

@end
