//
//  PAMethodsViewController.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-23.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAMethodsViewController.h"
#import "PAClassViewController.h"
#import "PAProtocolViewController.h"
#import "PAPropertyTableViewCell.h"
#import "PAMethodTableViewCell.h"
#import "PAAPI.h"

@interface PAMethodsViewController ()

@property(nonatomic, retain) UINib                 *propertyCellNib;
@property(nonatomic, retain) PAMethodTableViewCell *methodCell;
@property(nonatomic, copy)   NSArray               *properties;
@property(nonatomic, copy)   NSArray               *methods;
@property(nonatomic, copy)   NSArray               *methodHeights;
@property(nonatomic, copy)   NSArray               *visibleProperties;
@property(nonatomic, copy)   NSArray               *visibleMethods;
@property(nonatomic, copy)   NSArray               *visibleMethodHeights;

#pragma mark - Keyboard notifications

- (void)PA_keyboardWillChangeFrame:(NSNotification *)notification;

@end

@implementation PAMethodsViewController

@synthesize searchBar, tableView, tapRecognizer, propertyCell, propertyCellNib, methodCell, properties, methods, methodHeights, visibleProperties, visibleMethods, visibleMethodHeights;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PA_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [tableView addGestureRecognizer:tapRecognizer];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSArray *)properties
{
    if(properties == nil)
        properties = [PAAPI propertyList];
    
    return properties;
}

- (NSArray *)methods
{
    if(methods == nil)
    {
        methods = [PAAPI methodList];
        
        NSMutableArray *heights = [NSMutableArray arrayWithCapacity:[methods count]];
        
        if(methodCell == nil)
        {
            methodCell = [[PAMethodTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            
            [methodCell setContentViewInsets:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)];
        }
        
        for(PAMethod *method in methods)
        {
            [methodCell setMethod:method];
            
            [heights addObject:[NSNumber numberWithFloat:[methodCell sizeThatFits:CGSizeMake([tableView bounds].size.width, CGFLOAT_MAX)].height]];
        }
        
        methodHeights = heights;
    }
    
    return methods;
}

- (NSArray *)methodHeights
{
    [self methods];
    
    return methodHeights;
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
        {
            visibleMethods       = [self methods];
            visibleMethodHeights = [self methodHeights];
        }
        else
        {
            NSIndexSet *indices = [[self methods] indexesOfObjectsPassingTest:
                                   ^ BOOL (id obj, NSUInteger idx, BOOL *stop)
                                   {
                                       return [[obj name] rangeOfString:[searchBar text] options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound;
                                   }];
            
            visibleMethods       = [[self methods]       objectsAtIndexes:indices];
            visibleMethodHeights = [[self methodHeights] objectsAtIndexes:indices];
        }
    }
    
    return visibleMethods;
}

- (void)setVisibleMethods:(NSArray *)someVisibleMethods
{
    visibleMethods = [someVisibleMethods copy];
    
    [self setVisibleMethodHeights:nil];
}

- (NSArray *)visibleMethodHeights
{
    [self visibleMethods];
    
    return visibleMethodHeights;
}

#pragma mark - UISearchBarDelegate conformance

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)someSearchText
{
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:  return [[self visibleProperties] count];
        case 1:  return [[self visibleMethods]    count];
        default: return 0;
    }
}

- (CGFloat)tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:  return [[self visibleProperties] count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case 1:  return [[self visibleMethods]    count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        default: return 0.0;
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
        case 0:  return 83.0;
        case 1:  return [[[self visibleMethodHeights] objectAtIndex:[indexPath row]] floatValue];
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
                
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
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
        case 1:
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
        case 0:
        {
            PAProperty *property  = [[self visibleProperties] objectAtIndex:[indexPath row]];
            NSString   *ownerName = [[property owner] name];
            
            if([property owner] == [PAAPI classTreeForClassName:ownerName])
            {
                PAClassViewController *controller = [[PAClassViewController alloc] initWithNibName:@"PAClassViewController" bundle:nil];
                
                [controller setClassName:ownerName];
                [controller setTitle:ownerName];
                
                [[self navigationController] pushViewController:controller animated:YES];
            }
            else
            {
                PAProtocolViewController *controller = [[PAProtocolViewController alloc] initWithNibName:@"PAProtocolViewController" bundle:nil];
                
                [controller setProtocolName:ownerName];
                [controller setTitle:ownerName];
                
                [[self navigationController] pushViewController:controller animated:YES];
            }
            
            break;
        }
        case 1:
        {
            PAMethod *method    = [[self visibleMethods] objectAtIndex:[indexPath row]];
            NSString *ownerName = [[method owner] name];
            
            if([method owner] == [PAAPI classTreeForClassName:ownerName])
            {
                PAClassViewController *controller = [[PAClassViewController alloc] initWithNibName:@"PAClassViewController" bundle:nil];
                
                [controller setClassName:ownerName];
                [controller setTitle:ownerName];
                
                [[self navigationController] pushViewController:controller animated:YES];
            }
            else
            {
                PAProtocolViewController *controller = [[PAProtocolViewController alloc] initWithNibName:@"PAProtocolViewController" bundle:nil];
                
                [controller setProtocolName:ownerName];
                [controller setTitle:ownerName];
                
                [[self navigationController] pushViewController:controller animated:YES];
            }
            
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
