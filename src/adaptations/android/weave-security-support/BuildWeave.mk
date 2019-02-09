
#
# Input Configuration
#

ANDROID_HOME                    ?= /opt/android-sdk-linux/
ANDROID_NDK_HOME                ?= $(ANDROID_HOME)/ndk-bundle
ANDROID_API                     ?= 19
ANDROID_ABI                     ?= armeabi-v7a
ANDROID_STL                     ?= system

WEAVE_PROJECT_ROOT              ?= .
WEAVE_SOURCE_ROOT               ?= /home/jay/projects/weave
WEAVE_BUILD_DIR                 ?= /tmp/weave-build/$(ANDROID_ABI)
WEAVE_RESULTS_DIR               ?= /tmp/weave-output/$(ANDROID_ABI)
ENABLE_WEAVE_DEBUG              ?= 1
ENABLE_WEAVE_LOGGING            ?= 1


#
# Output Configuration
#

WEAVE_SHARED_LIB				= libWeaveSecuritySupport.so
WEAVE_SHARED_LIB_BUILD_DIR		= $(WEAVE_BUILD_DIR)/src/wrappers/jni/security-support/.libs


#
# Tools and Executables
#

android-ndk-which               = $(shell $(WEAVE_SOURCE_ROOT)/build/scripts/android-ndk-which --ndk-home $(ANDROID_NDK_HOME) $(1) $(ANDROID_ABI))

AR                              = $(call android-ndk-which,ar)
AS                              = $(call android-ndk-which,as)
CPP                             = $(call android-ndk-which,cpp)
CC                              = $(call android-ndk-which,gcc)
CXX                             = $(call android-ndk-which,g++)
LD                              = $(call android-ndk-which,ld)
STRIP                           = $(call android-ndk-which,strip)
NM                              = $(call android-ndk-which,nm)
RANLIB                          = $(call android-ndk-which,ranlib)
OBJCOPY                         = $(call android-ndk-which,objcopy)
ECHO                            = @echo
MAKE                            = make
MKDIR_P                         = mkdir -p
LN_S                            = ln -s
RM_F                            = rm -f
INSTALL                         = /usr/bin/install


#
# Common C/C++ Defines
#

DEFINES                        += -D__ANDROID_API__=$(ANDROID_API) \
                                  -DWEAVE_CONFIG_ENABLE_TARGETED_LISTEN=$(ENABLE_TARGETED_LISTEN) \
                                  -DWEAVE_PROGRESS_LOGGING=$(ENABLE_WEAVE_DEBUG) \
                                  -DWEAVE_ERROR_LOGGING=$(ENABLE_WEAVE_DEBUG) \
                                  -DWEAVE_DETAIL_LOGGING=$(ENABLE_WEAVE_DEBUG)

ifeq ($(ENABLE_WEAVE_DEBUG),1)
DEFINES                         = -DDEBUG=$(ENABLE_WEAVE_DEBUG) -UNDEBUG
else
DEFINES                         = -DNDEBUG=1 -UDEBUG
endif


#
# Common C/C++ Includes
#

INCLUDES                       += -isystem $(ANDROID_NDK_HOME)/sysroot/usr/include \
                                  $(ANDROID_STL_INCLUDES)

# NB: Regardless of where JAVA_HOME points, always use the JNI headers from the Android NDK,
# and only include the top-most directory (include), not the system directory (include/linux). 
# Because the NDK mixes the JNI headers in with the linux headers, listing the system
# directory in the -I flags will result in strange compilation errors.  And unlike the standard
# Java jni.h, the jni.h that comes with the Android NDK does not depend on any system-specific
# JNI header files (e.g. jni_md.h).  Thus only the top-level include directory is needed.
JNI_INCLUDE_DIRS                = $(ABI_SYSROOT)/usr/include


#
# Compilation/Build Flags
#
 
CPPFLAGS                        = --sysroot=$(ABI_SYSROOT) $(DEFINES) $(INCLUDES) $(ABI_CPPFLAGS)
CFLAGS                          = $(CPPFLAGS) -ffunction-sections -funwind-tables $(ABI_CFLAGS)
CXXFLAGS                        = $(CPPFLAGS) -fno-rtti $(ABI_CXXFLAGS)
LDFLAGS                         = --sysroot=$(ABI_SYSROOT) -Wl,--gc-sections $(ABI_LDFLAGS)
INSTALLFLAGS                    = -p

ifndef BuildJobs
BuildJobs := $(shell getconf _NPROCESSORS_ONLN)
endif
JOBSFLAG := -j$(BuildJobs)


#
# Common Weave configure options
#

CONFIGURE_OPTIONS               = --enable-java \
                                  --enable-shared \
                                  --disable-cocoa \
                                  --disable-docs \
                                  --disable-python \
                                  --disable-tests \
                                  --disable-tools

ifeq ($(ENABLE_WEAVE_DEBUG),1)
CONFIGURE_OPTIONS              += --enable-debug --enable-optimization=no
else
CONFIGURE_OPTIONS              += 
endif


#
# Android ABI-specific Configurations
#

ABI_CONFIG_TUPLE_armeabi        = arm-unknown-linux-android
ABI_SYSROOT_armeabi             = $(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-arm
ABI_CPPFLAGS_armeabi            = -march=armv5te -mtune=xscale -msoft-float -isystem $(ANDROID_NDK_HOME)/sysroot/usr/include/arm-linux-androideabi
ABI_CFLAGS_armeabi              = -fstack-protector
ABI_CXXFLAGS_armeabi            = -I$(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-arm/usr/include
ABI_LDFLAGS_armeabi             = -march=armv5te -mtune=xscale -msoft-float

ABI_CONFIG_TUPLE_armeabi-v7a    = armv7-unknown-linux-android
ABI_SYSROOT_armeabi-v7a         = $(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-arm
ABI_CPPFLAGS_armeabi-v7a        = -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -isystem $(ANDROID_NDK_HOME)/sysroot/usr/include/arm-linux-androideabi
ABI_CFLAGS_armeabi-v7a          = -fstack-protector
ABI_CXXFLAGS_armeabi-v7a        = -I$(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-arm/usr/include
ABI_LDFLAGS_armeabi-v7a         = -march=armv7-a -Wl,--fix-cortex-a8

ABI_CONFIG_TUPLE_arm64-v8a      = arm64-unknown-linux-android
ABI_SYSROOT_arm64-v8a           = $(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-arm64
ABI_CPPFLAGS_arm64-v8a          = -march=armv8-a -isystem $(ANDROID_NDK_HOME)/sysroot/usr/include/aarch64-linux-android
ABI_CFLAGS_arm64-v8a            = -fstack-protector
ABI_CXXFLAGS_arm64-v8a          = -I$(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-arm/usr/include
ABI_LDFLAGS_arm64-v8a           = -march=armv8-a

ABI_CONFIG_TUPLE_x86            = x86-unknown-linux-android
ABI_SYSROOT_x86                 = $(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-x86
ABI_CPPFLAGS_x86                = -march=i686 -mtune=intel -mssse3 -mfpmath=sse -m32 -isystem $(ANDROID_NDK_HOME)/sysroot/usr/include/i686-linux-android
ABI_CFLAGS_x86                  =
ABI_CXXFLAGS_x86                = -I$(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-x86/usr/include
ABI_LDFLAGS_x86                 = -march=i686 -mtune=intel -mssse3 -mfpmath=sse -m32

ABI_CONFIG_TUPLE_x86_64         = x86_64-unknown-linux-android
ABI_SYSROOT_x86_64              = $(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-x86_64
ABI_CPPFLAGS_x86_64             = -march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel -isystem $(ANDROID_NDK_HOME)/sysroot/usr/include/x86_64-linux-android
ABI_CFLAGS_x86_64               =
ABI_CXXFLAGS_x86_64             = -I$(ANDROID_NDK_HOME)/platforms/android-$(ANDROID_API)/arch-x86/usr/include
ABI_LDFLAGS_x86_64              = -march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel

ABI_CONFIG_TUPLE                = $(ABI_CONFIG_TUPLE_$(ANDROID_ABI))
ABI_SYSROOT                     = $(ABI_SYSROOT_$(ANDROID_ABI))
ABI_CPPFLAGS                    = $(ABI_CPPFLAGS_$(ANDROID_ABI))
ABI_CFLAGS                      = $(ABI_CFLAGS_$(ANDROID_ABI))
ABI_CXXFLAGS                    = $(ABI_CXXFLAGS_$(ANDROID_ABI))
ABI_LDFLAGS                     = $(ABI_LDFLAGS_$(ANDROID_ABI))


#
# Android C++ Runtime (STL) Selection
#

ANDROID_STLROOT                 = $(ANDROID_NDK_HOME)/sources/cxx-stl

ANDROID_STL_INCLUDE_DIRS_libc++ = $(ANDROID_STLROOT)/llvm-libc++/include \
                                  $(ANDROID_STLROOT)/llvm-libc++abi/include \
                                  $(ANDROID_NDK_HOME)/sources/android/support/include
ANDROID_STL_INCLUDE_DIRS_gnustl = $(ANDROID_STLROOT)/gnu-libstdc++/4.9/include
ANDROID_STL_INCLUDE_DIRS_system = $(ANDROID_STLROOT)/system/include

ANDROID_STL_INCLUDES            = $(foreach dir,$(ANDROID_STL_INCLUDE_DIRS_$(ANDROID_STL)),-isystem $(dir))


#
# Rules
#

.DEFAULT_GOAL := all

.PHONY : all summarize build configure install

all: summarize install

summarize:
	@echo "JAVA_HOME is '$(JAVA_HOME)' (source: $(origin JAVA_HOME))"
	@echo "ANDROID_HOME is '$(ANDROID_HOME)' (source: $(origin ANDROID_HOME))"
	@echo "ANDROID_NDK_HOME is '$(ANDROID_NDK_HOME)' (source: $(origin ANDROID_NDK_HOME))"
	@echo "ANDROID_API is $(ANDROID_API) (source: $(origin ANDROID_API))"
	@echo "ANDROID_ABI is '$(ANDROID_ABI)' (source: $(origin ANDROID_ABI))"
	@echo "ANDROID_STL is '$(ANDROID_STL)' (source: $(origin ANDROID_STL))"
	@echo "WEAVE_SOURCE_ROOT is '$(WEAVE_SOURCE_ROOT)' (source: $(origin WEAVE_SOURCE_ROOT))"
	@echo "WEAVE_BUILD_DIR is '$(WEAVE_BUILD_DIR)' (source: $(origin WEAVE_BUILD_DIR))"
	@echo "WEAVE_RESULTS_DIR is '$(WEAVE_RESULTS_DIR)' (source: $(origin WEAVE_RESULTS_DIR))"
	@echo "ENABLE_WEAVE_DEBUG is '$(ENABLE_WEAVE_DEBUG)' (source: $(origin ENABLE_WEAVE_DEBUG))"
	@echo "ENABLE_WEAVE_LOGGING is '$(ENABLE_WEAVE_LOGGING)' (source: $(origin ENABLE_WEAVE_LOGGING))"

install: $(WEAVE_RESULTS_DIR)/$(WEAVE_SHARED_LIB)

$(WEAVE_RESULTS_DIR)/$(WEAVE_SHARED_LIB): $(WEAVE_SHARED_LIB_BUILD_DIR)/$(WEAVE_SHARED_LIB) | $(WEAVE_RESULTS_DIR)
	$(ECHO) "  INSTALL"
	$(INSTALL) $^ $@

$(WEAVE_BUILD_DIR)/src/wrappers/jni/security-support/.libs/libWeaveSecuritySupport.so: build

build: configure
	$(ECHO) "  BUILD"
	$(MAKE) $(JOBSFLAG) -C $(WEAVE_BUILD_DIR) --no-print-directory all

configure: $(WEAVE_BUILD_DIR)/config.status

$(WEAVE_BUILD_DIR)/config.status: | $(WEAVE_BUILD_DIR)
	$(ECHO) "  CONFIG"
	(cd $(WEAVE_BUILD_DIR) && $(WEAVE_SOURCE_ROOT)/configure \
	CPP="$(CPP)" CC="$(CC)" CXX="$(CXX)" OBJC="$(OBJC)" OBJCXX="$(OBJCXX)" AR="$(AR)" RANLIB="$(RANLIB)" NM="$(NM)" STRIP="$(STRIP)" \
	INSTALL="$(INSTALL) $(INSTALLFLAGS)" \
	CPPFLAGS="$(CPPFLAGS)" \
	CFLAGS="$(CFLAGS)" \
	CXXFLAGS="$(CXXFLAGS)" \
	OBJCFLAGS="$(OBJCFLAGS)" \
	OBJCXXFLAGS="$(OBJCXXFLAGS)" \
	LDFLAGS="$(LDFLAGS)" \
	JAVA_HOME="$(JAVA_HOME)" \
	JNI_INCLUDE_DIRS="$(JNI_INCLUDE_DIRS)" \
	--build=$(shell $(WEAVE_SOURCE_ROOT)/third_party/nlbuild-autotools/repo/autoconf/config.guess) \
	--host=$(ABI_CONFIG_TUPLE) \
	--with-sysroot=$(ABI_SYSROOT) \
	--with-libtool-sysroot=$(ABI_SYSROOT) \
	--with-weave-project-includes=$(WEAVE_SOURCE_ROOT)/build/config/android \
	--prefix=/ \
	$(CONFIGURE_OPTIONS))
	
# TODO: change location of project includes

$(WEAVE_BUILD_DIR) $(WEAVE_RESULTS_DIR):
	$(ECHO) "  MKDIR    $@"
	@$(MKDIR_P) "$@"
