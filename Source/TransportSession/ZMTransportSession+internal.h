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

#import <WireTransport/ZMTransportSession.h>
#import "ZMPushChannelConnection.h"
#import "ZMTransportRequestScheduler.h"
#import "ZMAccessTokenHandler.h"
#import "ZMURLSession.h"

@class ZMTaskIdentifierMap;
@class ZMReachability;
@class ZMAccessToken;
@protocol URLSessionsDirectory;

@interface ZMTransportSession ()

- (NSURLSessionTask *)suspendedTaskForRequest:(ZMTransportRequest *)request onSession:(ZMURLSession *)session;

@end



@interface ZMTransportSession (RequestScheduler) <ZMTransportRequestSchedulerSession>
@end


@interface ZMTransportSession (Testing)
- (void)setAccessToken:(ZMAccessToken *)accessToken;
@end


@interface ZMTransportSession (URLSessionDelegate) <ZMURLSessionDelegate>
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(ZMURLSession *)URLSession;
@end



@interface ZMTransportSession (ReachabilityObserver) <ZMReachabilityObserver>

- (void)updateNetworkStatusFromDidReadDataFromNetwork;

@end
