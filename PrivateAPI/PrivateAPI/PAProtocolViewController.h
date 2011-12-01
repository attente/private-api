//
//  PAProtocolViewController.h
//  PrivateAPI
//
//  Created by William Hua on 11-11-26.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PAPropertyTableViewCell;

@interface PAProtocolViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, retain) IBOutlet UISearchBar             *searchBar;
@property(nonatomic, retain) IBOutlet UITableView             *tableView;
@property(nonatomic, retain) IBOutlet UITapGestureRecognizer  *tapRecognizer;
@property(nonatomic, retain) IBOutlet PAPropertyTableViewCell *propertyCell;

@property(nonatomic, copy) NSString *protocolName;

#pragma mark - Gesture recognizers

- (IBAction)gestureRecognizerDidTapTableView:(UITapGestureRecognizer *)recognizer;

@end
