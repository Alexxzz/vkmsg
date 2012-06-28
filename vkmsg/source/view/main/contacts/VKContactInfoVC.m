//
//  VKContactInfoVC.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 14.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKContactInfoVC.h"
#import "UIImageView+AFNetworking.h"
#import "VKDialogVC.h"
#import <QuartzCore/QuartzCore.h>

#define kTagInviteActionSheet 1
#define kTagSendCallActionSheet 2

@implementation VKContactInfoVC

@synthesize abPerson;

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

- (void)dealloc
{
    self.abPerson = nil;
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _user = [Storage userWithId:abPerson.uid];
    
    NSString* title = nil;
    
    if (_user != nil)
    {
        NSURL* avatarUrl = [NSURL URLWithString:_user.photo_rec];
        [_avatarImgView setImageWithURL:avatarUrl];
        title = [NSString stringWithFormat:@"%@ %@", _user.first_name, _user.last_name];
        
        [_sendMessageInviteButton setTitle:kStrSendMessage forState:UIControlStateNormal];
    }
    else
    {
        title = [abPerson getFullName];
        if (abPerson.avatar != nil)
            _avatarImgView.image = abPerson.avatar;
        
        [_sendMessageInviteButton setTitle:kStrSendInvite forState:UIControlStateNormal];
    }
    
    _nameLabel.text = self.navigationItem.title = title;
    
    CALayer* layer = _avatarImgView.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = 5.f;;
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

#pragma mark - IBAction
- (void)presentSendInviteSMSToNum:(NSString*)number
{
    MFMessageComposeViewController* composer = [[MFMessageComposeViewController alloc] init];
    [composer setBody:[NSString stringWithFormat:kStrInviteFormat, [abPerson getName]]];
    [composer setRecipients:[NSArray arrayWithObject:number]];
    [composer setMessageComposeDelegate:self];
    [self presentModalViewController:composer animated:YES];
    [composer release];
}

- (IBAction)onSendMsgInvite:(id)sender
{
    if (_user != nil)//VK user
    {
        VKDialogVC* dialog = [VKDialogVC new];
        dialog.uid = _user.uid;
        [self.navigationController pushViewController:dialog animated:YES];
        [dialog release];
    }
    else//Phone contact
    {
        if ([abPerson.phones count] > 1)
        {
            UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                     delegate:self 
                                                            cancelButtonTitle:nil 
                                                       destructiveButtonTitle:nil 
                                                            otherButtonTitles:nil];
            for (VKAddressBookPersonPhone* phone in abPerson.phones)
                [actionSheet addButtonWithTitle:phone.phone];            
            actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:kStrCancel];
            actionSheet.tag = kTagInviteActionSheet;
            [actionSheet showInView:self.view];
            [actionSheet release];
        }
        else
        {
            VKAddressBookPersonPhone* phone = [abPerson.phones lastObject];
            [self presentSendInviteSMSToNum:phone.phone];
        }
    }
}

#pragma mark - UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [abPerson.phones count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellId = @"phoneCell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 
                                      reuseIdentifier:cellId] autorelease];
    
    VKAddressBookPersonPhone* phone = [abPerson.phones objectAtIndex:indexPath.row];    
    cell.textLabel.text = phone.label;
    cell.detailTextLabel.text = phone.phone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    VKAddressBookPersonPhone* phone = [abPerson.phones objectAtIndex:indexPath.row];
    
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:phone.phone
                                                             delegate:self 
                                                    cancelButtonTitle:kStrCancel 
                                               destructiveButtonTitle:nil 
                                                    otherButtonTitles:kStrMakeACall, kStrSendSms, nil];
    actionSheet.tag = kTagSendCallActionSheet;
    [actionSheet showInView:self.view];
    [actionSheet release];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == kTagSendCallActionSheet)
    {
        NSString* number = actionSheet.title;
        
        if (buttonIndex == 0)//call
        {
            NSString *phoneNumber = [@"tel://" stringByAppendingString:number];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
        }
        else if (buttonIndex == 1)//sms
        {        
            MFMessageComposeViewController* composer = [[MFMessageComposeViewController alloc] init];
            [composer setRecipients:[NSArray arrayWithObject:number]];
            [composer setMessageComposeDelegate:self];
            [self presentModalViewController:composer animated:YES];
            [composer release];
        }
    }
    else
    {
        if (buttonIndex != actionSheet.cancelButtonIndex)
        {
            NSString* phone = [actionSheet buttonTitleAtIndex:buttonIndex];
            [self presentSendInviteSMSToNum:phone];
        }
    }
}

#pragma mark - MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
