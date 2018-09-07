if(WIN32)
	file(GLOB FMOD_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/src/inc/*.h*")

	install(FILES ${FMOD_HEADERS} DESTINATION include)


	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(FMOD_FILES
			${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fmod64.dll
			${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fmod64_vc.lib
			${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fmodL64.dll
			${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fmodL64_vc.lib
		)
	else()
		set(FMOD_FILES
			${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fmod.dll
			${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fmod_vc.lib
			${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fmodL.dll
			${CMAKE_CURRENT_SOURCE_DIR}/src/lib/fmodL_vc.lib
		)
	endif()

	install(FILES ${FMOD_FILES} DESTINATION "${LIB_DIRECTORY}/Debug")

	install(FILES ${FMOD_FILES} DESTINATION "${LIB_DIRECTORY}/Release")

endif()
