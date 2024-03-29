//
//  PAClassViewController.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-17.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAClassViewController.h"
#import "PAProtocolViewController.h"
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
@property(nonatomic, copy)   NSArray               *visibleSuperclasses;
@property(nonatomic, copy)   NSArray               *visibleSubclasses;
@property(nonatomic, copy)   NSArray               *visibleProtocols;
@property(nonatomic, copy)   NSArray               *visibleProperties;
@property(nonatomic, copy)   NSArray               *visibleMethods;
@property(nonatomic, copy)   NSArray               *visibleIvars;

#pragma mark - Keyboard notifications

- (void)PA_keyboardWillChangeFrame:(NSNotification *)notification;

@end

@implementation PAClassViewController

@synthesize searchBar, tableView, tapRecognizer, propertyCell, propertyCellNib, methodCell, className, classTree, superclasses, subclasses, protocols, properties, methods, ivars, visibleSuperclasses, visibleSubclasses, visibleProtocols, visibleProperties, visibleMethods, visibleIvars;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PA_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [tableView addGestureRecognizer:tapRecognizer];
}

- (void)setClassName:(NSString *)aClassName
{
    if(![aClassName isEqualToString:className])
    {
        className = aClassName;
        
        [self setClassTree:[PAAPI classTreeForClassName:className]];
        [self setSuperclasses:nil];
        [self setSubclasses:nil];
        [self setProtocols:nil];
        [self setProperties:nil];
        [self setMethods:nil];
        [self setIvars:nil];
        
        [tableView reloadData];
    }
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

- (void)setSuperclasses:(NSArray *)someSuperclasses
{
    superclasses = [someSuperclasses copy];
    
    [self setVisibleSuperclasses:nil];
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

- (void)setSubclasses:(NSArray *)someSubclasses
{
    subclasses = [someSubclasses copy];
    
    [self setVisibleSubclasses:nil];
}

- (NSArray *)protocols
{
    if(protocols == nil)
        protocols = [[PAAPI protocolNamesForClassName:className] sortedArrayUsingSelector:@selector(compare:)];
    
    return protocols;
}

- (void)setProtocols:(NSArray *)someProtocols
{
    protocols = [someProtocols copy];
    
    [self setVisibleProtocols:nil];
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

- (void)setProperties:(NSArray *)someProperties
{
    properties = [someProperties copy];
    
    [self setVisibleProperties:nil];
}

- (NSArray *)methods
{
    if(methods == nil)
        methods = [[PAAPI methodsForClassName:className] sortedArrayUsingComparator:
                   ^NSComparisonResult(id obj1, id obj2)
                   {
                       if([obj1 isInstanceMethod] != [obj2 isInstanceMethod])
                           return [obj1 isInstanceMethod] ? NSOrderedDescending : NSOrderedAscending;
                       else
                           return [[obj1 name] compare:[obj2 name]];
                   }];
    
    return methods;
}

- (void)setMethods:(NSArray *)someMethods
{
    methods = [someMethods copy];
    
    [self setVisibleMethods:nil];
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

- (void)setIvars:(NSArray *)someIvars
{
    ivars = [someIvars copy];
    
    [self setVisibleIvars:nil];
}

- (NSArray *)visibleSuperclasses
{
    if(visibleSuperclasses == nil)
    {
        if([[searchBar text] length] == 0)
            visibleSuperclasses = [self superclasses];
        else
            visibleSuperclasses = [[self superclasses] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self contains[cd] %@", [searchBar text]]];
    }
    
    return visibleSuperclasses;
}

- (NSArray *)visibleSubclasses
{
    if(visibleSubclasses == nil)
    {
        if([[searchBar text] length] == 0)
            visibleSubclasses = [self subclasses];
        else
            visibleSubclasses = [[self subclasses] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self contains[cd] %@", [searchBar text]]];
    }
    
    return visibleSubclasses;
}

- (NSArray *)visibleProtocols
{
    if(visibleProtocols == nil)
    {
        if([[searchBar text] length] == 0)
            visibleProtocols = [self protocols];
        else
            visibleProtocols = [[self protocols] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self contains[cd] %@", [searchBar text]]];
    }
    
    return visibleProtocols;
}

- (NSArray *)visibleProperties
{
    if(visibleProperties == nil)
    {
        if([[searchBar text] length] == 0)
            visibleProperties = [self properties];
        else
            visibleProperties = [[self properties] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name contains[cd] %@", [searchBar text]]];
    }
    
    return visibleProperties;
}

- (NSArray *)visibleMethods
{
    if(visibleMethods == nil)
    {
        if([[searchBar text] length] == 0)
            visibleMethods = [self methods];
        else
            visibleMethods = [[self methods] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name contains[cd] %@", [searchBar text]]];
    }
    
    return visibleMethods;
}

- (NSArray *)visibleIvars
{
    if(visibleIvars == nil)
    {
        if([[searchBar text] length] == 0)
            visibleIvars = [self ivars];
        else
            visibleIvars = [[self ivars] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name contains[cd] %@", [searchBar text]]];
    }
    
    return visibleIvars;
}

#pragma mark - UISearchBarDelegate conformance

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self setVisibleSuperclasses:nil];
    [self setVisibleSubclasses:nil];
    [self setVisibleProtocols:nil];
    [self setVisibleProperties:nil];
    [self setVisibleMethods:nil];
    [self setVisibleIvars:nil];
    
    [tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    [aSearchBar resignFirstResponder];
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
        case PAClassViewControllerSectionSuperclasses: return [[self visibleSuperclasses] count];
        case PAClassViewControllerSectionSubclasses:   return [[self visibleSubclasses]   count];
        case PAClassViewControllerSectionProtocols:    return [[self visibleProtocols]    count];
        case PAClassViewControllerSectionProperties:   return [[self visibleProperties]   count];
        case PAClassViewControllerSectionMethods:      return [[self visibleMethods]      count];
        case PAClassViewControllerSectionIvars:        return [[self visibleIvars]        count];
        default:                                       return 0;
    }
}

- (CGFloat)tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case PAClassViewControllerSectionSuperclasses: return [[self visibleSuperclasses] count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case PAClassViewControllerSectionSubclasses:   return [[self visibleSubclasses]   count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case PAClassViewControllerSectionProtocols:    return [[self visibleProtocols]    count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case PAClassViewControllerSectionProperties:   return [[self visibleProperties]   count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case PAClassViewControllerSectionMethods:      return [[self visibleMethods]      count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case PAClassViewControllerSectionIvars:        return [[self visibleIvars]        count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        default:                                       return 0.0;
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
            
            [methodCell setMethod:[[self visibleMethods] objectAtIndex:[indexPath row]]];
            
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
            
            [[cell textLabel] setText:[[self visibleSuperclasses] objectAtIndex:[indexPath row]]];
            
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
            
            [[cell textLabel] setText:[[self visibleSubclasses] objectAtIndex:[indexPath row]]];
            
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
            
            [[cell textLabel] setText:[[self visibleProtocols] objectAtIndex:[indexPath row]]];
            
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
            
            PAProperty *property = [[self visibleProperties] objectAtIndex:[indexPath row]];
            
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
            
            [cell setMethod:[[self visibleMethods] objectAtIndex:[indexPath row]]];
            
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
            
            PAIvar *ivar = [[self visibleIvars] objectAtIndex:[indexPath row]];
            
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
            NSArray  *names = [indexPath section] == PAClassViewControllerSectionSuperclasses ? [self visibleSuperclasses] : [self visibleSubclasses];
            NSString *name  = [names objectAtIndex:[indexPath row]];
            
            PAClassViewController *controller = [[PAClassViewController alloc] initWithNibName:@"PAClassViewController" bundle:nil];
            
            [controller setClassName:name];
            [controller setTitle:name];
            
            [[self navigationController] pushViewController:controller animated:YES];
            
            break;
        }
        case PAClassViewControllerSectionProtocols:
        {
            NSString *name = [[self visibleProtocols] objectAtIndex:[indexPath row]];
            
            PAProtocolViewController *controller = [[PAProtocolViewController alloc] initWithNibName:@"PAProtocolViewController" bundle:nil];
            
            [controller setProtocolName:name];
            [controller setTitle:name];
            
            [[self navigationController] pushViewController:controller animated:YES];
            
            break;
        }
    }
}

#pragma mark - Gesture recognizers

- (IBAction)gestureRecognizerDidTapTableView:(UITapGestureRecognizer *)recognizer
{
    [searchBar resignFirstResponder];
}

#pragma mark - Keyboard notifications

- (void)PA_keyboardWillChangeFrame:(NSNotification *)notification
{
    CGRect afterFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    afterFrame = [[self view] convertRect:afterFrame fromView:nil];
    
    CGFloat duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    UIViewAnimationOptions options = 0;
    
    switch([[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue])
    {
        case UIViewAnimationCurveEaseInOut: options = UIViewAnimationOptionCurveEaseInOut; break;
        case UIViewAnimationCurveEaseIn:    options = UIViewAnimationCurveEaseIn;          break;
        case UIViewAnimationCurveEaseOut:   options = UIViewAnimationCurveEaseOut;         break;
        case UIViewAnimationCurveLinear:    options = UIViewAnimationCurveLinear;          break;
    }
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:options
                     animations:
     ^{
         CGRect tableFrame = [tableView frame];
         
         tableFrame.size.height = MIN(CGRectGetMinY(afterFrame), CGRectGetMaxY([[self view] bounds])) - CGRectGetMinY(tableFrame);
         
         [tableView setFrame:tableFrame];
     }
                     completion:nil];
}

@end
