//
//  VKLoginVC.m
//  vk
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKLoginVC.h"
#import "VKApi.h"
#import "AppDelegate.h"

@implementation VKLoginVC

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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
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

#pragma mark - Actions
- (IBAction)onLogin:(id)sender
{
    [VKApi logInWithLogin:_phoneTextField.text 
             withPassword:_passwordTextField.text
     success:^{
         dispatch_async(dispatch_get_main_queue(), ^{             
             [AppDel regDeviceAtApi];             
             [AppDel showMainUI];
         });
     } failure:^(NSError *error, NSString* errorDesc) {
         dispatch_async(dispatch_get_main_queue(), ^{
             [VKHelper showErrorMessage:errorDesc];
         });
     }];
}

#pragma mark - UITextField delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _phoneTextField)
        [_passwordTextField becomeFirstResponder];
    else
        [self onLogin:nil];
    
    return YES;
}

#pragma mark - UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        return _loginCell;
    else
        return _passwordCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        [_phoneTextField becomeFirstResponder];
    else
        [_passwordCell becomeFirstResponder];
}

@end
