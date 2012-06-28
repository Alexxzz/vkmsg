//
//  VKAddressBookPerson.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 11.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKAddressBookPerson.h"

@implementation VKAddressBookPerson

@synthesize uid, firstName, lastName, nickName, phones, emails, avatar;

+ (NSString*)MSISDNFormatedPhone:(NSString*)unformated
{
    static NSMutableCharacterSet* numbers = nil;
    if (numbers == nil)
    {
        numbers = [[NSMutableCharacterSet decimalDigitCharacterSet] retain];
        [numbers invert];
    }
    
    NSMutableString* unformatedMut = [NSMutableString stringWithString:unformated];
    NSRange range = [unformatedMut rangeOfCharacterFromSet:numbers];
	while (range.location != NSNotFound) 
	{
		[unformatedMut deleteCharactersInRange:range];
		range = [unformatedMut rangeOfCharacterFromSet:numbers];
	}
    
    return [[unformatedMut copy] autorelease];
}

- (id)initWithABRecord:(ABRecordRef)abRecord
{
    self = [super init];
    if (self != nil)
    {
        [self loadFromRecord:abRecord];
    }
    return self;
}

- (NSArray*)getPhones:(ABMultiValueRef)multiValue
{
    NSArray* res = nil;
    
    static NSMutableCharacterSet* letters = nil;
    if (letters == nil)
    {
        letters = [NSMutableCharacterSet alphanumericCharacterSet];
        [letters invert];
    }
    
    if (multiValue != NULL)
    {
        CFIndex count = ABMultiValueGetCount(multiValue);
        if (count > 0)
        {
            NSMutableArray* mutRes = [NSMutableArray arrayWithCapacity:count];
            for (int idx = 0; idx < count; idx++)
            {
                NSString* value = ABMultiValueCopyValueAtIndex(multiValue, idx);
                NSString* label = (NSString*)ABMultiValueCopyLabelAtIndex(multiValue, idx);
                
                NSString* labelClean = [label stringByTrimmingCharactersInSet:letters];
                
                VKAddressBookPersonPhone* personPhone = [VKAddressBookPersonPhone new];
                personPhone.phone = value;
                personPhone.label = labelClean;                
                [mutRes addObject:personPhone];
                [personPhone release];
                
                [value release];
                [label release];
            }
            
            res = [[mutRes copy] autorelease];
        }
    }
    
    return res;
}

- (void)loadFromRecord:(ABRecordRef)abRecord
{
    //Phones
    ABMultiValueRef abPhones = ABRecordCopyValue(abRecord, kABPersonPhoneProperty);
    if (abPhones != NULL)
    {
        self.phones = [self getPhones:abPhones];
        CFRelease(abPhones);
    }
    
    if(ABPersonHasImageData(abRecord))
    {
        NSData* imgData = nil;
        // iOS >= 4.1
        if ( &ABPersonCopyImageDataWithFormat != nil )
            imgData = (NSData *)ABPersonCopyImageDataWithFormat(abRecord, kABPersonImageFormatThumbnail);
        else
            imgData = (NSData *)ABPersonCopyImageData(abRecord);
        
        if (imgData != nil)
        {
            avatar = [[UIImage imageWithData:imgData] retain];
            [imgData release];
        }                
    }
    
    //Names
    NSString* first = (NSString*)ABRecordCopyValue(abRecord, kABPersonFirstNameProperty);
	NSString* last = (NSString*)ABRecordCopyValue(abRecord, kABPersonLastNameProperty);
	NSString* nick = (NSString*)ABRecordCopyValue(abRecord, kABPersonNicknameProperty);    
    self.firstName = first;
    self.lastName = last;
    self.nickName = nick;
    [first release];
    [last release];
    [nick release];
    
    //Emails
    /*
    ABMultiValueRef abEMails = ABRecordCopyValue(abRecord, kABPersonEmailProperty);
    if (abEMails != NULL)
    {
        self.emails = [self valuesArrayFromABMultiValue:abEMails];
        CFRelease(abEMails);
    }
     */
}

- (NSString*)getName
{
    if (_dispName != nil)
        return _dispName;
    
    if (firstName != nil && [firstName length] > 0)
        _dispName = firstName;
    else if (lastName != nil && [lastName length] > 0)
        _dispName = lastName;
    else
        _dispName = nickName;
    
    return _dispName;
}

- (NSString*)getFullName
{
    if (_fullName != nil)
        return _fullName;
    
    if (firstName != nil && [firstName length] > 0)
    {
        if (lastName != nil && [lastName length] > 0)
            _fullName = [[NSString stringWithFormat:@"%@ %@", firstName, lastName] retain];
        else
            _fullName = [firstName retain];
    }
    else if (lastName != nil && [lastName length] > 0)
    {
        _fullName = [lastName retain];
    }
    
    return _fullName;
}

- (void)dealloc
{
    self.uid = nil;
    self.firstName = nil; 
    self.lastName = nil; 
    self.phones = nil; 
    self.emails = nil;
    self.nickName = nil;
    [avatar release];
    
    [_fullName release];
        
    [super dealloc];
}

@end

@implementation VKAddressBookPersonPhone

@synthesize phone, label;

- (void)dealloc
{
    self.phone = nil;
    self.label = nil;
    
    [super dealloc];
}

@end
