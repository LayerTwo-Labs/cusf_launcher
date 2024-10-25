# cusf_launcher

## Requirements:
* Godot v4.3 : https://github.com/godotengine/godot/releases/tag/4.3-stable
* Rust/Cargo : https://rustup.rs/

If cross-compiling for Windows, mingw-64 is required.

## Command line build instructions:

Linux:
```
pushd cusf_launcher_crypto
cargo build --target x86_64-unknown-linux-gnu
cargo build --release --target x86_64-unknown-linux-gnu
popd
godot --headless --path cusf_launcher/ --export-release "Linux" cusf_launcher.x86_64
```

Windows:
```
pushd cusf_launcher_crypto
cargo build --target x86_64-unknown-linux-gnu
RUSTFLAGS="-C linker=/usr/bin/x86_64-w64-mingw32-gcc" cargo build --release --target x86_64-pc-windows-gnu
popd
godot --headless --path cusf_launcher/ --export-release "Windows" cusf_launcher.exe
```

Mac:
```
pushd cusf_launcher_crypto
cargo build --target x86_64-apple-darwin
cargo build --release --target x86_64-apple-darwin
popd
godot --headless --path cusf_launcher/ --export-release "Mac" cusf_launcher.dmg`
```

