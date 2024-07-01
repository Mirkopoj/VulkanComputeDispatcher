#pragma once

#include <vulkan/vulkan_core.h>

#include <memory>

#include "../lve/lve_descriptors.hpp"
#include "../lve/lve_device.hpp"

namespace lve {

class FirstApp {
  public:
   FirstApp();
   ~FirstApp();

   FirstApp(const FirstApp &) = delete;
   FirstApp &operator=(const FirstApp &) = delete;

   void run();

  private:
   LveDevice lveDevice;

   std::unique_ptr<LveDescriptorPool> computePool{};
};
}  // namespace lve
