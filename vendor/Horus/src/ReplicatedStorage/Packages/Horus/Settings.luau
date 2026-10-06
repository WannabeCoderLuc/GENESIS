--!strict
export type LoaderSettings = {
	YIELD_THRESHOLD: number,
	VERBOSE_LOADING: boolean,
	WAIT_FOR_SERVER: boolean,
	WAIT_FOR_PERSISTENT: boolean,
	USE_COLLECTION_SERVICE: boolean,
	FOLDER_SEARCH_DEPTH: number,
	LOADER_TAG: string,
}

local SETTINGS: LoaderSettings = {
	YIELD_THRESHOLD = 10,
	VERBOSE_LOADING = true,
	WAIT_FOR_SERVER = true,
	WAIT_FOR_PERSISTENT = false,
	USE_COLLECTION_SERVICE = true,
	FOLDER_SEARCH_DEPTH = 1,
	LOADER_TAG = "Horus_Load",
}

return SETTINGS