//
//  BFNSQueue.m
//  StormPlayer
//
//  Created by gaoyang1 on 16/2/22.
//  Copyright © 2016年 BaoFeng. All rights reserved.
//

#import "BFNSQueue.h"

@interface BFNSQueue ()

@property (nonatomic, strong) NSArray *outFrames;
@end

@implementation BFNSQueue

- (instancetype)init
{
    if(self = [super init])
    {
        myQueue = [[NSMutableArray alloc] init];
        _count = 0;
        _maxCount = 0;
    }
    
    return self;
}

- (instancetype)initWithMaxCount: (unsigned int)maxCount
{
    if(self = [super init])
    {
        //myQueue = [NSMutableArray arrayWithCapacity:maxCount];
        myQueue = [[NSMutableArray alloc] init];
        _count = 0;
        _maxCount = maxCount;
    }
    
    return self;
}

- (void)dealloc
{
    [self clear];
}

- (BOOL)isFull
{
    BOOL isFull = NO;
    if(self.maxCount > 0 && [myQueue count] >= self.maxCount)
    {
        isFull = YES;
    }
    return isFull;
}

- (BOOL)isEmpty
{
    BOOL isEmpty = NO;
    if([myQueue count] == 0)
    {
        isEmpty = YES;
    }
    return isEmpty;
}

- (void)EnQueue: (id)object
{
    
    @synchronized(self)
    {
        if(object != nil)
        {
            [myQueue addObject: object];
            _count = myQueue.count;
        }
    }

}

- (id)DeQueue
{
    @synchronized(self)
    {
        
        if([myQueue count] > 0)
        {
            id object = [myQueue objectAtIndex:0];
            [myQueue removeObjectAtIndex:0];
            _count = myQueue.count;
            if(object != nil)
            {
                return object;
            }
        }
    }
    
    return nil;
}

- (void)clear
{
    @synchronized(self)
    {
        [myQueue removeAllObjects];
        _count = 0;
    }
}

- (void)sortWihtComparator:(NSComparator)comparator
{
    @synchronized(self)
    {
        [myQueue sortUsingComparator:comparator];

    }
}
@end
