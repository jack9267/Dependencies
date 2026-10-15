# Dependencies: the vendored third-party libraries, built as static libraries for every target but
# Windows - the ones premake5.lua names for this one (make help). See jbuild/make/premake.mk.
JBUILD ?= jbuild
include $(JBUILD)/make/premake.mk
