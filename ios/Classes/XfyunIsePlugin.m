#import "XfyunIsePlugin.h"
#import <iflyMSC/iflyMSC.h>
#import <objc/runtime.h>

static FlutterMethodChannel *_channel = nil;


@interface XfyunIsePlugin () <IFlySpeechEvaluatorDelegate, IFlyPcmRecorderDelegate>
@property (nonatomic, strong) NSString *resultString;
@property (nonatomic, strong) NSNumber *isEvaluating;

@end

@implementation XfyunIsePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"com.zhuobeitech/xfyun_ise"
            binaryMessenger:[registrar messenger]];
  XfyunIsePlugin* instance = [[XfyunIsePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  _channel = channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"init" isEqualToString:call.method]) {
        [self iflyInit:call.arguments];
        result(NULL);
    } else if ([@"setParameter" isEqualToString:call.method]) {
        [self setParameter:call.arguments];
        result(NULL);
    } else if ([@"start" isEqualToString:call.method]) {
        [self start: call.arguments[@"text"]];
        result(NULL);
    } else if ([@"writeAudio" isEqualToString:call.method]) {
        FlutterStandardTypedData *data = call.arguments[@"data"];
       [self writeAudio: data.data];
        result(NULL);
    } else if ([@"stop" isEqualToString:call.method]) {
        [self stop];
        result(NULL);
    } else if ([@"cancel" isEqualToString:call.method]) {
        [self cancel];
        result(NULL);
    } else if ([@"dispose" isEqualToString:call.method]) {
        [self cancel];
        result(NULL);
    } else if ([@"isEvaluating" isEqualToString:call.method]) {
        result(self.isEvaluating);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Bridge Actions

- (void)iflyInit:(NSString *)appId {
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", appId];
    [IFlySpeechUtility createUtility:initString];
    [[IFlySpeechEvaluator sharedInstance] setDelegate:self];
    [IFlySetting setLogFile:LVL_NONE];
    self.isEvaluating = @NO;
}

- (void)setParameter:(NSDictionary *)param {
    [param enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [[IFlySpeechEvaluator sharedInstance] setParameter:obj forKey:key];
    }];
}

- (void)start:(NSString *)text {
    if ([self.isEvaluating boolValue]) {
        return;
    }
    self.isEvaluating = @YES;
    self.resultString = nil;
    BOOL ret = [[IFlySpeechEvaluator sharedInstance] startListening:[text dataUsingEncoding:NSUTF8StringEncoding] params:nil];
    if(!ret) {
        NSLog(@"[OUT], Evaluation failed!");
    }
}

- (void)stop {
    self.isEvaluating = @NO;
    [[IFlySpeechEvaluator sharedInstance] stopListening];
}

- (void)cancel {
    self.isEvaluating = @NO;
    [[IFlySpeechEvaluator sharedInstance] cancel];
}

- (void)writeAudio:(NSData *)data {
    int ret = [[IFlySpeechEvaluator sharedInstance] writeAudio:data];
    if(!ret) {
        [[IFlySpeechEvaluator sharedInstance] stopListening];
    }
}

#pragma mark - IFlySpeechEvaluatorDelegate

- (void)onBeginOfSpeech {
    NSLog(@"[OUT], onBeginOfSpeech");
    [_channel invokeMethod:@"onBeginOfSpeech" arguments:NULL];
}

- (void)onCancel {
    [_channel invokeMethod:@"onCancel" arguments:NULL];
}

- (void)onCompleted:(IFlySpeechError *)errorCode {
    NSDictionary *dic = NULL;
    if (errorCode.errorCode != 0) {
        NSLog(@"[OUT], Evaluation failed! errcode: %d, desc: %@", errorCode.errorCode, errorCode.errorDesc);
        dic = @{@"code": @(errorCode.errorCode),
                @"type": @(errorCode.errorType),
                @"desc": errorCode.errorDesc
                };
    }
    if(dic) {
        [_channel invokeMethod:@"onError" arguments:@[dic]];
    }
}

- (void)onEndOfSpeech {
    NSLog(@"[OUT], onEndOfSpeech");
    [_channel invokeMethod:@"onEndOfSpeech" arguments:NULL];
}

- (void)onResults:(NSData *)results isLast:(BOOL)isLast {
    if(results) {
        NSString *ret = @"";
        const char * chResult = [results bytes];
        
        BOOL isUTF8 = [[[IFlySpeechEvaluator sharedInstance] parameterForKey:[IFlySpeechConstant RESULT_ENCODING]] isEqualToString:@"utf-8"];
        NSString* strTmpResults = nil;
        if(isUTF8) {
            strTmpResults = [[NSString alloc] initWithBytes:chResult length:[results length] encoding:NSUTF8StringEncoding];
        } else {
            NSLog(@"result encoding: gb2312");
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            strTmpResults = [[NSString alloc] initWithBytes:chResult length: [results length] encoding: encoding];
        }
        if(strTmpResults) {
            ret = [ret stringByAppendingString: strTmpResults];
        }
        if(isLast) {
            NSLog(@"[OUT], onResults: %@", ret);
            [_channel invokeMethod:@"onResult" arguments:ret];
        }
    }
}

- (void)onVolumeChanged:(int)volume buffer:(NSData *)buffer {
  [_channel invokeMethod:@"onVolumeChanged" arguments:@(volume)];
}

#pragma mark - IFlyPcmRecorderDelegate

- (void)onIFlyRecorderBuffer:(const void *)buffer bufferSize:(int)size {
    NSData *audioBuffer = [NSData dataWithBytes:buffer length:size];
    
    int ret = [[IFlySpeechEvaluator sharedInstance] writeAudio:audioBuffer];
    if(!ret) {
        [[IFlySpeechEvaluator sharedInstance] stopListening];
    }
}

- (void)onIFlyRecorderError:(IFlyPcmRecorder *)recoder theError:(int)error {
    NSLog(@"[OUT], onIFlyRecorderError: %d", error);
}

@end
