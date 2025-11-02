# Side Runner - Export Presets Backup

This document contains a backup of the export presets configuration for the Side Runner Godot project, in case the `export_presets.cfg` file gets reset or corrupted.

## Export Environment Setup

### Required Environment Variables
```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export ANDROID_HOME=/Users/gerthuybrechts/android-sdk
```

### Successful Export Command
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --export-debug "Android" /tmp/side-runner-gradle.apk
```

## Android Export Preset Configuration

### Basic Settings
- **Name**: "Android"
- **Platform**: "Android"
- **Runnable**: true
- **Export Filter**: "all_resources"
- **Script Export Mode**: 2 (compiled)

### Gradle Build Settings
- **Use Gradle Build**: true (CRITICAL - this must be enabled)
- **Export Format**: 0 (APK)
- **Min SDK**: "24"
- **Target SDK**: "34"
- **Compress Native Libraries**: false

### Architecture Settings
- **armeabi-v7a**: false
- **arm64-v8a**: true (ENABLED - modern 64-bit ARM)
- **x86**: false
- **x86_64**: false

### Package Settings
- **Unique Name**: "com.example.$genname"
- **Signed**: true
- **App Category**: 2
- **Retain Data on Uninstall**: false
- **Exclude from Recents**: false
- **Show in Android TV**: false
- **Show in App Library**: true
- **Show as Launcher App**: false

### Screen Settings
- **Immersive Mode**: true (hides system UI for full-screen gaming)
- **Edge to Edge**: false
- **Support Small/Normal/Large/XLarge**: all true
- **Background Color**: Color(0, 0, 0, 1) (black)

### XR and Graphics
- **XR Mode**: 0 (disabled)
- **OpenGL Debug**: false
- **Shader Baker Enabled**: false

### Permissions
All permissions are set to **false** by default. The game currently requires no special Android permissions.

Key disabled permissions include:
- Internet: false
- Camera: false
- Microphone (Record Audio): false
- Location services: false
- Storage access: false
- Phone/SMS: false

## Complete export_presets.cfg Content

```ini
[preset.0]

name="Android"
platform="Android"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path=""
patches=PackedStringArray()
encryption_include_filters=""
encryption_exclude_filters=""
seed=0
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

custom_template/debug=""
custom_template/release=""
gradle_build/use_gradle_build=true
gradle_build/gradle_build_directory=""
gradle_build/android_source_template=""
gradle_build/compress_native_libraries=false
gradle_build/export_format=0
gradle_build/min_sdk="24"
gradle_build/target_sdk="34"
gradle_build/custom_theme_attributes={}
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
version/code=1
version/name=""
package/unique_name="com.example.$genname"
package/name=""
package/signed=true
package/app_category=2
package/retain_data_on_uninstall=false
package/exclude_from_recents=false
package/show_in_android_tv=false
package/show_in_app_library=true
package/show_as_launcher_app=false
launcher_icons/main_192x192=""
launcher_icons/adaptive_foreground_432x432=""
launcher_icons/adaptive_background_432x432=""
launcher_icons/adaptive_monochrome_432x432=""
graphics/opengl_debug=false
shader_baker/enabled=false
xr_features/xr_mode=0
gesture/swipe_to_dismiss=false
screen/immersive_mode=true
screen/edge_to_edge=false
screen/support_small=true
screen/support_normal=true
screen/support_large=true
screen/support_xlarge=true
screen/background_color=Color(0, 0, 0, 1)
user_data_backup/allow=false
command_line/extra_args=""
apk_expansion/enable=false
apk_expansion/SALT=""
apk_expansion/public_key=""
permissions/custom_permissions=PackedStringArray()
permissions/access_checkin_properties=false
permissions/access_coarse_location=false
permissions/access_fine_location=false
permissions/access_location_extra_commands=false
permissions/access_media_location=false
permissions/access_mock_location=false
permissions/access_network_state=false
permissions/access_surface_flinger=false
permissions/access_wifi_state=false
permissions/account_manager=false
permissions/add_voicemail=false
permissions/authenticate_accounts=false
permissions/battery_stats=false
permissions/bind_accessibility_service=false
permissions/bind_appwidget=false
permissions/bind_device_admin=false
permissions/bind_input_method=false
permissions/bind_nfc_service=false
permissions/bind_notification_listener_service=false
permissions/bind_print_service=false
permissions/bind_remoteviews=false
permissions/bind_text_service=false
permissions/bind_vpn_service=false
permissions/bind_wallpaper=false
permissions/bluetooth=false
permissions/bluetooth_admin=false
permissions/bluetooth_privileged=false
permissions/brick=false
permissions/broadcast_package_removed=false
permissions/broadcast_sms=false
permissions/broadcast_sticky=false
permissions/broadcast_wap_push=false
permissions/call_phone=false
permissions/call_privileged=false
permissions/camera=false
permissions/capture_audio_output=false
permissions/capture_secure_video_output=false
permissions/capture_video_output=false
permissions/change_component_enabled_state=false
permissions/change_configuration=false
permissions/change_network_state=false
permissions/change_wifi_multicast_state=false
permissions/change_wifi_state=false
permissions/clear_app_cache=false
permissions/clear_app_user_data=false
permissions/control_location_updates=false
permissions/delete_cache_files=false
permissions/delete_packages=false
permissions/device_power=false
permissions/diagnostic=false
permissions/disable_keyguard=false
permissions/dump=false
permissions/expand_status_bar=false
permissions/factory_test=false
permissions/flashlight=false
permissions/force_back=false
permissions/get_accounts=false
permissions/get_package_size=false
permissions/get_tasks=false
permissions/get_top_activity_info=false
permissions/global_search=false
permissions/hardware_test=false
permissions/inject_events=false
permissions/install_location_provider=false
permissions/install_packages=false
permissions/install_shortcut=false
permissions/internal_system_window=false
permissions/internet=false
permissions/kill_background_processes=false
permissions/location_hardware=false
permissions/manage_accounts=false
permissions/manage_app_tokens=false
permissions/manage_documents=false
permissions/manage_external_storage=false
permissions/master_clear=false
permissions/media_content_control=false
permissions/modify_audio_settings=false
permissions/modify_phone_state=false
permissions/mount_format_filesystems=false
permissions/mount_unmount_filesystems=false
permissions/nfc=false
permissions/persistent_activity=false
permissions/post_notifications=false
permissions/process_outgoing_calls=false
permissions/read_calendar=false
permissions/read_call_log=false
permissions/read_contacts=false
permissions/read_external_storage=false
permissions/read_frame_buffer=false
permissions/read_history_bookmarks=false
permissions/read_input_state=false
permissions/read_logs=false
permissions/read_media_audio=false
permissions/read_media_images=false
permissions/read_media_video=false
permissions/read_media_visual_user_selected=false
permissions/read_phone_state=false
permissions/read_profile=false
permissions/read_sms=false
permissions/read_social_stream=false
permissions/read_sync_settings=false
permissions/read_sync_stats=false
permissions/read_user_dictionary=false
permissions/reboot=false
permissions/receive_boot_completed=false
permissions/receive_mms=false
permissions/receive_sms=false
permissions/receive_wap_push=false
permissions/record_audio=false
permissions/reorder_tasks=false
permissions/restart_packages=false
permissions/send_respond_via_message=false
permissions/send_sms=false
permissions/set_activity_watcher=false
permissions/set_alarm=false
permissions/set_always_finish=false
permissions/set_animation_scale=false
permissions/set_debug_app=false
permissions/set_orientation=false
permissions/set_pointer_speed=false
permissions/set_preferred_applications=false
permissions/set_process_limit=false
permissions/set_time=false
permissions/set_time_zone=false
permissions/set_wallpaper=false
permissions/set_wallpaper_hints=false
permissions/signal_persistent_processes=false
permissions/status_bar=false
permissions/subscribed_feeds_read=false
permissions/subscribed_feeds_write=false
permissions/system_alert_window=false
permissions/transmit_ir=false
permissions/uninstall_shortcut=false
permissions/update_device_stats=false
permissions/use_credentials=false
permissions/use_sip=false
permissions/vibrate=false
permissions/wake_lock=false
permissions/write_apn_settings=false
permissions/write_calendar=false
permissions/write_call_log=false
permissions/write_contacts=false
permissions/write_external_storage=false
permissions/write_gservices=false
permissions/write_history_bookmarks=false
permissions/write_profile=false
permissions/write_secure_settings=false
permissions/write_settings=false
permissions/write_sms=false
permissions/write_social_stream=false
permissions/write_sync_settings=false
permissions/write_user_dictionary=false
```

## Troubleshooting Notes

### Common Issues and Solutions

1. **Export Fails with SDK Errors**
   - Ensure ANDROID_HOME points to the correct SDK directory
   - Verify OpenJDK 17 is installed and JAVA_HOME is set correctly
   - Check that Android SDK Build Tools are installed

2. **Gradle Build Fails**
   - Make sure `gradle_build/use_gradle_build=true` is set
   - Verify Android SDK and NDK are properly installed
   - Check that target_sdk (34) is installed in Android SDK Manager

3. **APK Won't Install on Device**
   - Ensure `package/signed=true` is set
   - Check that device supports arm64-v8a architecture
   - Verify minimum SDK version (24) is supported by target device

### Key Settings for Side Runner Game

- **Immersive Mode**: Enabled for full-screen gaming experience
- **ARM64 Only**: Targets modern Android devices (64-bit ARM)
- **No Permissions**: Game doesn't require any special Android permissions
- **Gradle Build**: Essential for modern Android deployment

## Restoration Instructions

If `export_presets.cfg` gets reset:

1. Copy the complete configuration from the "Complete export_presets.cfg Content" section above
2. Save it as `export_presets.cfg` in the project root
3. Verify environment variables are set correctly
4. Test export with the provided command

---
*Last updated: November 2, 2025*
*Working export confirmed with APK size: ~80MB*