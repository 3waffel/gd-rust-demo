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
              targets.wasm32-unknown-emscripten.latest.rust-std
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

        godot-version = pkgs.godot-headless.version;
        export-templates = let
          unpatched = pkgs.fetchzip {
            url = "https://downloads.tuxfamily.org/godotengine/${godot-version}/Godot_v${godot-version}-stable_export_templates.tpz";
            extension = "zip";
            hash = "sha256-NG6TmfWiEBirvdrCs6mlb27mIp6sjdzvSyw4jyYvkCA=";
          };
        in
          pkgs.stdenv.mkDerivation {
            pname = "godot-export-templates";
            version = godot-version;
            buildInputs = with pkgs; [
              autoPatchelfHook
              xorg.libXcursor
              xorg.libXinerama
              xorg.libXext
              xorg.libXrandr
              xorg.libXi
              libglvnd
            ];
            dontUnpack = true;
            installPhase = ''
              cp -r ${unpatched} $out
            '';
          };
      in rec {
        defaultPackage = packages.linux64-pck;

        packages.linux64-lib = naerskBuildPackage "x86_64-unknown-linux-gnu" {
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

        packages.windows64-lib = naerskBuildPackage "x86_64-pc-windows-gnu" {
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

        # TODO: Not work for now
        # https://github.com/godot-rust/godot-rust/issues/647
        packages.wasm-lib = naerskBuildPackage "wasm32-unknown-emscripten" {
          src = ./rustlib;
          copyBins = false;
          copyLibs = true;
          release = true;
          nativeBuildInputs = with pkgs;
            lib.optionals (stdenv.isx86_64 && stdenv.isLinux)
            [
              gccMultiStdenv
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

        # TODO: embed pck
        packages.linux64-pck = with pkgs;
          stdenv.mkDerivation {
            name = "linux64-pck";
            src = ./gdproject;
            buildInputs = lib.optionals (stdenv.isLinux) [
              godot-headless
              godot-export-templates
            ];
            phases = ["buildPhase"];
            buildPhase = lib.optionals (stdenv.isLinux) ''
              mkdir -p "$TMP/.config"
              mkdir -p "$TMP/.local/share/godot/templates"
              mkdir -p "$TMP/.config/godot/projects/"
              export HOME=$TMP
              export XDG_CONFIG_HOME="$TMP/.config"
              export XDG_DATA_HOME="$TMP/.local/share"
              ln -s ${godot-export-templates} "$TMP/.local/share"
              echo $TMP

              cp -r $src $TMP/src
              chmod -R u+w -- "$TMP/src"
              mkdir -p "$TMP/src/build"
              godot-headless -v --path "$TMP/src" --export-pack "Linux/X11" build/gdproject.pck
              mv $TMP/src/build $out
            '';
          };

        packages.linux64 = with pkgs;
          stdenv.mkDerivation {
            name = "linux64";
            src = ./gdproject;
            buildInputs = lib.optionals (stdenv.isLinux) [
              godot-headless
            ];
            phases = ["buildPhase"];
            buildPhase = lib.optionals (stdenv.isLinux) ''
              mkdir -p "$TMP/.config"
              mkdir -p "$TMP/.local/share/godot/templates"
              mkdir -p "$TMP/.config/godot/projects/"
              export HOME=$TMP
              export XDG_CONFIG_HOME="$TMP/.config"
              export XDG_DATA_HOME="$TMP/.local/share"
              ln -s ${export-templates} "$TMP/.local/share/godot/templates/${godot-version}.stable"

              cp -r $src $TMP/src
              chmod -R u+w -- "$TMP/src"
              mkdir -p "$TMP/src/build/linux"
              godot-headless -v --path "$TMP/src" --export "Linux/X11" build/linux/gdproject.x86_64
              mv $TMP/src/build $out
            '';
            dontStrip = true;
          };

        packages.windows64 = with pkgs;
          stdenv.mkDerivation {
            name = "windows64";
            src = ./gdproject;
            buildInputs = lib.optionals (stdenv.isLinux) [
              godot-headless
            ];
            phases = ["buildPhase"];
            buildPhase = lib.optionals (stdenv.isLinux) ''
              mkdir -p "$TMP/.config"
              mkdir -p "$TMP/.local/share/godot/templates"
              mkdir -p "$TMP/.config/godot/projects/"
              export HOME=$TMP
              export XDG_CONFIG_HOME="$TMP/.config"
              export XDG_DATA_HOME="$TMP/.local/share"
              ln -s ${export-templates} "$TMP/.local/share/godot/templates/${godot-version}.stable"

              cp -r $src $TMP/src
              chmod -R u+w -- "$TMP/src"
              mkdir -p "$TMP/src/build/windows"
              godot-headless -v --path "$TMP/src" --export "Windows Desktop" build/windows/gdproject.exe
              mv $TMP/src/build $out
            '';
            dontStrip = true;
          };

        devShell = with pkgs;
          mkShell {
            buildInputs =
              [
                # rust
                cargo
                cargo-watch
                rustc
                rust-analyzer
                rustfmt
                rustPackages.clippy

                wasm-bindgen-cli
                wasm-pack
              ]
              ++ lib.optionals (stdenv.isLinux)
              [
                godot-headless
                godot-export-templates
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
