//
//  PAPrivateAPI.m
//  PrivateAPI
//
//  Created by William Hua on 11-11-20.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PAAPI.h"

static NSDictionary *classTrees;
static NSArray      *classList;
static NSArray      *classHierarchies;
static NSArray      *propertyList;
static NSArray      *methodList;

@interface PAAPI ()

+ (NSString *)PA_typeForEncoding:(NSString *)encoding;

@end

@implementation PAAPI

+ (void)initialize
{
    if(self == [PAAPI class])
    {
        NSSet *badClassNames = [NSSet setWithObjects:
                                @"__NSGenericDeallocHandler",
                                @"_NSZombie_",
                                @"Object",
                                @"NSMessageBuilder",
                                nil];
        
        int count = objc_getClassList(NULL, 0);
        __unsafe_unretained Class *classes = (__unsafe_unretained Class *)malloc(count * sizeof(Class));
        objc_getClassList(classes, count);
        
        NSMutableDictionary *hierarchies = [NSMutableDictionary dictionary];
        NSMutableDictionary *lookupTable = [NSMutableDictionary dictionaryWithCapacity:count];
        NSMutableDictionary *trees       = [NSMutableDictionary dictionaryWithCapacity:count];
        NSMutableArray      *properties  = [NSMutableArray array];
        NSMutableArray      *methods     = [NSMutableArray array];
        
        for(int index = 0; index < count; index++)
        {
            NSString *className = NSStringFromClass(classes[index]);
            
            if([badClassNames containsObject:className]) continue;
            
            NSMutableDictionary *classHierarchy = [lookupTable objectForKey:className];
            
            if(classHierarchy == nil)
            {
                classHierarchy = [NSMutableDictionary dictionary];
                [lookupTable setObject:classHierarchy forKey:className];
            }
            
            PATree *classTree = [trees objectForKey:className];
            
            if(classTree == nil)
            {
                classTree = [PATree treeWithName:className];
                [trees setObject:classTree forKey:className];
            }
            
            Class superclass = [classes[index] superclass];
            
            if(superclass != Nil)
            {
                NSString            *superclassName      = NSStringFromClass(superclass);
                NSMutableDictionary *superclassHierarchy = [lookupTable objectForKey:superclassName];
                
                if(superclassHierarchy == nil)
                {
                    superclassHierarchy = [NSMutableDictionary dictionaryWithCapacity:1];
                    [lookupTable setObject:superclassHierarchy forKey:superclassName];
                }
                
                [superclassHierarchy setObject:classHierarchy forKey:className];
                
                PATree *superclassTree = [trees objectForKey:superclassName];
                
                if(superclassTree == nil)
                {
                    superclassTree = [PATree treeWithName:superclassName];
                    [trees setObject:superclassTree forKey:superclassName];
                }
                
                [classTree setParents:[NSArray arrayWithObject:superclassTree]];
            }
            else [hierarchies setObject:classHierarchy forKey:className];
            
            unsigned int count;
            
            objc_property_t *runtimeProperties = class_copyPropertyList(classes[index], &count);
            
            for(int subindex = 0; subindex < count; subindex++)
                [properties addObject:[PAProperty propertyWithRuntimeObject:runtimeProperties[subindex] forOwner:classTree]];
            
            free(runtimeProperties);
            
            Method *runtimeMethods = class_copyMethodList(classes[index], &count);
            
            for(int subindex = 0; subindex < count; subindex++)
                [methods addObject:[PAMethod methodWithRuntimeObject:runtimeMethods[subindex] forOwner:classTree]];
            
            free(runtimeMethods);
        }
        
        [trees enumerateKeysAndObjectsUsingBlock:
         ^(id key, id obj, BOOL *stop)
         {
             [obj setChildren:[trees objectsForKeys:[[[lookupTable objectForKey:key] allKeys] sortedArrayUsingSelector:@selector(compare:)] notFoundMarker:[PATree tree]]];
         }];
        
        classTrees       = trees;
        classList        = [trees objectsForKeys:[[lookupTable allKeys] sortedArrayUsingSelector:@selector(compare:)] notFoundMarker:[PATree tree]];
        classHierarchies = [trees objectsForKeys:[[hierarchies allKeys] sortedArrayUsingSelector:@selector(compare:)] notFoundMarker:[PATree tree]];
        
        for(PATree *rootClasses in classHierarchies)
            [rootClasses setDepth:0];
        
        free(classes);
        
        propertyList = [properties sortedArrayUsingComparator:
                        ^NSComparisonResult(id obj1, id obj2)
                        {
                            return [[obj1 name] compare:[obj2 name]];
                        }];
        
        methodList = [methods sortedArrayUsingComparator:
                      ^NSComparisonResult(id obj1, id obj2)
                      {
                          return [[obj1 name] compare:[obj2 name]];
                      }];
    }
}

+ (NSArray *)classList
{
    return classList;
}

+ (NSArray *)classHierarchies
{
    return classHierarchies;
}

+ (NSArray *)propertyList
{
    return propertyList;
}

+ (NSArray *)methodList
{
    return methodList;
}

+ (PATree *)classTreeForClassName:(NSString *)className
{
    return [classTrees objectForKey:className];
}

+ (NSArray *)protocolNamesForClassName:(NSString *)className
{
    unsigned int count;
    
    Protocol * __unsafe_unretained *protocols = class_copyProtocolList(NSClassFromString(className), &count);
    
    NSMutableArray *protocolNames = [NSMutableArray arrayWithCapacity:count];
    
    for(int index = 0; index < count; index++)
        [protocolNames addObject:NSStringFromProtocol(protocols[index])];
    
    free(protocols);
    
    return protocolNames;
}

+ (NSArray *)propertiesForClassName:(NSString *)className
{
    unsigned int count;
    
    objc_property_t *runtimeObjects = class_copyPropertyList(NSClassFromString(className), &count);
    
    NSMutableArray *properties = [NSMutableArray arrayWithCapacity:count];
    
    for(int index = 0; index < count; index++)
        [properties addObject:[PAProperty propertyWithRuntimeObject:runtimeObjects[index] forOwner:[PAAPI classTreeForClassName:className]]];
    
    free(runtimeObjects);
    
    return properties;
}

+ (NSArray *)methodsForClassName:(NSString *)className
{
    unsigned int count;
    
    Method *runtimeObjects = class_copyMethodList(NSClassFromString(className), &count);
    
    NSMutableArray *methods = [NSMutableArray arrayWithCapacity:count];
    
    for(int index = 0; index < count; index++)
        [methods addObject:[PAMethod methodWithRuntimeObject:runtimeObjects[index] forOwner:[PAAPI classTreeForClassName:className]]];
    
    free(runtimeObjects);
    
    return methods;
}

+ (NSArray *)ivarsForClassName:(NSString *)className
{
    unsigned int count;
    
    Ivar *runtimeObjects = class_copyIvarList(NSClassFromString(className), &count);
    
    NSMutableArray *ivars = [NSMutableArray arrayWithCapacity:count];
    
    for(int index = 0; index < count; index++)
        [ivars addObject:[PAIvar ivarWithRuntimeObject:runtimeObjects[index] forOwner:[PAAPI classTreeForClassName:className]]];
    
    free(runtimeObjects);
    
    return ivars;
}

+ (NSString *)PA_typeForEncoding:(NSString *)encoding
{
    switch([encoding characterAtIndex:0])
    {
        case 'B': return @"bool";
        case 'C': return @"unsigned char";
        case 'c': return @"char";
        case 'd': return @"double";
        case 'f': return @"float";
        case 'I': return @"unsigned int";
        case 'i': return @"int";
        case 'L': return @"unsigned long";
        case 'l': return @"long";
        case 'Q': return @"unsigned long long";
        case 'q': return @"long long";
        case 'S': return @"unsigned short";
        case 's': return @"short";
        case 'v': return @"void";
        case '*': return @"char *";
        case '@':
        {
            NSInteger length = [encoding length];
            
            return length < 3 ? @"id" : [[encoding substringWithRange:NSMakeRange(2, length - 3)] stringByAppendingString:@" *"];
        }
        case '#': return @"Class";
        case ':': return @"SEL";
        case '[':
        {
            encoding = [encoding substringWithRange:NSMakeRange(1, [encoding length] - 2)];
            
            NSScanner *scanner = [NSScanner scannerWithString:encoding];
            
            NSInteger length;
            
            [scanner scanInteger:&length];
            
            encoding = [encoding substringFromIndex:[scanner scanLocation]];
            
            return [NSString stringWithFormat:@"%@[%d]", [PAAPI PA_typeForEncoding:encoding], length];
        }
        case '{':
        case '(':
        {
            NSScanner *scanner = [NSScanner scannerWithString:[encoding substringWithRange:NSMakeRange(1, [encoding length] - 2)]];
            
            NSString *name;
            
            [scanner scanUpToString:@"=" intoString:&name];
        }
        case 'b':
        {
            NSScanner *scanner = [NSScanner scannerWithString:[encoding substringFromIndex:1]];
            
            NSInteger bits;
            
            [scanner scanInteger:&bits];
            
            return [@"int" stringByAppendingFormat:@"%d", bits];
        }
        case '^':
        {
            NSString *type = [PAAPI PA_typeForEncoding:[encoding substringFromIndex:1]];
            
            return [type stringByAppendingString:[type hasSuffix:@"*"] ? @"*" : @" *"];
        }
        case '?': return @"?";
        case 'r': return [@"const "  stringByAppendingString:[PAAPI PA_typeForEncoding:[encoding substringFromIndex:1]]];
        case 'n': return [@"in "     stringByAppendingString:[PAAPI PA_typeForEncoding:[encoding substringFromIndex:1]]];
        case 'N': return [@"inout "  stringByAppendingString:[PAAPI PA_typeForEncoding:[encoding substringFromIndex:1]]];
        case 'o': return [@"out "    stringByAppendingString:[PAAPI PA_typeForEncoding:[encoding substringFromIndex:1]]];
        case 'O': return [@"bycopy " stringByAppendingString:[PAAPI PA_typeForEncoding:[encoding substringFromIndex:1]]];
        case 'R': return [@"byref "  stringByAppendingString:[PAAPI PA_typeForEncoding:[encoding substringFromIndex:1]]];
        case 'V': return [@"oneway " stringByAppendingString:[PAAPI PA_typeForEncoding:[encoding substringFromIndex:1]]];
        default:  return nil;
    }
}

@end

@implementation PATree

@synthesize name, depth, parents, children;

+ (PATree *)tree
{
    return [PATree treeWithName:nil];
}

+ (PATree *)treeWithName:(NSString *)name
{
    return [[PATree alloc] initWithName:name];
}

- (id)initWithName:(NSString *)aName
{
    if((self = [super init]) != nil)
        [self setName:aName];
    
    return self;
}

- (void)setDepth:(NSInteger)aDepth
{
    depth = aDepth;
    
    for(PATree *child in children)
        [child setDepth:depth + 1];
}

- (NSArray *)preorderTraversal
{
    return [self preorderTraversalPassingTest:nil];
}

- (NSArray *)preorderTraversalPassingTest:(BOOL (^)(PATree *))test
{
    return [self preorderTraversalPassingTest:nil includingSubhierarchies:NO];
}

- (NSArray *)preorderTraversalPassingTest:(BOOL (^)(PATree *))test includingSubhierarchies:(BOOL)includeSubhierarchies
{
    NSMutableArray *traversal = [NSMutableArray arrayWithObject:self];
    
    if(test == nil || test(self))
    {
        for(PATree *child in [self children])
            [traversal addObjectsFromArray:[child preorderTraversalPassingTest:includeSubhierarchies ? nil : test includingSubhierarchies:includeSubhierarchies]];
    }
    else
    {
        for(PATree *child in [self children])
            [traversal addObjectsFromArray:[child preorderTraversalPassingTest:test includingSubhierarchies:includeSubhierarchies]];
        
        if([traversal count] == 1) [traversal removeAllObjects];
    }
    
    return traversal;
}

@end

@interface PAProperty ()

- (void)PA_parseAttributes:(NSString *)attributes;

@end

@implementation PAProperty

@synthesize name, type, readonly, setterSemantics, nonatomic, getter, setter, dynamic, weak, garbageCollected, backingIvar, owner;

+ (PAProperty *)propertyWithRuntimeObject:(objc_property_t)object forOwner:(PATree *)anOwner
{
    return [[PAProperty alloc] initWithRuntimeObject:object forOwner:anOwner];
}

- (id)initWithRuntimeObject:(objc_property_t)object forOwner:(PATree *)anOwner
{
    if((self = [super init]) != nil)
    {
        [self setName:[NSString stringWithCString:property_getName(object) encoding:NSASCIIStringEncoding]];
        [self PA_parseAttributes:[NSString stringWithCString:property_getAttributes(object) encoding:NSASCIIStringEncoding]];
        [self setOwner:anOwner];
    }
    
    return self;
}

- (void)PA_parseAttributes:(NSString *)attributes
{
    for(NSString *attribute in [attributes componentsSeparatedByString:@","])
    {
        switch([attribute characterAtIndex:0])
        {
            case 'T':
            {
                [self setType:[PAAPI PA_typeForEncoding:[attribute substringFromIndex:1]]];
                break;
            }
            case 'R':
            {
                [self setReadonly:YES];
                break;
            }
            case 'C':
            {
                [self setSetterSemantics:PAPropertySetterSemanticsCopy];
                break;
            }
            case '&':
            {
                [self setSetterSemantics:PAPropertySetterSemanticsRetain];
                break;
            }
            case 'N':
            {
                [self setNonatomic:YES];
                break;
            }
            case 'G':
            {
                [self setGetter:[attribute substringFromIndex:1]];
                break;
            }
            case 'S':
            {
                [self setSetter:[attribute substringFromIndex:1]];
                break;
            }
            case 'D':
            {
                [self setDynamic:YES];
                break;
            }
            case 'W':
            {
                [self setWeak:YES];
                break;
            }
            case 'P':
            {
                [self setGarbageCollected:YES];
                break;
            }
            case 'V':
            {
                [self setBackingIvar:[attribute substringFromIndex:1]];
                break;
            }
        }
    }
}

@end

@implementation PAMethod

@synthesize name, returnType, argumentTypes, owner;

+ (PAMethod *)methodWithRuntimeObject:(Method)object forOwner:(PATree *)anOwner
{
    return [[PAMethod alloc] initWithRuntimeObject:object forOwner:anOwner];
}

- (id)initWithRuntimeObject:(Method)object forOwner:(PATree *)anOwner
{
    if((self = [super init]) != nil)
    {
        [self setName:[NSString stringWithCString:sel_getName(method_getName(object)) encoding:NSASCIIStringEncoding]];
        
        char *type = method_copyReturnType(object);
        
        [self setReturnType:[PAAPI PA_typeForEncoding:[NSString stringWithCString:type encoding:NSASCIIStringEncoding]]];
        
        free(type);
        
        unsigned int count = method_getNumberOfArguments(object) - 2;
        
        NSMutableArray *types = [NSMutableArray arrayWithCapacity:count];
        
        for(int index = 0; index < count; index++)
        {
            type = method_copyArgumentType(object, 2 + index);
            
            [types addObject:[PAAPI PA_typeForEncoding:[NSString stringWithCString:type encoding:NSASCIIStringEncoding]]];
            
            free(type);
        }
        
        [self setArgumentTypes:types];
        [self setOwner:anOwner];
    }
    
    return self;
}

@end

@implementation PAIvar

@synthesize name, type, offset, owner;

+ (PAIvar *)ivarWithRuntimeObject:(Ivar)object forOwner:(PATree *)anOwner
{
    return [[PAIvar alloc] initWithRuntimeObject:object forOwner:anOwner];
}

- (id)initWithRuntimeObject:(Ivar)object forOwner:(PATree *)anOwner
{
    if((self = [super init]) != nil)
    {
        [self setName:[NSString stringWithCString:ivar_getName(object) encoding:NSASCIIStringEncoding]];
        [self setType:[PAAPI PA_typeForEncoding:[NSString stringWithCString:ivar_getTypeEncoding(object) encoding:NSASCIIStringEncoding]]];
        [self setOffset:ivar_getOffset(object)];
        [self setOwner:anOwner];
    }
    
    return self;
}

@end
