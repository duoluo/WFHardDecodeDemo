//
//  AppDelegate.m
//  hardDecodeDemo
//
//  Created by wang feng on 16/12/7.
//  Copyright © 2016年 Wright. All rights reserved.
//

#import "AppDelegate.h"
#import "avformat.h"
#import "avcodec.h"
#import "avutil.h"
#import "swresample.h"
#import "swscale.h"
#import <VideoToolbox/VideoToolbox.h>
#import "WFSampleBuffer.h"
#import "WFNSQueue.h"
@import AVFoundation;

@interface AppDelegate ()
{
    AVFormatContext *_formatCtx;
    int videoStream;
    AVCodecContext *pCodecCtx;
    AVFrame *pframe;
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
}

@property (weak) IBOutlet NSImageView *showImageView;
@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) dispatch_queue_t decodeQueue;
@property (nonatomic, strong) WFNSQueue *frameQueue;

@end

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    //NSLog(@"---------++++++++++++++++++");
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self initParam];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (IBAction)selectFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:FALSE];
    [panel setCanChooseFiles:TRUE];
    [panel setCanChooseDirectories:FALSE];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *fileUrl = [panel URLs][0];
            self.filePath = [fileUrl path];
        }
    }];
}

- (void)initParam
{
    self.decodeQueue = dispatch_queue_create("com.htaiwan.backgroundqueue", NULL);
    av_register_all();
    self.frameQueue = [[WFNSQueue alloc] initWithMaxCount:100];
}

- (IBAction)play:(id)sender {
    
    BOOL bRet = [self initDemux:self.filePath];
    if (bRet) {
        bRet = [self openVideoStream];
    }
    
    if (bRet) {
        [self asyncDecodeFrames];
    }
}

- (BOOL)initDemux:(NSString *)filePath
{
    AVFormatContext *formatCtx = NULL;
    
    formatCtx = avformat_alloc_context();
    if (!formatCtx) {
        return FALSE;
    }
    
    if (avformat_open_input(&formatCtx, [filePath cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL) < 0) {
        if (formatCtx) {
            avformat_free_context(formatCtx);
            return FALSE;
        }
    }
    
    if (avformat_find_stream_info(formatCtx, NULL) < 0) {
        avformat_close_input(&formatCtx);
        return FALSE;
    }
    
    _formatCtx = formatCtx;
    return TRUE;
}

- (BOOL)openVideoStream
{
    AVCodec *pCodec;
    if ((videoStream = av_find_best_stream(_formatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &pCodec, 0)) < 0) {
        return FALSE;
    }
    
    pCodecCtx = _formatCtx->streams[videoStream]->codec;
    
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        return FALSE;
    }
    
    return TRUE;
}

-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    //CMVideoFormatDescriptionRef 获取描述信息
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        //设置回调函数。
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        //初始化VTDecompressionSession 设置解码器的相关信息，初始化信息需要CMSampleBuffer里面的FormatDescription以及设置解码后图像的存储方式
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        CFRelease(attrs);
    } else {
        //NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
    }
    
    return YES;
}

- (CVPixelBufferRef)decodePacket:(AVPacket *)packet
{
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)packet->data, packet->size,
                                                          kCFAllocatorNull,
                                                          NULL, 0, packet->size,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {packet->size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
     
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}

- (void)asyncDecodeFrames
{
    dispatch_async(self.decodeQueue, ^{
        @autoreleasepool {
            while (TRUE) {
                AVPacket *packet = NULL;
                packet = (AVPacket *)av_malloc(sizeof(AVPacket));
                if (packet) {
                    av_init_packet(packet);
                    packet->data = NULL;
                    packet->size = 0;
                }
                
                
                if (av_read_frame(_formatCtx, packet) < 0) {
                    break;
                }
                
                if (packet->stream_index == videoStream) {
                    
                    
                    uint8_t *extraData = pCodecCtx->extradata;
                    int extraSize = pCodecCtx->extradata_size;
                    
                    for(unsigned int i = 0; i < extraSize; ++i) {
                        
                        if ((i > 0) && extraData[i] == 0x67) {
                            int lengthPos = i -1;
                            _spsSize = extraData[lengthPos];
                            _sps = malloc(_spsSize);
                            memcpy(_sps, extraData + i, _spsSize);
                            
                        }
                        
                        if (extraData[i] == 0x68) {
                            int lengthPos = i -1;
                            _ppsSize = extraData[lengthPos];
                            _pps = malloc(_ppsSize);
                            memcpy(_pps, extraData + i, _ppsSize);
                        }
                    }
                    
                    CVPixelBufferRef pixelBuffer = NULL;
                    
                    int nalType = packet->data[4] & 0x1F;
                    switch (nalType) {
                        case 0x05:
                            if ([self initH264Decoder]) {
                                pixelBuffer = [self decodePacket:packet];
                            }
                            break;
                            
                        default:
                            pixelBuffer = [self decodePacket:packet];
                            break;
                    }
                    
                    WFSampleBuffer *buffer = [[WFSampleBuffer alloc] init];
                    [buffer setBuffer:pixelBuffer];
                    [buffer setPkt:packet->pts];
                    
                    if (![self.frameQueue isFull]) {
                        [self.frameQueue EnQueue:buffer];
                        [self.frameQueue sortWihtComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                            
                            if ([((WFSampleBuffer *)obj1) getPkt] > [((WFSampleBuffer *)obj2) getPkt]) {
                                return (NSComparisonResult)NSOrderedDescending;
                            }else if ([((WFSampleBuffer *)obj1) getPkt] < [((WFSampleBuffer *)obj2) getPkt]){
                                return (NSComparisonResult)NSOrderedAscending;
                            }
                            else
                                return (NSComparisonResult)NSOrderedSame;
                        }];
                    }
                    
                    if ([self.frameQueue count] > 20) {
                        WFSampleBuffer *bfBuffer = [self.frameQueue DeQueue];
                        CVPixelBufferRef pixelBuffer = [bfBuffer getBuffer];
                        NSLog(@"the pts is %lld", [bfBuffer getPkt]);
                        
                        [self getYUVPlane:pixelBuffer];
                    
                        if (pixelBuffer) {
                            //NSLog(@"the pixelBuffer is valid");
                            
                            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
                            CIContext *temporaryContext = [CIContext contextWithOptions:nil];
                            CGImageRef videoImage = [temporaryContext
                                                     createCGImage:ciImage
                                                     fromRect:CGRectMake(0, 0,
                                                                         CVPixelBufferGetWidth(pixelBuffer),
                                                                         CVPixelBufferGetHeight(pixelBuffer))];
                            NSImage* image = [[NSImage alloc] initWithCGImage:videoImage size:NSMakeSize(700, 700)];
                            
                            dispatch_sync(dispatch_get_main_queue(),^{
                                self.showImageView.image = image;
                            });
                            CVPixelBufferRelease(pixelBuffer);
                        }
                    }
         
                }
                NSLog(@"Read Nalu size %d", packet->size);
            }//while(1)
        }//autopool
        
    });
}

- (void)getYUVPlane:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    size_t numberOfPlane = CVPixelBufferGetPlaneCount(pixelBuffer);
    NSLog(@"the plane number is %ld", numberOfPlane);
}

@end
