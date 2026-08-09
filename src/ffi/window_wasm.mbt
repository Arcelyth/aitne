///|
#cfg(target="wasm-gc")
pub extern "wasm" fn prim_window() -> Window = "aitne" "prim_window"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn set_window_href(href : String) -> Unit = "aitne" "set_window_href"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn window_add_event_listener(
  ev_name : String,
  cb : (Event) -> Unit,
) -> EventHandle = "aitne" "window_add_event_listener"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn window_remove_event_listener(handle : EventHandle) -> Unit = "aitne" "window_remove_event_listener"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn window_event_listener(
  event : String,
  callback : (Event) -> Unit,
) -> EventHandle = "aitne" "window_event_listener"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn set_timeout(cb : () -> Unit, ms : Int) -> TimeoutHandle = "aitne" "set_timeout"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn clear_timeout(handle : TimeoutHandle) -> Unit = "aitne" "clear_timeout"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn set_interval(cb : () -> Unit, ms : Int) -> IntervalHandle = "aitne" "set_interval"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn clear_interval(handle : IntervalHandle) -> Unit = "aitne" "clear_interval"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn request_animation_frame(
  cb : () -> Unit,
) -> AnimationFrameHandle = "aitne" "request_animation_frame"

///|
#cfg(target="wasm-gc")
pub extern "wasm" fn cancel_animation_frame(
  handle : AnimationFrameHandle,
) -> Unit = "aitne" "cancel_animation_frame"
