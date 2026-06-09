extends Node

enum Platform { ANDROID, WEB, WINDOWS, LINUX, MACOS, IOS, UNKNOWN }

var platform: Platform
var is_mobile: bool
var is_desktop: bool
var is_web: bool
var is_android: bool
var has_touchscreen: bool

func _ready() -> void:
	var os_name = OS.get_name()
	match os_name:
		"Android":
			platform = Platform.ANDROID
		"Web":
			platform = Platform.WEB
		"Windows":
			platform = Platform.WINDOWS
		"Linux":
			platform = Platform.LINUX
		"macOS":
			platform = Platform.MACOS
		"iOS":
			platform = Platform.IOS
		_:
			platform = Platform.UNKNOWN

	is_android = platform == Platform.ANDROID
	is_web = platform == Platform.WEB
	is_mobile = is_android or platform == Platform.IOS
	is_desktop = platform == Platform.WINDOWS or platform == Platform.LINUX or platform == Platform.MACOS
	has_touchscreen = is_mobile or is_web
