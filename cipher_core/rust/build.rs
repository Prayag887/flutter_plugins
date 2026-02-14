fn main() {
    println!("cargo:rerun-if-changed=src/lib.rs");

    // Add iOS specific build configurations
    if std::env::var("TARGET").unwrap().contains("ios") {
        println!("cargo:rustc-link-arg=-Wl,-dead_strip");
        println!("cargo:rustc-link-arg=-Wl,-bitcode_bundle");
        println!("cargo:rustc-link-arg=-Wl,-ios_version_min,11.0");
    }

    // Add Android specific build configurations
    if std::env::var("TARGET").unwrap().contains("android") {
        println!("cargo:rustc-link-lib=log");
        println!("cargo:rustc-link-lib=android");
    }
}