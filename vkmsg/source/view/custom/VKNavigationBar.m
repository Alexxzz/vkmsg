//
//  VKNavigationBar.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 24.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKNavigationBar.h"

@implementation VKNavigationBar

@synthesize backgroundImg;

- (void)dealloc
{
    self.backgroundImg = nil;
    
    [super dealloc];
}

- (void)setBackgroundImg:(UIImage *)backgroundImg_
{
    if ([backgroundImg isEqual:backgroundImg_] == NO)
    {
        [backgroundImg release];
        backgroundImg = [backgroundImg_ retain];
        
        [self setNeedsDisplay];
    }
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (backgroundImg != nil) 
    {
        [backgroundImg drawAtPoint:CGPointMake(0, 0)];
    }
}


@end
