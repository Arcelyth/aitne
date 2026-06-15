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
  fn mount(Self, parent : Node, marker : Node) -> Unit
  fn insert_before(Self, child : &Mountable) -> Bool
  fn elements(Self) -> Array[Node]
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
} derive(Debug, Eq)

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
}

///|
pub struct ElementState {
  el : Element
  mut attrs : AttrState
  mut children : RenderState
}

///|
pub struct TextState {
  node : Text
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
  start_anchor : Node
  end_anchor : Node
  /// Called once after the anchors have been inserted into the DOM.
  /// Receives the parent node so initial children can be mounted.
  init : ((Node) -> Unit)?
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
    start_anchor: dom_create_comment(start_label),
    end_anchor: dom_create_comment(end_label),
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

// ----- Mountable implementations -----

///|
pub impl Mountable for RenderState with fn unmount(self) -> Unit {
  match self {
    Element(s) => dom_remove(el_as_node(s.el))
    Text(s) => dom_remove(text_as_node(s.node))
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
      dom_remove(s.start_anchor)
      dom_remove(s.end_anchor)
    }
    None => ()
  }
}

///|
pub impl Mountable for RenderState with fn mount(
  self,
  parent : Node,
  marker : Node,
) -> Unit {
  match self {
    Element(s) =>
      if dom_is_null(marker) {
        dom_append(parent, el_as_node(s.el))
      } else {
        dom_insert_before(parent, el_as_node(s.el), marker)
      }
    Text(s) =>
      if dom_is_null(marker) {
        dom_append(parent, text_as_node(s.node))
      } else {
        dom_insert_before(parent, text_as_node(s.node), marker)
      }
    Fragment(s) =>
      for child in s.children {
        child.mount(parent, marker)
      }
    MultiBlock(s) => {
      if dom_is_null(marker) {
        dom_append(parent, s.start_anchor)
        dom_append(parent, s.end_anchor)
      } else {
        dom_insert_before(parent, s.start_anchor, marker)
        dom_insert_before(parent, s.end_anchor, marker)
      }
      // Run the init callback (initial render for ForNode / Router).
      match s.init {
        Some(f) => f(parent)
        None => ()
      }
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
      let parent = dom_parent(el_as_node(s.el))
      if dom_is_null(parent) {
        false
      } else {
        child.mount(parent, el_as_node(s.el))
        true
      }
    }
    Text(s) => {
      let parent = dom_parent(text_as_node(s.node))
      if dom_is_null(parent) {
        false
      } else {
        child.mount(parent, text_as_node(s.node))
        true
      }
    }
    MultiBlock(s) => {
      let parent = dom_parent(s.start_anchor)
      if dom_is_null(parent) {
        false
      } else {
        child.mount(parent, s.start_anchor)
        true
      }
    }
    _ => false
  }
}

///|
pub impl Mountable for RenderState with fn elements(self) -> Array[Node] {
  match self {
    Element(s) => [el_as_node(s.el)]
    Text(s) => [text_as_node(s.node)]
    Fragment(s) => {
      let res = []
      for child in s.children {
        res.push_iter(child.elements().iter())
      }
      res
    }
    MultiBlock(s) => {
      // Collect all nodes between the anchors
      let nodes : Array[Node] = [s.start_anchor, s.end_anchor]
      let mut cur = dom_next_sibling(s.start_anchor)
      while true {
        match cur {
          Some(n) => {
            if prim_node_eq(n, s.end_anchor) {
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
    None => []
  }
}

// ----- Unit impls -----

///|
pub impl Render for Unit with fn build(_self) -> RenderState {
  RenderState::None
}

///|
pub impl Render for Unit with fn rebuild(_self, _state : Ref[RenderState]) -> Unit {

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
  RenderState::Text(TextState::{ node, })
}

///|
pub impl Render for String with fn rebuild(self, state : Ref[RenderState]) -> Unit {
  match state.val {
    RenderState::Text(s) => dom_set_text(text_as_node(s.node), self)
    _ => ()
  }
}

///|
pub impl RenderHtml for String with fn html_len(self) -> Int {
  self.length()
}

///|
pub impl RenderHtml for String with fn to_html_with_buf(self, buf, position) -> Unit {
  buf.write_string(self)
  position.val = Position::NextChild
}

// ----- Event handler helpers -----

///|
pub struct RemoveEventHandler(EventHandle?)

///|
pub fn RemoveEventHandler::new(fun : EventHandle) -> RemoveEventHandler {
  RemoveEventHandler(Some(fun))
}

///|
pub fn RemoveEventHandler::invoke(self : RemoveEventHandler) -> Unit {
  match self.0 {
    Some(h) => prim_call_event_handle(h)
    _ => ()
  }
}

///|
pub fn RemoveEventHandler::take(self : Ref[RemoveEventHandler]) -> EventHandle? {
  let res = self.val.0
  self.val = RemoveEventHandler(None)
  res
}

// ----- Utility -----

///|
/// Clear all DOM nodes between two anchor nodes (exclusive of the anchors).
fn clear_between_anchors(start : Node, end : Node) -> Unit {
  let mut cur = dom_next_sibling(start)
  while true {
    match cur {
      Some(n) => {
        if prim_node_eq(n, end) {
          break
        }
        let after = dom_next_sibling(n)
        dom_remove(n)
        cur = after
      }
      None => break
    }
  }
}

///|
/// Public version for use by ForNode / Router effects.
pub fn clear_between(start : Node, end : Node) -> Unit {
  clear_between_anchors(start, end)
}

///|
/// Insert a node before `marker` in its parent.
/// If `marker` is null, appends to `parent`.
pub fn insert_at(parent : Node, node : Node, marker : Node) -> Unit {
  if dom_is_null(marker) {
    dom_append(parent, node)
  } else {
    dom_insert_before(parent, node, marker)
  }
}
