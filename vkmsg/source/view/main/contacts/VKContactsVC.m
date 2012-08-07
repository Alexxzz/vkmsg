//
//  VKContactsVC.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKContactsVC.h"
#import "VKApi.h"
#import "VKDialogVC.h"
#import "VKAddressBook.h"
#import "VKContactInfoVC.h"
#import "VKHelper.h"
#import "VKStorage.h"
#import "VKStrings.h"

#define kDefImpMax 5

#define kTableHeight 375.f

#define kContactsCellHeight 44.f
#define kRequestCellHeight 47.f
#define kRequestSectionsCount 3

@interface VKContactsVC()
- (void)buildDataSurces;
- (void)getRequests;
@end

@implementation VKContactsVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        
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
    [_indexLetters release];
    [_contacts release];
    
    [_contactsAddressBook release];
    [_indexLettersAddressBook release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Nav bar
    self.navigationItem.title = kStrContacts;
    self.navigationItem.titleView = _segController;
    [_navBar setBackgroundImg:[UIImage imageNamed:@"Header_black.png"]];    
    
    [self onSegmentedController:_segController];
    
    NSMutableArray* allPhones = [NSMutableArray array];
    for (VKAddressBookPerson* person in [[VKAddressBook addressBook] contacts])
    {
        for (VKAddressBookPersonPhone* phone in person.phones)
            [allPhones addObject:[VKAddressBookPerson MSISDNFormatedPhone:phone.phone]];
    }
    
    [VKApi getFriendsByPhones:allPhones 
                      Success:^(NSArray *friends) {
                          for (VKUser* userWithMob in friends)
                          {                              
                              VKUser* user = [Storage userWithId:userWithMob.uid];
                              user.mobile_phone = [userWithMob.phone stringValue];
                              
                              VKAddressBookPerson* person = [[VKAddressBook addressBook] personWithPhone:userWithMob.phone];
                              if (person != nil)
                                  person.uid = userWithMob.uid;
                          }
                      } failure:^(NSError *error, NSDictionary *errDict) {
                          
                      }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated]; 
    
    if (_indexLetters == nil)
    {
        [self buildDataSurces];
        [_tableView reloadData];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions
- (void)hideSegmentedCtrl:(BOOL)hide
{
    self.navigationItem.titleView = (hide ? nil : _segController);
}

- (IBAction)onSegmentedController:(id)sender
{
    UISegmentedControl* segmentedCtrl = sender;
    
    _viewType = segmentedCtrl.selectedSegmentIndex; 
    
    switch (_viewType) 
    {
        //Contacts
        case eVKContactsViewType_contacts:
            _tableView.tableHeaderView = _searchBar;
            break;
            
        //Friends
        default:
        case eVKContactsViewType_friends:
            _tableView.tableHeaderView = _searchBar;
            break;
            
        //Requests
        case eVKContactsViewType_requests:
            _tableView.tableHeaderView = nil;
            
            if (Storage.requests == nil)
                [self getRequests];
            
            break;
    }
    
    [_tableView reloadData];
}

#pragma mark - Data sources
- (void)dataSourceForFriends
{
    NSMutableSet* lettersEng = [NSMutableSet new];
    NSMutableSet* letters = [NSMutableSet new];
    
    [_contacts release];
    _contacts = [NSMutableDictionary new];
    
    for (VKUser* friend in Storage.friends)
    {
        NSString* letter = [[friend.last_name substringToIndex:1] uppercaseString];
        unichar firstChar = [friend.last_name characterAtIndex:0];
        if (firstChar >= 'A' && firstChar <= 'Z')
            [lettersEng addObject:letter];
        else
            [letters addObject:letter];
        
        //Build data source
        NSMutableArray* letterArray = [_contacts valueForKey:letter];
        if (letterArray == nil)
        {
            letterArray = [NSMutableArray arrayWithCapacity:5];
            [_contacts setValue:letterArray forKey:letter];
        }
        [letterArray addObject:friend];
    }
    
    //Sort data
    for (NSMutableArray* array in [_contacts objectEnumerator])
    {
        [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            VKUser* user1 = obj1;
            VKUser* user2 = obj2;
            
            return [user1.last_name compare:user2.last_name options:NSCaseInsensitiveSearch];
        }];
    }
    
    //Add "Important" section
    NSInteger impMax = kDefImpMax;
    if ([Storage.friends count] < impMax)
        impMax = [Storage.friends count];
    NSMutableArray* important = [[Storage.friends subarrayWithRange:NSMakeRange(0, impMax)] mutableCopy];
    [_contacts setValue:important forKey:kStrImportant];
    [important release];
    
    //Create indexes
    NSArray* engArray = [lettersEng allObjects];
    engArray = [engArray sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    
    NSArray* array = [letters allObjects];
    array = [array sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    
    [_indexLetters release];
    _indexLetters = [[array arrayByAddingObjectsFromArray:engArray] retain];
    
    [lettersEng release];
    [letters release];
}

- (void)dataSourceForContacts
{
    [_contactsAddressBook release];
    _contactsAddressBook = [NSMutableDictionary new];
    
    NSMutableSet* lettersEng = [NSMutableSet new];
    NSMutableSet* letters = [NSMutableSet new];
    
    for (VKAddressBookPerson* person in [[VKAddressBook addressBook] contacts])
    {
        NSString* name = [person getName];
        if (name == nil || [name length] == 0)
            continue;
        
        NSString* letter = [[name substringToIndex:1] uppercaseString];
        unichar firstChar = [name characterAtIndex:0];
        if (firstChar >= 'A' && firstChar <= 'Z')
            [lettersEng addObject:letter];
        else
            [letters addObject:letter];
        
        //Build data source
        NSMutableArray* letterArray = [_contactsAddressBook valueForKey:letter];
        if (letterArray == nil)
        {
            letterArray = [NSMutableArray arrayWithCapacity:5];
            [_contactsAddressBook setValue:letterArray forKey:letter];
        }
        [letterArray addObject:person];
    }
    
    //Sort data
    for (NSMutableArray* array in [_contactsAddressBook objectEnumerator])
    {
        [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            VKAddressBookPerson* user1 = obj1;
            VKAddressBookPerson* user2 = obj2;
            
            return [[user1 getName] compare:[user2 getName] options:NSCaseInsensitiveSearch];
        }];
    }
    
    //Create indexes
    NSArray* engArray = [lettersEng allObjects];
    engArray = [engArray sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    
    NSArray* array = [letters allObjects];
    array = [array sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    
    [_indexLettersAddressBook release];
    _indexLettersAddressBook = [[array arrayByAddingObjectsFromArray:engArray] retain];
    
    [lettersEng release];
    [letters release];
}

- (void)dataSourceForRequests
{
    
}

- (void)buildDataSurces
{
    NSLog(@"<--------buildDataSurces start------------>");
    [self dataSourceForFriends];
    [self dataSourceForContacts];
    [self dataSourceForRequests];
    NSLog(@"<--------buildDataSurces finish------------>");
}

- (void)replaceUidsWithVKUsersInArray:(NSMutableArray*)array
{
    for (NSNumber* uid in array)
    {
        if ([uid isKindOfClass:[NSNumber class]])
        {
            VKUser* usr = [Storage userWithId:uid];
            if (usr != nil)
            {
                
            }
        }
    }
}

- (void)getRequests
{
    [VKApi getFriendsRequestsWithOffset:Storage.requestsCount 
                                  count:kInitialRequestsCount 
                           loadMessages:NO
                   loadOutgoingRequests:NO 
                                success:^(NSArray *response) {
                                    if (response != nil && [response count] > 0)
                                    {
                                        [VKApi getFriendsWithIds:response 
                                                         success:^(NSArray *friends) {                                                             
                                                             Storage.requests = [NSMutableArray arrayWithArray:friends];
                                                             Storage.requestsCount += [friends count];
                                                             
                                                             if (_tableView.superview != nil)
                                                                 [_tableView reloadData];
                                                         } failure:^(NSError *error, NSDictionary *errDict) {   
                                                             
                                                         }];
                                    }
                                } 
                                failure:^(NSError *error, NSDictionary *errDict) {
                                    
                                }];
}

#pragma mark - Search table
- (NSArray*)searchResultTitleSectionIndexTitles
{
    return nil;
}

- (NSString*)searchResulttitleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;
    
    return title;
}

- (NSInteger)searchResultNumberSections
{
    return 1;
}

- (NSInteger)searchResultNumberOfRowsInSection:(NSInteger)section
{
    return [_searchDataSource count];
}

- (UITableViewCell*)searchResultCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableView* searchTable = self.searchDisplayController.searchResultsTableView;
    
    if (_viewType == eVKContactsViewType_friends)
    {
        NSString* cellId = [VKContactCell reuseId];
        
        VKContactCell* cell = [searchTable dequeueReusableCellWithIdentifier:cellId];
        if (cell == nil)
            cell = [VKContactCell contactCell];
        
        VKUser* friend = [_searchDataSource objectAtIndex:indexPath.row];
        cell.type = eVKContactCellType_contact;
        [cell configWithUser:friend];
        
        return cell;
    }
    else
    {
        NSString* cellId = @"contactCell";
        
        UITableViewCell* cell = [searchTable dequeueReusableCellWithIdentifier:cellId];
        if (cell == nil)
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                           reuseIdentifier:cellId] autorelease];
        
        VKAddressBookPerson* person = [_searchDataSource objectAtIndex:indexPath.row];
        
        NSString* name = [person getName];
        NSString* fullName = [person getFullName];
        cell.textLabel.text = name;
        cell.detailTextLabel.text = (name != fullName ? fullName : nil);
        
        return cell;
    }
    
    return nil;
}

- (void)searchResultDidSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_viewType == eVKContactsViewType_contacts)
    {
        VKAddressBookPerson* person = [_searchDataSource objectAtIndex:indexPath.row];
        
        VKContactInfoVC* infoVC = [VKContactInfoVC new];
        infoVC.abPerson = person;
        infoVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:infoVC 
                                             animated:YES];
        [infoVC release];
    }
    else
    {
        VKUser* friend = [_searchDataSource objectAtIndex:indexPath.row];
        
        VKDialogVC* dialog = [VKDialogVC new];
        dialog.uid = friend.uid;    
        dialog.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:dialog animated:YES];
        [dialog release];
    }
}

#pragma mark - TableView
// return list of section titles to display in section index view (e.g. "ABCD...Z#")
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{    
    if (tableView != _tableView)
        return [self searchResultTitleSectionIndexTitles];
    
    switch (_viewType) 
    {
        case eVKContactsViewType_friends:
            return _indexLetters;
            
        case eVKContactsViewType_contacts:
            return _indexLettersAddressBook;
            
        case eVKContactsViewType_requests:
            return nil;
    }
    
    return nil;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView != _tableView)
        return [self searchResulttitleForHeaderInSection:section];
    
    NSString* title = nil;
    
    switch (_viewType) 
    {
        case eVKContactsViewType_friends:
        {
            if (section == 0)
                title = kStrImportant;
            else
                title = [_indexLetters objectAtIndex:section - 1];
            
            break;
        }
            
        case eVKContactsViewType_contacts:
        {
            title = [_indexLettersAddressBook objectAtIndex:section];
            break;
        }
            
        case eVKContactsViewType_requests:
        {
            switch (section) 
            {
                default:
                case 0:
                    title = nil;
                    break;
                    
                case 1:
                    title = kStrFriendRequests;
                    break;
                    
                case 2:
                    title = kStrSuggestions;
                    break;
            }
            break;
        }
    }
        
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat res;
    switch (_viewType) 
    {
        default:
        case eVKContactsViewType_contacts:
            res = kContactsCellHeight;
            break;
            
        case eVKContactsViewType_friends:
            res = [VKContactCell height];
            break;
            
        case eVKContactsViewType_requests:
            res = kRequestCellHeight;
            break;
    }
    
    return res;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView != _tableView)
        return [self searchResultNumberSections];
    
    NSInteger res = 0;
    switch (_viewType) 
    {
        case eVKContactsViewType_friends:
            res = [_indexLetters count] + 1;
            break;
            
        case eVKContactsViewType_contacts:
            res = [_indexLettersAddressBook count];
            break;
            
        case eVKContactsViewType_requests:
            res = kRequestSectionsCount;
            break;
            
        default:
            break;
    }
    
    return res;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    if (tableView != _tableView)
        return [self searchResultNumberOfRowsInSection:section];
        
    
    switch (_viewType) 
    {
        //Contacts
        case eVKContactsViewType_contacts:
        {
            NSString* key = [_indexLettersAddressBook objectAtIndex:section];
            NSArray* sectionArray = [_contactsAddressBook valueForKey:key];
            
            return [sectionArray count];
        }
            
        //Friends
        case eVKContactsViewType_friends:
        {
            NSString* key = nil;
            if (section == 0)
                key = kStrImportant;
            else
                key = [_indexLetters objectAtIndex:section - 1];
            NSArray* sectionArray = [_contacts valueForKey:key];
            
            return [sectionArray count];
        }
            
        //Requests
        default:
        case eVKContactsViewType_requests:
        {
            NSInteger count = 0;
            
            switch (section) 
            {
                case 0:
                    count = 1;
                    break;
                    
                case 1:
                    count = [Storage.requests count];
                    break;
                    
                case 2:
                    break;
                    
                default:
                    break;
            }
            
            return count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{ 
    if (tableView != _tableView)
        return [self searchResultCellForIndexPath:indexPath];
    
    switch (_viewType) 
    {
        //Contacts
        case eVKContactsViewType_contacts:
        {
            NSString* cellId = @"contactCell";
            
            UITableViewCell* cell = [_tableView dequeueReusableCellWithIdentifier:cellId];
            if (cell == nil)
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                               reuseIdentifier:cellId] autorelease];
            
            NSString* key = [_indexLettersAddressBook objectAtIndex:indexPath.section];
            NSArray* sectionArray = [_contactsAddressBook valueForKey:key];
            VKAddressBookPerson* person = [sectionArray objectAtIndex:indexPath.row];
            
            NSString* name = [person getName];
            NSString* fullName = [person getFullName];
            cell.textLabel.text = name;
            cell.detailTextLabel.text = (name != fullName ? fullName : nil);
            
            return cell;
        }
            
        //Friends
        default:
        case eVKContactsViewType_friends:
        {
            NSString* cellId = [VKContactCell reuseId];
            
            VKContactCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId];
            if (cell == nil)
                cell = [VKContactCell contactCell];
            
            NSString* key = nil;
            if (indexPath.section == 0)
                key = kStrImportant;
            else
                key = [_indexLetters objectAtIndex:indexPath.section - 1];
            NSArray* sectionArray = [_contacts valueForKey:key];
            
            VKUser* friend = [sectionArray objectAtIndex:indexPath.row];
            cell.type = eVKContactCellType_contact;
            [cell configWithUser:friend];
            
            return cell;
        }
            
        //Requests
        case eVKContactsViewType_requests:
        {
            switch (indexPath.section) {
                case 0:
                {
                    static NSString* invFriendsCellId = @"invFriendsCellId";
                    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:invFriendsCellId];
                    if (cell == nil)
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                      reuseIdentifier:invFriendsCellId] autorelease];
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.text = kStrInviteFriends;
                    
                    return cell;
                }
                    
                case 1:
                {
                    NSString* cellId = [VKContactCell reuseId];
                    
                    VKContactCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId];
                    if (cell == nil)
                        cell = [VKContactCell contactCellWithType:eVKContactCellType_request];
                    
                    VKUser* friend = [Storage.requests objectAtIndex:indexPath.row];
                    cell.type = eVKContactCellType_request;
                    [cell configWithUser:friend];
                    cell.delegate = self;
                    
                    return cell;
                }
                    
                case 2:
                {
                    
                }
                    
                default:
                    break;
            }
        }
    }
    
    return nil;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_viewType == eVKContactsViewType_requests && indexPath.section == 1)
        return UITableViewCellEditingStyleDelete;
    
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView != _tableView)
    {
        [self searchResultDidSelectRowAtIndexPath:indexPath];
        return;
    }
    
    switch (_viewType) 
    {
        case eVKContactsViewType_contacts:
        {
            NSString* key = [_indexLettersAddressBook objectAtIndex:indexPath.section];
            NSArray* sectionArray = [_contactsAddressBook valueForKey:key];            
            VKAddressBookPerson* contact = [sectionArray objectAtIndex:indexPath.row];
            
            VKContactInfoVC* infoVC = [VKContactInfoVC new];
            infoVC.abPerson = contact;
            infoVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:infoVC 
                                                 animated:YES];
            [infoVC release];
            
            break;
        }
            
        case eVKContactsViewType_friends:
        {
            NSString* key = nil;
            if (indexPath.section == 0)
                key = kStrImportant;
            else
                key = [_indexLetters objectAtIndex:indexPath.section - 1];
            NSArray* sectionArray = [_contacts valueForKey:key];
            
            VKUser* friend = [sectionArray objectAtIndex:indexPath.row];
            
            VKDialogVC* dialog = [VKDialogVC new];
            dialog.uid = friend.uid;    
            dialog.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:dialog animated:YES];
            [dialog release];
            
            break;
        }
            
        case eVKContactsViewType_requests:
        {
            break;
        }
    }
}

#pragma mark - VKContactCellDelegate
- (void)requestForCell:(VKContactCell*)cell accepted:(BOOL)accepted
{
    NSIndexPath* indexPath = [_tableView indexPathForCell:cell];
    VKUser* friend = [Storage.requests objectAtIndex:indexPath.row];
    
    if (accepted == YES)
    {
        [VKApi addFriendWithId:friend.uid 
                      withText:nil 
                       success:^{
                           NSLog(@"Request with friend id: %@ accepted", friend.uid);                              
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [Storage.requests removeObject:friend];
                               [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                                                 withRowAnimation:UITableViewRowAnimationFade];
                               
                               [VKApi getFriendsListCount:kInitialFriendsCount 
                                                   offset:0 
                                                    order:eVKFriendsOrder_hints 
                                                  success:^(NSArray *friends) {
                                                      Storage.friends = friends;
                                                  } failure:^(NSError *error, NSDictionary* errDict) {
                                                      
                                                  }];
                           });
                       } failure:^(NSError *error, NSDictionary *errDict) {
                           
                       }];
    }
    else 
    {
        [VKApi deleteFriendWithId:friend.uid 
                          success:^{
                              NSLog(@"Request with friend id: %@ denied", friend.uid);                              
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [Storage.requests removeObject:friend];
                                  [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                                                    withRowAnimation:UITableViewRowAnimationFade];
                              });
                          } 
                          failure:^(NSError *error, NSDictionary *errDict) {
                              
                          }];
    }
}

#pragma mark - Searching
- (void)searchForString:(NSString*)str
{
    [_searchDataSource release], _searchDataSource = nil;
    _searchDataSource = [NSMutableArray new];
    
    if (_viewType == eVKContactsViewType_friends)
    {
        for (NSArray* section in [_contacts objectEnumerator])
        {            
            //Skip search in important section
            if ([section isEqual:[_contacts valueForKey:kStrImportant]])
                continue;
            
            for (VKUser* usr in section)
            {
                NSString* fullName = [NSString stringWithFormat:@"%@ %@", usr.first_name, usr.last_name];
                NSRange nameRange = [fullName rangeOfString:str
                                                    options:NSCaseInsensitiveSearch];
                if (nameRange.location != NSNotFound)
                    [_searchDataSource addObject:usr];
            }
        }
    }
    else if (_viewType == eVKContactsViewType_contacts)
    {
        for (NSArray* section in [_contactsAddressBook objectEnumerator])
        {
            for (VKAddressBookPerson* person in section)
            {
                NSString* fullName = [person getFullName];
                NSRange nameRange = [fullName rangeOfString:str
                                                    options:NSCaseInsensitiveSearch];
                if (nameRange.location != NSNotFound)
                    [_searchDataSource addObject:person];
            }
        }
    }
}

#pragma mark - Search Controller delegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self searchForString:searchString];
    
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
    [_searchDataSource release], _searchDataSource = nil;
}

@end
