//
//  VKDialogCell.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 25.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKDialogCell.h"
#import "UIImageView+AFNetworking.h"
#import "VKLocationManager.h"

#define kTextWidth 240.f
#define kTextFont ([UIFont systemFontOfSize:15.f])
#define kTextOffset 15.f
#define kTextXOffset 5.f

#define kAttachmentOffset 5.f
#define kAttachmentSideSize 80.f
#define kAttachmentAudioHeight 30.f

@implementation VKDialogCell

#pragma mark - Class methods
+ (id)dialogCell
{
    VKDialogCell* res = nil;
    
    NSArray* objs = [[NSBundle mainBundle] loadNibNamed:@"VKDialogCell" 
                                                  owner:nil 
                                                options:nil];
    if (objs != nil)
    {
        for (id obj in objs)
        {
            if ([obj isKindOfClass:[VKDialogCell class]])
            {
                res = obj;
                break;
            }
        }
    }
    
    return res;
}

+ (NSString*)reuseID
{
    return @"VKDialogCell";
}

#pragma mark - Height
+ (CGFloat)heightForMessage:(VKMessage*)msg
{
    NSString* body = msg.body;
    
    CGSize maxSize = CGSizeMake(kTextWidth, MAXFLOAT);
    CGSize size = [body sizeWithFont:kTextFont 
                   constrainedToSize:maxSize 
                       lineBreakMode:UILineBreakModeWordWrap]; 
    
    NSInteger attachmentsCount = 0;
    NSInteger audioAttachmentsCount = 0;
    for (NSDictionary* attachDict in msg.attachments)
    {
        if ([[attachDict valueForKey:@"type"] isEqualToString:@"audio"])
            audioAttachmentsCount++;
        else
            attachmentsCount++;
    }
    if ([msg hasLocation] == YES)
        attachmentsCount++;
    
    float rows = ceilf((float)attachmentsCount / 3.f);
    CGFloat height = size.height + kTextOffset + (rows * 93.f);
    height += audioAttachmentsCount * kAttachmentAudioHeight;
    
    return height;
}

#pragma mark - Instance methods
- (void)dealloc
{
    [_attachmentsImgViews release];
    [_audioAttachments release];
    
    [super dealloc];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.backgroundView.frame;
    frame.origin.x = 0;
    frame.size.width = 320;
    self.backgroundView.frame = frame;
    
    frame = self.contentView.frame;
    frame.origin.x = 0;
    frame.size.width = 320;
    self.contentView.frame = frame;
}

#pragma mark - Attachments
- (void)onAttachment:(id)sender
{
    NSLog(@"Attachment clicked");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kVKNotificationAttachmentClicked 
                                                        object:nil 
                                                      userInfo:[sender attachDict]];
}

- (VKImgAttachmentView*)reuseImageViewWithIndex:(NSInteger)index
{
    VKImgAttachmentView* res = nil;
    
    if ([_attachmentsImgViews count] > index)
    {
        res = [_attachmentsImgViews objectAtIndex:index];
    }
    else
    {
        res = [VKImgAttachmentView imageAttachmentView];
        [res addTarget:self 
                action:@selector(onAttachment:) 
      forControlEvents:UIControlEventTouchDown | UIControlEventTouchUpInside];
        
        if (_attachmentsImgViews == nil)
            _attachmentsImgViews = [NSMutableArray new];
        
        [_attachmentsImgViews addObject:res];
    }
    
    if (res.superview == nil)
        [_containerView addSubview:res];
    
    return res;
}

- (void)removeUnusedImgViewsWithIndex:(NSInteger)index
{
    NSInteger count = [_attachmentsImgViews count];
    if (_attachmentsImgViews == nil || index >= count)
        return;
    
    NSArray* toRemove = [_attachmentsImgViews subarrayWithRange:NSMakeRange(index, count - index)];
    for (UIView* imgView in toRemove)
        [imgView removeFromSuperview];
}

- (VKAudioAttachmentView*)reuseAudioAttachmentWithIndex:(NSInteger)index
{
    VKAudioAttachmentView* res = nil;
    
    if ([_audioAttachments count] > index)
    {
        res = [_audioAttachments objectAtIndex:index];
    }
    else
    {        
        res = [VKAudioAttachmentView audioAttachmentView];
        [res addTarget:self 
                action:@selector(onAttachment:) 
      forControlEvents:UIControlEventTouchDown | UIControlEventTouchUpInside];
        
        if (_audioAttachments == nil)
            _audioAttachments = [NSMutableArray new];
        [_audioAttachments addObject:res];
    }
    
    return res;
}

- (void)removeUnusedAudioAttachmentsWithIndex:(NSInteger)idx
{
    NSInteger count = [_audioAttachments count];
    if (_audioAttachments == nil || idx >= count)
        return;
    
    NSArray* toRemove = [_audioAttachments subarrayWithRange:NSMakeRange(idx, count - idx)];
    for (UIView* imgView in toRemove)
        [imgView removeFromSuperview];
}

- (void)configAttachment:(VKAudioAttachmentView*)attach withDict:(NSDictionary*)attachDict
{ 
    NSDictionary* dict = [attachDict valueForKey:@"audio"];
    
    NSString* title = [dict valueForKey:@"title"];
    NSString* artist = [dict valueForKey:@"artist"];
    NSString* performer = [dict valueForKey:@"performer"];
    
    NSInteger duration = [[dict valueForKey:@"duration"] intValue];
    NSInteger h = duration / 3600;
    NSInteger m = duration / 60;
    NSInteger s = duration % 60;
    
    NSString* durationStr = nil;
    if (h != 0)
        durationStr = [NSString stringWithFormat:@"%.2d:%.2d:%.2d", h, m, s];
    else
        durationStr = [NSString stringWithFormat:@"%.2d:%.2d", m, s];
    
    attach.durationLabel.text = durationStr;
    
    if (artist != nil && [artist length] > 0)
        attach.artistLabel.text = artist;
    else
        attach.artistLabel.text = performer;
    
    if (title != nil && [title length] > 0)
        attach.titleLabel.text = title;
}

- (void)addAttachmentsForMsg:(VKMessage*)msg
{
    CGRect frame = _containerView.frame; 
    BOOL outMsg = [msg isOut];
    
    CGSize maxSize = CGSizeMake(kTextWidth, MAXFLOAT);
    CGSize textSize = [[msg body] sizeWithFont:kTextFont 
                         constrainedToSize:maxSize 
                             lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat x = 0.f;    
    CGFloat y = 0.f;
    CGFloat width = 0.f;
    NSInteger index = 0;
    NSInteger row = 0;
    NSInteger col = 0;
    
    NSMutableArray* audioAttachments = nil;
    
    //Photo/video
    if (msg.attachments != nil)
    {        
        for (NSDictionary* attachDict in msg.attachments)
        {
            NSString* type = [attachDict valueForKey:@"type"];
            
            BOOL video = [type isEqualToString:@"video"];
            BOOL photo = [type isEqualToString:@"photo"];
            
            if (video || photo)
            {            
                NSDictionary* photoDict = [attachDict valueForKey:type];
                NSString* urlStr = [photoDict valueForKey:@"src"];
                if (video == YES)
                    urlStr = [photoDict valueForKey:@"image"];
                
                VKImgAttachmentView* imgView = [self reuseImageViewWithIndex:index];           
                [imgView.imgView setImageWithURL:[NSURL URLWithString:urlStr]
                                placeholderImage:nil
                                         success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                            if (video == YES)
                                            {
                                                CGFloat scale = [[UIScreen mainScreen] scale];
                                                UIGraphicsBeginImageContextWithOptions(CGSizeMake(kAttachmentSideSize, kAttachmentSideSize), NO, scale);
                                                [image drawInRect:CGRectMake((kAttachmentSideSize - image.size.width)/2, 
                                                                             (kAttachmentSideSize - image.size.height)/2, 
                                                                             image.size.width, 
                                                                             image.size.height)];
                                                UIImage* playImg = [UIImage imageNamed:@"play_button.png"];
                                                [playImg drawInRect:CGRectMake(0, 0, kAttachmentSideSize, kAttachmentSideSize)];
                                                [imgView setImage:UIGraphicsGetImageFromCurrentImageContext()];
                                                UIGraphicsEndImageContext();
                                            }
                                         }
                                         failure:nil]; 
                imgView.attachDict = attachDict;
                
                col = index % 3;
                if (outMsg == YES)
                    x = kAttachmentOffset*2.f + ((kAttachmentOffset+kAttachmentSideSize)*col);
                else
                    x = kAttachmentOffset*2.8f + ((kAttachmentOffset+kAttachmentSideSize)*col);               
                
                row = index / 3;
                y = (kAttachmentOffset*2.f + textSize.height) + ((kAttachmentSideSize + kAttachmentOffset*1.5f)*row);
                
                imgView.frame = CGRectMake(x, y, kAttachmentSideSize, kAttachmentSideSize);
                
                width = MAX(width, x + kAttachmentSideSize + kAttachmentOffset*2.f);
                
                index++;
            }
            
            if ([type isEqualToString:@"audio"])
            {
                if (audioAttachments == nil)
                    audioAttachments = [NSMutableArray array];
                [audioAttachments addObject:attachDict];
            }
        }
    }
    //Location
    if ([msg hasLocation] == YES)
    {
        col = index % 3;
        row = index / 3;
        if (outMsg == YES)
            x = kAttachmentOffset*2.f + ((kAttachmentOffset+kAttachmentSideSize)*col);
        else
            x = kAttachmentOffset*2.8f + ((kAttachmentOffset+kAttachmentSideSize)*col); 
        y = (kAttachmentOffset*2.f + textSize.height) + ((kAttachmentSideSize + kAttachmentOffset*1.5f)*row);
        
        VKImgAttachmentView* imgView = [self reuseImageViewWithIndex:index];
        [imgView.imgView setImageWithURL:[VKLocationManager getURLForGoogleMapsWithLocation:[msg coordinate] 
                                                                                   withSize:CGSizeMake(kAttachmentSideSize, kAttachmentSideSize)]];
        imgView.frame = CGRectMake(x, y, kAttachmentSideSize, kAttachmentSideSize);
        imgView.attachDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"location", @"type",
                              [NSNumber numberWithFloat:[msg coordinate].latitude], @"lat",
                              [NSNumber numberWithFloat:[msg coordinate].longitude], @"lon",
                              nil];
        
        width = MAX(width, x + kAttachmentSideSize + kAttachmentOffset*2.f);
        
        index++;
    }
    
    [self removeUnusedImgViewsWithIndex:index];
    
    //Audio 
    NSInteger audioAttachCount = 0;
    if (audioAttachments != nil && [audioAttachments count] > 0)
    {
        row = index / 3;
        if (index > 0)
            row++;
        
        for (NSDictionary* audioDict in audioAttachments)
        {
            if (outMsg == YES)
                x = 10.f;
            else
                x = 13.f; 
            y = (kAttachmentOffset*1.f + textSize.height) + ((kAttachmentSideSize + kAttachmentOffset*1.5f)*row + kAttachmentAudioHeight*audioAttachCount);
            
            VKAudioAttachmentView* audioAttachment = [self reuseAudioAttachmentWithIndex:audioAttachCount];
            [self configAttachment:audioAttachment withDict:audioDict];
            CGRect frame = audioAttachment.frame;
            frame.origin.x = x;
            frame.origin.y = y;
            audioAttachment.frame = frame;
            [_containerView addSubview:audioAttachment];
            
            audioAttachment.attachDict = audioDict;
            
            audioAttachCount++;
        }
        
        if (width < 260.f)
            width = 260.f;
    }
    [self removeUnusedAudioAttachmentsWithIndex:audioAttachCount];
    
    if (outMsg == YES)
        width += kAttachmentOffset;
    
    frame.size.width = width;
    _containerView.frame = frame;
}

#pragma mark - Config
- (void)configWithMessage:(VKMessage*)msg
{
    if (msg == nil)
        return;
    
    BOOL outMsg = [msg isOut];
    CGRect selfFrame = self.frame;    
    selfFrame.size.width = 320.f;
    CGRect labelFrame = _timeLabel.frame;
    
    NSString* body = msg.body;
    
    //Attachment
    [self addAttachmentsForMsg:msg];
    
    CGRect frame = _containerView.frame; 
    
    CGSize maxSize = CGSizeMake(kTextWidth, MAXFLOAT);
    CGSize size = [body sizeWithFont:kTextFont 
                   constrainedToSize:maxSize 
                       lineBreakMode:UILineBreakModeWordWrap];
    if (frame.size.width < size.width + 25.f)
        frame.size.width = size.width + 25.f;
    
    //Size and placement 
    UIImage* bubbleImg = nil;
    if (outMsg)
    {
        bubbleImg = [UIImage imageNamed:@"Blue_Bubble.png"];
        
        frame.origin.x = selfFrame.size.width - (frame.size.width + kTextXOffset);        
        labelFrame.origin.x = selfFrame.size.width - (labelFrame.size.width + frame.size.width + kTextXOffset * 1.f);
    }
    else
    {
        bubbleImg = [UIImage imageNamed:@"Grey_Bubble.png"];
        
        frame.origin.x = kTextXOffset;        
        labelFrame.origin.x = frame.size.width + kTextXOffset * 1.4f;
    }
    _timeLabel.frame = labelFrame;
    _containerView.frame = frame;
    
    if ([msg.read_state boolValue] == NO)
        self.backgroundView.backgroundColor = [UIColor colorWithRed:199.f/255.f green:211.f/255.f blue:227.f/255.f alpha:0.8f];
    else
        self.backgroundView.backgroundColor = [UIColor clearColor];    
    
    _textView.text = body;
    
    NSDate* date = [NSDate dateWithTimeIntervalSinceReferenceDate:[msg.date integerValue]];
    _timeLabel.text = [VKHelper hhmmFromDate:date];
     
    _boubleImgView.image = [bubbleImg stretchableImageWithLeftCapWidth:bubbleImg.size.width/2 
                                                          topCapHeight:bubbleImg.size.height/2];
}

@end


#pragma mark - VKAudioAttachmentView
@implementation VKAudioAttachmentView
@synthesize audioImgView, artistLabel, titleLabel, durationLabel, attachDict;

+ (id)audioAttachmentView
{
    VKAudioAttachmentView* res = nil;
    
    NSArray* objs = [[NSBundle mainBundle] loadNibNamed:@"VKDialogCell" 
                                                  owner:nil 
                                                options:nil];
    if (objs != nil)
    {
        for (id obj in objs)
        {
            if ([obj isKindOfClass:[VKAudioAttachmentView class]])
            {
                res = obj;
                [res sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            }
        }
    }
    
    return res;
} 

- (void)dealloc
{
    [attachDict release];
    
    [super dealloc];
}

@end

#pragma mark - VKImgAttachmentView
@implementation  VKImgAttachmentView

@synthesize imgView = _imgView;
@synthesize attachDict;

+ (id)imageAttachmentView
{    
    return [[VKImgAttachmentView new] autorelease];
}

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, kAttachmentSideSize, kAttachmentSideSize)];
    if (self != nil)
    {
        _imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kAttachmentSideSize, kAttachmentSideSize)];
        _imgView.contentMode = UIViewContentModeScaleAspectFit;
        [self sendActionsForControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_imgView];
    }
    
    return self;
}

- (void)setImage:(UIImage*)img
{
    _imgView.image = img;
}

- (void)dealloc
{
    [_imgView release];
    [attachDict release];
    
    [super dealloc];
}

@end
