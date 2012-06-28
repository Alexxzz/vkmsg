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

@implementation VKContactCell

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

+ (CGFloat)height
{
    return 47.f;
}

- (void)configWithUser:(VKUser*)user
{
    NSURL* avatarUrl = [NSURL URLWithString:user.photo_rec];
    [_avatarImgView setImageWithURL:avatarUrl 
                   placeholderImage:[UIImage imageNamed:@"Profile_Avatar.png"]];
    
    _firstNameLabel.text = user.first_name;
    [_firstNameLabel sizeToFit];
    CGRect firstFrame = _firstNameLabel.frame;
    
    
    _lastNameLabel.text = user.last_name;
    [_lastNameLabel sizeToFit];
    CGRect lastFrame = _lastNameLabel.frame;
    lastFrame.origin.x = firstFrame.origin.x + firstFrame.size.width + 5.f;
    
    CGRect onlineFrame = _onlineImgView.frame;
    if (CGRectIntersectsRect(lastFrame, onlineFrame))
    {
        lastFrame.origin.x = onlineFrame.origin.x - 5.f - lastFrame.size.width;
        
        firstFrame.size.width = lastFrame.origin.x - 5.f - firstFrame.origin.x;
        _firstNameLabel.frame = firstFrame;
    }
    
    _lastNameLabel.frame = lastFrame;
    
    _onlineImgView.hidden = ![user.online boolValue];
}

@end
