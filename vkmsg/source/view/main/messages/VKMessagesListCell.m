//
//  VKMessagesListCell.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 21.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKMessagesListCell.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>

@implementation VKMessagesListCell

+ (NSString*)reuseId
{
    return @"VKMessagesListCell";
}

+ (id)messagesCell
{    
    VKMessagesListCell* res = nil;
    
    NSArray* objs = [[NSBundle mainBundle] loadNibNamed:@"VKMessagesListCell" 
                                                  owner:nil 
                                                options:nil];
    
    for (id obj in objs)
    {
        if ([obj isKindOfClass:[VKMessagesListCell class]])
        {
            res = obj;
            
            CALayer* layer = res->_avatarImageView.layer;
            layer.masksToBounds = YES;
            layer.cornerRadius = 3.f;  
            
            break;
        }
    }
    
    return res;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
    }
    return self;
}

- (void)setOnlineState:(BOOL)online
{
    _onlineImageView.hidden = !online;
}

- (void)configWithMessage:(VKMessage*)msg
{
    VKUser* user = [Storage userWithId:msg.uid];
    
    NSTimeInterval ti = [msg.date doubleValue];
    _timeLabel.text = [VKHelper formatedElapsedTimeFromDate:[NSDate dateWithTimeIntervalSince1970:ti] detailed:NO];
    [_timeLabel sizeToFit];
    CGRect frame = _timeLabel.frame;
    frame.origin.x = self.frame.size.width - (frame.size.width + 10.f);
    _timeLabel.frame = frame;
    
    _onlineImageView.hidden = ![user.online boolValue];
    frame = _onlineImageView.frame;
    frame.origin.x = _timeLabel.frame.origin.x - (frame.size.width + 4.f);
    _onlineImageView.frame = frame;
    
    _nickLabel.text = [NSString stringWithFormat:@"%@ %@", user.first_name, user.last_name];
    frame = _nickLabel.frame;
    frame.size.width = _onlineImageView.frame.origin.x - (_avatarImageView.frame.origin.x + _avatarImageView.frame.size.width + 10.f);
    
    _detailLabel.text = msg.body;
    
    if ([msg.read_state boolValue] == NO && [msg.out boolValue] == NO)
        self.backgroundView.backgroundColor = [UIColor colorWithRed:199.f/255.f green:211.f/255.f blue:227.f/255.f alpha:0.35f];
    else
        self.backgroundView.backgroundColor = [UIColor clearColor];
    
    NSURL* avatarUrl = [NSURL URLWithString:user.photo_rec];
    if (avatarUrl != nil)
    {
        [_avatarImageView setImageWithURL:avatarUrl
                         placeholderImage:[UIImage imageNamed:@"Header_Avatar.png"]];          
    }
}

@end
