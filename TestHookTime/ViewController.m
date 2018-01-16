//
//  ViewController.m
//  TestHookTime
//
//  Created by syfll on 2018/1/16.
//  Copyright © 2018年 syfll. All rights reserved.
//

#import "ViewController.h"
#import "JFTClassFinder.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    JFTClassFinder *finder = [[JFTClassFinder alloc] initWithRootClass:[NSObject class]];
    [finder generateClassTree];
    JFTClassNode *vcNode = [finder findDesNode:finder.tree withClass:[UIViewController class]];
    [self enumerateClassTree:vcNode usingBlock:^(JFTClassNode *node) {
        NSLog(@"%@", NSStringFromClass(node.isa_class));
    }];
}

- (void)enumerateClassTree:(JFTClassNode *)tree usingBlock:(void(^)(JFTClassNode *node))block {
    if (!block) return;
    block(tree);
    [tree.subNodes enumerateObjectsUsingBlock:^(JFTClassNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self enumerateClassTree:obj usingBlock:block];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
