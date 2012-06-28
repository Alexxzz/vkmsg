//
//  VKMessagesListCell.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 21.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKMessage.h"

@interface VKMessagesListCell : UITableViewCell
{
    IBOutlet UIImageView* _avatarImageView;
    IBOutlet UILabel* _nickLabel;
    IBOutlet UILabel* _detailLabel;
    IBOutlet UIImageView* _onlineImageView;
    IBOutlet UILabel* _timeLabel;
}

+ (NSString*)reuseId;
+ (id)messagesCell;

- (void)configWithMessage:(VKMessage*)msg;
- (void)setOnlineState:(BOOL)online;

@end
