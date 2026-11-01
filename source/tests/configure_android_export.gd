extends SceneTree

func _initialize() -> void:
    call_deferred("configure")

func configure() -> void:
    var sdk := OS.get_environment("ANDROID_SDK_ROOT")
    var java := OS.get_environment("JAVA_HOME_17_X64")
    if sdk.is_empty() or java.is_empty():
        push_error("ANDROID_SDK_ROOT and JAVA_HOME_17_X64 are required")
        quit(1)
        return
    var settings := EditorInterface.get_editor_settings()
    settings.set_setting("export/android/android_sdk_path", sdk)
    settings.set_setting("export/android/java_sdk_path", java)
    if settings.has_method("save"):
        settings.call("save")
    print("NATIVE_ANDROID_EDITOR_CONFIG_OK ", sdk)
    quit(0)
