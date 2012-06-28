//
//  VKCapchaVC.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 03.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKCapchaVC.h"
#import "UIImageView+AFNetworking.h"

@implementation VKCapchaVC

@synthesize capchaURL, delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    self.capchaURL = nil;
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_capchaImgView setImageWithURL:[NSURL URLWithString:self.capchaURL]];
    [_textField becomeFirstResponder];
}

#pragma mark - UITextField delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (delegate != nil && [delegate respondsToSelector:@selector(capchaTextEntered:)])
        [delegate capchaTextEntered:textField.text];
    
    return YES;
}

@end
