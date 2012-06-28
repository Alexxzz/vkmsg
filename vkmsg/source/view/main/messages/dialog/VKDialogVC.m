//
//  VKDialogVC.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 24.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKDialogVC.h"
#import "VKDialogCell.h"
#import "VKApi.h"
#import "VKCapchaVC.h"
#import "VKLongPollServerController.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "VKMapVC.h"
#import <MediaPlayer/MediaPlayer.h>
#import "NIPhotoScrollView.h"

#define kTableHeight 375.f

@interface VKDialogVC()
- (void)scrollToLastMessageAnimated:(BOOL)animated;
- (void)hideTypingFooter;
@end

@implementation VKDialogVC

@synthesize uid;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _lastTypingSentDate = [[NSDate date] retain];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    
    self.uid = nil;
    [_dialog release];
    [_text release];
    [_capchaSid release];
    [_serviceTimer invalidate];
    [_serviceTimer release];
    [_lastTypingIncDate release];
    [_lastTypingSentDate release];
    [_readMids release];
    
    [_user release];
    [_lastActivityDate release];
    
    [_attachImage release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

#pragma mark - Notification
- (void)onKeyboardWillShowNotification:(NSNotification*)notification
{
    _keyboardVisible = YES;
    
    if (_attachmentButton.selected == YES)
    {
        _attachmentButton.selected = NO;
        return;
    }
    
    NSDictionary* userInfo = [notification userInfo];
    NSValue* valRect = [userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keybFrame = CGRectZero;
    [valRect getValue:&keybFrame];
    
    __block CGRect tableRect = _tableView.frame;
    tableRect.origin.y = tableRect.origin.y - keybFrame.size.height;
    
    CGRect sendViewRect = _sendView.frame;
    sendViewRect.origin.y -= keybFrame.size.height;
    
    NSNumber* animationDuration = [userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];    
    [UIView animateWithDuration:[animationDuration doubleValue] 
                     animations:^{
                         _sendView.frame = sendViewRect;
                         _tableView.frame = tableRect;
                     }
                     completion:^(BOOL finished) {
                         tableRect.origin.y = 0;
                         tableRect.size.height = tableRect.size.height - keybFrame.size.height;
                         _tableView.frame = tableRect;      
                         
                         [_tableView setContentOffset:CGPointMake(0, _tableView.contentSize.height - _tableView.bounds.size.height) 
                                             animated:NO];
     }];
}

- (void)onKeyboardWillHideNotification:(NSNotification*)notification
{
    _keyboardVisible = NO;
    
    if (_attachmentButton.selected == YES || _attachmentButton.highlighted == YES)
        return;
    
    [_attachmentsView removeFromSuperview];
    
    NSDictionary* userInfo = [notification userInfo];
    
    __block CGRect tableRect = [_tableView frame];
    tableRect.origin.y = tableRect.size.height - kTableHeight;
    tableRect.size.height = kTableHeight;   
    _tableView.frame = tableRect;
    
    CGRect sendViewRect = _sendView.frame;
    sendViewRect.origin.y = self.view.frame.size.height - sendViewRect.size.height;
    
    NSNumber* animationDuration = [userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];    
    [UIView animateWithDuration:[animationDuration doubleValue] 
                     animations:^{
                         tableRect.origin.y = 0.f;
                         _tableView.frame = tableRect;
                         _sendView.frame = sendViewRect;
                     }
                     completion:^(BOOL finished) {
                         [_tableView setContentOffset:CGPointMake(0, _tableView.contentSize.height - _tableView.bounds.size.height) 
                                             animated:YES];
     }];
}

- (void)showOfflineFooter:(BOOL)show
{
    NSString* date = [VKHelper formatedElapsedTimeFromDate:_lastActivityDate detailed:YES];
    NSString* text = [NSString stringWithFormat:@"%@ was online %@", _user.first_name, date];
    _offlineLabel.text = text;
    
    _tableView.tableFooterView = _offlineFooterView;
    [_tableView setContentOffset:CGPointMake(0, _tableView.contentSize.height - _tableView.bounds.size.height) 
                        animated:YES];
}

- (void)getLastActivityForFriend
{
    [VKApi getLastActivityForUserId:uid 
                            success:^(BOOL online, NSDate *lastActivity) {
                                _user.online = [NSNumber numberWithBool:online];
                                [_lastActivityDate release];
                                _lastActivityDate = [lastActivity retain];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self showOfflineFooter:!online];
                                });
                                
                            } failure:^(NSError *error, NSDictionary *errDict) {
                                
                            }];
}

- (void)setOnlineStatus
{
    BOOL isOnline = [_user.online boolValue];
    if (isOnline == YES)
    {
        _onlineOfflineLabel.text = kStrOnline;
    }
    else
    {
        _onlineOfflineLabel.text = nil;
        
        [self getLastActivityForFriend];
    }
}

- (void)onLongPollUpdates:(NSNotification*)notification
{
    NSArray* updates = [[notification userInfo] valueForKey:kVKLongPollUpdatesKey];
    
    NSMutableArray* indexPathsForUpdate = [NSMutableArray arrayWithCapacity:[updates count]];
    
    for (VKLongPollUpdate* update in updates)
    {
        if (update.userId != nil && [update.userId isEqualToNumber:uid] == NO)
            continue;
        
        switch (update.type) 
        {
            //New message
            case eVKLongPollUpdateType_msgNew:
            {
                [_tableView reloadData];
                
                [self scrollToLastMessageAnimated:YES];
                
                [self hideTypingFooter];
                
                break;
            }
            //Typing
            case eVKLongPollUpdateType_chatTyping:
            {
                _tableView.tableFooterView = _typingFooter;
                [_tableView setContentOffset:CGPointMake(0, _tableView.contentSize.height - _tableView.bounds.size.height) 
                                    animated:YES];
                
                [_lastTypingIncDate release];
                _lastTypingIncDate = [[NSDate date] retain];
                
                break;
            }
            //Message read state changed                    
            case eVKLongPollUpdateType_msgReadStateChanged:
            {           
                VKMessage* msgUpdated = [Storage messageWithId:update.msgId];
                NSIndexPath* idxPath = [_dialog indexPathForMessage:msgUpdated];
                if (idxPath != nil)
                    [indexPathsForUpdate addObject:idxPath];
                
                break;
            }
            //User went online
            case eVKLongPollUpdateType_userOnline:
            {
                [self setOnlineStatus];
                break;
            }
            //User went offline
            case eVKLongPollUpdateType_userOffline:
            {
                [self setOnlineStatus];
                break;
            }
                
            default:
                break;
        }
    }
    
    if ([indexPathsForUpdate count] > 0)
        [_tableView reloadRowsAtIndexPaths:indexPathsForUpdate
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void)onAttachmentsReady:(NSNotification*)notification
{
    VKMessage* msg = [notification.userInfo valueForKey:@"message"];
    if ([msg.uid isEqualToNumber:uid])
    {
        NSArray* visibleCellsIdxPath = [_tableView indexPathsForVisibleRows];
        [_tableView beginUpdates];
        [_tableView reloadRowsAtIndexPaths:visibleCellsIdxPath 
                          withRowAnimation:UITableViewRowAnimationNone];
        [_tableView endUpdates];
        
        [self scrollToLastMessageAnimated:YES];
        
        [AppDel hideWaitingView];
    }
}

- (NSURL*)getTheLargestImageUrlFromAttachment:(NSDictionary*)attachDict
{
    NSString* urlStr = nil;
    
    urlStr = [attachDict valueForKey:@"src_xxxbig"];
    if (urlStr != nil)
        return [NSURL URLWithString:urlStr];
    
    urlStr = [attachDict valueForKey:@"src_xxbig"];
    if (urlStr != nil)
        return [NSURL URLWithString:urlStr]; 
    
    urlStr = [attachDict valueForKey:@"src_xbig"];
    if (urlStr != nil)
        return [NSURL URLWithString:urlStr]; 
    
    urlStr = [attachDict valueForKey:@"src_big"];
    if (urlStr != nil)
        return [NSURL URLWithString:urlStr]; 
    
    urlStr = [attachDict valueForKey:@"src"];
    if (urlStr != nil)
        return [NSURL URLWithString:urlStr];
    
    return nil;
}

- (void)onAttachmentClicked:(NSNotification*)notification
{
    NSDictionary* dict = notification.userInfo;
    
    NSString* attachmentType = [dict valueForKey:@"type"];    
    NSDictionary* attachDict = [dict valueForKey:attachmentType];
    if ([attachmentType isEqualToString:@"audio"])
    {
        NSString* audioUrlStr = [attachDict valueForKey:@"url"];
        
        MPMoviePlayerViewController* mpCtrl =  [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:audioUrlStr]];
        [self presentMoviePlayerViewControllerAnimated:mpCtrl];
        [mpCtrl autorelease];
    }
    else if ([attachmentType isEqualToString:@"video"])
    {
        [VKApi getVideoUrlWithVid:[attachDict valueForKey:@"vid"]
                          forUser:[attachDict valueForKey:@"owner_id"] 
                          success:^(NSDictionary *urls) {
                              NSString* audioUrlStr = [urls valueForKey:@"mp4_480"];
                              
                              MPMoviePlayerViewController* mpCtrl =  [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:audioUrlStr]];
                              [self presentMoviePlayerViewControllerAnimated:mpCtrl];
                              [mpCtrl autorelease];
                          } failure:^(NSError *error, NSDictionary *errDict) {
                              
                          }];
    }
    else if ([attachmentType isEqualToString:@"location"])
    {
        VKMapVC* mapView = [VKMapVC new];
        CGFloat lat = [[dict valueForKey:@"lat"] floatValue];
        CGFloat lon = [[dict valueForKey:@"lon"] floatValue];
        mapView.attachmentCoordinate = CLLocationCoordinate2DMake(lat, lon);
        [self.navigationController pushViewController:mapView 
                                             animated:YES];
        [mapView release];
    }
    else if ([attachmentType isEqualToString:@"photo"])
    {
        NSURL* url = [self getTheLargestImageUrlFromAttachment:attachDict];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url 
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                                           timeoutInterval:30.0];
        [request setHTTPShouldHandleCookies:NO];
        [request setHTTPShouldUsePipelining:YES];
        
        [AppDel showWaitingView];
        AFImageRequestOperation* imgRequestOper = [AFImageRequestOperation imageRequestOperationWithRequest:request 
                                                                                       imageProcessingBlock:nil 
                                                                                                  cacheName:nil 
                                                                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                                                        [AppDel hideWaitingView];
                                                                                                        
                                                                                                        UIViewController* photoVc = [UIViewController new];        
                                                                                                        NIPhotoScrollView* photoView = [[NIPhotoScrollView alloc] initWithFrame:self.view.bounds];
                                                                                                        [photoView setImage:image
                                                                                                                  photoSize:NIPhotoScrollViewPhotoSizeThumbnail];
                                                                                                        photoVc.view = photoView;
                                                                                                        [self.navigationController pushViewController:photoVc 
                                                                                                                                             animated:YES];
                                                                                                        [photoView release];
                                                                                                        [photoVc release];   
                                                                                                    } 
                                                                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                                                        [AppDel hideWaitingView];
                                                                                                    }];
        [imgRequestOper start];
    }
}

#pragma mark - Typing
- (void)hideTypingFooter
{
    _tableView.tableFooterView = nil;
    [_tableView setContentOffset:CGPointMake(0, _tableView.contentSize.height - _tableView.bounds.size.height) 
                        animated:YES];
}

#pragma mark - Service timer
- (void)onServiceTimer:(NSTimer*)theTimer
{
    //Typing
    if (-[_lastTypingIncDate timeIntervalSinceNow] >= 5 && _tableView.tableFooterView != nil)
        [self hideTypingFooter];
    
    //Mark as read
    if ([_readMids count] > 0)
    {
        NSArray* messagesWillBeRed = [NSArray arrayWithArray:[_readMids allObjects]];
        [VKApi markAsReadMessages:messagesWillBeRed 
                          success:^{
                              @synchronized(_readMids)
                              {
                                  for (id obj in messagesWillBeRed)
                                      [_readMids removeObject:obj];
                              }
                          } failure:^(NSError *error, NSDictionary *errDict) {
                              
                          }];
    }
}

#pragma mark - Tap gesture
- (void)onTableTap:(UIGestureRecognizer*)gesture
{
    [_inputTextView resignFirstResponder];
}

#pragma mark - View lifecycle
- (void)setAvatarWithUrl:(NSString*)urlStr
{
    [_avatarImageView setImageWithURL:[NSURL URLWithString:urlStr]];
    
    CALayer* layer = _avatarImageView.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = 5.f;
    
    UIBarButtonItem* bbi = [[UIBarButtonItem alloc] initWithCustomView:_avatarView];
    self.navigationItem.rightBarButtonItem = bbi;
    [bbi release];
}

- (void)onLoadMoreButton
{
    _dialog.offset += kInitialMsgCount;
    [AppDel showWaitingView];
    [VKApi getMessagesHistoryForId:uid
                             count:kInitialMsgCount 
                            offset:_dialog.offset
                           success:^(NSArray *messages, NSInteger count) {                               
                               [_dialog addMessages:messages];
                               
                               NSIndexPath* idx = [_dialog indexPathForMessage:[messages lastObject]];
                               
                               [_tableView reloadData];
                               [_tableView scrollToRowAtIndexPath:idx 
                                                 atScrollPosition:UITableViewScrollPositionTop
                                                         animated:NO];
                               
                               [AppDel hideWaitingView];
                           } failure:^(NSError *error, NSDictionary *errDict) {
                               [AppDel hideWaitingView];
                           }];
}

- (void)getDialog
{
    _dialog = [[Storage.dialogs objectForKey:uid] retain];
    if (_dialog == nil)
    {
        [AppDel showWaitingView];
        [VKApi getMessagesHistoryForId:uid
                                 count:kInitialMsgCount 
                                offset:0
                               success:^(NSArray *messages, NSInteger count) {
                                   _dialog = [[VKDialogContainer alloc] initWithMessagesArray:messages count:count];
                                   [Storage.dialogs setObject:_dialog forKey:uid];
                                   [_tableView reloadData];
                                   [self scrollToLastMessageAnimated:NO];
                                   [AppDel hideWaitingView];
                                   
                                   _dialog.onLoadMoreButtonTarget = self;
                                   _dialog.onLoadMoreButtonSelector = @selector(onLoadMoreButton);
                               } failure:^(NSError *error, NSDictionary *errDict) {
                                   [AppDel hideWaitingView];
                                   [self dismissModalViewControllerAnimated:YES];
                               }];
    }
    else
    {
        _dialog.onLoadMoreButtonTarget = self;
        _dialog.onLoadMoreButtonSelector = @selector(onLoadMoreButton);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage* img = [UIImage imageNamed:@"InputField.png"];
    _inputBackImgView.image = [img stretchableImageWithLeftCapWidth:img.size.width/2 
                                                       topCapHeight:img.size.height/2];
    img = [UIImage imageNamed:@"Msg_LowBar.png"];
    _inputBackgroundImgView.image = [img stretchableImageWithLeftCapWidth:img.size.width/2 
                                                             topCapHeight:img.size.height/2];
    
    //Get dialog
    [self getDialog];
    
    //Navbar
    _user = [[Storage userWithId:uid] retain];
    self.navigationItem.title = [_user first_name];
    [self setOnlineStatus];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onKeyboardWillShowNotification:) 
                                                 name:UIKeyboardWillShowNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onKeyboardWillHideNotification:) 
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onLongPollUpdates:) 
                                                 name:kVKNotificationLongPollUpdates
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAttachmentsReady:) 
                                                 name:kVKNotificationMessageAttachmentsReady 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onAttachmentClicked:) 
                                                 name:kVKNotificationAttachmentClicked 
                                               object:nil];
    
    //Tap gesture
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self 
                                                                                 action:@selector(onTableTap:)];
    [_tableView addGestureRecognizer:tapGesture];
    [tapGesture release];
    
    //Service timer
    _serviceTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] 
                                                 interval:5
                                                   target:self 
                                                 selector:@selector(onServiceTimer:) 
                                                 userInfo:nil 
                                                  repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_serviceTimer 
                              forMode:NSDefaultRunLoopMode];
    [_serviceTimer fire];
    
    //Attachments
    if ([Storage isFavouriteUid:uid] == YES)
        [_addToFavButton setTitle:kStrRemoveFromFavourites forState:UIControlStateNormal];
    else
        [_addToFavButton setTitle:kStrAddToFavourites forState:UIControlStateNormal];
    [VKHelper addGradient:_addToFavButton];
    [VKHelper addGradient:_addUserToConvButton];
    
    _inputTextView.text = kStrWriteMessage;
    _inputTextView.textColor = [UIColor colorWithRed:159.f/255.f green:159.f/255.f blue:159.f/255.f alpha:1.f];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_dialog release];
    [_serviceTimer invalidate];
    [_serviceTimer release];
    
    [_user release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self scrollToLastMessageAnimated:NO];
    
    VKUser* user = [Storage userWithId:uid];    
    [self setAvatarWithUrl:user.photo_rec];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_inputTextView resignFirstResponder];
}

- (void)scrollToLastMessageAnimated:(BOOL)animated
{
    NSInteger section = [_tableView numberOfSections] - 1;
    if (section < 0)
        return;
    NSInteger row = [_tableView numberOfRowsInSection:section] - 1;
    if (row < 0)
        return;
    
    NSIndexPath* lastMsg = [NSIndexPath indexPathForRow:row inSection:section];
    [_tableView scrollToRowAtIndexPath:lastMsg 
                      atScrollPosition:UITableViewScrollPositionBottom 
                              animated:animated];
}

#pragma mark - Marking as read
- (void)markMsgAsRead:(VKMessage*)msg
{
    @synchronized(_readMids)
    {
        if (_readMids == nil)
            _readMids = [NSMutableSet new];
        
        [_readMids addObject:msg.mid];
    }
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.0f;
    
    VKMessage* msg = [_dialog messageForIndexPath:indexPath];
    height = [VKDialogCell heightForMessage:msg];
    
    return height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dialog messagesCountForSection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_dialog sectionsCount];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section 
{
    UIView* headerView = [_dialog headerViewForSection:section];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([_dialog count] > kInitialMsgCount && section == 0)
        return [VKDialogContainer loadMoreSectionHeight];
    else
        return [VKDialogContainer sectionHeaderHeight];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* reuseId = [VKDialogCell reuseID]; 
    VKDialogCell* cell = [_tableView dequeueReusableCellWithIdentifier:reuseId];
    
    if (cell == nil)
        cell = [VKDialogCell dialogCell];
    
    VKMessage* msg = [_dialog messageForIndexPath:indexPath]; 
    [cell configWithMessage:msg];
    
    //Mark as read
    if ([msg isOut] == NO && [msg.read_state boolValue] == NO)
        [self markMsgAsRead:msg];
    
    CGRect frame = cell.contentView.frame;
    frame.origin.x = 0;
    frame.size.width = 320;
    cell.contentView.frame = frame;
    
    return cell;
}

#pragma mark - Captcha
- (void)onCapchaRequested:(NSDictionary*)dict
{    
    VKCapchaVC* capchaVC = [VKCapchaVC new];
    capchaVC.capchaURL = [dict valueForKey:@"captcha_img"];
    capchaVC.delegate = self;
    
    [_capchaSid release];
    _capchaSid = [[dict valueForKey:@"captcha_sid"] retain];
    
    [self.navigationController presentModalViewController:capchaVC 
                                                 animated:YES];
    [capchaVC release];
}

#pragma mark - IBActions
- (void)sendMessage:(NSString*)text withPhotoAttachment:(VKPhotoAttachment*)photoAttachment withLocationAttachment:(CLLocation*)location
{    
    [VKApi sendDialogMessageToUser:uid 
                           message:text 
                        attachment:photoAttachment
                               lat:location.coordinate.latitude
                               lon:location.coordinate.longitude
                           success:^(NSString *msgId) {  
                           } failure:^(NSError *error, NSDictionary* errDict) {
                               NSInteger error_code = [[errDict valueForKey:@"error_code"] intValue];
                               
                               if (error_code == 14) // Captcha
                               {
                                   [self onCapchaRequested:errDict];
                               }
                           }];
}
- (IBAction)onSendButton:(id)sender
{
    //Photo
    if (_attachImage != nil)
    {
        [AppDel showWaitingView];
        
        [VKApi uploadImage:_attachImage 
                   success:^(VKPhotoAttachment *attachment) {
                       //Text
                       NSString* text = nil;
                       if (_inputTextView.text != nil || [_inputTextView.text length] > 0)
                       {
                           [_text release];
                           text = _text = [_inputTextView.text retain];
                           
                           _inputTextView.text = nil;
                       }
                       
                       [self sendMessage:text withPhotoAttachment:attachment withLocationAttachment:nil];
                   } failure:^(NSError *error, NSDictionary *errDict) {
                       
                   }];
        
        [_attachImage release], _attachImage = nil;
    }
    else if (_attachLocation != nil)
    {
        [AppDel showWaitingView];
        
        NSString* text = nil;
        if (_inputTextView.text != nil || [_inputTextView.text length] > 0)
        {
            [_text release];
            text = _text = [_inputTextView.text retain];
            
            _inputTextView.text = nil;
        }
        
        [self sendMessage:text withPhotoAttachment:nil withLocationAttachment:_attachLocation];
        _attachLocation = nil;
    }
    else
    {
        //Text
        if (_inputTextView.text == nil || [_inputTextView.text length] == 0)
            return;
        
        [_text release];
        _text = [_inputTextView.text retain];
        
        _inputTextView.text = nil;
        
        [self sendMessage:_text withPhotoAttachment:nil withLocationAttachment:nil];
    }
    
    _photoAttButton.selected = NO;
    _galleryAttButton.selected = NO;
    _locationAttButton.selected = NO;
     
    /*
    [VKApi testCaptchaSuccess:^(NSDictionary *params) {
        
    } failure:^(NSError *error) {
        
    }];
     */
}
- (IBAction)onAttachmentsButton:(id)sender
{    
    _attachmentButton.selected = !_attachmentButton.selected;
    
    CGRect frame = _attachmentsView.frame;
    CGRect sendFrame = _sendView.frame;
    
    __block CGRect tableFrame = _tableView.frame;
    
    if (_attachmentsView.superview == nil)
    {
        frame.origin.y = self.view.frame.size.height;
        _attachmentsView.frame = frame;
        [self.view addSubview:_attachmentsView];
    }
    
    NSLog(@"_keyboardVisible %d", _keyboardVisible);
    if (_keyboardVisible == YES)
    {
        frame.origin.y = self.view.frame.size.height - frame.size.height;
        _attachmentsView.frame = frame;
        
        [_inputTextView resignFirstResponder];
        
        return;
    }
    
    [_inputTextView resignFirstResponder];
    
    if (_attachmentButton.selected == YES)
    {
        frame.origin.y = self.view.frame.size.height - frame.size.height;        
        tableFrame.origin.y = tableFrame.origin.y - frame.size.height;
    }
    else
    {
        frame.origin.y = self.view.frame.size.height;        
        tableFrame.origin.y = tableFrame.size.height - kTableHeight;
        tableFrame.size.height = kTableHeight;    
        _tableView.frame = tableFrame;
        tableFrame.origin.y = 0.f;
    }
    
    sendFrame.origin.y = frame.origin.y - sendFrame.size.height;
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         _attachmentsView.frame = frame;
                         _sendView.frame = sendFrame;
                         _tableView.frame = tableFrame;
                     }
     completion:^(BOOL finished) {
         tableFrame.origin.y = 0;
         tableFrame.size.height = sendFrame.origin.y + 9.f;
         _tableView.frame = tableFrame;      
         
         [_tableView setContentOffset:CGPointMake(0, _tableView.contentSize.height - _tableView.bounds.size.height) 
                             animated:NO];
     }];
}

- (IBAction)onAddRemoveFav:(id)sender
{
    if ([Storage isFavouriteUid:uid] == NO)
    {
        [_addToFavButton setTitle:kStrRemoveFromFavourites forState:UIControlStateNormal];
        
        [Storage addToFavsUid:uid];
    }
    else
    {
        [_addToFavButton setTitle:kStrAddToFavourites forState:UIControlStateNormal];
        
        [Storage removeFromFav:uid];
    }
}
- (IBAction)onAddUserToConv:(id)sender
{
    
}

- (IBAction)onAttachFromCamera:(id)sender
{
    _photoAttButton.selected = !_photoAttButton.selected;
    
    if (_photoAttButton.selected == YES)
    {
        _galleryAttButton.selected = NO;
        _locationAttButton.selected = NO;
        
        [_attachImage release], _attachImage = nil;
        _attachLocation = nil;
        
        UIImagePickerController* imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imgPicker.allowsEditing = YES;
        imgPicker.delegate = self;
        [self presentModalViewController:imgPicker animated:YES];
        [imgPicker release];
    }
}
- (IBAction)onAttachFromGallery:(id)sender
{
    _galleryAttButton.selected = !_galleryAttButton.selected;
    
    if (_galleryAttButton.selected == YES)
    {
        _photoAttButton.selected = NO;
        _locationAttButton.selected = NO;
        
        [_attachImage release], _attachImage = nil;
        _attachLocation = nil;
        
        UIImagePickerController* imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imgPicker.allowsEditing = YES;
        imgPicker.delegate = self;
        [self presentModalViewController:imgPicker animated:YES];
        [imgPicker release];
    }
}
- (IBAction)onAttachLocation:(id)sender
{
    _locationAttButton.selected = !_locationAttButton.selected;
    
    if (_locationAttButton.selected == YES)
    {
        _photoAttButton.selected = NO;
        _galleryAttButton.selected = NO;
        
        [_attachImage release], _attachImage = nil;
        
        [[VKLocationManager instance] getLocationSuccess:^(CLLocation* location) {
            NSLog(@"getLocation: %@", location);
            _attachLocation = location;            
        } failure:^(NSError* error) {
            NSLog(@"getLocation failed: %@", error);
        }];
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:kStrWriteMessage])
    {
        textView.text = nil;
        textView.textColor = [UIColor blackColor];
    }
    
    _sendButton.enabled = YES;
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if (textView.text == nil || [textView.text length] == 0)
    {
        textView.text = kStrWriteMessage;
        textView.textColor = [UIColor colorWithRed:159.f/255.f green:159.f/255.f blue:159.f/255.f alpha:1.f];
    }
    
    _sendButton.enabled = NO;
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSTimeInterval timeElapsed = [[NSDate date] timeIntervalSinceDate:_lastTypingSentDate];
    if (timeElapsed > 6)
    {
        [_lastTypingSentDate release];
        _lastTypingSentDate = [[NSDate date] retain];
        [VKApi sendTypingActivityForDialogWithUserId:uid 
                                             success:^{
                                                 NSLog(@"typing send");
                                             } failure:^(NSError *error, NSDictionary *errDict) {
                                                 
                                             }];
    }
}

#pragma mark - VKCapchaVCDelegate
- (void)capchaTextEntered:(NSString*)key
{
    [VKApi sendDialogMessageToUser:uid 
                           message:_text
                        attachment:nil
                               lat:0
                               lon:0
                         capchaKey:key 
                         capchaSid:_capchaSid 
                           success:^(NSString *msgId) {
                               [self.navigationController dismissModalViewControllerAnimated:YES];
                               _inputTextView.text = nil;
                           } 
                           failure:^(NSError *error, NSDictionary* errDict) {
                               NSInteger error_code = [[errDict valueForKey:@"error_code"] intValue];
                               
                               if (error_code == 14) // Captcha
                               {
                                   [self onCapchaRequested:errDict];
                               }
                           }];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [_attachImage release];
    _attachImage = [[info valueForKey:UIImagePickerControllerEditedImage] retain];
    
    [self dismissModalViewControllerAnimated:YES];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
    
    [_attachImage release], _attachImage = nil;
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
        _photoAttButton.selected = NO;
    else if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
        _galleryAttButton.selected = NO;
}

@end