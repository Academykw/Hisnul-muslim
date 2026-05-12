# Flutter Local Notifications rules
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.reflect.TypeToken
-keep class com.google.gson.internal.LinkedTreeMap { *; }

# Preserve generic signatures to avoid TypeToken issues
-keepattributes *Annotation*, Signature, EnclosingMethod
