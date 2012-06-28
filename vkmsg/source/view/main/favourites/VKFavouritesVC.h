//
//  VKFavouritesVC.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 15.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKNavigationBar.h"

@interface VKFavouritesVC : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
    IBOutlet UITableView* _tableView;
    IBOutlet VKNavigationBar* _navBar;
    
    UIBarButtonItem* _bbiEdit;
    UIBarButtonItem* _bbiDone;
    UIBarButtonItem* _bbiAdd;
}

@end
