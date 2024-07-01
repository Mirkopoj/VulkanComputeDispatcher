#include "first_app.hpp"

#include <vulkan/vulkan_core.h>

#include <glm/fwd.hpp>
#include <glm/geometric.hpp>
#include <iomanip>
#include <iostream>
#include <memory>
#include <vector>

#include "../lve/lve_descriptors.hpp"
#include "../systems/compute_system.hpp"
#include "lve/lve_buffer.hpp"

// libs
#define GLM_FORCE_RADIANS
#define GLM_FORCE_DEPTH_ZERO_TO_ONE
#include <glm/glm.hpp>
#include <glm/gtc/constants.hpp>

// std
#include <imgui.h>

namespace lve {

FirstApp::FirstApp() {
   computePool = LveDescriptorPool::Builder(lveDevice)
                     .setMaxSets(2)
                     .addPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 2)
                     .build();
}

FirstApp::~FirstApp() {
}

void FirstApp::run() {
   std::unique_ptr<LveDescriptorSetLayout> computeDescriptorSetLayout =
       LveDescriptorSetLayout::Builder(lveDevice)
           .addBinding(0, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                       VK_SHADER_STAGE_COMPUTE_BIT)
           .addBinding(1, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                       VK_SHADER_STAGE_COMPUTE_BIT)
           .build();

   ComputeSystem example_computation{
       lveDevice,
       {computeDescriptorSetLayout->getDescriptorSetLayout()},
       "shaders/suma.comp.spv"};

   const int width = 10;
   const int heigth = 10;
   std::vector<int> cpuBuffer;
   std::cout << "Input\n";
   for (int j = 0; j < heigth; ++j) {
      for (int i = 0; i < width; ++i) {
         size_t index = i + j * width;
         cpuBuffer.push_back(index);
         std::cout << std::setw(3) << cpuBuffer[index] << " ";
      }
      std::cout << "\n";
   }

   VkDescriptorSet DescriptorSet = {};
   std::unique_ptr<LveBuffer> InBuff = std::make_unique<LveBuffer>(
       lveDevice, sizeof(int), cpuBuffer.size(),
       VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
       VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT);
   std::unique_ptr<LveBuffer> OutBuff = std::make_unique<LveBuffer>(
       lveDevice, sizeof(int), cpuBuffer.size(),
       VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
       VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT);
   VkDescriptorBufferInfo InBuffDesc = InBuff->descriptorInfo();
   VkDescriptorBufferInfo OutBuffDesc = OutBuff->descriptorInfo();
   LveDescriptorWriter(*computeDescriptorSetLayout, *computePool)
       .writeBuffer(0, &InBuffDesc)
       .writeBuffer(1, &OutBuffDesc)
       .build(DescriptorSet);

   InBuff->map();
   InBuff->writeToBuffer(cpuBuffer.data());
   InBuff->unmap();

   example_computation.instant_dispatch(width, heigth, 1, DescriptorSet);

   OutBuff->map();
   OutBuff->readFromBuffer(cpuBuffer.data());
   OutBuff->unmap();

   std::cout << "Output\n";
   for (int j = 0; j < heigth; ++j) {
      for (int i = 0; i < width; ++i) {
         size_t index = i + j * width;
         std::cout << cpuBuffer[index] << " ";
      }
      std::cout << "\n";
   }

   vkDeviceWaitIdle(lveDevice.device());
}

}  // namespace lve
