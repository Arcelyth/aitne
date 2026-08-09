///|
#cfg(target="js")
pub extern "js" fn prim_window() -> Window =
  #|() => window

///|
#cfg(target="js")
pub extern "js" fn set_window_href(href : String) -> Unit =
  #|(href) => { window.location.href = href; }

///|
#cfg(target="js")
pub extern "js" fn window_add_event_listener(
  ev_name : String,
  cb : (Event) -> Unit,
) -> EventHandle =
  #|(name, cb) => {
  #|  const f = (e) => cb(e);
  #|  window.addEventListener(name, f);
  #|  return () => window.removeEventListener(name, f);
  #|}

///|
#cfg(target="js")
pub extern "js" fn window_remove_event_listener(handle : EventHandle) -> Unit =
  #|(handle) => { handle(); }

///|
#cfg(target="js")
pub extern "js" fn window_event_listener(
  event : String,
  callback : (Event) -> Unit,
) -> EventHandle =
  #|(event, callback) => {
  #|  window.addEventListener(event, callback);
  #|  return () => window.removeEventListener(event, callback);
  #|}

///|
#cfg(target="js")
pub extern "js" fn set_timeout(cb : () -> Unit, ms : Int) -> TimeoutHandle =
  #|(cb, ms) => setTimeout(cb, ms)

///|
#cfg(target="js")
pub extern "js" fn clear_timeout(handle : TimeoutHandle) -> Unit =
  #|(handle) => clearTimeout(handle)

///|
#cfg(target="js")
pub extern "js" fn set_interval(cb : () -> Unit, ms : Int) -> IntervalHandle =
  #|(cb, ms) => setInterval(cb, ms)

///|
#cfg(target="js")
pub extern "js" fn clear_interval(handle : IntervalHandle) -> Unit =
  #|(handle) => clearInterval(handle)

///|
#cfg(target="js")
pub extern "js" fn request_animation_frame(
  cb : () -> Unit,
) -> AnimationFrameHandle =
  #|(cb) => requestAnimationFrame(cb)

///|
#cfg(target="js")
pub extern "js" fn cancel_animation_frame(
  handle : AnimationFrameHandle,
) -> Unit =
  #|(handle) => cancelAnimationFrame(handle)
