//
//  VKAddressBook.m
//  vkmsg
//
//  Created by Alexander Zagorsky on 11.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKAddressBook.h"
#import <AddressBook/AddressBook.h>

@implementation VKAddressBook

#pragma mark - Singeltone stuff
static VKAddressBook* instance = nil;
+ (id)addressBook
{
    return instance;
}

+ (void)initialize
{
    [super initialize];
    
    if (instance == nil)
        instance = [VKAddressBook new];
}

- (id)retain
{ 
    return instance;
}
- (id)autorelease
{
    return instance;
}
- (oneway void)release
{
}

- (id)copy
{
    return instance;
}

#pragma mark - Init
@synthesize contacts;

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        [self load];
    }
    return self;
}

- (void)dealloc
{
    [contacts release];
    
    [super dealloc];
}

#pragma mark - Load
- (void)load
{
    dispatch_queue_t abLoadQueue = dispatch_queue_create("vkmsg.addressbook.load", NULL);
    dispatch_async(abLoadQueue, ^{
        @autoreleasepool 
        {
            ABAddressBookRef addressBook = ABAddressBookCreate();
            CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
            if (people != nil)
            {
                CFIndex count = CFArrayGetCount(people);
                
                NSMutableArray* contactsMut = [NSMutableArray arrayWithCapacity:count];
                
                for (CFIndex idx = 0; idx < count; idx++)
                {
                    ABRecordRef person = CFArrayGetValueAtIndex(people, idx);
                    if (person == nil) 
                        continue;
                    
                    VKAddressBookPerson* vkAbPerson = [[VKAddressBookPerson alloc] initWithABRecord:person];
                    [contactsMut addObject:vkAbPerson];
                    [vkAbPerson release];
                } 
                
                @synchronized (contacts)
                {
                    [contacts release];
                    contacts = [contactsMut copy];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kVKNotificationAddressBookLoaded 
                                                                   object:nil];
            }
            
            if (addressBook)
                CFRelease(addressBook);
            if (people)
                CFRelease(people);
        }
    });
    dispatch_release(abLoadQueue);
}

- (VKAddressBookPerson*)personWithPhone:(NSNumber*)phoneNum
{
    __block NSString* phone = [phoneNum stringValue];
    VKAddressBookPerson* res = nil;
    
    for (VKAddressBookPerson* person in contacts)
    {
        if (person.phones == nil || [person.phones count] == 0)
            continue;
    
        NSUInteger index = [person.phones indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            VKAddressBookPersonPhone* phone_ = obj;
            NSString* formattedPhone = [VKAddressBookPerson MSISDNFormatedPhone:phone_.phone];
            
            if ([phone isEqualToString:formattedPhone])
                return YES;
            
            NSRange range = [phone rangeOfString:formattedPhone];
            if (range.location != NSNotFound)
                return YES;
            
            range = [formattedPhone rangeOfString:phone];
            if (range.location != NSNotFound)
                return YES;
            
            return NO; 
        }];
        
        if (index != NSNotFound)
        {
            res = person;
            break;
        }
    }
    
    return res;
}

@end
