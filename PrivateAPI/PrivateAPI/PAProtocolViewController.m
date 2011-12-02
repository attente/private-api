//
//  PAProtocolViewController.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-26.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAProtocolViewController.h"
#import "PAPropertyTableViewCell.h"
#import "PAMethodTableViewCell.h"
#import "PAAPI.h"

enum PAProtocolViewControllerSection
{
    PAProtocolViewControllerSectionProtocols,
    PAProtocolViewControllerSectionExtensions,
    PAProtocolViewControllerSectionProperties,
    PAProtocolViewControllerSectionMethods,
    PAProtocolViewControllerSectionCount
};

@interface PAProtocolViewController ()

@property(nonatomic, retain) UINib                 *propertyCellNib;
@property(nonatomic, retain) PAMethodTableViewCell *methodCell;
@property(nonatomic, retain) PATree                *protocolTree;
@property(nonatomic, copy)   NSArray               *protocols;
@property(nonatomic, copy)   NSArray               *extensions;
@property(nonatomic, copy)   NSArray               *properties;
@property(nonatomic, copy)   NSArray               *methods;
@property(nonatomic, copy)   NSArray               *visibleProtocols;
@property(nonatomic, copy)   NSArray               *visibleExtensions;
@property(nonatomic, copy)   NSArray               *visibleProperties;
@property(nonatomic, copy)   NSArray               *visibleMethods;

#pragma mark - Keyboard notifications

- (void)PA_keyboardWillChangeFrame:(NSNotification *)notification;

@end

@implementation PAProtocolViewController

@synthesize searchBar, tableView, tapRecognizer, propertyCell, propertyCellNib, methodCell, protocolName, protocolTree, protocols, extensions, properties, methods, visibleProtocols, visibleExtensions, visibleProperties, visibleMethods;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PA_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [tableView addGestureRecognizer:tapRecognizer];
}

- (void)setProtocolName:(NSString *)aProtocolName
{
    if(![aProtocolName isEqualToString:protocolName])
    {
        protocolName = aProtocolName;
        
        [self setProtocolTree:[PAAPI protocolTreeForProtocolName:protocolName]];
        [self setProtocols:nil];
        [self setExtensions:nil];
        [self setProperties:nil];
        [self setMethods:nil];
        
        [tableView reloadData];
    }
}

- (NSArray *)protocols
{
    if(protocols == nil)
        protocols = [[[self protocolTree] parents] valueForKey:@"name"];
    
    return protocols;
}

- (void)setProtocols:(NSArray *)someProtocols
{
    protocols = [someProtocols copy];
    
    [self setVisibleProtocols:nil];
}

- (NSArray *)extensions
{
    if(extensions == nil)
        extensions = [[[self protocolTree] children] valueForKey:@"name"];
    
    return extensions;
}

- (void)setExtensions:(NSArray *)someExtensions
{
    extensions = [someExtensions copy];
    
    [self setVisibleExtensions:nil];
}

- (NSArray *)properties
{
    if(properties == nil)
        properties = [PAAPI propertiesForProtocolName:protocolName];
    
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
        methods = [PAAPI methodsForProtocolName:protocolName];
    
    return methods;
}

- (void)setMethods:(NSArray *)someMethods
{
    methods = [someMethods copy];
    
    [self setVisibleMethods:nil];
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

- (NSArray *)visibleExtensions
{
    if(visibleExtensions == nil)
    {
        if([[searchBar text] length] == 0)
            visibleExtensions = [self extensions];
        else
            visibleExtensions = [[self extensions] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self contains[cd] %@", [searchBar text]]];
    }
    
    return visibleExtensions;
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

#pragma mark - UISearchBarDelegate conformance

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self setVisibleProtocols:nil];
    [self setVisibleExtensions:nil];
    [self setVisibleProperties:nil];
    [self setVisibleMethods:nil];
    
    [tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    [aSearchBar resignFirstResponder];
}

#pragma mark - UITableViewDataSource and UITableViewDelegate conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return PAProtocolViewControllerSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case PAProtocolViewControllerSectionProtocols:  return [[self visibleProtocols]  count];
        case PAProtocolViewControllerSectionExtensions: return [[self visibleExtensions] count];
        case PAProtocolViewControllerSectionProperties: return [[self visibleProperties] count];
        case PAProtocolViewControllerSectionMethods:    return [[self visibleMethods]    count];
        default:                                        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case PAProtocolViewControllerSectionProtocols:  return [[self visibleProtocols]  count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case PAProtocolViewControllerSectionExtensions: return [[self visibleExtensions] count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case PAProtocolViewControllerSectionProperties: return [[self visibleProperties] count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case PAProtocolViewControllerSectionMethods:    return [[self visibleMethods]    count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        default:                                        return 0.0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case PAProtocolViewControllerSectionProtocols:  return @"Protocols";
        case PAProtocolViewControllerSectionExtensions: return @"Extensions";
        case PAProtocolViewControllerSectionProperties: return @"Properties";
        case PAProtocolViewControllerSectionMethods:    return @"Methods";
        default:                                        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch([indexPath section])
    {
        case PAProtocolViewControllerSectionProtocols:  return 36.0;
        case PAProtocolViewControllerSectionExtensions: return 36.0;
        case PAProtocolViewControllerSectionProperties: return 83.0;
        case PAProtocolViewControllerSectionMethods:
        {
            if(methodCell == nil)
            {
                methodCell = [[PAMethodTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                
                [methodCell setContentViewInsets:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)];
            }
            
            [methodCell setMethod:[[self visibleMethods] objectAtIndex:[indexPath row]]];
            
            return [methodCell sizeThatFits:CGSizeMake([aTableView bounds].size.width, CGFLOAT_MAX)].height;
        }
        default:                                        return  0.0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch([indexPath section])
    {
        case PAProtocolViewControllerSectionProtocols:
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
        case PAProtocolViewControllerSectionExtensions:
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
            
            [[cell textLabel] setText:[[self visibleExtensions] objectAtIndex:[indexPath row]]];
            
            return cell;
        }
        case PAProtocolViewControllerSectionProperties:
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
        case PAProtocolViewControllerSectionMethods:
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
        default: return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch([indexPath section])
    {
        case PAProtocolViewControllerSectionProtocols:
        case PAProtocolViewControllerSectionExtensions:
        {
            NSArray  *names = [indexPath section] == PAProtocolViewControllerSectionProtocols ? [self visibleProtocols] : [self visibleExtensions];
            NSString *name  = [names objectAtIndex:[indexPath row]];
            
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
