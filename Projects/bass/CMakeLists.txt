if(WIN32)
	install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/src/c/bass.h" DESTINATION include)

	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(BASS_FILES
			${CMAKE_CURRENT_SOURCE_DIR}/src/c/x64/bass.lib
			${CMAKE_CURRENT_SOURCE_DIR}/src/x64/bass.dll
		)
	else()
		set(BASS_FILES
			${CMAKE_CURRENT_SOURCE_DIR}/src/c/bass.lib
			${CMAKE_CURRENT_SOURCE_DIR}/src/bass.dll
		)
	endif()

	install(FILES ${BASS_FILES} DESTINATION "${LIB_DIRECTORY}/Debug")

	install(FILES ${BASS_FILES} DESTINATION "${LIB_DIRECTORY}/Release")
endif()
