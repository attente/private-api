//
//  PAClassViewController.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-17.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAClassViewController.h"
#import "PAPropertyTableViewCell.h"
#import "PAMethodTableViewCell.h"
#import "PAAPI.h"

enum PAClassViewControllerSection
{
    PAClassViewControllerSectionSuperclasses,
    PAClassViewControllerSectionSubclasses,
    PAClassViewControllerSectionProtocols,
    PAClassViewControllerSectionProperties,
    PAClassViewControllerSectionMethods,
    PAClassViewControllerSectionIvars,
    PAClassViewControllerSectionCount
};

@interface PAClassViewController ()

@property(nonatomic, retain) UINib                 *propertyCellNib;
@property(nonatomic, retain) PAMethodTableViewCell *methodCell;
@property(nonatomic, retain) PATree                *classTree;
@property(nonatomic, copy)   NSArray               *superclasses;
@property(nonatomic, copy)   NSArray               *subclasses;
@property(nonatomic, copy)   NSArray               *protocols;
@property(nonatomic, copy)   NSArray               *properties;
@property(nonatomic, copy)   NSArray               *methods;
@property(nonatomic, copy)   NSArray               *ivars;

@end

@implementation PAClassViewController

@synthesize searchBar, tableView, propertyCell, propertyCellNib, methodCell, className, classTree, superclasses, subclasses, protocols, properties, methods, ivars;

- (PATree *)classTree
{
    if(classTree == nil)
        classTree = [PAAPI classTreeForClassName:className];
    
    return classTree;
}

- (NSArray *)superclasses
{
    if(superclasses == nil)
    {
        PATree *tree = [self classTree];
        
        NSMutableArray *superclassNames = [NSMutableArray array];
        
        while([[tree parents] count] > 0)
        {
            tree = [[tree parents] lastObject];
            [superclassNames insertObject:[tree name] atIndex:0];
        }
        
        superclasses = superclassNames;
    }
    
    return superclasses;
}

- (NSArray *)subclasses
{
    if(subclasses == nil)
    {
        PATree *tree = [self classTree];
        
        NSMutableArray *subclassNames = [NSMutableArray arrayWithCapacity:[[tree children] count]];
        
        for(PATree *subclass in [tree children])
            [subclassNames addObject:[subclass name]];
        
        subclasses = subclassNames;
    }
    
    return subclasses;
}

- (NSArray *)protocols
{
    if(protocols == nil)
        protocols = [[PAAPI protocolNamesForClassName:className] sortedArrayUsingSelector:@selector(compare:)];
    
    return protocols;
}

- (NSArray *)properties
{
    if(properties == nil)
        properties = [[PAAPI propertiesForClassName:className] sortedArrayUsingComparator:
                      ^NSComparisonResult(id obj1, id obj2)
                      {
                          return [[obj1 name] compare:[obj2 name]];
                      }];
    
    return properties;
}

- (NSArray *)methods
{
    if(methods == nil)
        methods = [[PAAPI methodsForClassName:className] sortedArrayUsingComparator:
                   ^NSComparisonResult(id obj1, id obj2)
                   {
                       return [[obj1 name] compare:[obj2 name]];
                   }];
    
    return methods;
}

- (NSArray *)ivars
{
    if(ivars == nil)
        ivars = [[PAAPI ivarsForClassName:className] sortedArrayUsingComparator:
                 ^NSComparisonResult(id obj1, id obj2)
                 {
                     NSInteger offset1 = [obj1 offset];
                     NSInteger offset2 = [obj2 offset];
                     
                     return offset1 < offset2 ? NSOrderedAscending : offset1 == offset2 ? NSOrderedSame : NSOrderedDescending;
                 }];
    
    return ivars;
}

#pragma mark - UITableViewDataSource and UITableViewDelegate conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return PAClassViewControllerSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case PAClassViewControllerSectionSuperclasses: return [[self superclasses] count];
        case PAClassViewControllerSectionSubclasses:   return [[self subclasses]   count];
        case PAClassViewControllerSectionProtocols:    return [[self protocols]    count];
        case PAClassViewControllerSectionProperties:   return [[self properties]   count];
        case PAClassViewControllerSectionMethods:      return [[self methods]      count];
        case PAClassViewControllerSectionIvars:        return [[self ivars]        count];
        default:                                       return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case PAClassViewControllerSectionSuperclasses: return @"Superclasses";
        case PAClassViewControllerSectionSubclasses:   return @"Subclasses";
        case PAClassViewControllerSectionProtocols:    return @"Protocols";
        case PAClassViewControllerSectionProperties:   return @"Properties";
        case PAClassViewControllerSectionMethods:      return @"Methods";
        case PAClassViewControllerSectionIvars:        return @"Ivars";
        default:                                       return nil;
    }
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch([indexPath section])
    {
        case PAClassViewControllerSectionSuperclasses: return 36.0;
        case PAClassViewControllerSectionSubclasses:   return 36.0;
        case PAClassViewControllerSectionProtocols:    return 36.0;
        case PAClassViewControllerSectionProperties:   return 83.0;
        case PAClassViewControllerSectionMethods:
        {
            if(methodCell == nil)
            {
                methodCell = [[PAMethodTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                
                [methodCell setContentViewInsets:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)];
            }
            
            [methodCell setMethod:[[self methods] objectAtIndex:[indexPath row]]];
            
            return [methodCell sizeThatFits:CGSizeMake([aTableView bounds].size.width, CGFLOAT_MAX)].height;
        }
        case PAClassViewControllerSectionIvars:        return 44.0;
        default:                                       return  0.0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch([indexPath section])
    {
        case PAClassViewControllerSectionSuperclasses:
        {
            static NSString *identifier = @"Default UITableViewCell";
            
            UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];
            
            if(cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
                [[cell textLabel] setMinimumFontSize:10.0];
                [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
            }
            
            [[cell textLabel] setText:[[self superclasses] objectAtIndex:[indexPath row]]];
            
            return cell;
        }
        case PAClassViewControllerSectionSubclasses:
        {
            static NSString *identifier = @"Default UITableViewCell";
            
            UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];
            
            if(cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
                [[cell textLabel] setMinimumFontSize:10.0];
                [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
            }
            
            [[cell textLabel] setText:[[self subclasses] objectAtIndex:[indexPath row]]];
            
            return cell;
        }
        case PAClassViewControllerSectionProtocols:
        {
            static NSString *identifier = @"Default UITableViewCell";
            
            UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];
            
            if(cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
                [[cell textLabel] setMinimumFontSize:10.0];
                [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
            }
            
            [[cell textLabel] setText:[[self protocols] objectAtIndex:[indexPath row]]];
            
            return cell;
        }
        case PAClassViewControllerSectionProperties:
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
        case PAClassViewControllerSectionMethods:
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
        case PAClassViewControllerSectionIvars:
        {
            static NSString *identifier = @"Subtitle UITableViewCell";
            
            UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];
            
            if(cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
                
                [[cell textLabel]       setFont:[UIFont boldSystemFontOfSize:14.0]];
                [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:14.0]];
            }
            
            PAIvar *ivar = [[self ivars] objectAtIndex:[indexPath row]];
            
            [[cell textLabel]       setText:[ivar name]];
            [[cell detailTextLabel] setText:[ivar type]];
            
            return cell;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch([indexPath section])
    {
        case PAClassViewControllerSectionSuperclasses:
        case PAClassViewControllerSectionSubclasses:
        {
            NSArray  *names = [indexPath section] == PAClassViewControllerSectionSuperclasses ? [self superclasses] : [self subclasses];
            NSString *name  = [names objectAtIndex:[indexPath row]];
            
            PAClassViewController *controller = [[PAClassViewController alloc] initWithNibName:@"PAClassViewController" bundle:nil];
            
            [controller setClassName:name];
            [controller setTitle:name];
            
            [[self navigationController] pushViewController:controller animated:YES];
            
            break;
        }
    }
}

@end
