//
//  WFSampleBuffer.h
//  hardDecodeDemo
//
//  Created by wang feng on 16/12/9.
//  Copyright © 2016年 Wright. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface WFSampleBuffer : NSObject
{
    CVPixelBufferRef sampleBuffer;
    int64_t packetPkt;
}

- (void)setBuffer:(CVPixelBufferRef)buffer;
- (CVPixelBufferRef)getBuffer;
- (void)setPkt:(int64_t)pkt;
- (int64_t)getPkt;

@end
