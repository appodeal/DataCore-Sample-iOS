//
//  SceneDelegate.m
//  ObjcSample
//
//  Created by artur on 06.05.2020.
//  Copyright © 2020 artur. All rights reserved.
//

#import "SceneDelegate.h"
#import "ViewController.h"


@interface SceneDelegate ()

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if ([scene isKindOfClass:UIWindowScene.class]) {
        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        UIStoryboard *main = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ViewController *root = [main instantiateViewControllerWithIdentifier:@"main"];
        self.window.rootViewController = root;
        self.window.windowScene = (UIWindowScene *)scene;
        [self.window makeKeyAndVisible];
    }
}

@end
