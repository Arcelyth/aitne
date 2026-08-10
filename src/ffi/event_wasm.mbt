///|
#cfg(target="wasm-gc")
pub extern "wasm" fn dom_add_event(
  node : Node,
  ev : String,
  handler : (Event) -> Unit,
) -> Unit = "aitne" "dom_add_event"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_add_event_listener(
  el : Element,
  name : String,
  cb : (Event) -> Unit,
) -> EventHandle = "aitne" "prim_add_event_listener"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_add_event_listener_capture(
  el : Element,
  name : String,
  cb : (Event) -> Unit,
) -> EventHandle = "aitne" "prim_add_event_listener_capture"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_call_event_handle(handle : EventHandle) -> Unit = "aitne" "prim_call_event_handle"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_target_value(ev : Event) -> String = "aitne" "event_target_value"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_target_checked(ev : Event) -> Bool = "aitne" "event_target_checked"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_default_prevented(ev : Event) -> Bool = "aitne" "event_default_prevented"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_prevent_default(ev : Event) -> Unit = "aitne" "event_prevent_default"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_button(ev : Event) -> Int = "aitne" "event_button"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_meta_key(ev : Event) -> Bool = "aitne" "event_meta_key"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_alt_key(ev : Event) -> Bool = "aitne" "event_alt_key"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_ctrl_key(ev : Event) -> Bool = "aitne" "event_ctrl_key"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_shift_key(ev : Event) -> Bool = "aitne" "event_shift_key"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn event_composed_path(ev : Event) -> JsArray = "aitne" "event_composed_path"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn js_array_length(arr : JsArray) -> Int = "aitne" "js_array_length"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn js_array_get(arr : JsArray, idx : Int) -> Node = "aitne" "js_array_get"
