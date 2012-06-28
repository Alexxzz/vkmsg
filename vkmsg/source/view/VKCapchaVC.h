//
//  VKCapchaVC.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 03.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VKCapchaVCDelegate <NSObject>
- (void)capchaTextEntered:(NSString*)text;
@end

@interface VKCapchaVC : UIViewController <UITextFieldDelegate>
{
    IBOutlet UIImageView* _capchaImgView;
    IBOutlet UITextField* _textField;
    IBOutlet UILabel* _titleLabel;
}
@property(nonatomic,assign) id<VKCapchaVCDelegate> delegate;
@property(nonatomic,retain) NSString* capchaURL;

@end
