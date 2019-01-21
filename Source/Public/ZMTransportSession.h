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


#import <Foundation/Foundation.h>
#import <WireTransport/ZMTransportResponse.h>
#import <WireTransport/ZMTransportRequest.h>
#import <WireTransport/ZMReachability.h>
#import <WireTransport/ZMBackgroundable.h>
#import <WireTransport/ZMRequestCancellation.h>


NS_ASSUME_NONNULL_BEGIN

@class UIApplication;
@class ZMAccessToken;
@class ZMTransportRequest;
@class ZMPersistentCookieStorage;
@class ZMTransportRequestScheduler;
@protocol ZMPushChannelConsumer;
@protocol ZMSGroupQueue;
@protocol ZMKeyValueStore;
@protocol ZMPushChannel;
@protocol ReachabilityProvider;
@protocol BackendEnvironmentProvider;
@class ZMTransportRequest;

typedef ZMTransportRequest* _Nullable (^ZMTransportRequestGenerator)(void);

/// This is the error domain that the @c ZMTransportSession passes on to the @c ZMTransportResponse.
/// It should @b only be generated by the @c ZMTransportSession and @b only be interpreted by the @c ZMTransportResponse.
extern NSString * const ZMTransportSessionErrorDomain;
/// Error codes for @c ZMTransportSessionErrorDomain
typedef NS_ENUM(NSInteger, ZMTransportSessionErrorCode) {
    ZMTransportSessionErrorCodeInvalidCode = 0, ///< Should never be used
    ZMTransportSessionErrorCodeAuthenticationFailed, ///< Unable to get access token / cookie
    ZMTransportSessionErrorCodeRequestExpired, ///< Request went over its expiration date
    ZMTransportSessionErrorCodeTryAgainLater, ///< c.f. @code -[NSError isTryAgainLaterError] @endcode
};

extern NSString * const ZMTransportSessionNewRequestAvailableNotification;

/// Return type for an enqueue operation
@interface ZMTransportEnqueueResult : NSObject

+ (_Null_unspecified instancetype)resultDidHaveLessRequestsThanMax:(BOOL)didHaveLessThanMax didGenerateNonNullRequest:(BOOL)didGenerateRequest;

@property (nonatomic, readonly) BOOL didHaveLessRequestThanMax;
@property (nonatomic, readonly) BOOL didGenerateNonNullRequest;

@end

@interface ZMTransportSession : NSObject <ZMBackgroundable>

@property (nonatomic, readonly, nullable) ZMAccessToken *accessToken;
@property (nonatomic, readonly) NSURL *baseURL;
@property (nonatomic, readonly) NSOperationQueue *workQueue;
@property (nonatomic, assign) NSInteger maximumConcurrentRequests;
@property (nonatomic, readonly) ZMPersistentCookieStorage *cookieStorage;
@property (nonatomic, readonly) ZMURLSession *session;
@property (nonatomic, copy) void (^requestLoopDetectionCallback)(NSString*);
@property (nonatomic, readonly) id<ReachabilityProvider, TearDownCapable> reachability;

- (instancetype)initWithEnvironment:(id<BackendEnvironmentProvider>)environment
                      cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                       reachability:(id<ReachabilityProvider, TearDownCapable>)reachability
                 initialAccessToken:(nullable ZMAccessToken *)initialAccessToken;

- (void)tearDown;

/// Sets the access token failure callback. This can be called only before the first request is fired
- (void)setAccessTokenRenewalFailureHandler:(ZMCompletionHandlerBlock)handler; //TODO accesstoken // move this out of here?

/// Sets the access token success callback
- (void)setAccessTokenRenewalSuccessHandler:(ZMAccessTokenHandlerBlock)handler;

- (void)enqueueOneTimeRequest:(ZMTransportRequest *)searchRequest;
- (ZMTransportEnqueueResult *)attemptToEnqueueSyncRequestWithGenerator:(ZMTransportRequestGenerator)requestGenerator;

- (void)setNetworkStateDelegate:(nullable id<ZMNetworkStateDelegate>)delegate;

+ (void)notifyNewRequestsAvailable:(id<NSObject>)sender;

@end



@interface ZMTransportSession (PushChannel)

@property (nonatomic, readonly) id<ZMPushChannel> pushChannel;

- (void)configurePushChannelWithConsumer:(id<ZMPushChannelConsumer>)consumer groupQueue:(id<ZMSGroupQueue>)groupQueue;

@end

@interface ZMTransportSession (RequestCancellation) <ZMRequestCancellation>

@end


// 1 TODO:
// When we're offline / connection timeouts / backend tells us to back off:
// It would be helpful to be able to fail requests with a "temporary" network error which would cause
// the downstream / upstream object sync classes to put these requests back into their queues of
// outstanding objects.
// That way we wouldn't block the transport session with potentially old / low priority work once we're back
// online.


NS_ASSUME_NONNULL_END
