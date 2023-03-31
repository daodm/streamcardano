let entangled = https://raw.githubusercontent.com/entangled/entangled/v1.3.0/data/config-schema.dhall
                sha256:cb03a230547147223b6bd522c133d16d17921e249e7c2bd505d31bf7729d2cc5

let intercalComment = entangled.Comment.Line "PLEASE NOTE: "

let languages = entangled.languages #
    [ { name = "Unlambda", identifiers = ["unlambda"], comment = entangled.comments.hash }
    , { name = "Intercal", identifiers = ["intercal"], comment = intercalComment }
    , { name = "Bash", identifiers = ["bash", "sh"], comment = entangled.comments.hash }
    ]

let syntax : entangled.Syntax =
    { matchCodeStart       = "```[ ]*{[^{}]*}"
    , matchCodeEnd         = "```"
    , extractLanguage      = "```[ ]*{\\.([^{} \t]+)[^{}]*}"
    , extractReferenceName = "```[ ]*{[^{}]*#([^{} \t]*)[^{}]*}"
    , extractFileName      = "```[ ]*{[^{}]*file=([^{} \t]*)[^{}]*}"
    , extractProperty      = \(name : Text) -> "```[ ]*{[^{}]*${name}=([^{} \t]*)[^{}]*}" }

let database = Some ".entangled/db.sqlite"

let watchList = [ "README.md", "appendix.md" ]

in { entangled = entangled.Config :: { database = database
                                     , watchList = watchList
                                     , languages = languages
                                     , syntax = syntax }
}
