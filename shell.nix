let
  nixpkgs = import
    (fetchTarball {
      url = "https://github.com/jechol/nixpkgs/archive/22.05-otp25-no-jit.tar.gz";
      sha256 = "sha256:1k4wgcrffdlr7pr401md6dmvfwawcslvcwkv7qjgqqyrx52v130i";
    })
    { };
  platform =
    if nixpkgs.stdenv.isDarwin then [
      nixpkgs.darwin.apple_sdk.frameworks.CoreServices
      nixpkgs.darwin.apple_sdk.frameworks.Foundation
    ] else if nixpkgs.stdenv.isLinux then
      [ nixpkgs.inotify-tools ]
    else
      [ ];
in
nixpkgs.mkShell {
  buildInputs = with nixpkgs;
    [
      # OTP
      erlang
      elixir
    ] ++ platform;
}
