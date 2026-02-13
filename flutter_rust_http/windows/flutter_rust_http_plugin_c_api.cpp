#include "include/image_ffi/image_ffi_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "image_ffi_plugin.h"

void FlutterRustHttpPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  image_ffi::FlutterRustHttpPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
