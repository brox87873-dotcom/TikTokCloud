TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := CloudMod

CloudMod_FILES := CloudMod/Tweak.xm
CloudMod_CFLAGS := -fobjc-arc
CloudMod_FRAMEWORKS := UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk