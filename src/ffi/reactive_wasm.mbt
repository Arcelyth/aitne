///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_create_effect(cb : () -> Unit) -> Unit = "aitne" "dom_create_effect"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn int_to_string(n : Int) -> String = "aitne" "int_to_string"
