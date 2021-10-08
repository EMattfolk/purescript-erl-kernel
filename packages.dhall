let upstream =
      https://github.com/purerl/package-sets/releases/download/erl-0.14.3-20210709/packages.dhall sha256:9b07e1fe89050620e2ad7f7623d409f19b5e571f43c2bdb61242377f7b89d941

in  upstream
 with convertable-options =
        { repo = "https://github.com/natefaubion/purescript-convertable-options"
        , dependencies = [ "effect", "maybe", "record" ]
        , version = "f20235d464e8767c469c3804cf6bec4501f970e6"
        }
 with erl-process =
        { repo = "https://github.com/id3as/purescript-erl-process"
        , dependencies = [ "effect", "prelude" ]
        , version = "fc793e11ed2b0a0b3c38441de9dacb8652b1bbeb"
        }
 with erl-untagged-union =
        { repo = "https://github.com/id3as/purescript-erl-untagged-union.git"
        , dependencies =
        [ "erl-atom"
        , "erl-binary"
        , "erl-lists"
        , "erl-tuples"
        , "debug"
        , "foreign"
        , "typelevel-prelude"
        , "maybe"
        , "partial"
        , "prelude"
        , "unsafe-coerce"
        ]
        , version = "57f8aad9d2bd0a980dbd6ab3136f8d1edd16a1ad"
        }
 with erl-binary =
        { repo = "https://github.com/id3as/purescript-erl-binary.git"
        , dependencies = [ "erl-lists", "maybe", "prelude" ]
        , version = "e3a5da78a9264a800eb7bad918a58de5ac57ba4c"
        }
