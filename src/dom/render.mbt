///|
pub trait Render {
  fn build(Self) -> RenderState 
  fn rebuild(Self, state: Ref[RenderState]) -> Unit 
}

///|
pub trait RenderHtml : Render {
  fn html_len(Self) -> Int
  fn to_html(Self) -> String = _
  fn to_html_with_buf(Self, StringBuilder, Ref[Position]) -> Unit
}

///|
impl RenderHtml with to_html(self) -> String {
  let buf = StringBuilder::new(size_hint=self.html_len())
  self.to_html_with_buf(buf, Ref(Position::FirstChild))
  buf.to_string()
}

///|
pub trait Mountable {
  fn unmount(Self) -> Unit
  fn mount(Self, parent : Node, marker : Node) -> Unit
  fn insert_before(Self, child: &Mountable) -> Bool
  fn elements(Self) -> Array[Node]
}

///|
pub enum Position {
  Current
  FirstChild
  NextChild
  NextChildAfterText
  OnlyChild
  LastChild
} derive(Debug, Eq)

///|
pub enum RenderState {
  None
  Element(ElementState)
  Text(TextState)
  Fragment(FragmentState)
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
pub impl Mountable for RenderState with unmount(self) -> Unit {
  match self {
    Element(s) => dom_remove(el_as_node(s.el))
    Text(s) => dom_remove(text_as_node(s.node))
    Fragment(s) => {
      for child in s.children {
        child.unmount()
      }
    }
    None => ()
  }
}

///|
pub impl Mountable for RenderState with mount(self, parent : Node, marker : Node) -> Unit {
  match self {
    Element(s) => {
      if dom_is_null(marker) {
        dom_append(parent, el_as_node(s.el))
      } else {
        dom_insert_before(parent, el_as_node(s.el), marker)
      }
    }
    Text(s) => {
      if dom_is_null(marker) {
        dom_append(parent, text_as_node(s.node))
      } else {
        dom_insert_before(parent, text_as_node(s.node), marker)
      }
    }
    Fragment(s) => {
      for child in s.children {
        child.mount(parent, marker)
      }
    }
    None => ()
  }
}

///|
pub impl Mountable for RenderState with insert_before(self, child : &Mountable) -> Bool {
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
    _ => false
  }
}

///|
pub impl Mountable for RenderState with elements(self) -> Array[Node] {
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
    None => []
  }
}
