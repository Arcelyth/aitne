///|
#cfg(target="js")
pub extern "js" fn dom_add_event(
  node : Node,
  ev : String,
  handler : (Event) -> Unit,
) -> Unit =
  #|(node, ev, handler) => { node.addEventListener(ev, handler); }

///|
#cfg(target="js")
pub extern "js" fn prim_add_event_listener(
  el : Element,
  name : String,
  cb : (Event) -> Unit,
) -> EventHandle =
  #|(el, name, cb) => {
  #|  el.addEventListener(name, cb);
  #|  return () => el.removeEventListener(name, cb);
  #|}

///|
#cfg(target="js")
pub extern "js" fn prim_add_event_listener_capture(
  el : Element,
  name : String,
  cb : (Event) -> Unit,
) -> EventHandle =
  #|(el, name, cb) => {
  #|  el.addEventListener(name, cb, true);
  #|  return () => el.removeEventListener(name, cb, true);
  #|}

///|
#cfg(target="js")
pub extern "js" fn prim_call_event_handle(handle : EventHandle) -> Unit =
  #|(handle) => { handle(); }

///|
#cfg(target="js")
pub extern "js" fn event_target_value(ev : Event) -> String =
  #|(ev) => ev.target ? (ev.target.value || "") : ""

///|
#cfg(target="js")
pub extern "js" fn event_target_checked(ev : Event) -> Bool =
  #|(ev) => ev.target ? !!ev.target.checked : false

///|
#cfg(target="js")
pub extern "js" fn event_default_prevented(ev : Event) -> Bool =
  #|(ev) => ev.defaultPrevented

///|
#cfg(target="js")
pub extern "js" fn event_prevent_default(ev : Event) -> Unit =
  #|(ev) => ev.preventDefault()

///|
#cfg(target="js")
pub extern "js" fn event_button(ev : Event) -> Int =
  #|(ev) => ev.button

///|
#cfg(target="js")
pub extern "js" fn event_meta_key(ev : Event) -> Bool =
  #|(ev) => ev.metaKey

///|
#cfg(target="js")
pub extern "js" fn event_alt_key(ev : Event) -> Bool =
  #|(ev) => ev.altKey

///|
#cfg(target="js")
pub extern "js" fn event_ctrl_key(ev : Event) -> Bool =
  #|(ev) => ev.ctrlKey

///|
#cfg(target="js")
pub extern "js" fn event_shift_key(ev : Event) -> Bool =
  #|(ev) => ev.shiftKey

///|
#cfg(target="js")
pub extern "js" fn event_composed_path(ev : Event) -> JsArray =
  #|(ev) => ev.composedPath()

///|
#cfg(target="js")
pub extern "js" fn js_array_length(arr : JsArray) -> Int =
  #|(arr) => arr.length

///|
#cfg(target="js")
pub extern "js" fn js_array_get(arr : JsArray, idx : Int) -> Node =
  #|(arr, idx) => arr[idx]
