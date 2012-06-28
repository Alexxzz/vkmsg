//
//  VKFavouritesVC.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 15.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKFavouritesVC.h"
#import "VKStrings.h"
#import "VKDialogVC.h"

@interface VKFavouritesVC()
    - (void)onEdit:(id)sender;
    - (void)onAdd:(id)sender;
@end

@implementation VKFavouritesVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [_bbiEdit release];
    [_bbiAdd release];
    [_bbiDone release];
    
    [super dealloc];
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
    
    _navBar.backgroundImg = [UIImage imageNamed:@"Header_black.png"];
    
    self.navigationItem.title = kStrFavourites;
    
    _bbiDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                             target:self 
                                                             action:@selector(onEdit:)];
    _bbiEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit 
                                                                             target:self 
                                                                             action:@selector(onEdit:)];
    self.navigationItem.leftBarButtonItem = _bbiEdit;
    
    _bbiAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                            target:self 
                                                                            action:@selector(onAdd:)];
    self.navigationItem.rightBarButtonItem = _bbiAdd;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_tableView reloadData];
}

#pragma mark - Actions
- (void)onEdit:(id)sender
{
    [_tableView setEditing:!_tableView.editing animated:YES];
    
    if (_tableView.editing == YES)
    {        
        [self.navigationItem setLeftBarButtonItem:_bbiDone animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
    else
    {
        [self.navigationItem setLeftBarButtonItem:_bbiEdit animated:YES];
        [self.navigationItem setRightBarButtonItem:_bbiAdd animated:YES];
    }
}
- (void)onAdd:(id)sender
{
    
}

#pragma mark - UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [Storage.favourites count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellId = @"favCellId";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
                                       reuseIdentifier:cellId] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        
        UIView* backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 47)];
        backView.backgroundColor = [UIColor whiteColor];
        cell.backgroundView = backView;
        [backView release];
    }
    
    NSNumber* uid = [Storage.favourites objectAtIndex:indexPath.row];
    VKUser* friend = [Storage userWithId:uid];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", friend.first_name, friend.last_name];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNumber* uid = [Storage.favourites objectAtIndex:indexPath.row];
    
    VKDialogVC* dialog = [VKDialogVC new];
    dialog.uid = uid;
    dialog.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:dialog animated:YES];
    [dialog release];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSNumber* uid = [[Storage.favourites objectAtIndex:sourceIndexPath.row] retain];
    [Storage.favourites removeObject:uid];
    [Storage.favourites insertObject:uid atIndex:destinationIndexPath.row];
    [uid release];
    
    [Storage storeFavs];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [Storage.favourites removeObjectAtIndex:indexPath.row];
        [Storage storeFavs];
        
        [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                          withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self tableView:tableView didDeselectRowAtIndexPath:indexPath];
}

@end
