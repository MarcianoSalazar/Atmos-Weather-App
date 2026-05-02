//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<connectivity_plus/ConnectivityPlusPlugin.h>)
#import <connectivity_plus/ConnectivityPlusPlugin.h>
#else
@import connectivity_plus;
#endif

#if __has_include(<flutter_local_notifications/FlutterLocalNotificationsPlugin.h>)
#import <flutter_local_notifications/FlutterLocalNotificationsPlugin.h>
#else
@import flutter_local_notifications;
#endif

#if __has_include(<geocoding_ios/GeocodingPlugin.h>)
#import <geocoding_ios/GeocodingPlugin.h>
#else
@import geocoding_ios;
#endif

#if __has_include(<geolocator_apple/GeolocatorPlugin.h>)
#import <geolocator_apple/GeolocatorPlugin.h>
#else
@import geolocator_apple;
#endif

#if __has_include(<objectbox_flutter_libs/ObjectboxFlutterLibsPlugin.h>)
#import <objectbox_flutter_libs/ObjectboxFlutterLibsPlugin.h>
#else
@import objectbox_flutter_libs;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<sqflite_darwin/SqflitePlugin.h>)
#import <sqflite_darwin/SqflitePlugin.h>
#else
@import sqflite_darwin;
#endif

#if __has_include(<url_launcher_ios/URLLauncherPlugin.h>)
#import <url_launcher_ios/URLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [ConnectivityPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"ConnectivityPlusPlugin"]];
  [FlutterLocalNotificationsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterLocalNotificationsPlugin"]];
  [GeocodingPlugin registerWithRegistrar:[registry registrarForPlugin:@"GeocodingPlugin"]];
  [GeolocatorPlugin registerWithRegistrar:[registry registrarForPlugin:@"GeolocatorPlugin"]];
  [ObjectboxFlutterLibsPlugin registerWithRegistrar:[registry registrarForPlugin:@"ObjectboxFlutterLibsPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
  [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]];
}

@end
