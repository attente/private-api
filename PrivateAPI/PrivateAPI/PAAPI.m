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
static NSArray      *protocolList;
static NSDictionary *protocolTrees;
static NSArray      *propertyList;
static NSArray      *methodList;

@interface PAAPI ()

+ (NSString *)PA_typeForEncoding:(NSString *)encoding;

@end

@interface NSScanner (PrivateAPI)

- (unichar)scanCharacter;

- (BOOL)scanType:(NSString * __autoreleasing *)type;

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
        
        int classCount = objc_getClassList(NULL, 0);
        __unsafe_unretained Class *classes = (__unsafe_unretained Class *)malloc(classCount * sizeof(Class));
        objc_getClassList(classes, classCount);
        
        NSMutableDictionary *hierarchies = [NSMutableDictionary dictionary];
        NSMutableDictionary *lookupTable = [NSMutableDictionary dictionaryWithCapacity:classCount];
        NSMutableDictionary *trees       = [NSMutableDictionary dictionaryWithCapacity:classCount];
        NSMutableArray      *properties  = [NSMutableArray array];
        NSMutableArray      *methods     = [NSMutableArray array];
        
        for(int index = 0; index < classCount; index++)
        {
            NSString *className = NSStringFromClass(classes[index]);
            
            if([badClassNames containsObject:className]) continue;
            
            PATree *classTree = [trees objectForKey:className];
            
            if(classTree == nil)
            {
                classTree = [PATree treeWithName:className];
                [trees setObject:classTree forKey:className];
            }
            
            NSMutableDictionary *classHierarchy = [lookupTable objectForKey:className];
            
            if(classHierarchy == nil)
            {
                classHierarchy = [NSMutableDictionary dictionary];
                [lookupTable setObject:classHierarchy forKey:className];
            }
            
            Class superclass = [classes[index] superclass];
            
            if(superclass != Nil)
            {
                NSString *superclassName = NSStringFromClass(superclass);
                PATree   *superclassTree = [trees objectForKey:superclassName];
                
                if(superclassTree == nil)
                {
                    superclassTree = [PATree treeWithName:superclassName];
                    [trees setObject:superclassTree forKey:superclassName];
                }
                
                [classTree setParents:[NSArray arrayWithObject:superclassTree]];
                
                NSMutableDictionary *superclassHierarchy = [lookupTable objectForKey:superclassName];
                
                if(superclassHierarchy == nil)
                {
                    superclassHierarchy = [NSMutableDictionary dictionaryWithCapacity:1];
                    [lookupTable setObject:superclassHierarchy forKey:superclassName];
                }
                
                [superclassHierarchy setObject:classHierarchy forKey:className];
            }
            else [hierarchies setObject:classHierarchy forKey:className];
            
            unsigned int count;
            
            objc_property_t *runtimeProperties = class_copyPropertyList(classes[index], &count);
            
            for(int subindex = 0; subindex < count; subindex++)
                [properties addObject:[PAProperty propertyWithRuntimeObject:runtimeProperties[subindex] forOwner:classTree]];
            
            free(runtimeProperties);
            
            Method *runtimeMethods = class_copyMethodList(objc_getMetaClass([className UTF8String]), &count);
            
            for(int subindex = 0; subindex < count; subindex++)
            {
                PAMethod *method = [PAMethod methodWithRuntimeObject:runtimeMethods[subindex] forOwner:classTree];
                
                [method setRequiredMethod:YES];
                [method setInstanceMethod:NO];
                
                [methods addObject:method];
            }
            
            free(runtimeMethods);
            
            runtimeMethods = class_copyMethodList(classes[index], &count);
            
            for(int subindex = 0; subindex < count; subindex++)
            {
                PAMethod *method = [PAMethod methodWithRuntimeObject:runtimeMethods[subindex] forOwner:classTree];
                
                [method setRequiredMethod:YES];
                [method setInstanceMethod:YES];
                
                [methods addObject:method];
            }
            
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
        
        unsigned int protocolCount;
        
        Protocol * __unsafe_unretained *protocols = objc_copyProtocolList(&protocolCount);
        
        trees       = [NSMutableDictionary dictionaryWithCapacity:protocolCount];
        lookupTable = [NSMutableDictionary dictionaryWithCapacity:protocolCount];
        
        for(int index = 0; index < protocolCount; index++)
        {
            NSString *protocolName = NSStringFromProtocol(protocols[index]);
            PATree   *protocolTree = [trees objectForKey:protocolName];
            
            if(protocolTree == nil)
            {
                protocolTree = [PATree treeWithName:protocolName];
                [trees setObject:protocolTree forKey:protocolName];
            }
            
            unsigned int parentCount;
            
            Protocol * __unsafe_unretained *parentProtocols = protocol_copyProtocolList(protocols[index], &parentCount);
            
            NSMutableArray *parents = [NSMutableArray arrayWithCapacity:parentCount];
            
            for(int subindex = 0; subindex < parentCount; subindex++)
            {
                NSString *parentName = NSStringFromProtocol(parentProtocols[subindex]);
                PATree   *parentTree = [trees objectForKey:parentName];
                
                if(parentTree == nil)
                {
                    parentTree = [PATree treeWithName:parentName];
                    [trees setObject:parentTree forKey:parentName];
                }
                
                [parents addObject:parentTree];
                
                NSMutableDictionary *children = [lookupTable objectForKey:parentName];
                
                if(children == nil)
                {
                    children = [NSMutableDictionary dictionaryWithCapacity:1];
                    [lookupTable setObject:children forKey:parentName];
                }
                
                [children setObject:protocolTree forKey:protocolName];
            }
            
            [protocolTree setParents:[parents sortedArrayUsingComparator:
                                      ^NSComparisonResult(id obj1, id obj2)
                                      {
                                          return [[obj1 name] compare:[obj2 name]];
                                      }]];
        }
        
        for(PATree *protocolTree in [trees allValues])
        {
            NSMutableDictionary *children = [lookupTable objectForKey:[protocolTree name]];
            
            [protocolTree setChildren:[children objectsForKeys:[[children allKeys] sortedArrayUsingSelector:@selector(compare:)] notFoundMarker:[PATree tree]]];
        }
        
        protocolTrees = trees;
        protocolList  = [trees objectsForKeys:[[trees allKeys] sortedArrayUsingSelector:@selector(compare:)] notFoundMarker:[PATree tree]];
        
        free(protocols);
        
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

+ (NSArray *)protocolList
{
    return protocolList;
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

+ (PATree *)protocolTreeForProtocolName:(NSString *)protocolName
{
    return [protocolTrees objectForKey:protocolName];
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
    
    NSMutableArray *methods = [NSMutableArray array];
    
    Method *runtimeObjects = class_copyMethodList(objc_getMetaClass([className UTF8String]), &count);
    
    for(int index = 0; index < count; index++)
    {
        PAMethod *method = [PAMethod methodWithRuntimeObject:runtimeObjects[index] forOwner:[PAAPI classTreeForClassName:className]];
        
        [method setRequiredMethod:YES];
        [method setInstanceMethod:NO];
        
        [methods addObject:method];
    }
    
    free(runtimeObjects);
    
    runtimeObjects = class_copyMethodList(NSClassFromString(className), &count);
    
    for(int index = 0; index < count; index++)
    {
        PAMethod *method = [PAMethod methodWithRuntimeObject:runtimeObjects[index] forOwner:[PAAPI classTreeForClassName:className]];
        
        [method setRequiredMethod:YES];
        [method setInstanceMethod:YES];
        
        [methods addObject:method];
    }
    
    free(runtimeObjects);
    
    return methods;
}

+ (NSArray *)propertiesForProtocolName:(NSString *)protocolName
{
    unsigned int count;
    
    objc_property_t *runtimeObjects = protocol_copyPropertyList(NSProtocolFromString(protocolName), &count);
    
    NSMutableArray *properties = [NSMutableArray arrayWithCapacity:count];
    
    for(int index = 0; index < count; index++)
        [properties addObject:[PAProperty propertyWithRuntimeObject:runtimeObjects[index] forOwner:[PAAPI protocolTreeForProtocolName:protocolName]]];
    
    free(runtimeObjects);
    
    return properties;
}

+ (NSArray *)methodsForProtocolName:(NSString *)protocolName
{
    PATree         *protocolTree = [PAAPI protocolTreeForProtocolName:protocolName];
    Protocol       *protocol     = NSProtocolFromString(protocolName);
    NSMutableArray *methods      = [NSMutableArray array];
    
    void (^copy)(BOOL, BOOL) =
    ^(BOOL isRequiredMethod, BOOL isInstanceMethod)
    {
        unsigned int count;
        
        struct objc_method_description *descriptions = protocol_copyMethodDescriptionList(protocol, isRequiredMethod, isInstanceMethod, &count);
        
        for(int index = 0; index < count; index++)
        {
            PAMethod *method = [PAMethod methodWithDescription:descriptions + index forOwner:protocolTree];
            
            [method setRequiredMethod:isRequiredMethod];
            [method setInstanceMethod:isInstanceMethod];
            
            [methods addObject:method];
        }
        
        free(descriptions);
    };
    
    copy(YES, NO);
    copy(NO,  NO);
    copy(YES, YES);
    copy(NO,  YES);
    
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
    NSString *type;
    
    NSScanner *scanner = [NSScanner scannerWithString:encoding];
    
    [scanner scanType:&type];
    
    return type;
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
        [self setName:[NSString stringWithUTF8String:property_getName(object)]];
        [self PA_parseAttributes:[NSString stringWithUTF8String:property_getAttributes(object)]];
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

@synthesize name, returnType, argumentTypes, requiredMethod, instanceMethod, owner;

+ (PAMethod *)methodWithRuntimeObject:(Method)object forOwner:(PATree *)anOwner
{
    return [[PAMethod alloc] initWithRuntimeObject:object forOwner:anOwner];
}

+ (PAMethod *)methodWithDescription:(struct objc_method_description *)description forOwner:(PATree *)owner
{
    return [[PAMethod alloc] initWithDescription:description forOwner:owner];
}

- (id)initWithRuntimeObject:(Method)object forOwner:(PATree *)anOwner
{
    if((self = [super init]) != nil)
    {
        [self setName:[NSString stringWithUTF8String:sel_getName(method_getName(object))]];
        
        char *type = method_copyReturnType(object);
        
        [self setReturnType:[PAAPI PA_typeForEncoding:[NSString stringWithUTF8String:type]]];
        
        free(type);
        
        int count = method_getNumberOfArguments(object) - 2;
        
        if(count > 0)
        {
            NSMutableArray *types = [NSMutableArray arrayWithCapacity:count];
            
            for(int index = 0; index < count; index++)
            {
                type = method_copyArgumentType(object, 2 + index);
                
                [types addObject:[PAAPI PA_typeForEncoding:[NSString stringWithUTF8String:type]]];
                
                free(type);
            }
            
            [self setArgumentTypes:types];
        }
        
        [self setOwner:anOwner];
    }
    
    return self;
}

- (id)initWithDescription:(struct objc_method_description *)description forOwner:(PATree *)owner
{
    if((self = [super init]) != nil)
    {
        [self setName:NSStringFromSelector(description->name)];
        
        NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:description->types]];
        
        NSString *type;
        
        [scanner scanType:&type];
        [self setReturnType:type];
        [scanner scanInteger:NULL];
        [scanner scanType:NULL];
        [scanner scanInteger:NULL];
        [scanner scanType:NULL];
        [scanner scanInteger:NULL];
        
        NSMutableArray *types = [NSMutableArray array];
        
        while([scanner scanType:&type])
        {
            [types addObject:type];
            [scanner scanInteger:NULL];
        }
        
        [self setArgumentTypes:types];
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
        [self setName:[NSString stringWithUTF8String:ivar_getName(object)]];
        [self setType:[PAAPI PA_typeForEncoding:[NSString stringWithUTF8String:ivar_getTypeEncoding(object)]]];
        [self setOffset:ivar_getOffset(object)];
        [self setOwner:anOwner];
    }
    
    return self;
}

@end

@implementation NSScanner (PrivateAPI)

- (unichar)scanCharacter
{
    if([self scanLocation] < [[self string] length])
    {
        unichar character = [[self string] characterAtIndex:[self scanLocation]];
        
        [self setScanLocation:[self scanLocation] + 1];
        
        return character;
    }
    else return '\0';
}

- (BOOL)scanType:(NSString * __autoreleasing *)type
{
    if(type == NULL) type = &(__autoreleasing NSString *){ nil };
    
    NSUInteger startingLocation = [self scanLocation];
    
    BOOL (^failure)() =
    ^ BOOL
    {
        [self setScanLocation:startingLocation];
        
        return NO;
    };
    
    BOOL (^primitive)(NSString *) =
    ^ BOOL (NSString *name)
    {
        *type = name;
        
        return YES;
    };
    
    BOOL (^modifier)(NSString *) =
    ^ BOOL (NSString *name)
    {
        NSString *subtype;
        
        if(![self scanType:&subtype]) return failure();
        
        *type = [name stringByAppendingString:subtype];
        
        return YES;
    };
    
    switch([self scanCharacter])
    {
        case 'B': return primitive(@"bool");
        case 'C': return primitive(@"unsigned char");
        case 'c': return primitive(@"BOOL");
        case 'D': return primitive(@"long double");
        case 'd': return primitive(@"double");
        case 'f': return primitive(@"float");
        case 'I': return primitive(@"unsigned int");
        case 'i': return primitive(@"int");
        case 'j': return modifier(@"_Complex ");
        case 'L': return primitive(@"unsigned long");
        case 'l': return primitive(@"long");
        case 'Q': return primitive(@"unsigned long long");
        case 'q': return primitive(@"long long");
        case 'S': return primitive(@"unsigned short");
        case 's': return primitive(@"short");
        case 'v': return primitive(@"void");
        case '*': return primitive(@"char *");
        case '@':
        {
            switch([self scanCharacter])
            {
                case '"':
                {
                    BOOL isProtocol = [self scanString:@"<" intoString:NULL];
                    
                    NSString *subtype;
                    
                    [self scanUpToString:isProtocol ? @">\"" : @"\"" intoString:&subtype];
                    
                    if(![self scanString:isProtocol ? @">\"" : @"\"" intoString:NULL]) return failure();
                    
                    *type = isProtocol ? [NSString stringWithFormat:@"id<%@>", subtype] : [subtype stringByAppendingString:@" *"];
                    
                    break;
                }
                case '?':
                {
                    *type = @"block";
                    
                    break;
                }
                case '\0':
                {
                    *type = @"id";
                    
                    break;
                }
                default:
                {
                    [self setScanLocation:[self scanLocation] - 1];
                    
                    *type = @"id";
                    
                    break;
                }
            }
            
            return YES;
        }
        case '#': return primitive(@"Class");
        case ':': return primitive(@"SEL");
        case '[':
        {
            NSInteger  length;
            NSString  *subtype;
            
            if(![self scanInteger:&length] || ![self scanType:&subtype] || ![self scanString:@"]" intoString:NULL]) return failure();
            
            *type = [NSString stringWithFormat:@"%@[%d]", subtype, length];
            
            return YES;
        }
        case '{':
        {
            NSString *name;
            unichar   character;
            
            [self scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"=}"] intoString:&name];
            [self scanString:@"=" intoString:NULL];
            
            while((character = [self scanCharacter]) != '}')
            {
                if(character == '\0') return failure();
                
                if(character == '"')
                {
                    [self scanUpToString:@"\"" intoString:NULL];
                    
                    if(![self scanString:@"\"" intoString:NULL]) return failure();
                }
                else [self setScanLocation:[self scanLocation] - 1];
                
                if(![self scanType:NULL]) return failure();
            }
            
            *type = [@"struct " stringByAppendingString:name];
            
            return YES;
        }
        case '(':
        {
            NSString *name;
            unichar   character;
            
            [self scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"=)"] intoString:&name];
            [self scanString:@"=" intoString:NULL];
            
            while((character = [self scanCharacter]) != ')')
            {
                if(character == '\0') return failure();
                
                if(character == '"')
                {
                    [self scanUpToString:@"\"" intoString:NULL];
                    
                    if(![self scanString:@"\"" intoString:NULL]) return failure();
                }
                else [self setScanLocation:[self scanLocation] - 1];
                
                if(![self scanType:NULL]) return failure();
            }
            
            *type = [@"union " stringByAppendingString:name];
            
            return YES;
        }
        case 'b':
        {
            NSInteger bits;
            
            if(![self scanInteger:&bits]) return failure();
            
            *type = [NSString stringWithFormat:@"int%d", bits];
            
            return YES;
        }
        case '^':
        {
            switch([self scanCharacter])
            {
                case '?':
                {
                    *type = @"function";
                    
                    break;
                }
                default:
                {
                    [self setScanLocation:[self scanLocation] - 1];
                    
                    NSString *subtype;
                    
                    if(![self scanType:&subtype]) return failure();
                    
                    *type = [subtype stringByAppendingString:[subtype hasSuffix:@"*"] ? @"*" : @" *"];
                    
                    break;
                }
            }
            
            return YES;
        }
        case '?': return primitive(@"?");
        case 'r': return modifier(@"const ");
        case 'n': return modifier(@"in ");
        case 'N': return modifier(@"inout ");
        case 'o': return modifier(@"out ");
        case 'O': return modifier(@"bycopy ");
        case 'R': return modifier(@"byref ");
        case 'V': return modifier(@"oneway ");
        default:  return failure();
    }
}

@end
