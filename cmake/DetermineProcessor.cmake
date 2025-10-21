# Determine the processor/architecture for compiler optimizations

IF(UNIX)
	# Try uname -m first (machine hardware), it's more reliable for ARM64
	execute_process(
		COMMAND uname -m
		OUTPUT_VARIABLE NV_SYSTEM_PROCESSOR
		OUTPUT_STRIP_TRAILING_WHITESPACE
		RESULT_VARIABLE val
	)

	# If that fails or returns unknown, try uname -p (processor type)
	IF("${val}" GREATER 0 OR NV_SYSTEM_PROCESSOR STREQUAL "unknown")
		execute_process(
			COMMAND uname -p
			OUTPUT_VARIABLE NV_SYSTEM_PROCESSOR
			OUTPUT_STRIP_TRAILING_WHITESPACE
			RESULT_VARIABLE val
		)
	ENDIF()

	IF("${val}" GREATER 0)
		MESSAGE(ERROR " Failed to determine processor type")
		SET(NV_SYSTEM_PROCESSOR "unknown")
	ENDIF()
ENDIF(UNIX)

IF(WIN32)
	SET(NV_SYSTEM_PROCESSOR "$ENV{PROCESSOR_ARCHITECTURE}")
ENDIF(WIN32)

MESSAGE(STATUS "Detected processor: ${NV_SYSTEM_PROCESSOR}")
