# Preservar recursos raw para notificaciones
-keep class **.R$raw { *; }
-keepclassmembers class **.R$raw { *; }

# Preservar recursos para flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Mantener recursos raw (para archivos de sonido)
-keep class **.R

# Excluir completamente las clases relacionadas con publicidad
-assumenosideeffects class com.google.android.gms.ads.** { *; }
-assumenosideeffects class com.google.android.gms.ads.identifier.** { *; }

# No ofuscar pero eliminar references a ads en tiempo de compilación
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.firebase.ads.**

# Eliminar llamadas a advertising ID
-assumenosideeffects class com.google.android.gms.ads.identifier.AdvertisingIdClient {
    public static com.google.android.gms.ads.identifier.AdvertisingIdClient$Info getAdvertisingIdInfo(...);
}
-keep class **.R$* {
    <fields>;
}

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Mantener clases de método channel
-keep class com.truelove.truelovesocio.** { *; }

# Google Play Core (para solucionar errores R8)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Mantener enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }

# Para resolver errores de clases faltantes
-dontwarn javax.annotation.**
-dontwarn org.slf4j.**