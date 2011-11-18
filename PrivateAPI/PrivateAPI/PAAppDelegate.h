//
//  PAAppDelegate.h
//  PrivateAPI
//
//  Created by William Hua on 11-11-17.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PAClassesViewController;

@interface PAAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) PAClassesViewController *viewController;

@end
