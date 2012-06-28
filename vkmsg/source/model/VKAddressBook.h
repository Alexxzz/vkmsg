//
//  VKAddressBook.h
//  vkmsg
//
//  Created by Alexander Zagorsky on 11.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKAddressBookPerson.h"

@interface VKAddressBook : NSObject

@property(nonatomic, readonly) NSArray* contacts;

+ (id)addressBook;

- (void)load;

- (VKAddressBookPerson*)personWithPhone:(NSNumber*)phone;

@end
