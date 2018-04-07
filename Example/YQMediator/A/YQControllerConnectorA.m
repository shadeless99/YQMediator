#import "YQControllerConnectorA.h"
#import "YQViewControllerA.h"
#import "YQMediator.h"

#define kAController @"YQViewControllerA"

@interface YQControllerConnectorA ()<YQConnectorProtocol>

@end

@implementation YQControllerConnectorA
    
+ (void)load {
    @autoreleasepool {
        [YQMediator registerConnector:[self sharedConnector]];
    }
}
    
+ (instancetype)sharedConnector {
    static YQControllerConnectorA *_sharedConnector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConnector = [[YQControllerConnectorA alloc] init];
    });
    
    return _sharedConnector;
}
    
#pragma mark - YQConnectorProtocol
    
- (BOOL)canOpenURL:(NSURL *)url {
    if ([url.host isEqualToString:kAController]) {
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
    if ([URL.host isEqualToString:kAController]) {
        YQViewControllerA *viewController = [[YQViewControllerA alloc] init];
            
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
