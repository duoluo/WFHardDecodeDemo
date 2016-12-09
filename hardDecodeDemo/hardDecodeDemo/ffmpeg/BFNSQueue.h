//
//  BFNSQueue.h
//  StormPlayer
//
//  Created by gaoyang1 on 16/2/22.
//  Copyright © 2016年 BaoFeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BFNSQueue : NSObject
{
    NSMutableArray * myQueue;
}

- (instancetype)initWithMaxCount: (unsigned int)maxCount;
- (BOOL)isFull;
- (BOOL)isEmpty;
//多余maxCount也可以入队列，如需要限制，则需在EnQueue之前做判断
- (void)EnQueue: (id)object;
- (id)DeQueue;
- (void)clear;
- (void)sortWihtComparator:(NSComparator)comparator;

@property (nonatomic, readonly) unsigned long count;
@property (nonatomic, assign, readonly) unsigned long maxCount;

@end
