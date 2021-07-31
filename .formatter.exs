# Used by "mix format"

locals_without_parens = [let: 1, defr: 1, defr: 2, defrp: 2]

[
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
