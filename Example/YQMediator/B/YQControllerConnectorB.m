#import "YQControllerConnectorB.h"
#import "YQViewControllerB.h"
#import "YQMediator.h"

#define kBController @"YQViewControllerB"

@interface YQControllerConnectorB ()<YQConnectorProtocol>
    
@end

@implementation YQControllerConnectorB
    
+ (void)load {
    @autoreleasepool {
        [YQMediator registerConnector:[self sharedConnector]];
    }
}
    
+ (instancetype)sharedConnector {
    static YQControllerConnectorB *_sharedConnector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConnector = [[YQControllerConnectorB alloc] init];
    });
    
    return _sharedConnector;
}
    
#pragma mark - YQConnectorProtocol
    
- (BOOL)canOpenURL:(NSURL *)url {
    if ([url.host isEqualToString:kBController]) {
        return YES;
    }
    return NO;
}
    
- (nullable id)connectToOpenURL:(nonnull NSURL *)URL
                         params:(nullable NSDictionary *)params {
    return [self connectToOpenURL:URL
                           params:params
                        withBlock:nil];
}
    
- (nullable id)connectToOpenURL:(nonnull NSURL *)URL
                         params:(nullable NSDictionary *)params
                      withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock {
    // 处理scheme://ADetail的方式
    // tip: url较少的时候可以通过if-else去处理，如果url较多，可以自己维护一个url和ViewController的map，加快遍历查找，生成viewController；
    if ([URL.host isEqualToString:kBController]) {
        YQViewControllerB *viewController = [[YQViewControllerB alloc] init];
        
        if (didConnectBlock) {
            didConnectBlock(nil,YES);
        }
        
        return viewController;
    } else {
        // nothing to to
    }
    
    return nil;
}

@end
