//
//  PAClassesViewController.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-17.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAClassesViewController.h"
#import <objc/runtime.h>

enum PAClassesViewControllerMode
{
    PAClassesViewControllerModeBasic,
    PAClassesViewControllerModeDetailed,
    PAClassesViewControllerModeAlphabetical,
};

@interface PAClassesViewController ()

@property(nonatomic, copy) NSDictionary *classHierarchy;
@property(nonatomic, copy) NSArray      *classTraversal;
@property(nonatomic, copy) NSArray      *alphabeticalClasses;

#pragma mark - Keyboard notifications

- (void)PA_keyboardWillChangeFrame:(NSNotification *)notification;

#pragma mark - Class hierarchy traversal

- (NSArray *)PA_preorderTraversalForHierarchy:(NSDictionary *)hierarchy;
- (NSArray *)PA_preorderTraversalForHierarchy:(NSDictionary *)hierarchy passingTest:(BOOL (^)(id key, id subhierarchy))test includingSubhierarchies:(BOOL)includeSubhierarchies;
- (NSArray *)PA_preorderTraversalForHierarchy:(NSDictionary *)hierarchy atDepth:(NSInteger)depth passingTest:(BOOL (^)(id key, id subhierarchy))test includingSubhierarchies:(BOOL)includeSubhierarchies;

@end

@interface PANode : NSObject

@property(nonatomic, copy)   id        key;
@property(nonatomic, assign) NSInteger depth;

- (id)initWithKey:(id)aKey;
- (id)initWithKey:(id)aKey depth:(NSInteger)aDepth;

@end

@implementation PAClassesViewController

@synthesize searchBar, tableView, toolbar, modeControl, tapRecognizer;
@synthesize alphabeticalClasses, classHierarchy, classTraversal;

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
    
    [tableView registerNib:[UINib nibWithNibName:@"PAClassTableViewCell" bundle:nil] forCellReuseIdentifier:@"PAClassTableViewCell"];
    
    NSInteger classCount = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(classCount * sizeof(Class));
    objc_getClassList(classes, classCount);
    
    NSSet *redactedClasses = [NSSet setWithObjects:
                              @"__NSGenericDeallocHandler",
                              @"_NSZombie_",
                              @"Object",
                              @"NSMessageBuilder",
                              nil];
    
    NSMutableDictionary *hierarchy      = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *subhierarchies = [[NSMutableDictionary alloc] initWithCapacity:classCount];
    NSMutableArray      *allClasses     = [[NSMutableArray alloc] initWithCapacity:classCount];
    
    for(NSInteger index = 0; index < classCount; index++)
    {
        NSString *className = NSStringFromClass(classes[index]);
        
        if([redactedClasses containsObject:className]) continue;
        
        NSDictionary *subhierarchy = [subhierarchies objectForKey:className];
        
        if(subhierarchy == nil)
        {
            subhierarchy = [NSMutableDictionary dictionary];
            [subhierarchies setObject:subhierarchy forKey:className];
        }
        
        Class superclass = [classes[index] superclass];
        
        if(superclass != Nil)
        {
            NSString            *superclassName      = NSStringFromClass([classes[index] superclass]);
            NSMutableDictionary *superclassHierarchy = [subhierarchies objectForKey:superclassName];
            
            if(superclassHierarchy == nil)
            {
                superclassHierarchy = [NSMutableDictionary dictionaryWithCapacity:1];
                [subhierarchies setObject:superclassHierarchy forKey:superclassName];
            }
            
            [superclassHierarchy setObject:subhierarchy forKey:className];
        }
        else [hierarchy setObject:subhierarchy forKey:className];
        
        [allClasses addObject:className];
    }
    
    [self setClassHierarchy:hierarchy];
    [self setAlphabeticalClasses:[allClasses sortedArrayUsingSelector:@selector(compare:)]];
    
    free(classes);
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

- (NSArray *)classTraversal
{
    if(classTraversal == nil)
    {
        BOOL (^match)(id, id) = ^BOOL(id key, id subhierarchy)
        {
            return [key rangeOfString:[searchBar text] options:NSCaseInsensitiveSearch].location != NSNotFound;
        };
        
        switch([modeControl selectedSegmentIndex])
        {
            case PAClassesViewControllerModeBasic:
            case PAClassesViewControllerModeDetailed:
            {
                if([[searchBar text] length] > 0)
                {
                    BOOL includeSubhierarchies = [modeControl selectedSegmentIndex] == PAClassesViewControllerModeDetailed;
                    
                    classTraversal = [self PA_preorderTraversalForHierarchy:classHierarchy passingTest:match includingSubhierarchies:includeSubhierarchies];
                }
                else
                    classTraversal = [self PA_preorderTraversalForHierarchy:classHierarchy];
                
                break;
            }
            case PAClassesViewControllerModeAlphabetical:
            {
                NSMutableArray *traversal = [[NSMutableArray alloc] init];
                
                if([[searchBar text] length] > 0)
                {
                    for(NSString *className in alphabeticalClasses)
                    {
                        if(match(className, nil))
                            [traversal addObject:[[PANode alloc] initWithKey:className]];
                    }
                }
                else
                {
                    for(NSString *className in alphabeticalClasses)
                        [traversal addObject:[[PANode alloc] initWithKey:className]];
                }
                
                classTraversal = traversal;
                
                break;
            }
        }
    }
    
    return classTraversal;
}

- (IBAction)segmentedControlDidChangeValue:(id)sender
{
    [self setClassTraversal:nil];
    
    [tableView reloadData];
}

#pragma mark - UISearchBarDelegate conformance

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self setClassTraversal:nil];
    
    [tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    [aSearchBar resignFirstResponder];
}

#pragma mark - UITableViewDataSource and UITableViewDelegate conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self classTraversal] count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"PAClassTableViewCell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];
    
    PANode *node = [[self classTraversal] objectAtIndex:[indexPath row]];
    
    [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
    [[cell textLabel] setMinimumFontSize:10.0];
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
    [[cell textLabel] setText:[node key]];
    [cell setIndentationLevel:[node depth]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - Gesture recognizers

- (IBAction)gestureRecognizerDidTapTableView:(UITapGestureRecognizer *)recognizer
{
    [searchBar resignFirstResponder];
}

#pragma mark - Keyboard notifications

- (void)PA_keyboardWillChangeFrame:(NSNotification *)notification
{
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    keyboardFrame = [[self view] convertRect:keyboardFrame  fromView:nil];
    
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
         
         tableFrame.size.height = MIN(CGRectGetMinY(keyboardFrame), CGRectGetMinY([toolbar frame])) - CGRectGetMinY(tableFrame);
         
         [tableView setFrame:tableFrame];
     }
                     completion:NULL];
}

#pragma mark - Class hierarchy traversal

- (NSArray *)PA_preorderTraversalForHierarchy:(NSDictionary *)hierarchy
{
    return [self PA_preorderTraversalForHierarchy:hierarchy passingTest:nil includingSubhierarchies:YES];
}

- (NSArray *)PA_preorderTraversalForHierarchy:(NSDictionary *)hierarchy passingTest:(BOOL (^)(id, id))test includingSubhierarchies:(BOOL)includeSubhierarchies
{
    return [self PA_preorderTraversalForHierarchy:hierarchy atDepth:0 passingTest:test includingSubhierarchies:includeSubhierarchies];
}

- (NSArray *)PA_preorderTraversalForHierarchy:(NSDictionary *)hierarchy atDepth:(NSInteger)depth passingTest:(BOOL (^)(id, id))test includingSubhierarchies:(BOOL)includeSubhierarchies
{
    BOOL (^yes)(id, id) = ^BOOL(id key, id subhierarchy) { return YES; };
    
    if(test == nil) test = yes;
    
    NSMutableArray *traversal = [[NSMutableArray alloc] init];
    
    for(id key in [[hierarchy allKeys] sortedArrayUsingSelector:@selector(compare:)])
    {
        NSDictionary *subhierarchy = [hierarchy objectForKey:key];
        
        if(test(key, subhierarchy))
        {
            [traversal addObject:[[PANode alloc] initWithKey:key depth:depth]];
            [traversal addObjectsFromArray:[self PA_preorderTraversalForHierarchy:subhierarchy atDepth:depth + 1 passingTest:includeSubhierarchies ? yes : test includingSubhierarchies:includeSubhierarchies]];
        }
        else
        {
            NSArray *subtraversal = [self PA_preorderTraversalForHierarchy:subhierarchy atDepth:depth + 1 passingTest:test includingSubhierarchies:includeSubhierarchies];
            
            if([subtraversal count] > 0)
            {
                [traversal addObject:[[PANode alloc] initWithKey:key depth:depth]];
                [traversal addObjectsFromArray:subtraversal];
            }
        }
    }
    
    return traversal;
}

@end

@implementation PANode

@synthesize key, depth;

- (id)initWithKey:(id)aKey
{
    return [self initWithKey:aKey depth:0];
}

- (id)initWithKey:(id)aKey depth:(NSInteger)aDepth
{
    if((self = [super init]) != nil)
    {
        [self setKey:aKey];
        [self setDepth:aDepth];
    }
    
    return self;
}

@end
