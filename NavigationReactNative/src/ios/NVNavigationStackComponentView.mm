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
#import <React/RCTConversions.h>
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
        NSString *key = [NSString  stringWithUTF8String: newViewProps.keys[i].c_str()];
        [keysArr addObject:key];
    }
    self.keys = [keysArr copy];
    _enterAnimOff = newViewProps.enterAnimOff;
    [_enterTransitions removeAllObjects];
    [_exitTransitions removeAllObjects];
    NSString *durationStr = [NSString  stringWithUTF8String: newViewProps.enterTrans.duration.c_str()];
    int duration = [durationStr length] ? [durationStr intValue] : 350;
    for (auto i = 0; i < newViewProps.enterTrans.items.size(); i++) {
        NVNavigationStackEnterTransItemsStruct transItem = newViewProps.enterTrans.items[i];
        NVTransition *transition = [[NVTransition alloc] initWithType:[NSString  stringWithUTF8String: transItem.type.c_str()]];
        NSString *defaultVal = @"0";
        if ([transition.type isEqualToString:@"scale"] || [transition.type isEqualToString:@"alpha"])
            defaultVal = @"1";
        durationStr = [NSString  stringWithUTF8String: transItem.duration.c_str()];
        transition.duration = [durationStr length] ? [durationStr intValue] : duration;
        transition.x = [self parseAnimation:[NSString  stringWithUTF8String: transItem.fromX.c_str()] defaultVal:defaultVal];
        transition.y = [self parseAnimation:[NSString  stringWithUTF8String: transItem.fromY.c_str()] defaultVal:defaultVal];
        if ([transition.type isEqualToString:@"alpha"] || [transition.type isEqualToString:@"rotate"])
            transition.x = [self parseAnimation:[NSString  stringWithUTF8String: transItem.from.c_str()] defaultVal:defaultVal];
        [_enterTransitions addObject:transition];
    }
    durationStr = [NSString  stringWithUTF8String: newViewProps.exitTrans.duration.c_str()];
    duration = [durationStr length] ? [durationStr intValue] : 350;
    for (auto i = 0; i < newViewProps.exitTrans.items.size(); i++) {
        NVNavigationStackExitTransItemsStruct transItem = newViewProps.exitTrans.items[i];
        NVTransition *transition = [[NVTransition alloc] initWithType:[NSString  stringWithUTF8String: transItem.type.c_str()]];
        NSString *defaultVal = @"0";
        if ([transition.type isEqualToString:@"scale"] || [transition.type isEqualToString:@"alpha"])
            defaultVal = @"1";
        durationStr = [NSString  stringWithUTF8String: transItem.duration.c_str()];
        transition.duration = [durationStr length] ? [durationStr intValue] : duration;
        transition.x = [self parseAnimation:[NSString  stringWithUTF8String: transItem.toX.c_str()] defaultVal:defaultVal];
        transition.y = [self parseAnimation:[NSString  stringWithUTF8String: transItem.toY.c_str()] defaultVal:defaultVal];
        if ([transition.type isEqualToString:@"alpha"] || [transition.type isEqualToString:@"rotate"])
            transition.x = [self parseAnimation:[NSString  stringWithUTF8String: transItem.to.c_str()] defaultVal:defaultVal];
        [_exitTransitions addObject:transition];
    }
    _navigationController.view.backgroundColor = RCTUIColorFromSharedColor(newViewProps.underlayColor);
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

- (NVTransitionValue)parseAnimation:(NSString *)val defaultVal:(NSString *)defaultVal
{
    NVTransitionValue transitionValue;
    val = [val length] ? val : defaultVal;
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
        NVSceneController *prevSceneController = nil;
        for(NSInteger i = 0; i < crumb - currentCrumb; i++) {
            NSInteger nextCrumb = currentCrumb + i + 1;
            NVSceneComponentView *scene = (NVSceneComponentView *) [_scenes objectForKey:[self.keys objectAtIndex:nextCrumb]];
            if (!![scene superview])
                return;
            NVSceneController *controller = [[NVSceneController alloc] initWithScene:scene];
            id __weak weakSelf = self;
            scene.peekableDidChangeBlock = ^{
                [weakSelf checkPeekability:[self.keys count] - 1];
            };
            controller.navigationItem.title = scene.title;
            controller.enterTrans = _enterTransitions;
            controller.popExitTrans = scene.exitTrans;
            if (!prevSceneController)
                prevSceneController = (NVSceneController *) _navigationController.topViewController;
            prevSceneController.exitTrans = _exitTransitions;
            prevSceneController.popEnterTrans = scene.enterTrans;
            [controllers addObject:controller];
            prevSceneController = controller;
        }
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
        controller.enterTrans = _enterTransitions;
        controller.popExitTrans = scene.exitTrans;
        if (_navigationController.viewControllers.count > 1) {
            NVSceneController *prevSceneController = (NVSceneController *) _navigationController.viewControllers[_navigationController.viewControllers.count - 2];
            prevSceneController.exitTrans = _exitTransitions;
            prevSceneController.popEnterTrans = scene.enterTrans;
        }
        NVSceneController *topSceneController = (NVSceneController *) _navigationController.topViewController;
        topSceneController.exitTrans = topSceneController.popExitTrans;
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == _navigationController.interactivePopGestureRecognizer && [[otherGestureRecognizer view] isKindOfClass:[UIScrollView class]]) {
        return ((UIScrollView *)otherGestureRecognizer.view).panGestureRecognizer == otherGestureRecognizer;
    }
    return NO;
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
