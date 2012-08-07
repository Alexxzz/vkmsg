//
//  VKContactCell.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 08.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    eVKContactCellType_contact = 0,
    eVKContactCellType_request,
    
    eVKContactCellType_max
} eVKContactCellType;

@class VKContactCell;

@protocol VKContactCellDelegate <NSObject>

- (void)requestForCell:(VKContactCell*)cell accepted:(BOOL)accepted;

@end

@interface VKContactCell : UITableViewCell
{
    IBOutlet UIImageView* _avatarImgView;
    IBOutlet UILabel* _firstNameLabel;
    IBOutlet UILabel* _lastNameLabel;
    IBOutlet UIImageView* _onlineImgView;
}
@property(nonatomic,assign) id<VKContactCellDelegate> delegate;
@property(nonatomic,assign) eVKContactCellType type;
@property(nonatomic,retain) IBOutlet UIButton* declineRequestButton;
@property(nonatomic,retain) IBOutlet UIButton* acceptRequestButton;

+ (NSString*)reuseId;
+ (CGFloat)height;

+ (id)contactCell;
+ (id)contactCellWithType:(eVKContactCellType)type;

- (void)configWithUser:(VKUser*)user;

- (IBAction)onDeclineRequestButton:(id)sender;
- (IBAction)onAcceptRequestButton:(id)sender;

@end
