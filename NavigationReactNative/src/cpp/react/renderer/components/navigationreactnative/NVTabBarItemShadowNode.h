#pragma once

#include "NVTabBarItemState.h"
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include "EventEmitters.h"
#include "Props.h"
#include <react/renderer/imagemanager/ImageManager.h>

namespace facebook {
namespace react {

JSI_EXPORT extern const char NVTabBarItemComponentName[];

class JSI_EXPORT NVTabBarItemShadowNode final: public ConcreteViewShadowNode<
  NVTabBarItemComponentName,
  NVTabBarItemProps,
  NVTabBarItemEventEmitter,
  NVTabBarItemState
> {

public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  void setImageManager(const SharedImageManager &imageManager);

  static NVTabBarItemState initialStateData(
                                           ShadowNodeFragment const &fragment,
                                           ShadowNodeFamilyFragment const &familyFragment,
                                           ComponentDescriptor const &componentDescriptor) {
    auto imageSource = ImageSource{ImageSource::Type::Invalid};
    return {
      imageSource,
      {imageSource, nullptr}};
  }

#pragma mark - LayoutableShadowNode

  Size measureContent(
                      LayoutContext const &layoutContext,
                      LayoutConstraints const &layoutConstraints) const override;
  void layout(LayoutContext layoutContext) override;

private:
  void updateStateIfNeeded();

  ImageSource getImageSource() const;

  SharedImageManager imageManager_;
};

} // namespace react
} // namespace facebook