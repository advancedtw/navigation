#ifdef RCT_NEW_ARCH_ENABLED
#import "NVSharedElementComponentView.h"

#import <react/renderer/components/navigation-react-native/ComponentDescriptors.h>
#import <react/renderer/components/navigation-react-native/EventEmitters.h>
#import <react/renderer/components/navigation-react-native/Props.h>
#import <react/renderer/components/navigation-react-native/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@interface NVSharedElementComponentView () <RCTNVSharedElementViewProtocol>
@end

@implementation NVSharedElementComponentView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

#pragma mark - RCTComponentViewProtocol

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<NVSharedElementComponentDescriptor>();
}

@end

Class<RCTComponentViewProtocol> NVSharedElementCls(void)
{
  return NVSharedElementComponentView.class;
}

#endif