///|
/// Mount a `View` into the document body.
pub fn mount_to_body(app : () -> &View) -> RenderState {
  let owner = Owner::new()
  owner.with_(() => {
    let body_node = dom_get_body()
    let state = app().build()
    state.mount(body_node, @ffi.dom_null_node())
    state
  })
}

///|
/// Mount a `View` into an element by id.
pub fn mount_to_id(id : String, app : () -> &View) -> RenderState? {
  match dom_get_element_by_id(id) {
    Some(parent) => {
      let owner = Owner::new()
      owner.with_(() => {
        let state = app().build()
        state.mount(parent, @ffi.dom_null_node())
        Some(state)
      })
    }
    None => None
  }
}

///|
/// Create an HTML element.
pub fn dom_create_element(tag : String) -> @ffi.Element {
  @ffi.prim_create_element(document(), tag)
}

///|
/// Create a text node.
pub fn dom_create_text_node(text : String) -> @ffi.Text {
  @ffi.prim_create_text_node(document(), text)
}

///|
/// Get an element by id.
pub fn dom_get_element_by_id(id : String) -> @ffi.Node? {
  @ffi.prim_get_element_by_id(document(), id)
}

///|
/// Get the document body.
pub fn dom_get_body() -> @ffi.Node {
  @ffi.prim_get_body(document())
}

///|
/// Add a window event listener with cleanup.
pub fn on_window_event(ev_name : String, cb : (@ffi.Event) -> Unit) -> () -> Unit {
  @ffi.window_add_event_listener(ev_name, cb)
  fn() { @ffi.window_remove_event_listener(ev_name, cb) }
}

///|
/// Add an event listener to an element.
pub fn add_event_listener(
  el : @ffi.Element,
  name : String,
  cb : (@ffi.Event) -> Unit,
) -> RemoveEventHandler {
  let handle = @ffi.prim_add_event_listener(el, name, cb)
  RemoveEventHandler(Some(handle))
}

///|
/// Get the next sibling of a node, returning `None` if there is none.
pub fn dom_next_sibling(node : @ffi.Node) -> @ffi.Node? {
  let n = @ffi.prim_next_sibling(node)
  if @ffi.prim_is_null(n) {
    None
  } else {
    Some(n)
  }
}

///|
/// Add a capturing event listener.
pub fn add_event_listener_capture(
  el : @ffi.Element,
  name : String,
  cb : (@ffi.Event) -> Unit,
) -> RemoveEventHandler {
  let handle = @ffi.prim_add_event_listener_capture(el, name, cb)
  RemoveEventHandler(Some(handle))
}
