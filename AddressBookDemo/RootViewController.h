//
//  RootViewController.h
//  AddressBookDemo
//
//  Created by ligf on 13-8-15.
//  Copyright (c) 2013年 yonyou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iflyMSC/IFlyRecognizerViewDelegate.h"
#import "iflyMSC/IFlyRecognizerView.h"

#import "iflyMSC/IFlyDataUploader.h"
#import "iflyMSC/IFlyContact.h"

#define CONTACT @"subject=uup,dtt=contact"
#define APPID       @"50adb3f0"

@interface RootViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,IFlyRecognizerViewDelegate,IFlyDataUploaderDelegate,IFlySpeechUserDelegate>
{
    IFlyRecognizerView              *_iFlyRecognizerView;
    NSString                        *_ent;
    NSString                        *_grammarID;
}

@property (retain, nonatomic) IBOutlet UITableView *tblLinker;
@property (retain, nonatomic) IBOutlet UISearchBar *barSearch;

@property(copy) NSString *ent;

- (void) setText:(NSString *) text;
- (void) setGrammar:(NSString *)grammar;

@end
