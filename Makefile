TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = YouTube

ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iHateYTAds

iHateYTAds_FILES = Tweak.m
iHateYTAds_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
