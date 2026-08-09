///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_create_effect(cb : () -> Unit) -> Unit = "aitne" "dom_create_effect"
