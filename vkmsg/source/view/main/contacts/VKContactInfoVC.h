//
//  VKContactInfoVC.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 14.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "VKUser.h"
#import "VKAddressBook.h"

@interface VKContactInfoVC : UIViewController<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, MFMessageComposeViewControllerDelegate>

{
    IBOutlet UIImageView* _avatarImgView;
    IBOutlet UIButton* _sendMessageInviteButton;
    IBOutlet UILabel* _nameLabel;
    
    VKUser* _user;
}
@property(nonatomic,retain) VKAddressBookPerson* abPerson;

- (IBAction)onSendMsgInvite:(id)sender;

@end
