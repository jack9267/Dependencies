cmake_minimum_required(VERSION 3.12)

#set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/modules")
#set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

project(Dependencies C CXX)

# We only want Debug and Release
set(CMAKE_CONFIGURATION_TYPES "Debug;Release" CACHE STRING "Configuration types" FORCE)
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO}")

# C++11 minimum
if(NOT MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
	set(CMAKE_THREAD_PREFER_PTHREAD true)
	set(CMAKE_CXX_VISIBILITY_PRESET hidden)

	# Compiler-specific C++11 activation.
	if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
		execute_process(COMMAND ${CMAKE_CXX_COMPILER} -dumpversion OUTPUT_VARIABLE GCC_VERSION)
		if(NOT (GCC_VERSION VERSION_GREATER 4.7 OR GCC_VERSION VERSION_EQUAL 4.7))
			message(FATAL_ERROR "${PROJECT_NAME} requires g++ 4.7 or greater.")
		endif()
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
	else()
		message(FATAL_ERROR "Your C++ compiler does not support C++11.")
	endif()
endif()

# determine bits
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(ENGINE_PLATFORM "x64")

	set(RUNTIME_DEBUG_POSTFIX "_d_${ENGINE_PLATFORM}")
	set(RUNTIME_RELEASE_POSTFIX "_${ENGINE_PLATFORM}")
else()
	set(ENGINE_PLATFORM "x86")

	set(RUNTIME_DEBUG_POSTFIX "_d")
	set(RUNTIME_RELEASE_POSTFIX "")
endif()

# lib directory
if(MSVC)
	set(LIB_DIRECTORY "Lib/${ENGINE_PLATFORM}/${CMAKE_VS_PLATFORM_TOOLSET}")
else()
	set(LIB_DIRECTORY "Lib")
endif()

# hide symbols on unix
if(UNIX)
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -fno-rtti -fvisibility=hidden")
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -fvisibility=hidden")
endif()

# Enable DEBUG=1 for debug builds as some projects check that
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DDEBUG=1")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG=1")

# Add directx sdk to include/linker path
if(WIN32)
	if(DEFINED ENV{DXSDK_DIR})
		include_directories($ENV{DXSDK_DIR}/Include)
		link_directories("$ENV{DXSDK_DIR}/Lib/${ENGINE_PLATFORM}")
	else()
		message(FATAL_ERROR "The DirectX SDK needs to be installed.\n\nhttps://www.microsoft.com/en-gb/download/details.aspx?id=6812")
	endif()
endif()

macro(add_compiler_flags FLAGS)
	foreach(FLAG ${FLAGS})
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${FLAG}")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${FLAG}")
	endforeach()
endmacro()

macro(define_debug DEFINES)
	foreach(DEFINE ${DEFINES})
		set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -D${DEFINE}")
		set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -D${DEFINE}")
	endforeach()
endmacro()

# Visual Studio specifics
if(MSVC)
	# Force /MT for static VC runtimes if Release...
	option(FORCE_STATIC_VCRT "Force /MT for static VC runtimes" OFF)
	if(FORCE_STATIC_VCRT)
		foreach(flag_var
			CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
			CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO)
			if(${flag_var} MATCHES "/MD")
				string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
			endif()
		endforeach()

		set(LIB_DIRECTORY "${LIB_DIRECTORY}_static")
	endif()

	# common defines
	add_definitions(-DWIN32 -D_WINDOWS -D_CRT_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_WARNINGS -D_USE_MATH_DEFINES=1 -DNOMINMAX)

	if(MSVC_VERSION GREATER_EQUAL 1900)
		# Prevent static variables from being thread local storage
		add_compiler_flags("/Zc:threadSafeInit-")
	endif()

	# disable manifest on dlls
	set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /MANIFEST:NO")

	# Warnings should be errors
	#add_compiler_flags("/WX")

	# macro to disable VS warning
	macro(disable_warning ID)
		add_compiler_flags(/wd${ID})
	endmacro()

	# macro redefinition
	disable_warning(4005)

	# signed/unsigned mismatch
	disable_warning(4018)

	# different 'modifier' qualifiers
	disable_warning(4090)

	# ignored on left of 'type' when no variable is declared
	disable_warning(4091)

	# unary minus operator applied to unsigned type, result still unsigned
	disable_warning(4146)

	# conversion from 'type1' to 'type2', possible loss of data
	disable_warning(4242)

	# conversion from 'type1' to 'type2', possible loss of data
	disable_warning(4244)

	# conversion from 'type1' to 'type2', signed/unsigned mismatch
	disable_warning(4245)

	# conversion from 'size_t' to 'type', possible loss of data
	disable_warning(4267)

	# signed/unsigned mismatch
	disable_warning(4389)

	# conversion from 'type_1' to 'type_2' requires a narrowing conversion
	disable_warning(4838)
endif()

# to avoid repeating stuff
function(new_library_static NAME SOURCES INCLUDE DEFINES)
	set(LIBRARY_SOURCES "")
	foreach(SOURCE ${SOURCES})
		list(APPEND LIBRARY_SOURCES ${SOURCE})
	endforeach()

	add_library("${NAME}_static" STATIC ${LIBRARY_SOURCES})

	if(MSVC)
		# embedd pdb
		set_target_properties("${NAME}_static" PROPERTIES COMPILE_OPTIONS "/Z7")
	endif()

	foreach(DEFINE ${DEFINES})
		target_compile_definitions("${NAME}_static" PRIVATE ${DEFINE})
	endforeach()

	target_include_directories("${NAME}_static" PRIVATE "${INCLUDE}")

	install(TARGETS "${NAME}_static"
		RUNTIME DESTINATION "${LIB_DIRECTORY}/Debug" CONFIGURATIONS Debug
		LIBRARY DESTINATION "${LIB_DIRECTORY}/Debug" CONFIGURATIONS Debug
		ARCHIVE DESTINATION "${LIB_DIRECTORY}/Debug" CONFIGURATIONS Debug)
	install(TARGETS "${NAME}_static"
		RUNTIME DESTINATION "${LIB_DIRECTORY}/Release" CONFIGURATIONS Release
		LIBRARY DESTINATION "${LIB_DIRECTORY}/Release" CONFIGURATIONS Release
		ARCHIVE DESTINATION "${LIB_DIRECTORY}/Release" CONFIGURATIONS Release)
	install(DIRECTORY "${INCLUDE}/" DESTINATION include FILES_MATCHING PATTERN "*.h*")
endfunction()

function(new_library_shared NAME SOURCES INCLUDE DEFINES)
	set(LIBRARY_SOURCES "")
	foreach(SOURCE ${SOURCES})
		list(APPEND LIBRARY_SOURCES ${SOURCE})
	endforeach()

	add_library("${NAME}" SHARED ${LIBRARY_SOURCES})

	set_target_properties("${NAME}" PROPERTIES RUNTIME_OUTPUT_NAME_DEBUG "${NAME}${RUNTIME_DEBUG_POSTFIX}")
	set_target_properties("${NAME}" PROPERTIES RUNTIME_OUTPUT_NAME_RELEASE "${NAME}${RUNTIME_RELEASE_POSTFIX}")

	foreach(DEFINE ${DEFINES})
		target_compile_definitions("${NAME}" PRIVATE ${DEFINE})
	endforeach()

	target_include_directories("${NAME}" PRIVATE "${INCLUDE}")

	install(TARGETS "${NAME}"
		RUNTIME DESTINATION "${LIB_DIRECTORY}/Debug" CONFIGURATIONS Debug
		LIBRARY DESTINATION "${LIB_DIRECTORY}/Debug" CONFIGURATIONS Debug
		ARCHIVE DESTINATION "${LIB_DIRECTORY}/Debug" CONFIGURATIONS Debug)
	install(TARGETS "${NAME}"
		RUNTIME DESTINATION "${LIB_DIRECTORY}/Release" CONFIGURATIONS Release
		LIBRARY DESTINATION "${LIB_DIRECTORY}/Release" CONFIGURATIONS Release
		ARCHIVE DESTINATION "${LIB_DIRECTORY}/Release" CONFIGURATIONS Release)
	install(DIRECTORY "${INCLUDE}/" DESTINATION include FILES_MATCHING PATTERN "*.h*")

	if(MSVC)
		install(FILES $<TARGET_PDB_FILE:${NAME}> DESTINATION "${LIB_DIRECTORY}/Debug" CONFIGURATIONS Debug OPTIONAL)
		install(FILES $<TARGET_PDB_FILE:${NAME}> DESTINATION "${LIB_DIRECTORY}/Release" CONFIGURATIONS Release OPTIONAL)
	endif()
endfunction()

add_subdirectory(Projects)
