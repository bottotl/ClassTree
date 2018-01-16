# ClassTree
make class tree of objc

## How to use

    JFTClassFinder *finder = [[JFTClassFinder alloc] initWithRootClass:[NSObject class]];
    [finder generateClassTree];
    JFTClassNode *vcNode = [finder findDesNode:finder.tree withClass:[UIViewController class]];
    [self enumerateClassTree:vcNode usingBlock:^(JFTClassNode *node) {
        NSLog(@"%@", NSStringFromClass(node.isa_class));
    }];


## Util

    - (void)enumerateClassTree:(JFTClassNode *)tree usingBlock:(void(^)(JFTClassNode *node))block {
        if (!block) return;
        block(tree);
        [tree.subNodes enumerateObjectsUsingBlock:^(JFTClassNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self enumerateClassTree:obj usingBlock:block];
        }];
    }
