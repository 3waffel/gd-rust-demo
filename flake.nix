{
  inputs = {
    naersk = {
      url = "github:nix-community/naersk/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    utils,
    naersk,
    fenix,
    flake-compat,
  }:
    utils.lib.eachSystem ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"] (
      system: let
        pkgs = import nixpkgs {inherit system;};
        inherit (pkgs) lib stdenv;
        toolchain = with fenix.packages.${system};
          combine ([
              minimal.rustc
              minimal.cargo
              targets.x86_64-unknown-linux-gnu.latest.rust-std
            ]
            ++ lib.optionals stdenv.isLinux
            [
              targets.x86_64-pc-windows-gnu.latest.rust-std
            ]);
        naersk-lib = naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        };
        naerskBuildPackage = target: args:
          naersk-lib.buildPackage
          (args // {CARGO_BUILD_TARGET = target;});
        commonNativeBuildInputs = with pkgs; [
          llvmPackages.libclang
          pkg-config
        ];
      in rec {
        defaultPackage = packages.x86_64-unknown-linux-gnu;

        packages.x86_64-unknown-linux-gnu = naerskBuildPackage "x86_64-unknown-linux-gnu" {
          src = ./rustlib;
          copyBins = false;
          copyLibs = true;
          release = true;
          buildInputs = with pkgs; [openssl];
          nativeBuildInputs = with pkgs;
            [
              pkgsStatic.stdenv.cc
            ]
            ++ commonNativeBuildInputs;
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          BINDGEN_EXTRA_CLANG_ARGS = with pkgs; "${builtins.readFile "${stdenv.cc}/nix-support/libc-crt1-cflags"} \
                ${builtins.readFile "${stdenv.cc}/nix-support/libc-cflags"} \
                ${builtins.readFile "${stdenv.cc}/nix-support/cc-cflags"} \
                ${builtins.readFile "${stdenv.cc}/nix-support/libcxx-cxxflags"} \
                -idirafter ${pkgs.libiconv}/include \
                ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
                ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${lib.getVersion stdenv.cc.cc}/include"} \
            ";
        };

        packages.x86_64-pc-windows-gnu = naerskBuildPackage "x86_64-pc-windows-gnu" {
          src = ./rustlib;
          copyBins = false;
          copyLibs = true;
          release = true;
          buildInputs = with pkgs.pkgsCross.mingwW64.windows; [mingw_w64_pthreads pthreads];
          nativeBuildInputs = with pkgs;
            [
              pkgsCross.mingwW64.stdenv.cc
            ]
            ++ commonNativeBuildInputs;
          singleStep = true;
          preBuild = ''
            export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C link-args=$(echo $NIX_LDFLAGS | tr ' ' '\n' | grep -- '^-L' | tr '\n' ' ')"
            export NIX_LDFLAGS=
          '';
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          BINDGEN_EXTRA_CLANG_ARGS = with pkgs; "${builtins.readFile "${stdenv.cc}/nix-support/libc-crt1-cflags"} \
                ${builtins.readFile "${stdenv.cc}/nix-support/libc-cflags"} \
                ${builtins.readFile "${stdenv.cc}/nix-support/cc-cflags"} \
                ${builtins.readFile "${stdenv.cc}/nix-support/libcxx-cxxflags"} \
                -idirafter ${pkgs.libiconv}/include \
                ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
                ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${lib.getVersion stdenv.cc.cc}/include"} \
            ";
        };

        devShell = with pkgs;
          mkShell {
            buildInputs = [
              # rust
              cargo
              cargo-watch
              rustc
              rust-analyzer
              rustfmt
              rustPackages.clippy
            ];
            nativeBuildInputs = commonNativeBuildInputs;
            shellHook = ''
              export PATH=$HOME/.cargo/bin:$PATH
            '';
            RUST_LOG = "info";
            RUST_SRC_PATH = rustPlatform.rustLibSrc;
            LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
            BINDGEN_EXTRA_CLANG_ARGS = "${builtins.readFile "${stdenv.cc}/nix-support/libc-crt1-cflags"} \
                ${builtins.readFile "${stdenv.cc}/nix-support/libc-cflags"} \
                ${builtins.readFile "${stdenv.cc}/nix-support/cc-cflags"} \
                ${builtins.readFile "${stdenv.cc}/nix-support/libcxx-cxxflags"} \
                -idirafter ${pkgs.libiconv}/include \
                ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
                ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${lib.getVersion stdenv.cc.cc}/include"} \
            ";
          };
      }
    );
}
