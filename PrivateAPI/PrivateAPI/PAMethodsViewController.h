//
//  PAMethodsViewController.h
//  PrivateAPI
//
//  Created by William Hua on 11-11-23.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PAPropertyTableViewCell;

@interface PAMethodsViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, retain) IBOutlet UISearchBar             *searchBar;
@property(nonatomic, retain) IBOutlet UITableView             *tableView;
@property(nonatomic, retain) IBOutlet UITapGestureRecognizer  *tapRecognizer;
@property(nonatomic, retain) IBOutlet PAPropertyTableViewCell *propertyCell;

#pragma mark - Gesture recognizers

- (IBAction)gestureRecognizerDidTapTableView:(UITapGestureRecognizer *)recognizer;

@end
