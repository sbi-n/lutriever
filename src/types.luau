export type Dependencies = {
	read [string]: string
}

export type Manifest = {
	read dependencies: Dependencies,
	read dev_dependencies: Dependencies
}

return nil