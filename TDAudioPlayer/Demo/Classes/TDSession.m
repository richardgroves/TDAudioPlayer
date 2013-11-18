//
//  TDSession.m
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 11/15/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "TDSession.h"

@interface TDSession () <MCSessionDelegate, MCBrowserViewControllerDelegate>

@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCAdvertiserAssistant *advertiser;
@property (strong, nonatomic) MCPeerID *peerID;
@property (strong, nonatomic) NSOutputStream *output;

@end

@implementation TDSession

- (instancetype)initWithPeerDisplayName:(NSString *)name
{
    self = [super init];
    if (!self) return nil;

    self.peerID = [[MCPeerID alloc] initWithDisplayName:name];

    return self;
}

#pragma mark - Properties

- (MCSession *)session
{
    if (!_session) {
        _session = [[MCSession alloc] initWithPeer:self.peerID];
        _session.delegate = self;
    }
    return _session;
}

#pragma mark - MCSessionDelegate methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        NSLog(@"Connecting to %@", peerID.displayName);
    } else if (state == MCSessionStateConnected) {
        NSLog(@"Connected to %@", peerID.displayName);
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    //    NSString *title =[NSString stringWithFormat:@"Message from %@", peerID.displayName];
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSLog(@"Message: %@ --- from %@", message, peerID.displayName);
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    if ([streamName isEqualToString:@"music"]) {
        [[TDAudioPlayer sharedAudioPlayer] loadAudioFromStream:stream];
        [[TDAudioPlayer sharedAudioPlayer] play];
    }
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{

}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{

}

- (NSArray *)connectedPeers
{
    return [self.session connectedPeers];
}

- (NSArray *)openOutputStreams
{
    if ([self.session connectedPeers].count == 0) return nil;

    NSMutableArray *outputs = [NSMutableArray array];

    for (MCPeerID *peer in [self.session connectedPeers]) {
        [outputs addObject:[self.session startStreamWithName:@"music" toPeer:peer error:nil]];
    }

    return [outputs copy];
}

- (NSOutputStream *)outputStreamForPeer:(MCPeerID *)peer
{
    return [self.session startStreamWithName:@"music" toPeer:peer error:nil];
}

#pragma mark - MCBrowserViewController delegate

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (MCBrowserViewController *)browserViewControllerForSeriviceType:(NSString *)type
{
    MCBrowserViewController *view = [[MCBrowserViewController alloc] initWithServiceType:type session:self.session];
    view.delegate = self;
    return view;
}

#pragma mark - Advertising Assistant

- (void)startAdvertisingForServiceType:(NSString *)type discoveryInfo:(NSDictionary *)info
{
    if (!self.advertiser)
        self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:type discoveryInfo:info session:self.session];

    [self.advertiser start];
}

@end
