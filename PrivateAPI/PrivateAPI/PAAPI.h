//
//  PAPrivateAPI.h
//  PrivateAPI
//
//  Created by William Hua on 11-11-20.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@class PATree;

typedef enum
{
    PAPropertySetterSemanticsAssign,
    PAPropertySetterSemanticsCopy,
    PAPropertySetterSemanticsRetain
} PAPropertySetterSemantics;

@interface PAAPI : NSObject

+ (NSArray *)classList;
+ (NSArray *)classHierarchies;
+ (PATree  *)classTreeForClassName:(NSString *)className;

+ (NSArray *)propertyList;
+ (NSArray *)methodList;

+ (NSArray *)protocolNamesForClassName:(NSString *)className;
+ (NSArray *)propertiesForClassName:(NSString *)className;
+ (NSArray *)methodsForClassName:(NSString *)className;
+ (NSArray *)ivarsForClassName:(NSString *)className;

@end

@interface PATree : NSObject

@property(nonatomic, copy)   NSString  *name;
@property(nonatomic, assign) NSInteger  depth;
@property(nonatomic, copy)   NSArray   *parents;
@property(nonatomic, copy)   NSArray   *children;

+ (PATree *)tree;
+ (PATree *)treeWithName:(NSString *)name;

- (id)initWithName:(NSString *)name;

- (NSArray *)preorderTraversal;
- (NSArray *)preorderTraversalPassingTest:(BOOL (^)(PATree *tree))test;
- (NSArray *)preorderTraversalPassingTest:(BOOL (^)(PATree *tree))test includingSubhierarchies:(BOOL)includeSubhierarchies;

@end

@interface PAProperty : NSObject

@property(nonatomic, copy)                              NSString                  *name;
@property(nonatomic, copy)                              NSString                  *type;
@property(nonatomic, assign, getter=isReadonly)         BOOL                       readonly;
@property(nonatomic, assign)                            PAPropertySetterSemantics  setterSemantics;
@property(nonatomic, assign, getter=isNonatomic)        BOOL                       nonatomic;
@property(nonatomic, copy)                              NSString                  *getter;
@property(nonatomic, copy)                              NSString                  *setter;
@property(nonatomic, assign, getter=isDynamic)          BOOL                       dynamic;
@property(nonatomic, assign, getter=isWeak)             BOOL                       weak;
@property(nonatomic, assign, getter=isGarbageCollected) BOOL                       garbageCollected;
@property(nonatomic, copy)                              NSString                  *backingIvar;
@property(nonatomic, retain)                            PATree                    *owner;

+ (PAProperty *)propertyWithRuntimeObject:(objc_property_t)object forOwner:(PATree *)owner;

- (id)initWithRuntimeObject:(objc_property_t)object forOwner:(PATree *)owner;

@end

@interface PAMethod : NSObject

@property(nonatomic, copy)   NSString *name;
@property(nonatomic, copy)   NSString *returnType;
@property(nonatomic, copy)   NSArray  *argumentTypes;
@property(nonatomic, retain) PATree   *owner;

+ (PAMethod *)methodWithRuntimeObject:(Method)object forOwner:(PATree *)owner;

- (id)initWithRuntimeObject:(Method)object forOwner:(PATree *)owner;

@end

@interface PAIvar : NSObject

@property(nonatomic, copy)   NSString  *name;
@property(nonatomic, copy)   NSString  *type;
@property(nonatomic, assign) NSInteger  offset;
@property(nonatomic, retain) PATree    *owner;

+ (PAIvar *)ivarWithRuntimeObject:(Ivar)object forOwner:(PATree *)owner;

- (id)initWithRuntimeObject:(Ivar)object forOwner:(PATree *)owner;

@end
