//
//  VKDialogCell.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 25.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKMessage.h"

static NSString* const kVKNotificationAttachmentClicked = @"vk.attachment.clicked";

//////////////////////
@interface VKAudioAttachmentView : UIControl

@property(nonatomic,assign) IBOutlet UIImageView* audioImgView;
@property(nonatomic,assign) IBOutlet UILabel* artistLabel;
@property(nonatomic,assign) IBOutlet UILabel* titleLabel;
@property(nonatomic,assign) IBOutlet UILabel* durationLabel;

@property(nonatomic,retain) NSDictionary* attachDict;

+ (id)audioAttachmentView;

@end

//////////////////////
@interface VKImgAttachmentView : UIControl 
{
    UIImageView* _imgView;
}
@property(nonatomic,readonly) UIImageView* imgView;
@property(nonatomic,retain) NSDictionary* attachDict;

+ (id)imageAttachmentView;

- (void)setImage:(UIImage*)img;

@end

//////////////////////
@interface VKDialogCell : UITableViewCell
{
    IBOutlet UILabel* _timeLabel;
    
    IBOutlet UIView* _containerView;
    IBOutlet UIImageView* _boubleImgView;
    IBOutlet UITextView* _textView;
    
    NSMutableArray* _attachmentsImgViews;
    NSMutableArray* _audioAttachments;
}

+ (id)dialogCell;
+ (NSString*)reuseID;

+ (CGFloat)heightForMessage:(VKMessage*)msg;

- (void)configWithMessage:(VKMessage*)msg;

@end
