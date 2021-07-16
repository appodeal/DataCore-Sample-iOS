//
//  ViewController.m
//  ObjcSample
//
//  Created by artur on 06.05.2020.
//  Copyright © 2020 artur. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

#import <HolisticSolutionSDK/HolisticSolutionSDK.h>
#import <Appodeal/Appodeal.h>
#import <Adjust/Adjust.h>
#import <AppsFlyerLib/AppsFlyerLib.h>
#import <Firebase.h>
#import <FirebaseRemoteConfig.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *adjustVersion;
@property (weak, nonatomic) IBOutlet UILabel *adjustAttID;
@property (weak, nonatomic) IBOutlet UILabel *appsflyerVersion;
@property (weak, nonatomic) IBOutlet UILabel *appsflyerAttID;
@property (weak, nonatomic) IBOutlet UILabel *firebaseVersion;
@property (weak, nonatomic) IBOutlet UILabel *firebaseKeyWords;
@property (weak, nonatomic) IBOutlet UILabel *facebookVersion;
@property (weak, nonatomic) IBOutlet UILabel *facebookAppID;
@property (weak, nonatomic) IBOutlet UILabel *apdVersion;
@property (weak, nonatomic) IBOutlet UILabel *apdInitialized;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didInitialiseAd)
                                                 name:completeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didInitialiseAd {
    [Appodeal showAd:AppodealShowStyleBannerBottom rootViewController:self];
    [self updateLabels];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selected = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    if ([selected isEqualToString:@"Event"]) {
        [self synthesizeEvent];
    } else if ([selected isEqualToString:@"Purchase"]) {
        [self synthesizePurchase:HSPurchaseTypeConsumable];
    } else if ([selected isEqualToString:@"Subscription"]) {
        [self synthesizePurchase:HSPurchaseTypeAutoRenewableSubscription];
    } else {
        return;
    }
}

- (void)synthesizePurchase:(HSPurchaseType)type {
    NSDictionary *params = @{
        @"Test Custom 1" : @"Value 1",
        @"Test Custom 2" : @"Value 2"
    };
    __weak typeof(self) weakSelf = self;
    [Appodeal.hs validateAndTrackInAppPurchaseWithProductId:@"some product id"
                                                       type:type
                                                      price:@"9.99"
                                                   currency:@"USD"
                                              transactionId:@"some transiton id"
                                       additionalParameters:params
                                                    success:^(NSDictionary *result) {
        [weakSelf alertWithTitle:@"Purchase is valid" message:result.description];
    }
                                                    failure:^(NSError *error, id obj) {
        [weakSelf alertWithTitle:@"Purchase is invalid" message:error.localizedDescription];
    }];
}

- (void)synthesizeEvent {
    [Appodeal.hs trackEvent:@"level_started" customParameters:nil];
}

- (void)alertWithTitle:(NSString *)title message:(NSString * _Nullable)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateLabels {
    //adjust
    _adjustVersion.text = Adjust.sdkVersion;
    _adjustAttID.text = Adjust.adid;
    
    //appsflyer
    _appsflyerVersion.text = AppsFlyerLib.shared.getSDKVersion;
    _appsflyerAttID.text = AppsFlyerLib.shared.getAppsFlyerUID;
    
    //firebase
    _firebaseVersion.text = FIRFirebaseVersion();
    _firebaseKeyWords.text = [[FIRRemoteConfig.remoteConfig allKeysFromSource:FIRRemoteConfigSourceRemote] componentsJoinedByString:@", "];
    
    //facebook
    _facebookVersion.text = FBSDK_VERSION_STRING;
    _facebookAppID.text = [NSBundle.mainBundle objectForInfoDictionaryKey:@"FacebookAppID"];
    
    //appodeal
    _apdVersion.text = APDSdkVersionString();
    _apdInitialized.text = [Appodeal isInitalizedForAdType:kAppodealTypes] ? @"true" : @"false";
}

@end
