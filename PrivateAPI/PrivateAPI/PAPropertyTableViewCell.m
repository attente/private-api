//
//  PAPropertyTableViewCell.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-21.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAPropertyTableViewCell.h"

@implementation PAPropertyTableViewCell

@synthesize nameLabel, typeLabel, attributesLabel;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    UIColor *textColor = selected ? [UIColor whiteColor] : [UIColor blackColor];
    
    [nameLabel       setTextColor:textColor];
    [typeLabel       setTextColor:textColor];
    [attributesLabel setTextColor:textColor];
}

@end
