--!strict
--[[
	GENERATED FILE - DO NOT EDIT.
	Vector set: HashVectorsV1 (v1) - FNV-1a 64, fmix64, hashString, SplitMix64
	Source:     tools/gen-golden-vectors.mjs, reference tools/reference/uc-reference.mjs (independent BigInt model)
	Regenerate: npm run gen:vectors      Verify: npm run check:vectors
]]

return table.freeze({
	fmix64 = {
		{
			inputHex = "0000000000000000",
			outputHex = "0000000000000000",
		},
		{
			inputHex = "0000000000000001",
			outputHex = "b456bcfc34c2cb2c",
		},
		{
			inputHex = "ffffffffffffffff",
			outputHex = "64b5720b4b825f21",
		},
		{
			inputHex = "0123456789abcdef",
			outputHex = "87cbfbfe89022cea",
		},
		{
			inputHex = "8000000000000000",
			outputHex = "8f780810af31a493",
		},
		{
			inputHex = "deadbeefcafef00d",
			outputHex = "97242897596c395d",
		},
		{
			inputHex = "867d780937fec92d",
			outputHex = "a54494ea4aced25e",
		},
		{
			inputHex = "e7f774e17bf1faab",
			outputHex = "f86e0ef16748f421",
		},
		{
			inputHex = "8635aefb4351ef97",
			outputHex = "50aa5090c76ea702",
		},
		{
			inputHex = "e53ea2007d8a6375",
			outputHex = "4cc37e249d6dfc30",
		},
		{
			inputHex = "50667515500f9210",
			outputHex = "107176d84f1362c5",
		},
		{
			inputHex = "96e530770640d160",
			outputHex = "6cb7628d61c10d67",
		},
		{
			inputHex = "cbf4db9948fdf1bd",
			outputHex = "827cffb4fa586d72",
		},
		{
			inputHex = "1c6a014d128de782",
			outputHex = "68edca8fcf6b6660",
		},
		{
			inputHex = "09b0a566f3dc1f73",
			outputHex = "4587c45caa8885f5",
		},
		{
			inputHex = "a8a8c3e95dd2937d",
			outputHex = "edcffc1afeb9c146",
		},
		{
			inputHex = "22d3931b9fe14a36",
			outputHex = "48738a2ba1652c3c",
		},
		{
			inputHex = "f3e98b9fab6b297d",
			outputHex = "9adcec0355b47c60",
		},
		{
			inputHex = "0282dba4fddefc84",
			outputHex = "be4af83e4b15f138",
		},
		{
			inputHex = "f5a61eee6678c1c2",
			outputHex = "ef1a79e46d5faba4",
		},
		{
			inputHex = "8ebaa9f4322b9dc2",
			outputHex = "d2d8818729e0d8eb",
		},
		{
			inputHex = "0a79242a0084e7f8",
			outputHex = "0c238f3e5e579a7d",
		},
		{
			inputHex = "75ddb6952dceae71",
			outputHex = "9589b13f4617d2e8",
		},
		{
			inputHex = "95ee18a5cf996971",
			outputHex = "8d2d722195c26daa",
		},
		{
			inputHex = "b9a4647f264e35e4",
			outputHex = "423f4bb8bbd78a96",
		},
		{
			inputHex = "d4fccef05ed914a5",
			outputHex = "9dc18aa4bd403207",
		},
		{
			inputHex = "2082b946ffabdd6b",
			outputHex = "5696de4a787598c7",
		},
		{
			inputHex = "ed56961e9e6d0514",
			outputHex = "e0395f90b0525a35",
		},
		{
			inputHex = "faf4dfa4d5a174bc",
			outputHex = "a83d67ca3a115e9b",
		},
		{
			inputHex = "65d56172d52f08f5",
			outputHex = "8d62182da5d93f20",
		},
	},
	fnv1a64 = {
		{
			hex = "cbf29ce484222325",
			input = "",
		},
		{
			hex = "af63dc4c8601ec8c",
			input = "a",
		},
		{
			hex = "85944171f73967e8",
			input = "foobar",
		},
		{
			hex = "a430d84680aabd0b",
			input = "hello",
		},
		{
			hex = "d30d3eab31cf8111",
			input = "UCSEEDV1",
		},
		{
			hex = "fc9697d1196e6ba6",
			input = "epoch",
		},
		{
			hex = "3033b5c2805ad9d1",
			input = "universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-",
		},
		{
			hex = "4242dc5249c33625",
			input = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff",
		},
		{
			hex = "af63bd4c8601b7df",
			input = "\x00",
		},
		{
			hex = "0a99c807b6f645b0",
			input = "\xff\xfe",
		},
	},
	hashString = {
		{
			hex = "efd01f60ba992926",
			input = "",
		},
		{
			hex = "82a2a958a9bece5b",
			input = "a",
		},
		{
			hex = "2c22194922d1672b",
			input = "foobar",
		},
		{
			hex = "e9c562c0fdb23244",
			input = "hello",
		},
		{
			hex = "8bf20d786b8b18ce",
			input = "UCSEEDV1",
		},
		{
			hex = "ccb35be5ab9982e6",
			input = "epoch",
		},
		{
			hex = "f27c773cc0638d04",
			input = "universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-universe-creator-",
		},
		{
			hex = "2067db6dbd4efa06",
			input = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff",
		},
		{
			hex = "b9034ad37056f5fb",
			input = "\x00",
		},
		{
			hex = "75c9056eb1c4b960",
			input = "\xff\xfe",
		},
	},
	splitmix64 = {
		{
			outputs = {
				{
					outHex = "e220a8397b1dcdaf",
					stateHex = "9e3779b97f4a7c15",
				},
				{
					outHex = "6e789e6aa1b965f4",
					stateHex = "3c6ef372fe94f82a",
				},
				{
					outHex = "06c45d188009454f",
					stateHex = "daa66d2c7ddf743f",
				},
				{
					outHex = "f88bb8a8724c81ec",
					stateHex = "78dde6e5fd29f054",
				},
				{
					outHex = "1b39896a51a8749b",
					stateHex = "1715609f7c746c69",
				},
				{
					outHex = "53cb9f0c747ea2ea",
					stateHex = "b54cda58fbbee87e",
				},
				{
					outHex = "2c829abe1f4532e1",
					stateHex = "538454127b096493",
				},
				{
					outHex = "c584133ac916ab3c",
					stateHex = "f1bbcdcbfa53e0a8",
				},
			},
			seedHex = "0000000000000000",
		},
		{
			outputs = {
				{
					outHex = "910a2dec89025cc1",
					stateHex = "9e3779b97f4a7c16",
				},
				{
					outHex = "beeb8da1658eec67",
					stateHex = "3c6ef372fe94f82b",
				},
				{
					outHex = "f893a2eefb32555e",
					stateHex = "daa66d2c7ddf7440",
				},
				{
					outHex = "71c18690ee42c90b",
					stateHex = "78dde6e5fd29f055",
				},
				{
					outHex = "71bb54d8d101b5b9",
					stateHex = "1715609f7c746c6a",
				},
				{
					outHex = "c34d0bff90150280",
					stateHex = "b54cda58fbbee87f",
				},
				{
					outHex = "e099ec6cd7363ca5",
					stateHex = "538454127b096494",
				},
				{
					outHex = "85e7bb0f12278575",
					stateHex = "f1bbcdcbfa53e0a9",
				},
			},
			seedHex = "0000000000000001",
		},
		{
			outputs = {
				{
					outHex = "901d4f652fb472cb",
					stateHex = "7ce538a94a496c22",
				},
				{
					outHex = "a7ce246440f74527",
					stateHex = "1b1cb262c993e837",
				},
				{
					outHex = "19b40bbbb9380d34",
					stateHex = "b9542c1c48de644c",
				},
				{
					outHex = "e7a86dc5be618392",
					stateHex = "578ba5d5c828e061",
				},
				{
					outHex = "7366ce945d00e82c",
					stateHex = "f5c31f8f47735c76",
				},
				{
					outHex = "0ff6905e190d8244",
					stateHex = "93fa9948c6bdd88b",
				},
				{
					outHex = "c13c6626abd0306b",
					stateHex = "32321302460854a0",
				},
				{
					outHex = "f6c95b6ed4267a56",
					stateHex = "d0698cbbc552d0b5",
				},
			},
			seedHex = "deadbeefcafef00d",
		},
		{
			outputs = {
				{
					outHex = "e4d971771b652c20",
					stateHex = "9e3779b97f4a7c14",
				},
				{
					outHex = "e99ff867dbf682c9",
					stateHex = "3c6ef372fe94f829",
				},
				{
					outHex = "382ff84cb27281e9",
					stateHex = "daa66d2c7ddf743e",
				},
				{
					outHex = "6d1db36ccba982d2",
					stateHex = "78dde6e5fd29f053",
				},
				{
					outHex = "b4a0472e578069ae",
					stateHex = "1715609f7c746c68",
				},
				{
					outHex = "d31dadbda438bb33",
					stateHex = "b54cda58fbbee87d",
				},
				{
					outHex = "f14f2cf802083fa5",
					stateHex = "538454127b096492",
				},
				{
					outHex = "405da438a39e8064",
					stateHex = "f1bbcdcbfa53e0a7",
				},
			},
			seedHex = "ffffffffffffffff",
		},
		{
			outputs = {
				{
					outHex = "157a3807a48faa9d",
					stateHex = "9f5abf2108f64a04",
				},
				{
					outHex = "d573529b34a1d093",
					stateHex = "3d9238da8840c619",
				},
				{
					outHex = "2f90b72e996dccbe",
					stateHex = "dbc9b294078b422e",
				},
				{
					outHex = "a2d419334c4667ec",
					stateHex = "7a012c4d86d5be43",
				},
				{
					outHex = "01404ce914938008",
					stateHex = "1838a60706203a58",
				},
				{
					outHex = "14bc574c2a2b4c72",
					stateHex = "b6701fc0856ab66d",
				},
				{
					outHex = "b8fc5b1060708c05",
					stateHex = "54a7997a04b53282",
				},
				{
					outHex = "8931545f4f9ea651",
					stateHex = "f2df133383ffae97",
				},
			},
			seedHex = "0123456789abcdef",
		},
	},
} :: any)
