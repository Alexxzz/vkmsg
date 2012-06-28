//
//  VKDialogVC.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 24.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKDialogContainer.h"
#import "VKCapchaVC.h"
#import "VKLocationManager.h"

@interface VKDialogVC : UIViewController<UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, VKCapchaVCDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    IBOutlet UITableView* _tableView;
    
    IBOutlet UIView* _sendView;
    IBOutlet UIButton* _sendButton;
    IBOutlet UIButton* _attachmentButton;
    IBOutlet UIImageView* _inputBackImgView;
    IBOutlet UITextView* _inputTextView;
    IBOutlet UIView* _typingFooter;
    IBOutlet UIImageView* _inputBackgroundImgView;
    
    IBOutlet UIView* _avatarView;
    IBOutlet UIImageView* _avatarImageView;
    IBOutlet UILabel* _onlineOfflineLabel;
    
    IBOutlet UIView* _offlineFooterView;
    IBOutlet UILabel* _offlineLabel;
    
    IBOutlet UIView* _attachmentsView;
    IBOutlet UIButton* _photoAttButton;
    IBOutlet UIButton* _galleryAttButton;
    IBOutlet UIButton* _locationAttButton;
    IBOutlet UIButton* _addToFavButton;
    IBOutlet UIButton* _addUserToConvButton;
    
    NSTimer* _serviceTimer;
    
    NSDate* _lastTypingIncDate;
    NSDate* _lastTypingSentDate;
    
    NSMutableSet* _readMids;
    
    VKDialogContainer* _dialog;
    NSString* _text;
    NSString* _capchaSid;
    
    VKUser* _user;
    NSDate* _lastActivityDate;
    
    UIImage* _attachImage;
    CLLocation* _attachLocation;
    
    BOOL _keyboardVisible;
}
@property(nonatomic,retain) NSNumber* uid; 

- (IBAction)onSendButton:(id)sender;
- (IBAction)onAttachmentsButton:(id)sender;

- (IBAction)onAddRemoveFav:(id)sender;
- (IBAction)onAddUserToConv:(id)sender;

- (IBAction)onAttachFromCamera:(id)sender;
- (IBAction)onAttachFromGallery:(id)sender;
- (IBAction)onAttachLocation:(id)sender;

@end
