///|
#cfg(target="js")
pub extern "js" fn dom_create_effect(cb : () -> Unit) -> Unit =
  #|(cb) => { if (globalThis.reactive) globalThis.reactive.create_effect(cb); }

///|
#cfg(target="js")
pub extern "js" fn int_to_string(n : Int) -> String =
  #|(n) => String(n)
