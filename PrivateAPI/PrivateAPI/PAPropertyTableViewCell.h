//
//  PAPropertyTableViewCell.h
//  PrivateAPI
//
//  Created by William Hua on 11-11-21.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PAPropertyTableViewCell : UITableViewCell

@property(nonatomic, retain) IBOutlet UILabel *nameLabel;
@property(nonatomic, retain) IBOutlet UILabel *typeLabel;
@property(nonatomic, retain) IBOutlet UILabel *attributesLabel;

@end
