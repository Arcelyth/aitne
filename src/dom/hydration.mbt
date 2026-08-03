///|
pub struct PositionState {
  state : Ref[Position]
}

///|
#inline
pub fn PositionState::new(pos : Position) -> PositionState {
  { state: Ref(pos) }
}

///|
#inline
pub fn PositionState::default() -> PositionState {
  { state: Ref(Position::FirstChild) }
}

///|
#inline
pub fn PositionState::set(self : PositionState, pos : Position) -> Unit {
  self.state.val = pos
}

///|
#inline
pub fn PositionState::get(self : PositionState) -> Position {
  self.state.val
}

///|
#inline
pub fn PositionState::deep_clone(self : PositionState) -> PositionState {
  { state: Ref(self.state.val) }
}

///|
pub struct Cursor {
  inner : Ref[@ffi.Node]
}

///|
pub fn Cursor::new(root : @ffi.Node) -> Cursor {
  { inner: Ref(root) }
}

///|
pub fn Cursor::clone(self : Cursor) -> Cursor {
  { inner: self.inner }
}

///|
pub fn Cursor::current(self : Cursor) -> @ffi.Node {
  self.inner.val
}

///|
pub fn Cursor::set(self : Cursor, node : @ffi.Node) -> Unit {
  self.inner.val = node
}

///|
pub fn Cursor::child(self : Cursor) -> Unit {
  match @ffi.first_child_skip_comments(self.inner.val) {
    Some(node) => self.inner.val = node
    None => ()
  }
}

///|
pub fn Cursor::sibling(self : Cursor) -> Unit {
  match @ffi.next_sibling_skip_comments(self.inner.val) {
    Some(node) => self.inner.val = node
    None => ()
  }
}

///|
pub fn Cursor::parent(self : Cursor) -> Unit {
  match @ffi.parent_node(self.inner.val) {
    Some(node) => self.inner.val = node
    None => ()
  }
}

///|
pub fn Cursor::advance_to_placeholder(
  self : Cursor,
  position : PositionState,
) -> Unit {
  if position.get() == Position::FirstChild {
    self.child()
  } else {
    self.sibling()
  }
  position.set(Position::NextChild)
}

///|
pub fn Cursor::next_placeholder(
  self : Cursor,
  position : PositionState,
) -> @ffi.Comment {
  self.advance_to_placeholder(position)
  let marker = self.current()

  if @ffi.is_comment_node(marker) {
    @ffi.cast_node_to_comment(marker)
  } else {
    failed_to_cast_marker_node(marker)
  }
}

///|
let currently_hydrating : Ref[String?] = Ref(None)

///|
pub fn set_currently_hydrating(location : String?) -> Unit {
  currently_hydrating.val = location
}

///|
fn get_hydrating_location() -> String {
  match currently_hydrating.val {
    Some(loc) => loc
    None => "{unknown}"
  }
}

///|
pub fn failed_to_cast_element(tag_name : String, node : @ffi.Node) -> Element {
  let loc = get_hydrating_location()
  let msg1 = "A hydration error occurred while trying to hydrate an element defined at " +
    loc +
    ".\n\nThe framework expected an HTML <" +
    tag_name +
    "> element, but found this instead: "
  let msg2 = "\n\nThe hydration mismatch may have occurred slightly earlier, but this is the first time the framework found a node of an unexpected type."

  @ffi.console_error(msg1, node, msg2)
  panic() // Unrecoverable hydration error
}

///|
pub fn failed_to_cast_marker_node(node : @ffi.Node) -> @ffi.Comment {
  let loc = get_hydrating_location()
  let msg1 = "A hydration error occurred while trying to hydrate an element defined at " +
    loc +
    ".\n\nThe framework expected a marker node, but found this instead: "
  let msg2 = "\n\nThe hydration mismatch may have occurred slightly earlier, but this is the first time the framework found a node of an unexpected type."

  @ffi.console_error(msg1, node, msg2)
  panic()
}

///|
pub fn failed_to_cast_text_node(node : @ffi.Node) -> @ffi.Text {
  let loc = get_hydrating_location()
  let msg1 = "A hydration error occurred while trying to hydrate an element defined at " +
    loc +
    ".\n\nThe framework expected a text node, but found this instead: "
  let msg2 = "\n\nThe hydration mismatch may have occurred slightly earlier, but this is the first time the framework found a node of an unexpected type."

  @ffi.console_error(msg1, node, msg2)
  panic()
}
