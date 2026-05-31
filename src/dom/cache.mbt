type Window
type Document
type Element
type Event
type TimeoutHandle
type IntervalHandle
type AnimationFrameHandle

///|
/// This a DOM cache for reducing ffi.
pub struct DomCache {
  mut window : Option[Window]
  mut document : Option[Document]
}

let cache : Ref[DomCache] = { val: { window: None, document: None } }

///|
pub fn window() -> Window {
  match cache.val.window {
    Some(w) => w
    None => {
      let w = prim_window()
      cache.val.window = Some(w)
      w
    }
  }
}

///|
pub fn document() -> Document {
  match cache.val.document {
    Some(d) => d
    None => {
      let d = prim_document()
      cache.val.document = Some(d)
      d
    }
  }
}

///| 
pub extern "js" fn prim_window() -> Window =
  #|() => window

///| 
pub extern "js" fn prim_document() -> Document =
  #|() => document

///| 
pub extern "js" fn body() -> Element =
  #|() => document.body

///| 
pub extern "js" fn set_property(el : Element, prop_name : String, value : String) -> Unit =
  #|(el, prop_name, value) => { el[prop_name] = value; }

///| 
pub extern "js" fn remove_property(el : Element, prop_name : String) -> Unit =
  #|(el, prop_name) => { delete el[prop_name]; }

///| 
pub extern "js" fn get_property(el : Element, prop_name : String) -> String =
  #|(el, prop_name) => String(el[prop_name] || "")

///| 
pub extern "js" fn event_target_value(ev : Event) -> String =
  #|(ev) => ev.target ? (ev.target.value || "") : ""

///| 
pub extern "js" fn event_target_checked(ev : Event) -> Bool =
  #|(ev) => ev.target ? !!ev.target.checked : false

///| 
pub extern "js" fn set_timeout(cb : () -> Unit, ms : Int) -> TimeoutHandle =
  #|(cb, ms) => setTimeout(cb, ms)

///| 
pub extern "js" fn clear_timeout(handle : TimeoutHandle) -> Unit =
  #|(handle) => clearTimeout(handle)

///| 
pub extern "js" fn set_interval(cb : () -> Unit, ms : Int) -> IntervalHandle =
  #|(cb, ms) => setInterval(cb, ms)

///| 
pub extern "js" fn clear_interval(handle : IntervalHandle) -> Unit =
  #|(handle) => clearInterval(handle)

///| 
pub extern "js" fn request_animation_frame(cb : () -> Unit) -> AnimationFrameHandle =
  #|(cb) => requestAnimationFrame(cb)

///| 
pub extern "js" fn cancel_animation_frame(handle : AnimationFrameHandle) -> Unit =
  #|(handle) => cancelAnimationFrame(handle)

///| 
pub extern "js" fn window_add_event_listener(ev_name : String, cb : (Event) -> Unit) -> Unit =
  #|(name, cb) => window.addEventListener(name, cb)

///| 
pub extern "js" fn window_remove_event_listener(ev_name : String, cb : (Event) -> Unit) -> Unit =
  #|(name, cb) => window.removeEventListener(name, cb)

///| 
pub fn on_window_event(ev_name : String, cb : (Event) -> Unit) -> () -> Unit {
  window_add_event_listener(ev_name, cb)
  fn() {
    window_remove_event_listener(ev_name, cb)
  }
}
