//
//  VKContactCell.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 08.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKContactCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+AFNetworking.h"

#define kXOffset 6.f

@implementation VKContactCell

@synthesize type, declineRequestButton, acceptRequestButton, delegate;

+ (NSString*)reuseId
{
    return @"VKContactCell";
}

+ (id)contactCell
{
    VKContactCell* res = nil;
    
    NSArray* objs = [[NSBundle mainBundle] loadNibNamed:@"VKContactCell" 
                                                  owner:nil 
                                                options:nil];
    if (objs != nil)
    {
        for (id obj in objs)
        {
            if ([obj isKindOfClass:[VKContactCell class]])
            {
                res = obj;
                CALayer* layer = res->_avatarImgView.layer;
                layer.masksToBounds = YES;
                layer.cornerRadius = 3.f;  
                
                break;
            }
        }
    }
    
    return res;
}

+ (id)contactCellWithType:(eVKContactCellType)type
{
    VKContactCell* res = nil;
    
    res = [self contactCell];
    res.type = type;
    
    return res;
}

+ (CGFloat)height
{
    return 47.f;
}

- (void)dealloc
{
    self.acceptRequestButton = nil;
    self.declineRequestButton = nil;
    
    [super dealloc];
}

- (void)configWithUser:(VKUser*)user
{
    if (type == eVKContactCellType_request)
    {
        self.accessoryView = self.acceptRequestButton;
        self.declineRequestButton.hidden = NO;
    }
    else
    {
        self.accessoryView = nil;
        self.declineRequestButton.hidden = YES;
    }
    
    NSURL* avatarUrl = [NSURL URLWithString:user.photo_rec];
    [_avatarImgView setImageWithURL:avatarUrl 
                   placeholderImage:[UIImage imageNamed:@"Profile_Avatar.png"]];
    CGRect avatarFrame = _avatarImgView.frame;
    avatarFrame.origin.x = self.declineRequestButton.frame.origin.x + (type == eVKContactCellType_request ?  self.declineRequestButton.frame.size.width : 0.f );
     _avatarImgView.frame = avatarFrame;
    
    _firstNameLabel.text = user.first_name;
    [_firstNameLabel sizeToFit];
    CGRect firstFrame = _firstNameLabel.frame;
    firstFrame.origin.x = avatarFrame.origin.x + avatarFrame.size.width + kXOffset;
    
    _lastNameLabel.text = user.last_name;
    [_lastNameLabel sizeToFit];
    CGRect lastFrame = _lastNameLabel.frame;
    lastFrame.origin.x = firstFrame.origin.x + firstFrame.size.width + 5.f;
    
    CGRect onlineFrame = _onlineImgView.frame;
    if (CGRectIntersectsRect(lastFrame, onlineFrame))
    {
        lastFrame.origin.x = onlineFrame.origin.x - 2.f - lastFrame.size.width;        
        firstFrame.size.width = lastFrame.origin.x - 2.f - firstFrame.origin.x;        
    }
    
    _firstNameLabel.frame = firstFrame;
    _lastNameLabel.frame = lastFrame;
    
    _onlineImgView.hidden = ![user.online boolValue];
}

- (IBAction)onDeclineRequestButton:(id)sender
{
    if (delegate != nil && [delegate respondsToSelector:@selector(requestForCell:accepted:)])
        [delegate requestForCell:self accepted:NO];
}
- (IBAction)onAcceptRequestButton:(id)sender
{
    if (delegate != nil && [delegate respondsToSelector:@selector(requestForCell:accepted:)])
        [delegate requestForCell:self accepted:YES];
}

@end
