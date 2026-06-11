export type Manifest = {
	packages: {
		name: string,
		authors: { string },
		version: string,
	},

	dependencies: {
		[string]: string,
	},
}


return nil