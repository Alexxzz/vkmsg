//
//  VKContactsVC.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKContactsVC.h"
#import "VKContactCell.h"
#import "VKStorage.h"
#import "VKApi.h"
#import "VKStrings.h"
#import "VKDialogVC.h"
#import "VKAddressBook.h"
#import "VKContactInfoVC.h"

#define kDefImpMax 5

@interface VKContactsVC()
- (void)buildDataSurces;
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

#pragma mark - TableView
// return list of section titles to display in section index view (e.g. "ABCD...Z#")
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{    
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
            break;
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
            res = 44.f;
            break;
            
        case eVKContactsViewType_friends:
            res = [VKContactCell height];
            break;
    }
    
    return res;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger res = 0;
    switch (_viewType) 
    {
        case eVKContactsViewType_friends:
            res = [_indexLetters count] + 1;
            break;
            
        case eVKContactsViewType_contacts:
            res = [_indexLettersAddressBook count];
            break;
            
        default:
            break;
    }
    
    return res;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
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
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
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
            [cell configWithUser:friend];
            
            return cell;
        }
            
        //Requests
        case eVKContactsViewType_requests:
        {
            break;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    
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

@end
