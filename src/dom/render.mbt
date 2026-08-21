///|
/// The `Render` trait — every view-like value implements this.
/// `build` produces an initial `RenderState`; `rebuild` updates an existing one.
pub trait Render {
  fn build(Self) -> RenderState
  fn rebuild(Self, state : Ref[RenderState]) -> Unit
}

///|
/// Optional HTML serialization for SSR / static generation.
pub trait RenderHtml: Render {
  fn html_len(Self) -> Int
  fn to_html(Self) -> String = _
  fn to_html_with_buf(Self, StringBuilder, Ref[Position]) -> Unit
  fn hydrate(Self, cursor : Cursor, pos : PositionState) -> RenderState
}

///|
impl RenderHtml with fn to_html(self) -> String {
  let buf = StringBuilder::new(size_hint=self.html_len())
  self.to_html_with_buf(buf, Ref(Position::FirstChild))
  buf.to_string()
}

///|
/// A value that can be inserted into the DOM at a specific position.
pub trait Mountable {
  fn unmount(Self) -> Unit
  fn mount(Self, parent : @ffi.Node, marker : @ffi.Node) -> Unit
  fn insert_before(Self, child : &Mountable) -> Bool
  fn elements(Self) -> Array[@ffi.Node]
}

///|
/// Tracks where we are during HTML serialization.
pub enum Position {
  Current
  FirstChild
  NextChild
  NextChildAfterText
  OnlyChild
  LastChild
} derive(Eq, Hash)

///|
/// The runtime representation of a rendered view.
///
/// `Element` / `Text` are straightforward DOM nodes.
/// `Fragment` groups several children.
/// `MultiBlock` represents content between two comment anchors,
/// used by `ForNode` and the router so they can efficiently
/// replace their inner content without touching siblings.
pub enum RenderState {
  None
  Element(ElementState)
  Text(TextState)
  Fragment(FragmentState)
  MultiBlock(MultiBlockState)
  KeyedState(KeyedState)
  Router(RouterState)
  OwnedViewState(OwnedViewState)
  RawNode(@ffi.Node)
}

///|
pub struct ElementState {
  el : @ffi.Element
  mut attrs : AttrState
  mut children : RenderState
}

///|
pub struct TextState {
  node : @ffi.Text
  mut text : String
}

///|
pub fn TextState::new(node : @ffi.Text, text : String) -> TextState {
  { node, text }
}

///|
pub struct FragmentState {
  children : Array[RenderState]
}

///|
/// Content anchored between a start and end comment node.
/// Used by dynamic lists and the router so the reactive
/// effect can clear and re-populate the range without
/// touching siblings.
pub struct MultiBlockState {
  start_anchor : @ffi.Node
  end_anchor : @ffi.Node
  /// Called once after the anchors have been inserted into the DOM.
  /// Receives the parent node so initial children can be mounted.
  init : ((@ffi.Node) -> Unit)?
  /// Cleanup callback registered via `on_cleanup`.
  /// Called when the MultiBlock is unmounted.
  cleanup : (() -> Unit)?
}

///|
/// Create a MultiBlock state with two comment anchors.
pub fn MultiBlockState::new(
  start_label : String,
  end_label : String,
) -> MultiBlockState {
  MultiBlockState::{
    start_anchor: @ffi.dom_create_comment(start_label),
    end_anchor: @ffi.dom_create_comment(end_label),
    init: None,
    cleanup: None,
  }
}

///|
/// Set the cleanup callback for a MultiBlock.
pub fn MultiBlockState::set_cleanup(
  self : MultiBlockState,
  f : () -> Unit,
) -> MultiBlockState {
  { ..self, cleanup: Some(f) }
}

///|
pub struct RouterState {
  path : Ref[String]
  current_url : RwSignal[Url]
  outlets : Ref[Array[RouteContext]]
  view : Ref[RenderState]
  outer_owner : Ref[Owner]
}

// ----- Mountable implementations -----

///|
pub impl Mountable for RenderState with fn unmount(self) -> Unit {
  match self {
    Element(s) => @ffi.dom_remove(@ffi.el_as_node(s.el))
    Text(s) => @ffi.dom_remove(@ffi.text_as_node(s.node))
    Fragment(s) =>
      for child in s.children {
        child.unmount()
      }
    MultiBlock(s) => {
      // Run cleanup (disposes effects, etc.)
      match s.cleanup {
        Some(f) => f()
        None => ()
      }
      // Remove everything between (and including) the anchors
      clear_between_anchors(s.start_anchor, s.end_anchor)
      @ffi.dom_remove(s.start_anchor)
      @ffi.dom_remove(s.end_anchor)
    }
    Router(s) => s.view.val.unmount()
    KeyedState(s) => {
      @ffi.dom_remove(s.marker)
      for child in s.rendered_items {
        match child {
          Some((_, child_state)) => child_state.unmount()
          None => ()
        }
      }
    }
    OwnedViewState(s) => s.unmount()
    RawNode(n) => @ffi.dom_remove(n)
    None => ()
  }
}

///|
pub impl Mountable for RenderState with fn mount(
  self,
  parent : @ffi.Node,
  marker : @ffi.Node,
) -> Unit {
  match self {
    Element(s) =>
      if @ffi.dom_is_null(marker) {
        @ffi.dom_append(parent, @ffi.el_as_node(s.el))
      } else {
        @ffi.dom_insert_before(parent, @ffi.el_as_node(s.el), marker)
      }
    Text(s) =>
      if @ffi.dom_is_null(marker) {
        @ffi.dom_append(parent, @ffi.text_as_node(s.node))
      } else {
        @ffi.dom_insert_before(parent, @ffi.text_as_node(s.node), marker)
      }
    Fragment(s) =>
      for child in s.children {
        child.mount(parent, marker)
      }
    MultiBlock(s) => {
      if @ffi.dom_is_null(marker) {
        @ffi.dom_append(parent, s.start_anchor)
        @ffi.dom_append(parent, s.end_anchor)
      } else {
        @ffi.dom_insert_before(parent, s.start_anchor, marker)
        @ffi.dom_insert_before(parent, s.end_anchor, marker)
      }
      // Run the init callback (initial render for ForNode / Router).
      match s.init {
        Some(f) => f(parent)
        None => ()
      }
    }
    Router(s) => s.view.val.mount(parent, marker)
    KeyedState(s) => {
      s.parent = Some(@ffi.node_as_element(parent))
      @ffi.dom_insert_before(parent, s.marker, marker)
      for child in s.rendered_items {
        match child {
          Some((_, child_state)) => child_state.mount(parent, s.marker)
          None => ()
        }
      }
    }
    OwnedViewState(s) => s.mount(parent, marker)
    RawNode(n) =>
      if @ffi.dom_is_null(marker) {
        @ffi.dom_append(parent, n)
      } else {
        @ffi.dom_insert_before(parent, n, marker)
      }
    None => ()
  }
}

///|
pub impl Mountable for RenderState with fn insert_before(
  self,
  child : &Mountable,
) -> Bool {
  match self {
    Element(s) => {
      let parent = @ffi.dom_parent(@ffi.el_as_node(s.el))
      if @ffi.dom_is_null(parent) {
        false
      } else {
        child.mount(parent, @ffi.el_as_node(s.el))
        true
      }
    }
    Text(s) => {
      let parent = @ffi.dom_parent(@ffi.text_as_node(s.node))
      if @ffi.dom_is_null(parent) {
        false
      } else {
        child.mount(parent, @ffi.text_as_node(s.node))
        true
      }
    }
    MultiBlock(s) => {
      let parent = @ffi.dom_parent(s.start_anchor)
      if @ffi.dom_is_null(parent) {
        false
      } else {
        child.mount(parent, s.start_anchor)
        true
      }
    }
    Router(s) => s.view.val.insert_before(child)
    OwnedViewState(s) => s.insert_before(child)
    RawNode(n) => {
      let p = @ffi.dom_parent(n)
      if @ffi.dom_is_null(p) {
        false
      } else {
        child.mount(p, n)
        true
      }
    }
    KeyedState(s) => {
      let parent = @ffi.dom_parent(s.marker)
      if @ffi.dom_is_null(parent) {
        false
      } else {
        child.mount(parent, s.marker)
        true
      }
    }
    Fragment(s) =>
      if s.children.is_empty() {
        false
      } else {
        s.children[0].insert_before(child)
      }
    None => false
  }
}

///|
pub impl Mountable for RenderState with fn elements(self) -> Array[@ffi.Node] {
  match self {
    Element(s) => [@ffi.el_as_node(s.el)]
    Text(s) => [@ffi.text_as_node(s.node)]
    Fragment(s) => {
      let res : Array[@ffi.Node] = []
      for child in s.children {
        match child {
          Element(es) => res.push(@ffi.el_as_node(es.el))
          Text(ts) => res.push(@ffi.text_as_node(ts.node))
          RawNode(n) => res.push(n)
          _ => res.push_iter(child.elements().iter())
        }
      }
      res
    }
    MultiBlock(s) => {
      // Collect all nodes between the anchors
      let nodes : Array[@ffi.Node] = [s.start_anchor, s.end_anchor]
      let mut cur = dom_next_sibling(s.start_anchor)
      while true {
        match cur {
          Some(n) => {
            if @ffi.prim_node_eq(n, s.end_anchor) {
              break
            }
            nodes.push(n)
            cur = dom_next_sibling(n)
          }
          None => break
        }
      }
      nodes
    }
    Router(s) => s.view.val.elements()
    RawNode(n) => [n]
    None => []
    _ => []
  }
}

///|
pub extend RenderState with Mountable::{unmount, mount, insert_before, elements}

// ----- Unit impls -----

///|
pub impl Render for Unit with fn build(_self) -> RenderState {
  RenderState::None
}

///|
pub impl Render for Unit with fn rebuild(_self, _state : Ref[RenderState]) -> Unit {

}

///|
pub impl RenderHtml for Unit with fn hydrate(_self, _cursor, _pos) -> RenderState {
  RenderState::None
}

///|
pub impl RenderHtml for Unit with fn html_len(_self) -> Int {
  0
}

///|
pub impl RenderHtml for Unit with fn to_html_with_buf(_self, _buf, _position) -> Unit {

}

// ----- String impls -----

///|
pub impl Render for String with fn build(self) -> RenderState {
  let node = dom_create_text_node(self)
  RenderState::Text(TextState::{ node, text: self })
}

///|
pub impl Render for String with fn rebuild(self, state : Ref[RenderState]) -> Unit {
  match state.val {
    RenderState::Text(s) =>
      if s.text != self {
        s.text = self
        @ffi.dom_set_text(@ffi.text_as_node(s.node), self)
      }
    _ => ()
  }
}

///|
pub impl RenderHtml for String with fn html_len(self) -> Int {
  self.length()
}

///|
pub impl RenderHtml for String with fn hydrate(_self, cursor, pos) -> RenderState {
  if pos.get() == Position::FirstChild {
    cursor.child()
  } else {
    cursor.sibling()
  }

  // Placecholder will be inserted between adjacent text nodes. 
  if pos.get() == Position::NextChildAfterText {
    cursor.sibling()
  }

  let curr_node = cursor.current()
  let text_node = if @ffi.is_text_node(curr_node) {
    @ffi.cast_node_to_text(curr_node)
  } else {
    failed_to_cast_text_node(curr_node)
  }

  pos.set(Position::NextChildAfterText)

  RenderState::Text(TextState::{ node: text_node, text: _self })
}

///|
pub impl RenderHtml for String with fn to_html_with_buf(self, buf, position) -> Unit {
  buf.write_string(self)
  position.val = Position::NextChild
}

// ----- Event handler helpers -----

///|
pub struct RemoveEventHandler(@ffi.EventHandle?)

///|
pub fn RemoveEventHandler::new(fun : @ffi.EventHandle) -> RemoveEventHandler {
  RemoveEventHandler(Some(fun))
}

///|
pub fn RemoveEventHandler::invoke(self : RemoveEventHandler) -> Unit {
  match self.0 {
    Some(h) => @ffi.prim_call_event_handle(h)
    _ => ()
  }
}

///|
pub fn RemoveEventHandler::take(
  self : Ref[RemoveEventHandler],
) -> @ffi.EventHandle? {
  let res = self.val.0
  self.val = RemoveEventHandler(None)
  res
}

// ----- Utility -----

///|
/// Clear all DOM nodes between two anchor nodes (exclusive of the anchors).
fn clear_between_anchors(start : @ffi.Node, end : @ffi.Node) -> Unit {
  @ffi.dom_remove_range(start, end)
}

///|
/// Public version for use by ForNode / Router effects.
pub fn clear_between(start : @ffi.Node, end : @ffi.Node) -> Unit {
  clear_between_anchors(start, end)
}

///|
/// Insert a node before `marker` in its parent.
/// If `marker` is null, appends to `parent`.
pub fn insert_at(
  parent : @ffi.Node,
  node : @ffi.Node,
  marker : @ffi.Node,
) -> Unit {
  if @ffi.dom_is_null(marker) {
    @ffi.dom_append(parent, node)
  } else {
    @ffi.dom_insert_before(parent, node, marker)
  }
}
