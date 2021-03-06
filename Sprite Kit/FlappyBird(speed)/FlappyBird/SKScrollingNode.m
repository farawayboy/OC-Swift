//
//  SKScrollingNode.m
//  FlappyBird
//
//  Created by STMBP on 2017/4/8.
//  Copyright © 2017年 sensetime. All rights reserved.
//

#import "SKScrollingNode.h"

@implementation SKScrollingNode

+ (instancetype)scrollingNodeWithImageNamed:(NSString *)name inContainerSize:(CGSize)size
{
    UIImage * image = [UIImage imageNamed:name];

    SKScrollingNode * realNode = [SKScrollingNode spriteNodeWithColor:
                                  [UIColor clearColor] size:size];
    float total = 0;
    while(total<(size.width + image.size.width))
    {
        SKSpriteNode * child = [SKSpriteNode spriteNodeWithImageNamed:name];
        [child setAnchorPoint:CGPointZero];
        [child setPosition:CGPointMake(total, 0)];
        [realNode addChild:child];
        total+=child.size.width;
    }
    return realNode;
}

- (void)update:(NSTimeInterval)currentTime
{
    [self.children enumerateObjectsUsingBlock:^(SKNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        SKSpriteNode * child = (SKSpriteNode*)obj;
        child.position = CGPointMake(child.position.x-self.scrollingSpeed, child.position.y);
        if (child.position.x <= -child.size.width)
        {
            float delta = child.position.x+child.size.width;
            child.position = CGPointMake(child.size.width*(self.children.count-1)+delta, child.position.y);
        }
    }];
}
@end
