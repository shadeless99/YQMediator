#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** 连接建立回调 */
typedef void(^YQConnectorDidConnectBlock)(id _Nullable returnVal,BOOL isConnected);

/**
 * 组件链接协议，需要每个上线的组件实现
 */
@protocol YQConnectorProtocol <NSObject>

@required

/** 判断url是否匹配 */
- (BOOL)canOpenURL:(nonnull NSURL *)url;

/** 连接到指定url，返回对应实例 */
- (nullable id)connectToOpenURL:(nonnull NSURL *)URL
                         params:(nullable NSDictionary *)params;

/** 连接到指定url，返回对应实例 */
- (nullable id)connectToOpenURL:(nonnull NSURL *)URL
                         params:(nullable NSDictionary *)params
                      withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock;
    
@end

@interface YQMediator : NSObject

#pragma mark 注册
/** 组件连接器注册方法 */
+ (void)registerConnector:(nonnull id<YQConnectorProtocol>)connector;

#pragma mark- 通过URL页面跳转
/** 判断某个url能否导航 */
+ (BOOL)canRouteURL:(nonnull NSURL *)URL;

/** 导航到某个url，不带参数 */
+ (BOOL)routeURL:(nonnull NSURL *)URL
       withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock;

/** 导航到某个url，带参数 */
+ (BOOL)routeURL:(nonnull NSURL *)URL
  withParameters:(nonnull NSDictionary *)params
       withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock;


#pragma mark- 通过URL获取对应的viewcontroller
/** 获取对应的viewcontroller */
+ (nullable UIViewController *)viewControllerForURL:(nonnull NSURL *)URL
                                          withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock;

/** 获取对应的viewcontroller */
+ (nullable UIViewController *)viewControllerForURL:(nonnull NSURL *)URL
                                     withParameters:(nullable NSDictionary *)params
                                          withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock;

/** 获取对应的view */
+ (nullable UIView *)viewForURL:(nonnull NSURL *)URL
                 withParameters:(nullable NSDictionary *)params
                      withBlock:(nullable YQConnectorDidConnectBlock)didConnectBlock;

/** 获取全部注册的组件 */
+ (NSDictionary *)registeredConnectors;

@end
