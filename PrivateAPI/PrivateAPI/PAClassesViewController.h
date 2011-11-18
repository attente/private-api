//
//  PAClassesViewController.h
//  PrivateAPI
//
//  Created by William Hua on 11-11-17.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PAClassesViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, retain) IBOutlet UISearchBar            *searchBar;
@property(nonatomic, retain) IBOutlet UITableView            *tableView;
@property(nonatomic, retain) IBOutlet UIToolbar              *toolbar;
@property(nonatomic, retain) IBOutlet UISegmentedControl     *modeControl;
@property(nonatomic, retain) IBOutlet UITapGestureRecognizer *tapRecognizer;

- (IBAction)segmentedControlDidChangeValue:(id)sender;

#pragma mark - Gesture recognizers

- (IBAction)gestureRecognizerDidTapTableView:(UITapGestureRecognizer *)recognizer;

@end
