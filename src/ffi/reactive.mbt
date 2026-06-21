///|
pub extern "js" fn dom_create_effect(cb : () -> Unit) -> Unit =
  #|(cb) => { if (globalThis.reactive) globalThis.reactive.create_effect(cb); }
