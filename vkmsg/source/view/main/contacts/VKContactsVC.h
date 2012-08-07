//
//  VKContactsVC.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKNavigationBar.h"
#import "VKContactCell.h"

typedef enum 
{
    eVKContactsViewType_contacts = 0,
    eVKContactsViewType_friends,
    eVKContactsViewType_requests,
} eVKContactsViewType;

@interface VKContactsVC : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, VKContactCellDelegate>
{
    IBOutlet UITableView* _tableView;
    IBOutlet UISearchBar* _searchBar;
    
    IBOutlet UISegmentedControl* _segController;
    IBOutlet VKNavigationBar* _navBar;
    
    NSArray* _indexLetters;
    NSMutableDictionary* _contacts;
    
    NSArray* _indexLettersAddressBook;
    NSMutableDictionary* _contactsAddressBook;
    
    NSMutableArray* _searchDataSource;
    
    eVKContactsViewType _viewType;
}

- (void)hideSegmentedCtrl:(BOOL)hide;

- (IBAction)onSegmentedController:(id)sender;

@end
