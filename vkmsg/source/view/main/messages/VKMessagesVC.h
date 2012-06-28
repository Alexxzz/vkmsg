//
//  VKMessagesVC.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 21.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKMessagesListCell.h"
#import "VKNavigationBar.h"

@interface VKMessagesVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITableView* _tableView;
    IBOutlet VKNavigationBar* _navBar;
}

- (IBAction)onNewDialog:(id)sender;

@end
