//
//  VKMessagesVC.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 21.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKMessagesVC.h"
#import "VKApi.h"
#import "VKStorage.h"
#import "VKMessage.h"
#import "VKDialogVC.h"
#import "VKLongPollServerController.h"
#import "VKContactsVC.h"

@implementation VKMessagesVC

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

#pragma mark - Long Poll Updates
- (void)onLongPollUpdates:(NSNotification*)notification
{
    NSArray* updates = [[notification userInfo] valueForKey:kVKLongPollUpdatesKey];
    
    BOOL shouldReload = NO;
    for (VKLongPollUpdate* update in updates)
    {
        switch (update.type) 
        {
            //New message
            case eVKLongPollUpdateType_msgNew:
            {
                //Check if user is loaded
                if (update.userId != nil)
                {
                    VKUser* user = [Storage userWithId:update.userId];
                    if (user == nil)//Should load user
                    {
                        [VKApi getFriendsWithIds:[NSArray arrayWithObject:update.userId] 
                                         success:^(NSArray *friends) {
                                             [_tableView reloadData];
                                         } failure:^(NSError *error, NSDictionary *errDict) {
                                             
                                         }];
                        return;
                    }
                }
            }
            case eVKLongPollUpdateType_userOnline:
            case eVKLongPollUpdateType_userOffline:
            {
                shouldReload = YES;
                break;
            }
            default:
                break;
        }
        
        if (shouldReload == YES)
        {            
            NSArray* visibleCells = [_tableView indexPathsForVisibleRows];
            [_tableView reloadRowsAtIndexPaths:visibleCells
                              withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
    }
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Nav bar
    [self.navigationItem setTitle:kStrMessages];
    [_navBar setBackgroundImg:[UIImage imageNamed:@"Header_black.png"]];
    
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"new_msg.png"] forState:UIControlStateNormal];
    [btn sizeToFit];
    [btn addTarget:self 
            action:@selector(onNewDialog:) 
  forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* bbi = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = bbi;
    [bbi release];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onLongPollUpdates:) 
                                                 name:kVKNotificationLongPollUpdates
                                               object:nil];
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

- (void)addLoadingFooterIfNeeded
{
    if (Storage.dialogsCount < Storage.dialogsTotalCount)
        _tableView.tableFooterView = _loadMoreView;
    else
        _tableView.tableFooterView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_tableView reloadData];
    
    [self addLoadingFooterIfNeeded];
}

#pragma mark - Getting more

#pragma mark - IBActions
- (void)onNewDialog:(id)sender
{
    VKContactsVC* contactsVC = [VKContactsVC new];
    [contactsVC view];    
    [contactsVC hideSegmentedCtrl:YES];
    [contactsVC.navigationItem setTitle:kStrContacts];
    contactsVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:contactsVC animated:YES];
    [contactsVC release];
}

#pragma mark - Scroll delegate
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView 
{
    if (_isLoadingMore == YES || Storage.dialogsCount >= Storage.dialogsTotalCount)
        return;
    
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = 10;
    if(y > h + reload_distance) 
    {
        NSLog(@"load more dialogs");
        
        _isLoadingMore = YES;
        
        [VKApi getDialogsListCount:kInitialDlgCount
                            offset:Storage.dialogsCount 
                           success:^(NSArray *messages, NSInteger count) {
                               NSIndexPath* idx = [NSIndexPath indexPathForRow:([_tableView numberOfRowsInSection:0] - 1) 
                                                                     inSection:0];
                               
                               Storage.dialogsCount += kInitialDlgCount;
                               [self addLoadingFooterIfNeeded];
                               Storage.dialogList = [Storage.dialogList arrayByAddingObjectsFromArray:messages];
                               
                               [_tableView reloadData];
                               [_tableView scrollToRowAtIndexPath:idx 
                                                 atScrollPosition:UITableViewScrollPositionBottom
                                                         animated:NO];
                               
                               //Check for non-loaded friends
                               NSMutableArray* newFriendsIds = [NSMutableArray array];
                               for (VKMessage* msg in messages)
                               {
                                   VKUser* user = [Storage userWithId:msg.uid];
                                   if (user == nil)//Should load user
                                       [newFriendsIds addObject:msg.uid];
                               }
                               
                               if ([newFriendsIds count] > 0)
                               {
                                   [VKApi getFriendsWithIds:newFriendsIds 
                                                    success:^(NSArray *friends) {
                                                        Storage.friends = [Storage.friends arrayByAddingObjectsFromArray:friends];
                                                        
                                                        NSArray* visibleRows = [_tableView indexPathsForVisibleRows];
                                                        [_tableView reloadRowsAtIndexPaths:visibleRows withRowAnimation:UITableViewRowAnimationNone];
                                                    } failure:^(NSError *error, NSDictionary *errDict) {
                                                        
                                                    }];
                               }
                               
                               _isLoadingMore = NO;
                           } failure:^(NSError *error, NSDictionary *errDict) {
                               _isLoadingMore = NO;
                           }];
    }
}

#pragma mark - UITableView delegate/datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [Storage.dialogList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellId = [VKMessagesListCell reuseId];
    
    VKMessagesListCell* cell = [_tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil)
        cell = [VKMessagesListCell messagesCell];
    
    VKMessage* msg = [Storage.dialogList objectAtIndex:indexPath.row];
    [cell configWithMessage:msg];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    VKMessage* msg = [Storage.dialogList objectAtIndex:indexPath.row];
    
    VKDialogVC* dialog = [VKDialogVC new];
    dialog.uid = msg.uid;
    dialog.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:dialog animated:YES];
    [dialog release];
}

@end
