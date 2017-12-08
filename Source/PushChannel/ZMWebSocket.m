// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


@import WireSystem;
#import "ZMWebSocket.h"
#import "ZMWebSocketHandshake.h"
#import "ZMWebSocketFrame.h"

#import <libkern/OSAtomic.h>
#import "ZMTLogging.h"
#import <WireTransport/WireTransport-Swift.h>

static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_PUSHCHANNEL;


@interface ZMWebSocket (NetworkSocket) <NetworkSocketDelegate>

@end

@interface ZMWebSocket ()
{
    int32_t _isOpen;
}

@property (nonatomic) NSURL *URL;
@property (nonatomic) NSMutableArray *dataPendingTransmission;
@property (nonatomic, weak) id<ZMWebSocketConsumer> consumer;
@property (atomic) dispatch_queue_t consumerQueue;
@property (atomic) ZMSDispatchGroup *consumerGroup;
@property (nonatomic) NetworkSocket *networkSocket;
@property (nonatomic) BOOL handshakeCompleted;
@property (nonatomic) DataBuffer *inputBuffer;
@property (nonatomic) ZMWebSocketHandshake *handshake;
@property (nonatomic, copy) NSDictionary* additionalHeaderFields;
@property (nonatomic) NSHTTPURLResponse *response;

@end



@implementation ZMWebSocket

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"You should not use -init" userInfo:nil];
    return [self initWithConsumer:nil queue:nil group:nil networkSocket:nil url:nil additionalHeaderFields:nil];
}

- (instancetype)initWithConsumer:(id<ZMWebSocketConsumer>)consumer
                           queue:(dispatch_queue_t)queue
                           group:(ZMSDispatchGroup *)group
                             url:(NSURL *)url
          additionalHeaderFields:(NSDictionary *)additionalHeaderFields;
{
    return [self initWithConsumer:consumer
                            queue:queue
                            group:group
                    networkSocket:nil
                              url:url
           additionalHeaderFields:additionalHeaderFields];
}

- (instancetype)initWithConsumer:(id<ZMWebSocketConsumer>)consumer
                           queue:(dispatch_queue_t)queue
                           group:(ZMSDispatchGroup *)group
                   networkSocket:(NetworkSocket *)networkSocket
                             url:(NSURL *)url
          additionalHeaderFields:(NSDictionary *)additionalHeaderFields;
{
    VerifyReturnNil(consumer != nil);
    VerifyReturnNil(queue != nil);
    self = [super init];
    if (self) {
        self.URL = url;
        self.consumer = consumer;
        self.consumerQueue = queue;
        self.consumerGroup = group;
        if (networkSocket == nil) {
            networkSocket = [[NetworkSocket alloc] initWithUrl:url
                                                      delegate:self
                                                         queue:self.consumerQueue
                                                         group:self.consumerGroup];
        }
        self.inputBuffer = [[DataBuffer alloc] init];
        self.networkSocket = networkSocket;
        self.handshake = [[ZMWebSocketHandshake alloc] initWithDataBuffer:self.inputBuffer];
        self.dataPendingTransmission = [NSMutableArray array];
        self.additionalHeaderFields = additionalHeaderFields;
        [self open];
    }
    return self;
}

- (void)safelyDispatchOnQueue:(void (^)(void))block
{
    dispatch_queue_t consumerQueue = self.consumerQueue;
    ZMSDispatchGroup *consumerGroup = self.consumerGroup;
    
    if(consumerGroup == nil || consumerQueue == nil) {
        return;
    }
    [consumerGroup asyncOnQueue:consumerQueue block:block];
}

- (void)open;
{
    RequireString(OSAtomicCompareAndSwap32Barrier(0, 1, &_isOpen), "Trying to open %p multiple times.", (__bridge void *) self);
    
    [self.networkSocket open];
}

- (dispatch_data_t)handshakeRequestData
{
    // The Opening Handshake:
    // C.f. <http://tools.ietf.org/html/rfc6455#section-1.3>
    
    Require(self.URL != nil);
    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(NULL, (__bridge CFStringRef) @"GET", (__bridge CFURLRef) self.URL, kCFHTTPVersion1_1);
    Require(message != NULL);
    NSMutableDictionary *headers = [@{@"Upgrade": @"websocket",
                              @"Host": self.URL.host,
                              @"Connection": @"Upgrade",
                              @"Sec-WebSocket-Key": @"dGhlIHNhbXBsZSBub25jZQ==",
                              @"Sec-WebSocket-Version": @"13"} mutableCopy];
    [headers addEntriesFromDictionary:self.additionalHeaderFields];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *headerField, NSString *headerValue, BOOL * ZM_UNUSED stop){
        CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef) headerField, (__bridge CFStringRef) headerValue);
    }];
    //CFHTTPMessageSetBody(message, (__bridge CFDataRef) [NSData data]);
    NSData *requestData = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(message));
    Require(requestData != nil);
    CFRelease(message);
    
    CFDataRef cfdata = (CFDataRef) CFBridgingRetain(requestData);
    dispatch_data_t handshakeRequestData = dispatch_data_create(requestData.bytes, requestData.length, dispatch_get_global_queue(0, 0), ^{
        CFRelease(cfdata);
    });
    return handshakeRequestData;
}

- (ZMWebSocketHandshakeResult)didParseHandshakeInBuffer
{
    NSError *error;
    ZMWebSocketHandshakeResult handshakeCompleted = [self.handshake parseAndClearBufferIfComplete:YES error:&error];
    self.response = self.handshake.response;
    if (handshakeCompleted == ZMWebSocketHandshakeCompleted) {
        for (NSData *data in self.dataPendingTransmission) {
            [self.networkSocket writeData:data];
        }
        self.dataPendingTransmission = nil;
    } else if (handshakeCompleted == ZMWebSocketHandshakeError) {
        ZMLogError(@"Failed to parse WebSocket handshake response: %@", error);
    }
    return handshakeCompleted;
}

- (void)close;
{
    // The compare & swap ensure that the code only runs if the values of isClosed was 0 and sets it to 1.
    // The check for 0 and setting it to 1 happen as a single atomic operation.
    if (OSAtomicCompareAndSwap32Barrier(1, 0, &_isOpen)) {
        dispatch_queue_t queue = self.consumerQueue;
        ZMSDispatchGroup *group = self.consumerGroup;
        self.consumerQueue = nil;
        self.consumerGroup = nil;
        [self.networkSocket close];
        NSHTTPURLResponse *response = self.response;
        self.response = nil;
        id<ZMWebSocketConsumer> consumer = self.consumer;
        self.consumer = nil;
        ZMWebSocket *socket = self;
        
        [group asyncOnQueue:queue block:^{
            [consumer webSocketDidClose:socket HTTPResponse:response];
        }];
    }
}

- (void)sendTextFrameWithString:(NSString *)string;
{
    ZMWebSocketFrame *frame = [[ZMWebSocketFrame alloc] initWithTextFrameWithPayload:string];
    [self sendFrame:frame];
}

- (void)sendBinaryFrameWithData:(NSData *)data;
{
    ZMWebSocketFrame *frame = [[ZMWebSocketFrame alloc] initWithBinaryFrameWithPayload:data];
    [self sendFrame:frame];
}

- (void)sendPingFrame;
{
    ZMLogDebug(@"Sending ping");
    ZMWebSocketFrame *frame = [[ZMWebSocketFrame alloc] initWithPingFrame];
    [self sendFrame:frame];
}

- (void)sendPongFrame;
{
    ZMLogDebug(@"Sending PONG");
    ZMWebSocketFrame *frame = [[ZMWebSocketFrame alloc] initWithPongFrame];
    [self sendFrame:frame];
}

- (void)sendFrame:(ZMWebSocketFrame *)frame;
{
    dispatch_data_t frameData = frame.frameData;
    if (frameData != nil) {
        ZM_WEAK(self);
        [self safelyDispatchOnQueue:^{
            ZM_STRONG(self);
            if (self.handshakeCompleted) {
                [self.networkSocket writeData:(NSData *)frameData];
            } else {
                RequireString(self.dataPendingTransmission != nil, "Was already sent & cleared?");
                [self.dataPendingTransmission addObject:frameData];
            }
        }];
    }
}

- (void)sendHandshakeFrame
{
    ZM_WEAK(self);
    [self safelyDispatchOnQueue:^{
        ZM_STRONG(self);
        dispatch_data_t headerData = self.handshakeRequestData;
        [self.networkSocket writeData:(NSData *)headerData];
    }];
}

- (void)didReceivePing;
{
    [self sendPongFrame];
    ZMLogDebug(@"Received ping");
}

- (void)didReceivePong;
{
    ZMLogDebug(@"Received PONG");
}

@end


@implementation ZMWebSocket (NetworkSocket)

- (void)networkSocketDidOpen:(NetworkSocket *)socket
{
    VerifyReturn(socket == self.networkSocket);
    [self sendHandshakeFrame];
}

- (void)didReceiveData:(NSData *)data networkSocket:(NetworkSocket *)socket
{
    VerifyReturn(socket == self.networkSocket);
    
    dispatch_data_t dispatchData = dispatch_data_create(data.bytes, data.length, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    [self.inputBuffer appendData:dispatchData];
    
    if(!self.handshakeCompleted) {
        ZMWebSocketHandshakeResult parseResult = [self didParseHandshakeInBuffer];
        switch (parseResult) {
            case ZMWebSocketHandshakeCompleted:
                {
                    NSHTTPURLResponse *response = self.response;
                    self.response = nil;
                    self.handshakeCompleted = YES;
                    ZM_WEAK(self);
                    [self safelyDispatchOnQueue:^{
                        ZM_STRONG(self);
                        [self.consumer webSocketDidCompleteHandshake:self HTTPResponse:response];
                        self.response = nil;
                    }];
                }
                break;
            case ZMWebSocketHandshakeNeedsMoreData:
                break;
            case ZMWebSocketHandshakeError:
                [self close];
                break;
                
        }
        return;
    }
    
    // Parse frames until the input is empty or contains a partial frame:
    while ([self parseFrameFromInputBufferForSocket:socket]) {
        // nothing
    }
}

- (BOOL)parseFrameFromInputBufferForSocket:(NetworkSocket * __unused)socket
{
    if (self.inputBuffer.isEmpty) {
        return NO;
    }
    
    NSError *frameError;
    ZMWebSocketFrame *frame = [[ZMWebSocketFrame alloc] initWithDataBuffer:self.inputBuffer error:&frameError];
    if (frame == nil) {
        if (![frameError.domain isEqualToString:ZMWebSocketFrameErrorDomain] ||
            (frameError.code != ZMWebSocketFrameErrorCodeDataTooShort))
        {
            [self close];
        }
        return NO;
    } else {
        switch (frame.frameType) {
            case ZMWebSocketFrameTypeText: {
                ZM_WEAK(self);
                [self safelyDispatchOnQueue:^{
                    ZM_STRONG(self);
                    NSString *text = [[NSString alloc] initWithData:frame.payload encoding:NSUTF8StringEncoding];
                    [self.consumer webSocket:self didReceiveFrameWithText:text];
                }];
                break;
            }
            case ZMWebSocketFrameTypeBinary: {
                ZM_WEAK(self);
                [self safelyDispatchOnQueue:^{
                    ZM_STRONG(self);
                    [self.consumer webSocket:self didReceiveFrameWithData:frame.payload];
                }];
                break;
            }
            case ZMWebSocketFrameTypePing: {
                [self didReceivePing];
                break;
            }
            case ZMWebSocketFrameTypePong: {
                [self didReceivePong];
                break;
            }
            case ZMWebSocketFrameTypeClose: {
                [self close];
                return NO;
                break;
            }
            default:
                break;
        }
        return YES;
    }
}

- (void)networkSocketDidClose:(NetworkSocket *)socket
{
    VerifyReturn(socket == self.networkSocket);
    [self close];
}

@end
