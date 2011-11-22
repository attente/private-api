//
//  PAMethodTableViewCell.h
//  PrivateAPI
//
//  Created by William Hua on 11-11-21.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PAMethod;

@interface PAMethodTableViewCell : UITableViewCell

@property(nonatomic, retain) PAMethod     *method;
@property(nonatomic, assign) UIEdgeInsets  contentViewInsets;

@end
