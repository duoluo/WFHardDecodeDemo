//
//  BFSampleBuffer.m
//  WFPlayer
//
//  Created by wang feng on 16/9/8.
//  Copyright © 2016年 Wright. All rights reserved.
//

#import "BFSampleBuffer.h"

@implementation BFSampleBuffer

- (instancetype)init
{
    if(self = [super init])
    {
        sampleBuffer = NULL;
        packetPkt = 0;
    }
    return self;
}

- (void)dealloc
{
    if(sampleBuffer)
    {
        CFRelease(sampleBuffer);
    }
   
}

- (void)setBuffer:(CVPixelBufferRef)buffer
{
    if (buffer) {
        CFRetain(buffer);
        sampleBuffer = buffer;
        
    } else {
        sampleBuffer = NULL;
    }
}

- (CVPixelBufferRef)getBuffer
{
    if (sampleBuffer) {
        return sampleBuffer;
    } else {
        return NULL;
    }
}

- (void)setPkt:(int64_t)pkt
{
    if (pkt) {
        packetPkt = pkt;
    } else {
        packetPkt = 0;
    }
}

- (int64_t)getPkt
{
    if (packetPkt) {
        return packetPkt;
    } else {
        return 0;
    }
}


@end
