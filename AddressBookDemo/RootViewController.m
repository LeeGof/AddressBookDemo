//
//  RootViewController.m
//  AddressBookDemo
//
//  Created by ligf on 13-8-15.
//  Copyright (c) 2013年 yonyou. All rights reserved.
//

#import "RootViewController.h"
#import "TKAddressBook.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <QuartzCore/QuartzCore.h>
#import "TelephoneNumberFunction.h"

@interface RootViewController ()
{
    NSMutableArray                  *_arrListData;
    BOOL                            isLogin;
    BOOL                            isUpload;
}

@property (retain, nonatomic) NSMutableArray *arrListData;

@end

@implementation RootViewController
@synthesize arrListData = _arrListData;
@synthesize ent = _ent;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _arrListData = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"通讯录";
    isLogin = NO;
    isUpload = NO;
    
    for(id cc in [_barSearch subviews])
    {
        if([cc isKindOfClass:[UIButton class]])
        {
            UIButton *btn = (UIButton *)cc;
//            [btn setFrame:CGRectMake(0, 0, 40, 40)];
//            [btn setBackgroundImage:[UIImage imageNamed:@"voice.png"] forState:UIControlStateNormal];
//            [btn setBackgroundImage:[UIImage imageNamed:@"voice.png"] forState:UIControlStateHighlighted];
            [btn setTitle:@"取消" forState:UIControlStateNormal];
            [btn setTitle:@"取消" forState:UIControlStateHighlighted];
        }
    }
    [self getAddressBookData:@""];
    
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",APPID ];
    _iFlyRecognizerView = [[IFlyRecognizerView alloc] initWithOrigin:CGPointMake(15, 60) initParam:initString];
    _iFlyRecognizerView.delegate = self;
    [initString release];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [_tblLinker release];
    [_barSearch release];
    
    [_arrListData release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendButton.frame = CGRectMake(0, 0, 36, 33);
    [sendButton setImage:[UIImage imageNamed:@"voice.png"] forState:UIControlStateNormal];
    sendButton.tag = 5001;
    [sendButton addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *barBtnSend = [[UIBarButtonItem alloc] initWithCustomView:sendButton];
    barBtnSend.style=UIBarButtonItemStyleBordered;
    self.navigationItem.rightBarButtonItem = barBtnSend;
    [barBtnSend release];
    
}

- (void) setGrammar:(NSString *)grammar
{
    [_grammarID release];
    _grammarID = [grammar retain];
}

- (void) setText:(NSString *) text
{
    _barSearch.text = text;
}

- (void)getAddressBookData:(NSString *)strKey;
{
    [_arrListData removeAllObjects];
    _arrListData = [NSMutableArray array];
    
    //新建一个通讯录类
    ABAddressBookRef addressBooks = nil;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBooks =  ABAddressBookCreateWithOptions(NULL, NULL);
        //获取通讯录权限
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBooks, ^(bool granted, CFErrorRef error){dispatch_semaphore_signal(sema);});
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    }
    else
    {
        addressBooks = ABAddressBookCreate();
    }
    
    //获取通讯录中的所有人
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBooks);
    //通讯录中人数
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBooks);
    
    //循环，获取每个人的个人信息
    for (NSInteger i = 0; i < nPeople; i++)
    {
        //新建一个addressBook model类
        TKAddressBook *addressBook = [[TKAddressBook alloc] init];
        //获取个人
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
        //获取个人名字
        CFTypeRef abName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
        CFTypeRef abLastName = ABRecordCopyValue(person, kABPersonLastNameProperty);
        CFStringRef abFullName = ABRecordCopyCompositeName(person);
        NSString *nameString = (NSString *)abName;
        NSString *lastNameString = (NSString *)abLastName;
        
        if ((id)abFullName != nil)
        {
            nameString = (NSString *)abFullName;
        }
        else
        {
            if ((id)abLastName != nil)
            {
                nameString = [NSString stringWithFormat:@"%@%@", nameString, lastNameString];
            }
        }
        addressBook.name = [nameString stringByReplacingOccurrencesOfString:@" " withString:@""];
        addressBook.recordID = (int)ABRecordGetRecordID(person);;
        
        ABPropertyID multiProperties[] =
        {
            kABPersonPhoneProperty,
            kABPersonEmailProperty
        };
        NSInteger multiPropertiesTotal = sizeof(multiProperties) / sizeof(ABPropertyID);
        for (NSInteger j = 0; j < multiPropertiesTotal; j++)
        {
            ABPropertyID property = multiProperties[j];
            ABMultiValueRef valuesRef = ABRecordCopyValue(person, property);
            NSInteger valuesCount = 0;
            if (valuesRef != nil) valuesCount = ABMultiValueGetCount(valuesRef);
            
            if (valuesCount == 0)
            {
                CFRelease(valuesRef);
                continue;
            }
            //获取电话号码和email
            for (NSInteger k = 0; k < valuesCount; k++)
            {
                CFTypeRef value = ABMultiValueCopyValueAtIndex(valuesRef, k);
                switch (j)
                {
                    case 0:
                    {// Phone number
                        addressBook.tel = (NSString *)value;
                        break;
                    }
                    case 1:
                    {// Email
                        addressBook.email = (NSString *)value;
                        break;
                    }
                }
                CFRelease(value);
            }
            CFRelease(valuesRef);
        }
        //将个人信息添加到数组中，循环完成后addressBookTemp中包含所有联系人的信息
        if ([strKey isEqualToString:@""])
        {
            [_arrListData addObject:addressBook];
        }
        else
        {
            NSRange foundObj = [addressBook.name rangeOfString:strKey options:NSCaseInsensitiveSearch];

            if(foundObj.length > 0)
            {
                [_arrListData addObject:addressBook];
            }
        }
        
        if (abName) CFRelease(abName);
        if (abLastName) CFRelease(abLastName);
        if (abFullName) CFRelease(abFullName);
    }
    
    [_arrListData retain];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_arrListData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"ContactCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    TKAddressBook *book = [_arrListData objectAtIndex:indexPath.row];
    
    cell.textLabel.text = book.name;
    cell.detailTextLabel.text = book.tel;
    return cell;

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_barSearch resignFirstResponder];
    
    TKAddressBook *book = [_arrListData objectAtIndex:indexPath.row];
    
    TelephoneNumberFunction *telephoneNumberFunction = [[TelephoneNumberFunction alloc] init];
    telephoneNumberFunction.phoneNumber = book.tel;
    [telephoneNumberFunction showIn:self];
}

#pragma mark - Search Bar Delegate Methods
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [_barSearch resignFirstResponder];
    
    [self getAddressBookData:searchBar.text];
    
    [_tblLinker reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [_barSearch resignFirstResponder];
    
    [self getAddressBookData:@""];
    
    [_tblLinker reloadData];
}

- (void)btnClick:(id)sender
{
    [self loginAndUpload];
    
    _barSearch.text = @"";
    [_iFlyRecognizerView setParameter:@"grammarID" value:_grammarID];
    
    // 参数设置
    [_iFlyRecognizerView setParameter:@"domain" value:_ent];
    [_iFlyRecognizerView setParameter:@"sample_rate" value:@"16000"];
    [_iFlyRecognizerView setParameter:@"vad_eos" value:@"1800"];
    [_iFlyRecognizerView setParameter:@"vad_bos" value:@"6000"];
    [_iFlyRecognizerView start];
}

- (void) onResult:(IFlyRecognizerView *)iFlyRecognizerView theResult:(NSArray *)resultArray
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [resultArray objectAtIndex:0];
    for (NSString *key in dic)
    {
        if (!key || [key isEqualToString:@"(null)"])
        {
            
        }
        else
        {
            [result appendFormat:@"%@",key];
        }
    }
    _barSearch.text = [NSString stringWithFormat:@"%@%@",_barSearch.text,[result stringByReplacingOccurrencesOfString:@"。" withString:@""]];
    [result release];
    
    [self getAddressBookData:_barSearch.text];
    [_tblLinker reloadData];
}

- (void)onEnd:(IFlyRecognizerView *)iFlyRecognizerView theError:(IFlySpeechError *) error
{
    NSLog(@"recognizer end");
}
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */
- (void) dismissKeyBoard
{
    [_barSearch resignFirstResponder];
}

- (void)loginAndUpload
{
    if (![IFlySpeechUser isLogin] || !isLogin)
    {
        // 需要先登陆
        IFlySpeechUser *loginUser = [[IFlySpeechUser alloc] initWithDelegate:self];
        
        // user 和 pwd 都传入nil时表示是匿名登陆
        NSString *loginString = [[NSString alloc] initWithFormat:@"appid=%@",APPID];
        [loginUser login:nil pwd:nil param:loginString];
    }
    
    if (!isUpload)
    {
        // 获取联系人
        IFlyContact *iFlyContact = [[IFlyContact alloc] init];
        IFlyDataUploader *uploader = [[IFlyDataUploader alloc] initWithDelegate:nil pwd:nil params:nil delegate:self];
        NSString *contact = [iFlyContact contact];
        [uploader uploadData:@"contact" params:CONTACT data: contact];
        [iFlyContact release];
    }
}

- (void) onEnd:(IFlySpeechUser *)iFlySpeechUser error:(IFlySpeechError *)error
{
    if (![error errorCode])
    {
        isLogin = YES;
    }
    else
    {
        isLogin = NO;
    }
}

- (void) onEnd:(IFlyDataUploader*) uploader grammerID:(NSString *)grammerID error:(IFlySpeechError *)error
{
    if (![error errorCode])
    {
        isUpload = YES;
    }
    else
    {
        isUpload = NO;
    }
}

@end
