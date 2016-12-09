//
//  WFNSQueue.h
//  hardDecodeDemo
//
//  Created by wang feng on 16/12/9.
//  Copyright © 2016年 Wright. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WFNSQueue : NSObject
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
