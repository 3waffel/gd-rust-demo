# Godot Rust Integration Demo

## Trivial way

Build with Cargo
```
cargo build --release --manifest-path ./rustlib/Cargo.toml
cp ./rustlib/target/release/rustlib.dll ./gdproject/gdnative/bin/windows/rustlib.dll
```

## Nix way

Build with `flake.nix` 
```
nix build .#windows64
```

## `godot-rust-cli` way

Install the cli
```
cargo install godot-rust-cli
```

Create the project
```
godot-rust-cli new rustlib gdproject
godot-rust-cli create ClassName
godot-rust-cli build --watch
```

Add platform (only few platforms are supported)
```
godot-rust-cli add-platform <platform-name>
```

## Export the project

```
godot -v --export "Windows Desktop" build/windows/gdproject.exe --no-window

godot -v --export "Linux/X11" build/linux/gdproject.x86_64 --no-window
```

## Notes 

### 关于 GDNative
+ 将 GDNativeLibrary 中特定架构的路径指向相应 target 的 release 库文件
+ 在 NativeScript 中，引用包含相应 class 的 GDNativeLibrary
+ 在 NativeScript 中，`class_name` 应当与 rust 中的 class 相同