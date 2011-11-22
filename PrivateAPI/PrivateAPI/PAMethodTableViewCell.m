//
//  PAMethodTableViewCell.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-21.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAMethodTableViewCell.h"
#import "PAAPI.h"

@interface PAMethodTableViewCell ()

@property(nonatomic, copy) NSArray *labels;

@end

@implementation PAMethodTableViewCell

@synthesize method, contentViewInsets, labels;

- (void)setMethod:(PAMethod *)aMethod
{
    if(aMethod != method)
    {
        method = aMethod;
        
        NSMutableArray *labelArray = [NSMutableArray arrayWithCapacity:MAX(2, 1 + [[method argumentTypes] count])];
        
        UILabel *label = [[UILabel alloc] init];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setFont:[UIFont systemFontOfSize:14.0]];
        [label setTextColor:[UIColor blackColor]];
        [label setText:[NSString stringWithFormat:@"(%@)", [method returnType]]];
        [labelArray addObject:label];
        
        if([[method argumentTypes] count] == 0)
        {
            label = [[UILabel alloc] init];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setFont:[UIFont boldSystemFontOfSize:14.0]];
            [label setTextColor:[UIColor blackColor]];
            [label setText:[method name]];
            [labelArray addObject:label];
        }
        else
        {
            NSArray *components = [[method name] componentsSeparatedByString:@":"];
            
            for(NSInteger index = 0; index < [[method argumentTypes] count]; index++)
            {
                label = [[UILabel alloc] init];
                [label setBackgroundColor:[UIColor clearColor]];
                [label setFont:[UIFont boldSystemFontOfSize:14.0]];
                [label setTextColor:[UIColor blackColor]];
                [label setText:[NSString stringWithFormat:index == 0 ? @"%@:" : @" %@:", [components objectAtIndex:index]]];
                [labelArray addObject:label];
                
                label = [[UILabel alloc] init];
                [label setBackgroundColor:[UIColor clearColor]];
                [label setFont:[UIFont systemFontOfSize:14.0]];
                [label setTextColor:[UIColor blackColor]];
                [label setText:[NSString stringWithFormat:@"(%@)", [[method argumentTypes] objectAtIndex:index]]];
                [labelArray addObject:label];
            }
        }
        
        [self setLabels:labelArray];
    }
}

- (void)setLabels:(NSArray *)someLabels
{
    [labels makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    labels = someLabels;
    
    for(UIView *view in labels)
        [[self contentView] addSubview:view];
    
    [self setNeedsLayout];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    UIColor *textColor = selected ? [UIColor whiteColor] : [UIColor blackColor];
    
    [labels makeObjectsPerformSelector:@selector(setTextColor:) withObject:textColor];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    size.width  -= contentViewInsets.left + contentViewInsets.right;
    size.height -= contentViewInsets.top + contentViewInsets.bottom;
    
    CGPoint origin    = CGPointZero;
    CGSize  labelSize = CGSizeZero;
    
    for(UILabel *label in labels)
    {
        labelSize = [label sizeThatFits:size];
        
        if(origin.x > 0.0 && origin.x + labelSize.width > size.width)
        {
            origin.x = 0.0;
            origin.y += labelSize.height;
        }
        
        origin.x += labelSize.width;
    }
    
    size.width += contentViewInsets.left + contentViewInsets.right;
    
    return CGSizeMake(size.width, MIN(origin.y + labelSize.height, size.height) + contentViewInsets.top + contentViewInsets.bottom);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect  bounds = UIEdgeInsetsInsetRect([[self contentView] bounds], contentViewInsets);
    CGPoint origin = bounds.origin;
    
    for(UILabel *label in labels)
    {
        CGSize labelSize = [label sizeThatFits:bounds.size];
        
        if(origin.x > bounds.origin.x && origin.x + labelSize.width > CGRectGetMaxX(bounds))
        {
            origin.x = bounds.origin.x;
            origin.y += labelSize.height;
        }
        
        [label setFrame:(CGRect){ .origin = origin, .size = labelSize }];
        
        origin.x += labelSize.width;
    }
}

@end
