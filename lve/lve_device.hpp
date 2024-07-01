#pragma once

#include <vulkan/vulkan_core.h>

// std lib headers
#include <vector>

namespace lve {

struct QueueFamilyIndices {
   uint32_t computeFamily;
   bool computeFamilyHasValue = false;
   bool isComplete() {
      return computeFamilyHasValue;
   }
};

class LveDevice {
  public:
#ifdef NDEBUG
   const bool enableValidationLayers = false;
#else
   const bool enableValidationLayers = true;
#endif

   LveDevice();
   ~LveDevice();

   // Not copyable or movable
   LveDevice(const LveDevice &) = delete;
   LveDevice &operator=(const LveDevice &) = delete;
   LveDevice(LveDevice &&) = delete;
   LveDevice &operator=(LveDevice &&) = delete;

   VkCommandPool getCommandPool() {
      return commandPool;
   }
   VkDevice device() {
      return device_;
   }
   VkQueue computeQueue() {
      return computeQueue_;
   }

   VkPhysicalDevice physical_device() {
      return physicalDevice;
   }
   VkInstance get_instance() {
      return instance;
   }

   uint32_t findMemoryType(uint32_t typeFilter,
                           VkMemoryPropertyFlags properties);
   QueueFamilyIndices findPhysicalQueueFamilies() {
      return findQueueFamilies(physicalDevice);
   }

   // Buffer Helper Functions
   void createBuffer(VkDeviceSize size, VkBufferUsageFlags usage,
                     VkMemoryPropertyFlags properties, VkBuffer &buffer,
                     VkDeviceMemory &bufferMemory);
   void copyBuffer(VkBuffer srcBuffer, VkBuffer dstBuffer,
                   VkDeviceSize size);
   void copyBufferToImage(VkBuffer buffer, VkImage image, uint32_t width,
                          uint32_t height, uint32_t layerCount);

   VkPhysicalDeviceProperties properties;
   VkCommandBuffer beginSingleTimeCommands();
   void endSingleTimeCommands(VkCommandBuffer commandBuffer);

  private:
   void createInstance();
   void setupDebugMessenger();
   void pickPhysicalDevice();
   void createLogicalDevice();
   void createCommandPool();

   // helper functions
   bool isDeviceSuitable(VkPhysicalDevice device);
   std::vector<const char *> getRequiredExtensions();
   bool checkValidationLayerSupport();
   QueueFamilyIndices findQueueFamilies(VkPhysicalDevice device);
   void populateDebugMessengerCreateInfo(
       VkDebugUtilsMessengerCreateInfoEXT &createInfo);
   bool checkDeviceExtensionSupport(VkPhysicalDevice device);

   VkInstance instance;
   VkDebugUtilsMessengerEXT debugMessenger;
   VkPhysicalDevice physicalDevice = VK_NULL_HANDLE;
   VkCommandPool commandPool;

   VkDevice device_;
   VkQueue computeQueue_;

   const std::vector<const char *> validationLayers = {
       "VK_LAYER_KHRONOS_validation"};
   const std::vector<const char *> deviceExtensions = {};
};

}  // namespace lve
