//
//  BFSampleBuffer.h
//  WFPlayer
//
//  Created by wang feng on 16/9/8.
//  Copyright © 2016年 Wright. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface BFSampleBuffer : NSObject
{
    CVPixelBufferRef sampleBuffer;
    int64_t packetPkt;
}

- (void)setBuffer:(CVPixelBufferRef)buffer;
- (CVPixelBufferRef)getBuffer;
- (void)setPkt:(int64_t)pkt;
- (int64_t)getPkt;

@end
