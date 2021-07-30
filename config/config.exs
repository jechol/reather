use Mix.Config

config :defre, :trace, true

config :defre, :reader_modules, [
  Defre.NestedCallTest.User,
  Defre.NestedCallTest.Accounts,
  Defre.NestedCallTest.UserController
]
