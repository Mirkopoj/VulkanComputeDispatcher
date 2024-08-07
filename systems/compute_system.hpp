#pragma once

#include <vulkan/vulkan_core.h>

#include <string>

#include "../lve/lve_device.hpp"

namespace lve {

class ComputeSystem {
  public:
   ComputeSystem(LveDevice &device,
                 const std::vector<VkDescriptorSetLayout>,
                 const std::string &);
   ComputeSystem(ComputeSystem &&) = delete;
   ComputeSystem(const ComputeSystem &) = delete;
   ComputeSystem &operator=(ComputeSystem &&) = delete;
   ComputeSystem &operator=(const ComputeSystem &) = delete;
   ~ComputeSystem();

   void dispatch(int width, int height, int channels,
                 VkDescriptorSet &DescriptorSet,
                 VkCommandBuffer &CmdBuffer);
   void await(VkCommandBuffer &CmdBuffer);
   void instant_dispatch(int width, int height, int channels,
                         VkDescriptorSet &DescriptorSet);

  private:
   LveDevice &lveDevice;
   VkShaderModule module;
   VkPipeline computePipeline;
   VkPipelineLayout pipelineLayout;
   VkCommandBuffer CmdBuffer;
   VkSubmitInfo submitInfo;
   VkFence Fence;

   void createFence();
   void createPipelineLayout(const std::vector<VkDescriptorSetLayout>);
   void createPipeline();
   void createShaderModule(const std::string &);
   std::vector<char> readFile(const std::string &filepath);

   static VkPipeline bindedPipeline;
   static VkDescriptorSet bindedDescriptorSet;
};

}  // namespace lve
