//
//  JFTClassFinder.m
//  TestHookTime
//
//  Created by syfll on 2018/1/16.
//  Copyright © 2018年 syfll. All rights reserved.
//

#import "JFTClassFinder.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface JFTClassFinder()
@property (nonatomic, strong) JFTClassNode *tree;
@end

@implementation JFTClassFinder

- (instancetype)initWithRootClass:(Class)isa_class {
    if (self = [super init]) {
        _rootClass = isa_class;
        _bundles = [[self appBundles] copy];
    }
    return self;
}

- (NSArray *)appBundles {
    NSMutableArray *bundlesFilter = [NSMutableArray array];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *excutableName = [mainBundle infoDictionary][(__bridge NSString*)kCFBundleExecutableKey];
    
    NSArray *allBundles = [NSBundle allBundles];
    NSArray *allFrameworks = [NSBundle allFrameworks];
    
    for (NSBundle *bundle in allBundles) {
        NSString *path = [bundle bundlePath];
        if ([path containsString:excutableName]) {
            [bundlesFilter addObject:bundle];
        }
    }
    
    for (NSBundle *bundle in allFrameworks) {
        NSString *path = [bundle bundlePath];
        if ([path containsString:excutableName]) {
            [bundlesFilter addObject:bundle];
        }
    }
    return [NSArray arrayWithArray:bundlesFilter];
}

- (NSArray *)getClassNames {
    NSMutableArray* classNames = [NSMutableArray array];
    unsigned int count = 0;
    const char** classes = objc_copyClassNamesForImage([[[NSBundle mainBundle] executablePath] UTF8String], &count);
    for(unsigned int i=0;i<count;i++){
        NSString* className = [NSString stringWithUTF8String:classes[i]];
        [classNames addObject:className];
    }
    return classNames;
}

- (void)generateClassTree {
    self.startTime = CACurrentMediaTime();
    
    JFTClassNode *tree = [JFTClassNode new];
    tree.isa_class = NULL;
    tree.subNodes = [NSMutableArray array];
    
    int numClasses;
    Class *classes = NULL;
    
    classes = NULL;
    numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses > 0 )
    {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        
        NSMutableDictionary *classNodeMap = [NSMutableDictionary dictionaryWithCapacity:numClasses];
        for (int i = 0; i < numClasses; i++) {
            Class aClass = classes[i];
            JFTClassNode *node = [JFTClassNode new];
            node.isa_class = classes[i];
            NSString *className = [NSString stringWithUTF8String:class_getName(aClass)];
            classNodeMap[className] = node;
        }
        
        for (int i = 0; i < numClasses; i++) {
            Class aClass = classes[i];
            Class superClass = class_getSuperclass(aClass);
            
            NSString *className = [NSString stringWithUTF8String:class_getName(aClass)];
            JFTClassNode *node = classNodeMap[className];
            
            // root class
            if (superClass == NULL) {
                if (aClass == self.rootClass) {
                    [tree.subNodes addObject:node];
                }
            } else {
                if (![self isBundleContainsClass:aClass]) {
                    continue;
                }
                
                Class currentClass = aClass;
                JFTClassNode *currentNode = node;
                Class aSuperClass = class_getSuperclass(currentClass);
                while (aSuperClass) {
                    NSString *superClassName = [NSString stringWithUTF8String:class_getName(aSuperClass)];
                    JFTClassNode *superNode = classNodeMap[superClassName];
                    
                    // 因为我们本身在for循环里面，防止重复加入，这里判断一下即可
                    if (![superNode.subNodes containsObject:currentNode]) {
                        [superNode.subNodes addObject:currentNode];
                    }
                    
                    currentClass = aSuperClass;
                    currentNode = superNode;
                    aSuperClass = class_getSuperclass(currentClass);
                    if (currentClass == self.rootClass) {
                        break;
                    }
                }
            }
        }
    }
    
    self.endTime = CACurrentMediaTime();
    
    self.tree = tree;
}

- (BOOL)isBundleContainsClass:(Class)aClass {
    if (!aClass) return NO;
    NSBundle *bundle = [NSBundle bundleForClass:aClass];
    return [self.bundles containsObject:bundle];
}

- (NSArray <JFTClassNode *> *)findLeafNodeWithRootClass:(Class)isa_class {
    JFTClassNode *des = [self findDesNode:self.tree withClass:isa_class];
    return [self findLeafNodeWithDesNode:des];
}

- (NSArray <JFTClassNode *> *)findLeafNodeWithDesNode:(JFTClassNode *)tree {
    NSMutableArray <JFTClassNode *> *leafs = @[].mutableCopy;
    if (!tree.subNodes.count) {
        [leafs addObject:tree];
    } else {
        for (JFTClassNode *node in tree.subNodes) {
            [leafs addObjectsFromArray:[self findLeafNodeWithDesNode:node]];
        }
    }
    return leafs;
}

- (void)printNodesOfTree:(JFTClassNode *)tree withClass:(Class)class {
    JFTClassNode *des = [self findDesNode:tree withClass:class];
    [self printLeafOfTree:des];
}

- (void)printLeafOfTree:(JFTClassNode *)tree {
    if (!tree.subNodes.count) {
        NSLog(@"%s", class_getName(tree.isa_class));
    } else {
        for (JFTClassNode *node in tree.subNodes) {
            [self printLeafOfTree:node];
        }
    }
}

- (JFTClassNode *)findDesNode:(JFTClassNode *)tree withClass:(Class)class {
    if (tree.isa_class == class) {
        return tree;
    } else {
        JFTClassNode *des;
        for (JFTClassNode *node in tree.subNodes) {
            des = [self findDesNode:node withClass:class];
            if (des) {
                break;
            }
        }
        return des;
    }
}

- (void)logTree:(JFTClassNode *)tree {
    NSLog(@"%s", class_getName(tree.isa_class));
    [tree.subNodes enumerateObjectsUsingBlock:^(JFTClassNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self logTree:obj];
    }];
}


@end

@implementation JFTClassNode

- (NSMutableArray<JFTClassNode *> *)subNodes {
    if (!_subNodes) {
        _subNodes = @[].mutableCopy;
    }
    return _subNodes;
}

-(NSString *)description {
    NSMutableString *subclassDesc = [NSMutableString string];
    for (JFTClassNode *node in self.subNodes) {
        [subclassDesc appendFormat:@"<%@: %p, class: %s, subclasses count: %lld>", NSStringFromClass([node class]), node, class_getName(node.isa_class), (long long)node.subNodes.count];
    }
    
    return [NSString stringWithFormat:@"<%@: %p, class: %s, subclasses: %@>",
            NSStringFromClass([self class]), self, class_getName(self.isa_class), self.subNodes.count > 0 ? subclassDesc : @"no subclass"];
}
@end
