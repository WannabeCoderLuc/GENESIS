--!strict
--[[
	GENERATED FILE - DO NOT EDIT.
	Vector set: CanonicalVectorsV1 (v1) - canonical encoding and checksums
	Source:     tools/gen-golden-vectors.mjs, reference tools/reference/uc-reference.mjs (independent BigInt model)
	Regenerate: npm run gen:vectors      Verify: npm run check:vectors
]]

return table.freeze({
	valid = {
		{
			checksumHex = "2e2b2c19dc674c3b",
			encoded = "T",
			name = "true",
			value = true,
		},
		{
			checksumHex = "bb14d1ffce3a2f41",
			encoded = "F",
			name = "false",
			value = false,
		},
		{
			checksumHex = "05705b58e9d2c2cf",
			encoded = "i0;",
			name = "zero",
			value = 0,
		},
		{
			checksumHex = "ad748101253ed296",
			encoded = "i1;",
			name = "one",
			value = 1,
		},
		{
			checksumHex = "9ceaf9c365df981b",
			encoded = "i-42;",
			name = "negative",
			value = -42,
		},
		{
			checksumHex = "8470dee5f9f41942",
			encoded = "i9007199254740991;",
			name = "maxSafe",
			value = 9007199254740991,
		},
		{
			checksumHex = "32cc8e7fb14d0076",
			encoded = "i-9007199254740991;",
			name = "minSafe",
			value = -9007199254740991,
		},
		{
			checksumHex = "6af144e9fc3581e5",
			encoded = "d4340000000000000",
			name = "beyondSafe",
			value = 9007199254740992,
		},
		{
			checksumHex = "b0e529df1f9647a4",
			encoded = "d3fe0000000000000",
			name = "half",
			value = 0.5,
		},
		{
			checksumHex = "e81c7ad75c432ec3",
			encoded = "d3fb999999999999a",
			name = "tenth",
			value = 0.1,
		},
		{
			checksumHex = "a09725e08ae6fd6d",
			encoded = "dbe80c6f7a0b5ed8d",
			name = "negativeSmall",
			value = -1.25e-7,
		},
		{
			checksumHex = "f32b1cb7182d7aaa",
			encoded = "d7e37e43c8800759c",
			name = "large",
			value = 1e+300,
		},
		{
			checksumHex = "69e2dd02390c7b05",
			encoded = "d0000000000000001",
			name = "denormal",
			value = 5e-324,
		},
		{
			checksumHex = "b4b4c779093dc5b9",
			encoded = "d7fefffffffffffff",
			name = "maxDouble",
			value = 1.7976931348623157e+308,
		},
		{
			checksumHex = "9771f2162909798b",
			encoded = "s0:",
			name = "emptyString",
			value = "",
		},
		{
			checksumHex = "68784a0e0a7df5fc",
			encoded = "s3:abc",
			name = "ascii",
			value = "abc",
		},
		{
			checksumHex = "e4ddc3d3d595d06f",
			encoded = "s4:\x00\xff\xc3\xa9",
			name = "bytes",
			value = "\x00\xff\xc3\xa9",
		},
		{
			checksumHex = "4d9a05c3d5f4c234",
			encoded = "a0:",
			name = "emptyTable",
			value = {},
		},
		{
			checksumHex = "f1d945fa9eec4fb1",
			encoded = "a4:i1;s3:twoTd3fe0000000000000",
			name = "array",
			value = { 1, "two", true, 0.5 },
		},
		{
			checksumHex = "c1501bf303f5110c",
			encoded = "a3:a2:i1;i2;a0:a1:a1:i3;",
			name = "nestedArray",
			value = {
				{ 1, 2 },
				{},
				{
					{ 3 },
				},
			},
		},
		{
			checksumHex = "ca53a50bda804f5e",
			encoded = "m6:s0:i4;s4:Betai3;s6:_underi5;s5:alphai2;s4:zetai1;s1:\xe9i6;",
			name = "map",
			value = {
				[""] = 4,
				Beta = 3,
				_under = 5,
				alpha = 2,
				zeta = 1,
				["\xe9"] = 6,
			},
		},
		{
			checksumHex = "6ce9cf84848edf58",
			encoded = "m2:s1:am1:s1:bm1:s1:ca2:i1;m1:s1:dFs4:lista2:s1:xs1:y",
			name = "nestedMap",
			value = {
				a = {
					b = {
						c = {
							1,
							{
								d = false,
							},
						},
					},
				},
				list = { "x", "y" },
			},
		},
		{
			checksumHex = "3efc799fcf5973a7",
			encoded = "m4:s5:owneda2:s2:u1s2:u2s14:profileVersioni1;s8:settingsm2:s13:reducedMotionFs15:uiScalePermillei1000;s6:userIdi123456789;",
			name = "profileLike",
			value = {
				owned = { "u1", "u2" },
				profileVersion = 1,
				settings = {
					reducedMotion = false,
					uiScalePermille = 1000,
				},
				userId = 123456789,
			},
		},
	},
} :: any)
