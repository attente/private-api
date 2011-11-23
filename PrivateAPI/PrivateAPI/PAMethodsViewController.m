//
//  PAMethodsViewController.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-23.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAMethodsViewController.h"
#import "PAPropertyTableViewCell.h"
#import "PAMethodTableViewCell.h"
#import "PAAPI.h"

@interface PAMethodsViewController ()

@property(nonatomic, retain) UINib                 *propertyCellNib;
@property(nonatomic, retain) PAMethodTableViewCell *methodCell;
@property(nonatomic, copy)   NSArray               *properties;
@property(nonatomic, copy)   NSArray               *methods;

@end

@implementation PAMethodsViewController

@synthesize searchBar, tableView, propertyCell, propertyCellNib, methodCell, properties, methods;

- (NSArray *)properties
{
    if(properties == nil)
        properties = [PAAPI propertyList];
    
    return properties;
}

- (NSArray *)methods
{
    if(methods == nil)
        methods = [PAAPI methodList];
    
    return methods;
}

#pragma mark - UITableViewDataSource and UITableViewDelegate conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:  return [[self properties] count];
        case 1:  return [[self methods]    count];
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:  return @"Properties";
        case 1:  return @"Methods";
        default: return nil;
    }
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch([indexPath section])
    {
        case 0: return 83.0;
        case 1:
        {
            if(methodCell == nil)
            {
                methodCell = [[PAMethodTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                
                [methodCell setContentViewInsets:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)];
            }
            
            [methodCell setMethod:[[self methods] objectAtIndex:[indexPath row]]];
            
            return [methodCell sizeThatFits:CGSizeMake([aTableView bounds].size.width, CGFLOAT_MAX)].height;
        }
        default: return 0.0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch([indexPath section])
    {
        case 0:
        {
            static NSString *identifier = @"PAPropertyTableViewCell";
            
            PAPropertyTableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];
            
            if(cell == nil)
            {
                if(propertyCellNib == nil)
                    propertyCellNib = [UINib nibWithNibName:@"PAPropertyTableViewCell" bundle:nil];
                
                [propertyCellNib instantiateWithOwner:self options:nil];
                
                cell = [self propertyCell];
                [self setPropertyCell:nil];
            }
            
            PAProperty *property = [[self properties] objectAtIndex:[indexPath row]];
            
            NSString *getter      = [property getter] ? : [property name];
            NSString *setter      = [property setter] ? : [property isReadonly] ? nil : [NSString stringWithFormat:@"set%@:", [[property name] capitalizedString]];
            NSString *type        = [property type];
            NSString *backingIvar = [property backingIvar];
            
            NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:6];
            
            if([property isNonatomic]) [attributes addObject:@"nonatomic"];
            
            switch([property setterSemantics])
            {
                case PAPropertySetterSemanticsAssign: [attributes addObject:@"assign"]; break;
                case PAPropertySetterSemanticsCopy:   [attributes addObject:@"copy"];   break;
                case PAPropertySetterSemanticsRetain: [attributes addObject:@"retain"]; break;
            }
            
            if([property isReadonly]) [attributes addObject:@"readonly"];
            if([property isDynamic])  [attributes addObject:@"dynamic"];
            if([property isWeak])     [attributes addObject:@"__weak"];
            
            [[cell nameLabel] setText:[[NSArray arrayWithObjects:getter, setter, nil] componentsJoinedByString:@", "]];
            [[cell typeLabel] setText:[[NSArray arrayWithObjects:type, backingIvar, nil] componentsJoinedByString:@" "]];
            [[cell attributesLabel] setText:[attributes componentsJoinedByString:@", "]];
            
            return cell;
        }
        case 1:
        {
            static NSString *identifier = @"PAMethodTableViewCell";
            
            PAMethodTableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];
            
            if(cell == nil)
            {
                cell = [[PAMethodTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                
                [cell setContentViewInsets:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)];
            }
            
            [cell setMethod:[[self methods] objectAtIndex:[indexPath row]]];
            
            return cell;
        }
        default: return nil;
    }
}

@end
