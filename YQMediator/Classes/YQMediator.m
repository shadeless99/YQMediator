#import "YQMediator.h"

static NSMutableDictionary<NSString *, id<YQConnectorProtocol>> *connectorMap = nil;

@interface NSObject (YQPerformSelector)

/** 自定义performSelector方法，允许传入多个参数 */
- (id)performSelector:(SEL)selector withObjects:(NSArray *)objects;
    
@end

@implementation NSObject (YQPerformSelector)
    
- (id)performSelector:(SEL)selector withObjects:(NSArray *)objects {
    // 方法签名(方法的描述)
    NSMethodSignature *signature = [[self class] instanceMethodSignatureForSelector:selector];
    if (signature == nil) {
        return nil;
    }
    
    // NSInvocation : 利用一个NSInvocation对象包装一次方法调用（方法调用者、方法名、方法参数、方法返回值）
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = self;
    invocation.selector = selector;
    
    // 设置参数
    NSInteger paramsCount = signature.numberOfArguments - 2; // 除self、_cmd以外的参数个数
    paramsCount = MIN(paramsCount, objects.count);
    for (NSInteger i = 0; i < paramsCount; i++) {
        id object = objects[i];
        if ([object isKindOfClass:[NSNull class]]) continue;
        [invocation setArgument:&object atIndex:i + 2];
    }
    
    // 调用方法
    [invocation invoke];
    
    // 获取返回值
    id returnValue = nil;
    if (signature.methodReturnLength) { // 有返回值类型，才去获得返回值
        [invocation getReturnValue:&returnValue];
    }
    
    return returnValue;
}
    
@end

@implementation YQMediator

#pragma mark- 注册组件连接器
/** 组件连接器注册方法 */
+ (void)registerConnector:(id<YQConnectorProtocol>)connector {
    if (![connector conformsToProtocol:@protocol(YQConnectorProtocol)]) {
        return;
    }
    
    @synchronized (connectorMap) {
        if (connectorMap == nil) {
            connectorMap = [[NSMutableDictionary alloc] initWithCapacity:5];
        }
        
        NSString *connectorClassStr = NSStringFromClass([connector class]);
        if ([connectorMap objectForKey:connectorClassStr] == nil) {
            [connectorMap setValue:connector forKey:connectorClassStr];
        }
    }
}

#pragma mark- 通过URL页面跳转
/** 判断某个url能否导航 */
+ (BOOL)canRouteURL:(nonnull NSURL *)URL {
    if (connectorMap == nil ||
        connectorMap.count <= 0) {
        return NO;
    }
    
    __block BOOL success = NO;
    [connectorMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<YQConnectorProtocol>  _Nonnull connector, BOOL * _Nonnull stop) {
        if ([connector respondsToSelector:@selector(canOpenURL:)]) {
            if ([connector canOpenURL:URL]){
                success = YES;
                *stop = YES;
            }
        }
    }];
    
    return success;
}

/** 导航到某个url，不带参数 */
+ (BOOL)routeURL:(nonnull NSURL *)URL
       withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock {
    return [YQMediator routeURL:URL
                 withParameters:@{}
                withBlock:didConnectBlock];
}

/** 导航到某个url，带参数 */
+ (BOOL)routeURL:(nonnull NSURL *)URL
  withParameters:(nonnull NSDictionary *)params
       withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock {
    __block BOOL success = NO;
    __block id<YQConnectorProtocol> returnObj = nil;
    NSDictionary *userParams = [self userParametersWithURL:URL andParameters:params];
    [connectorMap enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * _Nonnull key, id<YQConnectorProtocol>  _Nonnull connector, BOOL * _Nonnull stop) {
        if ([connector respondsToSelector:@selector(connectToOpenURL:params:)]) {
            id returnObj = [connector connectToOpenURL:URL params:userParams];
            if (returnObj && [returnObj isKindOfClass:[UIViewController class]]) {
                success = YES;
                *stop = YES;
                returnObj = returnObj;
            }
        }
    }];
    
    if (didConnectBlock) {
        didConnectBlock(returnObj,success);
    }
    return success;
}

#pragma mark- 通过URL获取对应的viewcontroller
/** 获取对应的viewcontroller */
+ (nullable UIViewController *)viewControllerForURL:(nonnull NSURL *)URL
                                          withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock {
    return [YQMediator viewControllerForURL:URL
                             withParameters:nil
                            withBlock:didConnectBlock];
}

/** 获取对应的viewcontroller */
+ (nullable UIViewController *)viewControllerForURL:(nonnull NSURL *)URL
                                     withParameters:(nullable NSDictionary *)params
                                          withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock {
    if (!connectorMap || connectorMap.count <= 0) return nil;
    
    __block UIViewController *targetObj = nil;
    __block id returnObj;

    NSDictionary *userParams = [self userParametersWithURL:URL andParameters:params];
    [connectorMap enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * _Nonnull key, id<YQConnectorProtocol>  _Nonnull connector, BOOL * _Nonnull stop) {

        if ([connector respondsToSelector:@selector(connectToOpenURL:params:)]) {
            // target
            targetObj = [connector connectToOpenURL:URL params:userParams];
            
            // action
            if (URL.path != nil) {
                NSString *actionName = [URL.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
                SEL actionSel = NSSelectorFromString(actionName);
                if ([targetObj respondsToSelector:actionSel]) {
                    // return vlaue
                    returnObj = [targetObj performSelector:actionSel withObjects:[params allValues]];
                }
            }
            
            if (targetObj && [targetObj isKindOfClass:[UIViewController class]]) {
                *stop = YES;
            }
        }
    }];
    if (!targetObj) {
        if ([URL.host isKindOfClass:[NSString class]]) {
            targetObj = [[NSClassFromString(URL.host) alloc] init];
        }
    }
    if (didConnectBlock) {
        didConnectBlock(returnObj,targetObj ? YES : NO);
    }
    return targetObj;
}

/** 获取对应的view */
+ (nullable UIView *)viewForURL:(nonnull NSURL *)URL
                 withParameters:(nullable NSDictionary *)params
                      withBlock:(nullable YQConnectorDidConnectBlock)connectDidBlock {
    if (!connectorMap || connectorMap.count <= 0) return nil;
    
    __block UIView *targetObj = nil;
    __block id returnObj;
    
    NSDictionary *userParams = [self userParametersWithURL:URL andParameters:params];
    [connectorMap enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * _Nonnull key, id<YQConnectorProtocol>  _Nonnull connector, BOOL * _Nonnull stop) {
        
        if ([connector respondsToSelector:@selector(connectToOpenURL:params:)]) {
            // target
            targetObj = [connector connectToOpenURL:URL params:userParams];
            
            // action
            if (URL.path != nil) {
                NSString* actionName = [URL.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
                SEL actionSel = NSSelectorFromString(actionName);
                if ([targetObj respondsToSelector:actionSel]) {
                    // return vlaue
                    returnObj = [targetObj performSelector:actionSel withObjects:[params allValues]];
                }
            }
            
            if (targetObj && [targetObj isKindOfClass:[UIView class]]) {
                *stop = YES;
            }
        }
    }];
    if (!targetObj) {
        if ([URL.host isKindOfClass:[NSString class]]) {
            targetObj = [[NSClassFromString(URL.host) alloc] init];
        }
    }
    if (connectDidBlock) {
        connectDidBlock(returnObj,targetObj?YES:NO);
    }
    return targetObj;
}

/**
 * 从url获取query参数放入到参数列表中
 */
+ (NSDictionary *)userParametersWithURL:(nonnull NSURL *)URL andParameters:(nullable NSDictionary *)params {
    NSArray *pairs = [URL.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *userParams = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count == 2) {
            NSString *key = [kv objectAtIndex:0];
            NSString *value = [self URLDecodedString:[kv objectAtIndex:1]];
            [userParams setObject:value forKey:key];
        }
    }
    [userParams addEntriesFromDictionary:params];
    return [NSDictionary dictionaryWithDictionary:userParams];
}

/**
 * 对url的value部分进行urlDecoding
 */
+ (nonnull NSString *)URLDecodedString:(nonnull NSString *)urlString {
    NSString *result = urlString;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
    result = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                                   (__bridge CFStringRef)urlString,
                                                                                                   CFSTR(""),
                                                                                                   kCFStringEncodingUTF8);
#else
    result = [urlString stringByRemovingPercentEncoding];
#endif
    return result;
}
    
@end
