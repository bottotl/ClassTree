//
//  JFTClassFinder.h
//  TestHookTime
//
//  Created by syfll on 2018/1/16.
//  Copyright © 2018年 syfll. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JFTClassNode : NSObject
@property (nonatomic, assign) Class isa_class;
@property (nonatomic, strong) NSMutableArray <JFTClassNode *> *subNodes;
@end

@interface JFTClassFinder : NSObject

- (instancetype)initWithRootClass:(Class)isa_class;

@property (nonatomic) Class rootClass;
@property (nonatomic, copy) NSArray<NSBundle *> *bundles;
@property (nonatomic, readonly) JFTClassNode *tree;

// 生成Class树的耗时信息
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) CFTimeInterval endTime;

- (void)generateClassTree;
- (BOOL)isBundleContainsClass:(Class)aClass;

- (NSArray <JFTClassNode *> *)findLeafNodeWithRootClass:(Class)isa_class;

@end
