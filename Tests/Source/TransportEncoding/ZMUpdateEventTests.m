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


@import ZMTransport;
@import ZMTesting;

@interface ZMUpdateEventTests : ZMTBaseTest

@end

@implementation ZMUpdateEventTests

- (NSDictionary *)typesMapping
{
    return @{
             @"call.device-info" : @(ZMUpdateEventCallDeviceInfo),
             @"call.flow-active" : @(ZMUpdateEventCallFlowActive),
             @"call.flow-add" : @(ZMUpdateEventCallFlowAdd),
             @"call.flow-delete" : @(ZMUpdateEventCallFlowDelete),
             @"call.info" : ZM_ALLOW_DEPRECATED(@(ZMUpdateEventCallInfo)),
             @"call.participants": @(ZMUpdateEventCallParticipants),
             @"call.remote-candidates-add" : @(ZMUpdateEventCallCandidatesAdd),
             @"call.remote-candidates-update" : @(ZMUpdateEventCallCandidatesUpdate),
             @"call.remote-sdp" : @(ZMUpdateEventCallRemoteSDP),
             @"call.state" : @(ZMUpdateEventCallState),
             @"conversation.asset-add" : @(ZMUpdateEventConversationAssetAdd),
             @"conversation.connect-request" : @(ZMUpdateEventConversationConnectRequest),
             @"conversation.create" : @(ZMUpdateEventConversationCreate),
             @"conversation.knock" : @(ZMUpdateEventConversationKnock),
             @"conversation.member-join" : @(ZMUpdateEventConversationMemberJoin),
             @"conversation.member-leave" : @(ZMUpdateEventConversationMemberLeave),
             @"conversation.member-update" : @(ZMUpdateEventConversationMemberUpdate),
             @"conversation.message-add" : @(ZMUpdateEventConversationMessageAdd),
             @"conversation.client-message-add" : @(ZMUpdateEventConversationClientMessageAdd),
             @"conversation.otr-message-add" : @(ZMUpdateEventConversationOtrMessageAdd),
             @"conversation.otr-asset-add" : @(ZMUpdateEventConversationOtrAssetAdd),
             @"conversation.rename" : @(ZMUpdateEventConversationRename),
             @"conversation.typing" : @(ZMUpdateEventConversationTyping),
             @"conversation.voice-channel" : @(ZMUpdateEventConversationVoiceChannel),
             @"conversation.voice-channel-activate" : @(ZMUpdateEventConversationVoiceChannelActivate),
             @"conversation.voice-channel-deactivate" : @(ZMUpdateEventConversationVoiceChannelDeactivate),
             @"user.connection" : @(ZMUpdateEventUserConnection),
             @"user.new" : @(ZMUpdateEventUserNew),
             @"user.push-remove" : @(ZMUpdateEventUserPushRemove),
             @"user.update" : @(ZMUpdateEventUserUpdate),
             @"user.contact-join" : @(ZMUpdateEventUserContactJoin),
             @"user.client-add" : @(ZMUpdateEventUserClientAdd),
             @"user.client-remove" : @(ZMUpdateEventUserClientRemove),
             };
}

- (void)testThatItParsesCorrectTypes
{
    // given

    NSDictionary *types = [self typesMapping];
    
    for (NSString *key in [types keyEnumerator]) {
        NSDictionary *data =
            @{
                @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
                @"payload" :
                    @[
                        @{
                        @"type" : key,
                        },
                    ]
            };

        NSArray *events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
        
        // when
        ZMUpdateEvent *event = events[0];

        // then
        XCTAssertNotNil(event);
        XCTAssertEqual([types[key] intValue], event.type);
    }

}

- (void)testEventTypeConversion_1;
{
    // given
    NSArray *types = [self typesMapping].allKeys;
    
    // then
    for (NSString *s in types) {
        ZMUpdateEventType t = [ZMUpdateEvent updateEventTypeForEventTypeString:s];
        NSString *converted = [ZMUpdateEvent eventTypeStringForUpdateEventType:t];
        XCTAssertEqualObjects(converted, s);
    }
}

- (void)testEventTypeConversion_2;
{
    // given
    
    NSArray *types = [self typesMapping].allValues;
    
    // then
    for (NSNumber *n in types) {
        ZMUpdateEventType type = (ZMUpdateEventType) n.intValue;
        NSString *s = [ZMUpdateEvent eventTypeStringForUpdateEventType:type];
        ZMUpdateEventType converted = [ZMUpdateEvent updateEventTypeForEventTypeString:s];
        XCTAssertEqual(converted, type);
    }
}

- (void)testThatItReturnsNullForInvalidEventType
{
    // given
    NSString *eventType = @"myevent.invalid";
    id <ZMTransportData> data =
        @{
            @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"payload" : @[
                        @{
                            @"type" : eventType,
                        }
                        ]
        };

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];

    // then
    XCTAssertEqual(events.count, 0u);
}

- (void)testThatItReturnsNullForMissingEventType
{
    // given
    id <ZMTransportData> data =
        @{
            @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"payload" : @[@{}]
        };

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];
    
    // then
    XCTAssertEqual(events.count, 0u);

}

- (void)testThatItReturnsNullForInvalidData
{
    // given
    id <ZMTransportData> data =
        @{
        };

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];
    
    // then
    XCTAssertEqual(events.count, 0u);

}

- (void)testThatItReturnsNullForNonDictionary
{
    // given
    id <ZMTransportData> data = @[];

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];
    
    // then
    XCTAssertEqual(events.count, 0u);

}

- (void)testThatItSetsPayload
{
    // given
    NSString *eventType = @"user.update";

    NSDictionary *innerPayload = @{
        @"type" : eventType,
        @"foo" : @"barzaz"
    };
    NSDictionary *data =
        @{
            @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"payload" : @[innerPayload]
        };

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];

    // then
    XCTAssertEqual(events.count, 1u);
    ZMUpdateEvent *event = events[0];
    XCTAssertEqualObjects(event.payload, innerPayload);
}

- (void)testThatItSetsEventId
{
    // given
    NSString *eventType = @"user.update";

    NSDictionary *innerPayload = @{
        @"type" : eventType,
        @"foo" : @"barzaz"
    };
    NSDictionary *data =
        @{
            @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"payload" : @[innerPayload]
        };

    // when
    NSArray *events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    
    // then
    XCTAssertEqual(events.count, 1u);
    ZMUpdateEvent *event = events[0];
    XCTAssertEqualObjects(event.uuid, [data[@"id"] UUID]);
}


- (void)testThatItSetsPayloadFromStreamEvent
{
    // given
    NSDictionary *payload = @{
        @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7c",
        @"time" : @"2014-06-18T12:36:51.755Z",
        @"data" : @{
            @"content" : @"First! ;)",
            @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
        },
        @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
        @"id" : @"8.800122000a68ee1d",
        @"type" : @"conversation.message-add"
    };

    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    
    // then
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.payload, payload);
}


- (void)testThatItSetsIDToNilFromStreamEvent
{
    // given
    NSDictionary *payload = @{
        @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
        @"time" : @"2014-06-18T12:36:51.755Z",
        @"data" : @{
            @"content" : @"First! ;)",
            @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
        },
        @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
        @"id" : @"8.800122000a68ee1d",
        @"type" : @"conversation.message-add"
    };

    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];

    // then
    XCTAssertNotNil(event);
    XCTAssertNil(event.uuid);
}

- (void)testThatItSetsTypeFromStreamEvent
{
    // given
    NSDictionary *payload = @{
        @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
        @"time" : @"2014-06-18T12:36:51.755Z",
        @"data" : @{
            @"content" : @"First! ;)",
            @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
        },
        @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
        @"id" : @"8.800122000a68ee1d",
        @"type" : @"conversation.message-add"
    };

    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];

    // then
    XCTAssertNotNil(event);
    XCTAssertEqual(ZMUpdateEventConversationMessageAdd, event.type);
}




- (void)testThatItReturnsNullForInvalidEventTypeFromStreamEvent
{
    // given
    NSString *eventType = @"myevent.invalid";
    id <ZMTransportData> payload =
        @{
            @"type" : eventType,
        };

    // when
    __block ZMUpdateEvent *event;
    [self performIgnoringZMLogError:^{
        event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    }];

    // then
    XCTAssertNil(event);
}

- (void)testThatItReturnsNullForMissingEventTypeFromStreamEvent
{
    // given
    id <ZMTransportData> payload =
        @{
            @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"time" : @"2014-06-18T12:36:51.755Z",
            @"data" : @{
                @"content" : @"First! ;)",
                @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
            },
            @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
            @"id" : @"8.800122000a68ee1d"
        };

    // when
    __block ZMUpdateEvent *event;
    [self performIgnoringZMLogError:^{
        event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    }];

    // then
    XCTAssertNil(event);
}


- (void)testThatItReturnsNullForInvalidDataFromStreamEvent
{
    // given
    id <ZMTransportData> payload =
        @{
        };

    // when
    __block ZMUpdateEvent *event;
    [self performIgnoringZMLogError:^{
        event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    }];

    // then
    XCTAssertNil(event);
}

- (void)testThatItReturnsNullForNonDictionaryFromStreamEvent
{
    // given
    id <ZMTransportData> payload = @[];

    // when
    __block ZMUpdateEvent *event;
    [self performIgnoringZMLogError:^{
        event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    }];

    // then
    XCTAssertNil(event);
}

@end


@implementation ZMUpdateEventTests (Source)

- (void)testThatItSetsTheSourceOnTheUpdateEvent
{
    [self performWithAllSourceTypes:^(ZMUpdateEventSource source) {
        // given & then
        NSArray <ZMUpdateEvent *>*events = [ZMUpdateEvent eventsArrayFromTransportData:self.pushChannelDataFixture source:source];
        XCTAssertEqual(events.firstObject.source, source);
    }];
}

- (void)testThatTheSourceForEventsFromPushChannelDataIsWebSocket
{
    // when
    NSArray <ZMUpdateEvent *>*events = [ZMUpdateEvent eventsArrayFromPushChannelData:self.pushChannelDataFixture];
    
    // then
    XCTAssertEqual(events.firstObject.source, ZMUpdateEventSourceWebSocket);
}

- (void)testThatItSetsTheSourceForEventsFromEventStreamPayloadIsDownload
{
    // when
    NSUUID *identifier = NSUUID.createUUID;
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:[self payloadFixtureWithID:identifier] uuid:identifier];
    
    // then
    XCTAssertEqual(event.source, ZMUpdateEventSourceDownload);
}

- (void)testThatItSetsTheSourceWhenCreatingDecryptedUpdateEventFromTransportData
{
    [self performWithAllSourceTypes:^(ZMUpdateEventSource source) {
        NSUUID *identifier = NSUUID.createUUID;
        ZMUpdateEvent *event = [ZMUpdateEvent decryptedUpdateEventFromEventStreamPayload:[self payloadFixtureWithID:identifier] uuid:identifier transient:NO source:source];
        XCTAssertEqual(event.source, source);
    }];
}

- (void)performWithAllSourceTypes:(void (^)(ZMUpdateEventSource))block
{
    ZMUpdateEventSource sources[3] = { ZMUpdateEventSourceDownload, ZMUpdateEventSourcePushNotification, ZMUpdateEventSourceWebSocket };
    NSUInteger size = sizeof(sources) / sizeof(ZMUpdateEventSource);
    for (NSUInteger idx = 0; idx < size; idx++) {
        block(sources[idx]);
    }
}

#pragma mark - Helper

- (id <ZMTransportData>)payloadFixture
{
    return [self payloadFixtureWithID:nil];
}

- (id <ZMTransportData>)payloadFixtureWithID:(NSUUID *)identifier
{
    return @{
             @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7c",
             @"time" : @"2014-06-18T12:36:51.755Z",
             @"data" : @{
                     @"content" : @"Foo Bar Bazinga",
                     @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
                     },
             @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
             @"id" : identifier.transportString ?: @"8.800122000a68ee1d",
             @"type" : @"conversation.message-add"
             };
}

- (id <ZMTransportData>)pushChannelDataFixture
{
    return @{
             @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
             @"payload" : @[
                     @{
                         @"type" : @"user.update",
                         @"foo" : @"barzaz"
                         }
                     ]
             };
}

@end


@implementation ZMUpdateEventTests (Transient)

- (void)testThatAnEventIsNotTransientIfNotSpecified_Stream
{
    // given
    NSDictionary *payload = @{
                              @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
                              @"time" : @"2014-06-18T12:36:51.755Z",
                              @"data" : @{
                                      @"content" : @"First! ;)",
                                      @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
                                      },
                              @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
                              @"id" : @"8.800122000a68ee1d",
                              @"type" : @"conversation.message-add"
                              };
    
    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    
    // then
    XCTAssertFalse(event.isTransient);
}

- (void)testThatAnEventIsNotTransientIfNotSpecified_Push
{
    // given
    NSDictionary *data =
    @{
      @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
      @"payload" : @[
                      @{
                          @"type" : @"user.update",
                          @"foo" : @"barzaz"
                      }
                    ]
      };
    
    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:data].firstObject;
    
    // then
    XCTAssertFalse(event.isTransient);
}

- (void)testThatAnEventIsNotTransientIfExplicitlySaysSo
{
    // given
    NSDictionary *data =
    @{
      @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
      @"transient" : @(NO),
      @"payload" : @[
              @{
                  @"type" : @"user.update",
                  @"foo" : @"barzaz"
                  }
              ]
      };
    
    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:data].firstObject;
    
    // then
    XCTAssertFalse(event.isTransient);
}


- (void)testThatAnEventIsTransientIfExplicitlySaysSo
{
    // given
    NSDictionary *data =
    @{
      @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
      @"transient" : @(YES),
      @"payload" : @[
              @{
                  @"type" : @"user.update",
                  @"foo" : @"barzaz"
                  }
              ]
      };
    
    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:data].firstObject;
    
    // then
    XCTAssertTrue(event.isTransient);
}


- (void)testThatItDetectsFlowEvents;
{
    for (ZMUpdateEventType type = ZMUpdateEventUnknown; type < ZMUpdateEvent_LAST; type++) {
        // given
        BOOL expected = NO;
        switch (type) {
            case ZMUpdateEventUnknown:
                continue;
            case ZMUpdateEventCallCandidatesAdd:
            case ZMUpdateEventCallCandidatesUpdate:
            case ZMUpdateEventCallFlowActive:
            case ZMUpdateEventCallFlowAdd:
            case ZMUpdateEventCallFlowDelete:
            case ZMUpdateEventCallRemoteSDP:
                expected = YES;
                break;
            case ZMUpdateEventCallParticipants:
            case ZM_ALLOW_DEPRECATED(ZMUpdateEventCallInfo):
            case ZMUpdateEventCallDeviceInfo:
            case ZMUpdateEventCallState:
            case ZMUpdateEventConversationAssetAdd:
            case ZMUpdateEventConversationConnectRequest:
            case ZMUpdateEventConversationCreate:
            case ZMUpdateEventConversationKnock:
            case ZMUpdateEventConversationMemberJoin:
            case ZMUpdateEventConversationMemberLeave:
            case ZMUpdateEventConversationMemberUpdate:
            case ZMUpdateEventConversationMessageAdd:
            case ZMUpdateEventConversationClientMessageAdd:
            case ZMUpdateEventConversationOtrMessageAdd:
            case ZMUpdateEventConversationOtrAssetAdd:
            case ZMUpdateEventConversationRename:
            case ZMUpdateEventConversationTyping:
            case ZMUpdateEventConversationVoiceChannel:
            case ZMUpdateEventConversationVoiceChannelActivate:
            case ZMUpdateEventConversationVoiceChannelDeactivate:
            case ZMUpdateEventUserConnection:
            case ZMUpdateEventUserNew:
            case ZMUpdateEventUserUpdate:
            case ZMUpdateEventUserPushRemove:
            case ZMUpdateEventUserContactJoin:
            case ZMUpdateEventUserClientAdd:
            case ZMUpdateEventUserClientRemove:
            case ZMUpdateEvent_LAST:
                break;
        }
        __block NSString *typeString;
        [self.typesMapping enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSNumber *encodedType, BOOL *stop) {
            if (encodedType.intValue == (int) type) {
                *stop = YES;
                typeString = name;
            }
        }];
        XCTAssertNotNil(typeString, @"%d", (int) type);
        
        // when
        ZMUpdateEvent *sut = [ZMUpdateEvent eventFromEventStreamPayload:@{@"type": typeString} uuid:nil];
        
        // then
        XCTAssertEqual(sut.isFlowEvent, expected, @"%d", (int) type);
    }
}

@end
