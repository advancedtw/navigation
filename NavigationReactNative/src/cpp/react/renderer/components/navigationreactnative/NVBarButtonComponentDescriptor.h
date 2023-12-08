#pragma once

#include "NVBarButtonShadowNode.h"
#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook {
namespace react {

class NVBarButtonComponentDescriptor final
    : public ConcreteComponentDescriptor<NVBarButtonShadowNode> {
 public:
    NVBarButtonComponentDescriptor(ComponentDescriptorParameters const &parameters)
      : ConcreteComponentDescriptor(parameters),
        imageManager_(std::make_shared<ImageManager>(contextContainer_)){}

  void adopt(ShadowNode& shadowNode) const override {
    ConcreteComponentDescriptor::adopt(shadowNode);

    auto &barButtonShadowNode =
        static_cast<NVBarButtonShadowNode&>(shadowNode);

    barButtonShadowNode.setImageManager(imageManager_);
  }

 private:
  const SharedImageManager imageManager_;
};

} // namespace react
} // namespace facebook