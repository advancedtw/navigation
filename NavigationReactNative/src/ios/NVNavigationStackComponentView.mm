#ifdef RCT_NEW_ARCH_ENABLED
#import "NVNavigationStackComponentView.h"
#import "NVSceneComponentView.h"
#import "NVNavigationStackView.h"
#import "NVSceneComponentView.h"
#import "NVSceneController.h"
#import "NVSceneComponentView.h"
#import "NVSceneTransitioning.h"
#import "NVNavigationBarComponentView.h"

#import <react/renderer/components/navigationreactnative/ComponentDescriptors.h>
#import <react/renderer/components/navigationreactnative/EventEmitters.h>
#import <react/renderer/components/navigationreactnative/Props.h>
#import <react/renderer/components/navigationreactnative/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <React/RCTI18nUtil.h>
#import <React/UIView+React.h>

using namespace facebook::react;

@interface NVNavigationStackComponentView () <RCTNVNavigationStackViewProtocol>
@end

@implementation NVNavigationStackComponentView
{
    NSMutableDictionary *_scenes;
    NSInteger _nativeEventCount;
    UINavigationController *_oldNavigationController;
    NSMutableArray<NVTransition*> *_enterTransitions;
    NSMutableArray<NVTransition*> *_exitTransitions;
    BOOL _navigated;
    BOOL _presenting;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        static const auto defaultProps = std::make_shared<const NVNavigationStackProps>();
        _props = defaultProps;
        _scenes = [[NSMutableDictionary alloc] init];
        _enterTransitions = [[NSMutableArray alloc] init];
        _exitTransitions = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)ensureNavigationController
{
    if (!_navigationController) {
        [_oldNavigationController willMoveToParentViewController:nil];
        [_oldNavigationController.view removeFromSuperview];
        [_oldNavigationController removeFromParentViewController];
        _navigationController = [[NVStackController alloc] init];
        _navigationController.view.semanticContentAttribute = ![[RCTI18nUtil sharedInstance] isRTL] ? UISemanticContentAttributeForceLeftToRight : UISemanticContentAttributeForceRightToLeft;
        _navigationController.navigationBar.semanticContentAttribute = ![[RCTI18nUtil sharedInstance] isRTL] ? UISemanticContentAttributeForceLeftToRight : UISemanticContentAttributeForceRightToLeft;
        [self addSubview:_navigationController.view];
        _navigationController.delegate = self;
        _navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    [self ensureNavigationController];
    const auto &newViewProps = *std::static_pointer_cast<NVNavigationStackProps const>(props);
    NSMutableArray *keysArr = [[NSMutableArray alloc] init];
    for (auto i = 0; i < newViewProps.keys.size(); i++) {
        NSString *key = [[NSString alloc] initWithUTF8String: newViewProps.keys[i].c_str()];
        [keysArr addObject:key];
    }
    self.keys = [keysArr copy];
    _enterAnimOff = newViewProps.enterAnimOff;
    [_enterTransitions removeAllObjects];
    [_exitTransitions removeAllObjects];
    for (auto i = 0; i < newViewProps.enterTrans.items.size(); i++) {
        NVNavigationStackEnterTransItemsStruct transItem = newViewProps.enterTrans.items[i];
        NVTransition *transition = [[NVTransition alloc] initWithType:[[NSString alloc] initWithUTF8String: transItem.type.c_str()]];
        transition.duration = [[[NSString alloc] initWithUTF8String: transItem.duration.c_str()] intValue];
        transition.x = [self parseAnimation:[[NSString alloc] initWithUTF8String: transItem.fromX.c_str()]];
        transition.y = [self parseAnimation:[[NSString alloc] initWithUTF8String: transItem.fromY.c_str()]];
        if ([transition.type isEqualToString:@"alpha"] || [transition.type isEqualToString:@"rotate"])
            transition.x = [self parseAnimation:[[NSString alloc] initWithUTF8String: transItem.from.c_str()]];
        [_enterTransitions addObject:transition];
    }
    for (auto i = 0; i < newViewProps.exitTrans.items.size(); i++) {
        NVNavigationStackExitTransItemsStruct transItem = newViewProps.exitTrans.items[i];
        NVTransition *transition = [[NVTransition alloc] initWithType:[[NSString alloc] initWithUTF8String: transItem.type.c_str()]];
        transition.duration = [[[NSString alloc] initWithUTF8String: transItem.duration.c_str()] intValue];
        transition.x = [self parseAnimation:[[NSString alloc] initWithUTF8String: transItem.toX.c_str()]];
        transition.y = [self parseAnimation:[[NSString alloc] initWithUTF8String: transItem.toY.c_str()]];
        if ([transition.type isEqualToString:@"alpha"] || [transition.type isEqualToString:@"rotate"])
            transition.x = [self parseAnimation:[[NSString alloc] initWithUTF8String: transItem.to.c_str()]];
        [_exitTransitions addObject:transition];
    }
    _mostRecentEventCount = newViewProps.mostRecentEventCount;
    if (!_navigated) {
        [self navigate];
        _navigated = YES;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self navigate];
        });
    }
    [super updateProps:props oldProps:oldProps];
}

- (NVTransitionValue)parseAnimation:(NSString *)val
{
    NVTransitionValue transitionValue;
    if ([val hasSuffix:@"%"]) {
        transitionValue.val = [[val substringToIndex:[val length] -1] floatValue];
        transitionValue.percent = YES;
    } else {
        transitionValue.val = [val floatValue];
        transitionValue.percent = NO;
    }
    return transitionValue;
}

- (void)navigate
{
    NSInteger eventLag = _nativeEventCount - _mostRecentEventCount;
    if (eventLag != 0 || _scenes.count == 0)
        return;
    NSInteger crumb = [self.keys count] - 1;
    NSInteger currentCrumb = [_navigationController.viewControllers count] - 1;
    if (crumb < currentCrumb) {
        [_navigationController popToViewController:_navigationController.viewControllers[crumb] animated:true];
    }
    BOOL animate = !self.enterAnimOff;
    if (crumb > currentCrumb) {
        NSMutableArray<NVSceneController*> *controllers = [[NSMutableArray alloc] init];
        NVSceneComponentView *scene;
        for(NSInteger i = 0; i < crumb - currentCrumb; i++) {
            NSInteger nextCrumb = currentCrumb + i + 1;
            scene = (NVSceneComponentView *) [_scenes objectForKey:[self.keys objectAtIndex:nextCrumb]];
            if (!![scene superview])
                return;
            NVSceneController *controller = [[NVSceneController alloc] initWithScene:scene];
            id __weak weakSelf = self;
            scene.peekableDidChangeBlock = ^{
                [weakSelf checkPeekability:[self.keys count] - 1];
            };
            controller.navigationItem.title = scene.title;
            [controllers addObject:controller];
        }
        [controllers lastObject].enterTrans = _enterTransitions;
        [controllers lastObject].popExitTrans = scene.exitTrans;
        ((NVSceneController *) _navigationController.topViewController).exitTrans = _exitTransitions;
        ((NVSceneController *) _navigationController.topViewController).popEnterTrans = scene.enterTrans;
        __block BOOL completed = NO;
        [self completeNavigation:^{
            if (completed) return;
            completed = YES;
            if (crumb - currentCrumb == 1) {
                [self->_navigationController pushViewController:controllers[0] animated:animate];
            } else {
                NSArray *allControllers = [self->_navigationController.viewControllers arrayByAddingObjectsFromArray:controllers];
                [self->_navigationController setViewControllers:allControllers animated:animate];
            }
        } waitOn:[controllers lastObject]];
        _navigationController.retainedViewController = _navigationController.topViewController;
    }
    if (crumb == currentCrumb) {
        NVSceneComponentView *scene = (NVSceneComponentView *) [_scenes objectForKey:[self.keys objectAtIndex:crumb]];
        if (!![scene superview])
            return;
        NVSceneController *controller = [[NVSceneController alloc] initWithScene:scene];
        NSMutableArray *controllers = [NSMutableArray arrayWithArray:_navigationController.viewControllers];
        [controllers replaceObjectAtIndex:crumb withObject:controller];
        __block BOOL completed = NO;
        [self completeNavigation:^{
            if (completed) return;
            completed = YES;
            [self->_navigationController setViewControllers:controllers animated:animate];
        } waitOn:controller];
        _navigationController.retainedViewController = _navigationController.topViewController;
    }
}

-(void) completeNavigation:(void (^)(void)) completeNavigation waitOn:(NVSceneController *)sceneController
{
    UIView<NVNavigationBar> *navigationBar = [sceneController findNavigationBar];
    if (!navigationBar.backImageLoading) {
        completeNavigation();
    } else {
        navigationBar.backImageDidLoadBlock = completeNavigation;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .1 * NSEC_PER_SEC), dispatch_get_main_queue(), completeNavigation);
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    UIView *parentView = (UIView *)self.superview;
    while (!self.navigationController.parentViewController && parentView) {
        if (parentView.reactViewController) {
            [parentView.reactViewController addChildViewController:self.navigationController];
        }
        parentView = parentView.superview;
    }
}
- (void)checkPeekability:(NSInteger)crumb
{
    NVSceneComponentView *scene;
    if (crumb > 1 && self.keys.count > crumb - 1) {
        scene = (NVSceneComponentView *) [_scenes objectForKey:[self.keys objectAtIndex:crumb - 1]];
    }
    _navigationController.interactivePopGestureRecognizer.enabled = scene ? scene.subviews.count > 0 : YES;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    _navigationController.view.frame = self.bounds;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    _presenting = [_navigationController presentedViewController];
    NSInteger crumb = [((NVSceneComponentView *) viewController.view).crumb intValue];
    if (crumb < [self.keys count] - 1) {
        std::static_pointer_cast<NVNavigationStackEventEmitter const>(_eventEmitter)
            ->onWillNavigateBack(NVNavigationStackEventEmitter::OnWillNavigateBack{
                .crumb = static_cast<int>(crumb)
            });
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (_presenting) {
        [navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        _navigationController.retainedViewController = navigationController.topViewController;
    }
    NSInteger crumb = [navigationController.viewControllers indexOfObject:viewController];
    [self checkPeekability:crumb];
    if (crumb < [self.keys count] - 1) {
        _nativeEventCount++;
    }
    NSInteger eventCount = crumb < [self.keys count] - 1 ? _nativeEventCount: 0;
    std::static_pointer_cast<NVNavigationStackEventEmitter const>(_eventEmitter)
        ->onRest(NVNavigationStackEventEmitter::OnRest{
            .crumb = static_cast<int>(crumb),
            .eventCount = static_cast<int>(eventCount)
        });

}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    NVSceneController *fromScene = ((NVSceneController *) fromVC);
    NVSceneController *toScene = ((NVSceneController *) toVC);
    if (operation == UINavigationControllerOperationPush && (fromScene.exitTrans.count > 0 || toScene.enterTrans.count > 0))
        return [[NVSceneTransitioning alloc] initWithDirection:YES];
    if (operation == UINavigationControllerOperationPop && (fromScene.popExitTrans.count > 0 || toScene.popEnterTrans.count > 0))
        return [[NVSceneTransitioning alloc] initWithDirection:NO];
    return nil;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (void)prepareForRecycle
{
    [super prepareForRecycle];
    _nativeEventCount = 0;
    _scenes = [[NSMutableDictionary alloc] init];
    _oldNavigationController = _navigationController;
    _navigationController = nil;
    _navigated = NO;
}

#pragma mark - RCTComponentViewProtocol

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<NVNavigationStackComponentDescriptor>();
}

- (void)mountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index
{
    _scenes[((NVSceneComponentView *) childComponentView).sceneKey] = childComponentView;
}

- (void)unmountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index
{
    [_scenes removeObjectForKey:((NVSceneComponentView *) childComponentView).sceneKey];
    [childComponentView removeFromSuperview];
}

@end

Class<RCTComponentViewProtocol> NVNavigationStackCls(void)
{
  return NVNavigationStackComponentView.class;
}
#endif
