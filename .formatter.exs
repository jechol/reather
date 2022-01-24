# Used by "mix format"

locals_without_parens = [
  let: 1,
  reather: 1,
  reather: 2,
  reatherp: 2,
  assert_ast: 1
]

[
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
