//
//  VKLoginVC.h
//  vk
//
//  Created by Alexander Zagorsky on 15.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VKLoginVC : UIViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    IBOutlet UIView* _navBarView;
    IBOutlet UITextField* _phoneTextField;
    IBOutlet UITextField* _passwordTextField;
    IBOutlet UITableViewCell* _loginCell;
    IBOutlet UITableViewCell* _passwordCell;
}

- (IBAction)onLogin:(id)sender;

@end
