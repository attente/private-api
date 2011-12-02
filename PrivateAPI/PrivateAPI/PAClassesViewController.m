//
//  PAClassesViewController.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-17.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAClassesViewController.h"
#import "PAClassViewController.h"
#import "PAProtocolViewController.h"
#import "PAAPI.h"

enum PAClassesViewControllerMode
{
    PAClassesViewControllerModeBasic,
    PAClassesViewControllerModeDetailed,
    PAClassesViewControllerModeAlphabetical,
};

@interface PAClassesViewController ()

@property(nonatomic, copy) NSArray *visibleClasses;
@property(nonatomic, copy) NSArray *visibleProtocols;

#pragma mark - Keyboard notifications

- (void)PA_keyboardWillChangeFrame:(NSNotification *)notification;

@end

@implementation PAClassesViewController

@synthesize searchBar, tableView, toolbar, modeControl, tapRecognizer, visibleClasses, visibleProtocols;

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

- (NSArray *)visibleClasses
{
    if(visibleClasses == nil)
    {
        switch([modeControl selectedSegmentIndex])
        {
            case PAClassesViewControllerModeBasic:
            case PAClassesViewControllerModeDetailed:
            {
                NSMutableArray *classes = [NSMutableArray array];
                
                if([[searchBar text] length] == 0)
                {
                    for(PATree *tree in [PAAPI classHierarchies])
                        [classes addObjectsFromArray:[tree preorderTraversal]];
                }
                else
                {
                    BOOL (^test)(PATree *) =
                    ^ BOOL (PATree *tree)
                    {
                        return [[tree name] rangeOfString:[searchBar text] options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound;
                    };
                    
                    BOOL includeSubhierarchies = [modeControl selectedSegmentIndex] == PAClassesViewControllerModeDetailed;
                    
                    for(PATree *tree in [PAAPI classHierarchies])
                        [classes addObjectsFromArray:[tree preorderTraversalPassingTest:test includingSubhierarchies:includeSubhierarchies]];
                }
                
                visibleClasses = classes;
                
                break;
            }
            case PAClassesViewControllerModeAlphabetical:
            {
                if([[searchBar text] length] == 0)
                    visibleClasses = [PAAPI classList];
                else
                    visibleClasses = [[PAAPI classList] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name contains[cd] %@", [searchBar text]]];
                
                break;
            }
        }
    }
    
    return visibleClasses;
}

- (NSArray *)visibleProtocols
{
    if(visibleProtocols == nil)
    {
        if([[searchBar text] length] == 0)
            visibleProtocols = [PAAPI protocolList];
        else
            visibleProtocols = [[PAAPI protocolList] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name contains[cd] %@", [searchBar text]]];
    }
    
    return visibleProtocols;
}

- (IBAction)segmentedControlDidChangeValue:(id)sender
{
    [self setVisibleClasses:nil];
    [self setVisibleProtocols:nil];
    
    [tableView reloadData];
}

#pragma mark - UISearchBarDelegate conformance

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self setVisibleClasses:nil];
    [self setVisibleProtocols:nil];
    
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
        case 0:  return [[self visibleClasses]   count];
        case 1:  return [[self visibleProtocols] count];
        default: return 0;
    }
}

- (CGFloat)tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:  return [[self visibleClasses]   count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        case 1:  return [[self visibleProtocols] count] > 0 ? [aTableView sectionHeaderHeight] : 0.0;
        default: return 0.0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:  return @"Classes";
        case 1:  return @"Protocols";
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch([indexPath section])
    {
        case 0:
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
            
            PATree *class = [[self visibleClasses] objectAtIndex:[indexPath row]];
            
            [cell setIndentationLevel:[modeControl selectedSegmentIndex] == PAClassesViewControllerModeAlphabetical ? 0 : [class depth]];
            [[cell textLabel] setText:[class name]];
            
            return cell;
        }
        case 1:
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
            
            PATree *protocol = [[self visibleProtocols] objectAtIndex:[indexPath row]];
            
            [cell setIndentationLevel:0];
            [[cell textLabel] setText:[protocol name]];
            
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
            NSString *className = [[[self visibleClasses] objectAtIndex:[indexPath row]] name];
            
            PAClassViewController *controller = [[PAClassViewController alloc] initWithNibName:@"PAClassViewController" bundle:nil];
            
            [controller setClassName:className];
            [controller setTitle:className];
            
            [[self navigationController] pushViewController:controller animated:YES];
            
            break;
        }
        case 1:
        {
            NSString *protocolName = [[[self visibleProtocols] objectAtIndex:[indexPath row]] name];
            
            PAProtocolViewController *controller = [[PAProtocolViewController alloc] initWithNibName:@"PAProtocolViewController" bundle:nil];
            
            [controller setProtocolName:protocolName];
            [controller setTitle:protocolName];
            
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
         
         tableFrame.size.height = MIN(CGRectGetMinY(afterFrame), CGRectGetMinY([toolbar frame])) - CGRectGetMinY(tableFrame);
         
         [tableView setFrame:tableFrame];
     }
                     completion:nil];
}

@end
