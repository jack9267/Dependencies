disable_rtti()

set(SOURCES src/SDLnet.c src/SDLnetselect.c src/SDLnetsys.h src/SDLnetTCP.c src/SDLnetUDP.c)

if(WIN32)
	list(APPEND SOURCES src/Version.rc)
endif()

new_library_static(SDL2_net "${SOURCES}" "")
new_library_shared(SDL2_net "${SOURCES}" "SDL2_BUILDING")

target_link_libraries(SDL2_net SDL2)

if(WIN32)
	target_link_libraries(SDL2_net wsock32 iphlpapi)
endif()
