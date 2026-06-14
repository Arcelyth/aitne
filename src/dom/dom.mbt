using @hashmap { type HashMap}

///|
pub fn dom_create_element(tag : String) -> Element {
  prim_create_element(document(), tag)
}

///|
pub fn dom_create_text_node(text : String) -> Text {
  prim_create_text_node(document(), text)
}

///|
pub fn dom_get_element_by_id(id : String) -> Option[Node] {
  prim_get_element_by_id(document(), id)
}

///|
pub fn dom_get_body() -> Node {
  prim_get_body(document())
}

///|
pub fn on_window_event(ev_name : String, cb : (Event) -> Unit) -> () -> Unit {
  window_add_event_listener(ev_name, cb)
  fn() {
    window_remove_event_listener(ev_name, cb)
  }
}

///|
pub fn option_node_eq(a : Option[Node], b : Option[Node]) -> Bool {
  match (a, b) {
    (Some(n1), Some(n2)) => prim_node_eq(n1, n2)
    (None, None) => true
    _ => false
  }
}

///|
pub fn dom_next_sibling(node : Node) -> Option[Node] {
  let n = prim_next_sibling(node)
  if prim_is_null(n) {
    None
  } else {
    Some(n)
  }
}

///|
pub fn mount_to_body(app : &View) -> RenderState {
  let body_node = dom_get_body()
  let state = app.build() 
  
  state.mount(body_node, dom_null_node()) 
  
  state
}


