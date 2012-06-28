//
//  VKContactCell.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 08.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VKContactCell : UITableViewCell
{
    IBOutlet UIImageView* _avatarImgView;
    IBOutlet UILabel* _firstNameLabel;
    IBOutlet UILabel* _lastNameLabel;
    IBOutlet UIImageView* _onlineImgView;
}

+ (NSString*)reuseId;
+ (CGFloat)height;

+ (id)contactCell;

- (void)configWithUser:(VKUser*)user;

@end
