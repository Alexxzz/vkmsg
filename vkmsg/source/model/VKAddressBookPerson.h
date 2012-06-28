//
//  VKAddressBookPerson.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 11.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface VKAddressBookPersonPhone : NSObject 

@property(nonatomic,retain) NSString* phone;
@property(nonatomic,retain) NSString* label;

@end

@interface VKAddressBookPerson : NSObject
{
    NSString* _dispName;
    NSString* _fullName;
}

@property(nonatomic,retain) NSNumber* uid;
@property(nonatomic,retain) NSString* firstName;
@property(nonatomic,retain) NSString* lastName;
@property(nonatomic,retain) NSString* nickName;
@property(nonatomic,retain) NSArray* phones;
@property(nonatomic,retain) NSArray* emails;
@property(nonatomic,readonly) UIImage* avatar;

- (id)initWithABRecord:(ABRecordRef)abRecord;

- (void)loadFromRecord:(ABRecordRef)abRecord;

- (NSString*)getName;
- (NSString*)getFullName;

+ (NSString*)MSISDNFormatedPhone:(NSString*)unformated;

@end
