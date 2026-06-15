/////|
//pub(all) struct HtmlElement[T, A, C] {
//  tag : T
//  attrs : A
//  children : C
//}
//
/////|
//pub trait ElementType {
//  fn tag(Self) -> String 
//  fn is_self_closing(Self) -> Bool
//}
//
//// ----- Impl Render for HtmlElement
/////|
//pub impl[T: ElementType, A: Attribute, C: Render] Render for HtmlElement[T, A, C] with build(self) -> RenderState {
//  let el = dom_create_element(self.tag.tag())
//
//  let attrs = self.attrs.build(el)
//  println("debug: \{self.tag.tag()}htmlelement build")
//  let children = self.children.build()
//
//  children.mount(el_as_node(el), dom_null_node())
//
//  RenderState::Element({
//    el,
//    attrs,
//    children,
//  })
//}
//
/////|
//pub impl[T: ElementType, A: Attribute, C: Render] Render for HtmlElement[T, A, C] with rebuild(self, state : Ref[RenderState]) -> Unit {
//  match state.val {
//    RenderState::Element(el_state) => {
//      let attr_ref = @ref.new(el_state.attrs)
//      self.attrs.rebuild(attr_ref)
//      el_state.attrs = attr_ref.val
//
//      let children_ref = @ref.new(el_state.children)
//      self.children.rebuild(children_ref)
//      el_state.children = children_ref.val
//    }
//    _ => {()} 
//  }
//}
//
//// ----- 
//
//// ----- Impl RenderHtml for HtmlElement
/////|
//pub impl[T: ElementType, A: Attribute, C: RenderHtml] RenderHtml for HtmlElement[T, A, C] with html_len(self) -> Int {
//  let tag_len = self.tag.tag().length()
//  let attrs_len = self.attrs.html_len()
//  
//  if self.tag.is_self_closing() {
//    // <tag attrs />
//    3 + tag_len + attrs_len
//  } else {
//    // <tag attrs>children</tag>
//    2 + tag_len + attrs_len + self.children.html_len() + 3 + tag_len
//  }
//}
//
/////|
//pub impl[T: ElementType, A: Attribute, C: RenderHtml] RenderHtml for HtmlElement[T, A, C] with to_html_with_buf(self, buf, position) -> Unit {
//  let tag_name = self.tag.tag()
//
//  buf.write_string("<")
//  buf.write_string(tag_name)
//
//  let class_buf = StringBuilder::new()
//  let style_buf = StringBuilder::new()
//  let inner_buf = StringBuilder::new()
//  
//  self.attrs.to_html(buf, class_buf, style_buf, inner_buf)
//
//  if class_buf.to_string().length() > 0 {
//    buf.write_string(" class=\"")
//    buf.write_string(class_buf.to_string())
//    buf.write_string("\"")
//  }
//  if style_buf.to_string().length() > 0 {
//    buf.write_string(" style=\"")
//    buf.write_string(style_buf.to_string())
//    buf.write_string("\"")
//  }
//
//  if self.tag.is_self_closing() {
//    buf.write_string(" />")
//  } else {
//    buf.write_string(">")
//    position.val = Position::FirstChild
//    self.children.to_html_with_buf(buf, position)
//
//    buf.write_string("</")
//    buf.write_string(tag_name)
//    buf.write_string(">")
//  }
//
//  position.val = Position::NextChild
//}
//
//pub fn[T : ElementType, A : Attribute, C : Render] HtmlElement::children(
//  self : HtmlElement[T, A, C],
//  children : Array[&View]
//) -> HtmlElement[T, A, Array[&View]] {
//  HtmlElement::{ tag: self.tag, attrs: self.attrs, children: children}
//}
//
//pub fn[T : ElementType, A : Attribute, C : Render] HtmlElement::add_attr(
//  self : HtmlElement[T, A, C],
//  attr: &Attribute
//) -> HtmlElement[T, &Attribute, C] {
//  println("debug: \{self.tag.tag()} add attr ")
//  HtmlElement::{
//    tag: self.tag,
//    attrs: self.attrs.add_attr(attr),
//    children: self.children
//  }
//}
//
//pub impl Render for Array[&View] with build(self) -> RenderState {
//  let states = []
//  for kid in self {
//    states.push(kid.build())
//  }
//  RenderState::Fragment({ children: states })
//}
//
//pub impl Render for Array[&View] with rebuild(self, state : Ref[RenderState]) -> Unit {
//  match state.val {
//    RenderState::Fragment(frag) => {
//      for i in 0..<self.length() {
//        let child_ref = @ref.new(frag.children[i])
//        self[i].rebuild(child_ref)
//        frag.children[i] = child_ref.val
//      }
//    }
//    _ => ()
//  }
//}
//
//pub impl RenderHtml for Array[&View] with html_len(self) -> Int {
//  let mut len = 0
//  for kid in self { len += kid.html_len() }
//  len
//}
//
//pub impl RenderHtml for Array[&View] with to_html_with_buf(self, buf, pos) -> Unit {
//  for kid in self { kid.to_html_with_buf(buf, pos) }
//}
//
//pub struct TextNode { val : String }
//pub fn text(s : String) -> TextNode { TextNode::{ val: s } }
//
//pub impl Render for TextNode with build(self) -> RenderState {
//  let node = prim_create_text_node(document(), self.val)
//  RenderState::Text(TextState::{ node })
//}
//
//pub impl Render for TextNode with rebuild(_self, _state) -> Unit {}
//pub impl RenderHtml for TextNode with html_len(self) -> Int { self.val.length() }
//pub impl RenderHtml for TextNode with to_html_with_buf(self, buf, _pos) -> Unit {
//  buf.write_string(self.val)
//}
//
//pub struct DynTextNode { getter : () -> String }
//pub fn text_dyn(f : () -> String) -> DynTextNode { DynTextNode::{ getter: f } }
//
//pub impl Render for DynTextNode with build(self) -> RenderState {
//  let node = prim_create_text_node(document(), (self.getter)())
//  @reactive.create_effect(fn() {
//    dom_set_text(text_as_node(node), (self.getter)())
//  })
//  RenderState::Text(TextState::{ node })
//}
//pub impl Render for DynTextNode with rebuild(_self, _state) -> Unit {}
//pub impl RenderHtml for DynTextNode with html_len(_self) -> Int { 0 }
//pub impl RenderHtml for DynTextNode with to_html_with_buf(self, buf, _pos) -> Unit {
//  buf.write_string((self.getter)())
//}
//
/////|
//pub(all) enum EventType {
//  Click
//  Input
//  Change
//  Submit
//  Keydown
//  Keyup
//}
//
/////|
//pub fn EventType::to_string(self : EventType) -> String {
//  match self {
//    Click   => "click"
//    Input   => "input"
//    Change  => "change"
//    Submit  => "submit"
//    Keydown => "keydown"
//    Keyup   => "keyup"
//  }
//}
//
/////|
//pub fn[T : ElementType, A : Attribute, C : Render, P : IntoProperty] HtmlElement::prop(
//  self : HtmlElement[T, A, C], 
//  key : String, 
//  value : P
//) -> HtmlElement[T, &Attribute, C] {
//  self.add_attr(prop(key, value)) 
//}
//
//pub fn[T: ElementType, A: Attribute, C: Render] HtmlElement::on(
//  self: HtmlElement[T, A, C],
//  ev: EventType,
//  fun: (Event) -> Unit
//) -> HtmlElement[T, &Attribute, C] {
//  let desp = EventDesp::{
//    name: ev.to_string(),
//    bubbles: true,
//    capture: false
//  }
//  
//  self.add_attr(on(desp, fun)) 
//}
//
//pub fn[T : ElementType, A : Attribute, C : Render, P : IntoProperty] HtmlElement::attr(
//  self : HtmlElement[T, A, C],
//  key : String,
//  val : P
//) -> HtmlElement[T, &Attribute, C] {
//  println("debug: \{self.tag.tag()}'s attr \{key}")
//  self.prop(key, val)
//}
//
//pub fn[T : ElementType, A : Attribute, C : Render, P : IntoProperty] HtmlElement::value(
//  self : HtmlElement[T, A, C],
//  getter : P
//) -> HtmlElement[T, &Attribute, C] {
//
//  println("debug: \{self.tag.tag()}'s value value")
//  self.prop("value", getter)
//}
//
//pub fn[T : ElementType, A : Attribute, C : Render, S : IntoStyle] HtmlElement::style(
//  self : HtmlElement[T, A, C],
//  style : S
//) -> HtmlElement[T, &Attribute, C] {
//  println("debug: \{self.tag.tag()}'s style ")
//  self.add_attr(get_style(style))
//}



///|
/// A typed HTML element builder.
///
/// `T` is the tag type (e.g. `TagDiv`, `TagButton`).
/// `C` is the child content (starts as `Unit`, set via `.children()`).
/// Attributes are collected in a concrete `AttrList` that supports
/// chaining without type-level gymnastics.
pub(all) struct HtmlElement[T, C] {
  tag : T
  attrs : AttrList
  children : C
}

///|
/// Every element tag knows its HTML name and whether it is self-closing.
pub trait ElementType {
  fn tag(Self) -> String
  fn is_self_closing(Self) -> Bool
}

// ----- AttrList: a concrete collection of attributes -----

///|
/// A flat list of trait-object attributes attached to an element.
pub(all) struct AttrList {
  items : Array[&Attribute]
}

///|
pub fn AttrList::new() -> AttrList {
  AttrList::{ items: [] }
}

///|
fn AttrList::push(self : AttrList, attr : &Attribute) -> AttrList {
  let items = self.items
  AttrList::{ items: items + [attr] }
}

///|
pub impl Attribute for AttrList with fn html_len(self) -> Int {
  let mut len = 0
  for item in self.items {
    len += item.html_len()
  }
  len
}

///|
pub impl Attribute for AttrList with fn to_html(
  self,
  buf : StringBuilder,
  class : StringBuilder,
  style : StringBuilder,
  inner_html : StringBuilder,
) -> Unit {
  for item in self.items {
    item.to_html(buf, class, style, inner_html)
  }
}

///|
pub impl Attribute for AttrList with fn build(self, el : Element) -> AttrState {
  let mut cur = AttrState::None
  for item in self.items {
    cur = AttrState::Pair(cur, item.build(el))
  }
  cur
}

///|
pub impl Attribute for AttrList with fn rebuild(self, state : Ref[AttrState]) -> Unit {
  let mut rem = state.val
  for item in self.items {
    match rem {
      AttrState::Pair(first, rest) => {
        let r = Ref::{ val: first }
        item.rebuild(r)
        rem = rest
        state.val = AttrState::Pair(r.val, rem)
      }
      _ =>
        // Attribute count mismatch — re-build.
        ()
    }
  }
}

///|
pub impl Attribute for AttrList with fn dry_resolve(self) -> Unit {
  for item in self.items {
    item.dry_resolve()
  }
}

///|
pub impl Attribute for AttrList with fn add_attr(self, attr : &Attribute) -> &Attribute {
  self.push(attr)
}

// ----- Render impl for HtmlElement -----

///|
pub impl[T : ElementType, C : Render] Render for HtmlElement[T, C] with fn build(
  self,
) -> RenderState {
  let el = dom_create_element(self.tag.tag())
  let attrs = self.attrs.build(el)
  let children = self.children.build()
  children.mount(el_as_node(el), dom_null_node())
  RenderState::Element(ElementState::{ el, attrs, children })
}

///|
pub impl[T : ElementType, C : Render] Render for HtmlElement[T, C] with fn rebuild(
  self,
  state : Ref[RenderState],
) -> Unit {
  match state.val {
    RenderState::Element(el_state) => {
      let attr_ref = @ref.new(el_state.attrs)
      self.attrs.rebuild(attr_ref)
      el_state.attrs = attr_ref.val

      let children_ref = @ref.new(el_state.children)
      self.children.rebuild(children_ref)
      el_state.children = children_ref.val
    }
    _ => ()
  }
}

// ----- RenderHtml impl for HtmlElement -----

///|
pub impl[T : ElementType, C : RenderHtml] RenderHtml for HtmlElement[T, C] with fn html_len(
  self,
) -> Int {
  let tag_len = self.tag.tag().length()
  let attrs_len = self.attrs.html_len()
  if self.tag.is_self_closing() {
    3 + tag_len + attrs_len
  } else {
    2 + tag_len + attrs_len + self.children.html_len() + 3 + tag_len
  }
}

///|
pub impl[T : ElementType, C : RenderHtml] RenderHtml for HtmlElement[T, C] with fn to_html_with_buf(
  self,
  buf,
  position,
) -> Unit {
  let tag_name = self.tag.tag()
  buf.write_string("<")
  buf.write_string(tag_name)

  let class_buf = StringBuilder::new()
  let style_buf = StringBuilder::new()
  let inner_buf = StringBuilder::new()

  self.attrs.to_html(buf, class_buf, style_buf, inner_buf)

  if class_buf.to_string().length() > 0 {
    buf.write_string(" class=\"")
    buf.write_string(class_buf.to_string())
    buf.write_string("\"")
  }
  if style_buf.to_string().length() > 0 {
    buf.write_string(" style=\"")
    buf.write_string(style_buf.to_string())
    buf.write_string("\"")
  }

  if self.tag.is_self_closing() {
    buf.write_string(" />")
  } else {
    buf.write_string(">")
    position.val = Position::FirstChild
    self.children.to_html_with_buf(buf, position)
    buf.write_string("</")
    buf.write_string(tag_name)
    buf.write_string(">")
  }
  position.val = Position::NextChild
}

// ----- Builder methods -----

///|
/// Replace children of this element.
pub fn[T : ElementType, C : Render] HtmlElement::children(
  self : HtmlElement[T, C],
  kids : Array[&View],
) -> HtmlElement[T, Array[&View]] {
  HtmlElement::{ tag: self.tag, attrs: self.attrs, children: kids }
}

///|
/// Add an attribute to this element.
pub fn[T : ElementType, C : Render] HtmlElement::add_attr(
  self : HtmlElement[T, C],
  attr : &Attribute,
) -> HtmlElement[T, C] {
  HtmlElement::{
    tag: self.tag,
    attrs: self.attrs.push(attr),
    children: self.children,
  }
}

///|
/// Shorthand: set an attribute by key + value.
pub fn[T : ElementType, C : Render, P : IntoProperty] HtmlElement::attr(
  self : HtmlElement[T, C],
  key : String,
  val : P,
) -> HtmlElement[T, C] {
  self.add_attr(prop(key, val))
}

///|
/// Shorthand: set a DOM property.
pub fn[T : ElementType, C : Render, P : IntoProperty] HtmlElement::prop(
  self : HtmlElement[T, C],
  key : String,
  value : P,
) -> HtmlElement[T, C] {
  self.add_attr(prop(key, value))
}

///|
/// Shorthand: bind a reactive value to the "value" property.
pub fn[T : ElementType, C : Render, P : IntoProperty] HtmlElement::value(
  self : HtmlElement[T, C],
  getter : P,
) -> HtmlElement[T, C] {
  self.prop("value", getter)
}

///|
/// Attach an event listener.
pub fn[T : ElementType, C : Render] HtmlElement::on(
  self : HtmlElement[T, C],
  ev : EventType,
  fun : (Event) -> Unit,
) -> HtmlElement[T, C] {
  let desp = EventDesp::{ name: ev.to_string(), bubbles: true, capture: false }
  self.add_attr(on(desp, fun))
}

///|
/// Set inline styles.
pub fn[T : ElementType, C : Render, S : IntoStyle] HtmlElement::style(
  self : HtmlElement[T, C],
  s : S,
) -> HtmlElement[T, C] {
  self.add_attr(style_val(s))
}

// ----- Array[&View] as children -----

///|
pub impl Render for Array[&View] with fn build(self) -> RenderState {
  let states = []
  for kid in self {
    states.push(kid.build())
  }
  RenderState::Fragment(FragmentState::{ children: states })
}

///|
pub impl Render for Array[&View] with fn rebuild(self, state : Ref[RenderState]) -> Unit {
  match state.val {
    RenderState::Fragment(frag) => {
      let len = self.length()
      for i in 0..<len {
        let child_ref = @ref.new(frag.children[i])
        self[i].rebuild(child_ref)
        frag.children[i] = child_ref.val
      }
    }
    _ => ()
  }
}

///|
pub impl RenderHtml for Array[&View] with fn html_len(self) -> Int {
  let mut len = 0
  for kid in self {
    len += kid.html_len()
  }
  len
}

///|
pub impl RenderHtml for Array[&View] with fn to_html_with_buf(self, buf, pos) -> Unit {
  for kid in self {
    kid.to_html_with_buf(buf, pos)
  }
}

// ----- Text nodes -----

///|
/// Static text node.
pub struct TextNode {
  val : String
}

///|
pub fn text(s : String) -> TextNode {
  TextNode::{ val: s }
}

///|
pub impl Render for TextNode with fn build(self) -> RenderState {
  let node = prim_create_text_node(document(), self.val)
  RenderState::Text(TextState::{ node, })
}

///|
pub impl Render for TextNode with fn rebuild(_self, _state) -> Unit {

}

///|
pub impl RenderHtml for TextNode with fn html_len(self) -> Int {
  self.val.length()
}

///|
pub impl RenderHtml for TextNode with fn to_html_with_buf(self, buf, _pos) -> Unit {
  buf.write_string(self.val)
}

// ----- Dynamic (reactive) text node -----

///|
/// Text node that reactively updates when signals it reads change.
pub struct DynTextNode {
  getter : () -> String
}

///|
pub fn text_dyn(f : () -> String) -> DynTextNode {
  DynTextNode::{ getter: f }
}

///|
pub impl Render for DynTextNode with fn build(self) -> RenderState {
  let node = prim_create_text_node(document(), (self.getter)())
  @reactive.create_effect(fn() {
    dom_set_text(text_as_node(node), (self.getter)())
  })
  RenderState::Text(TextState::{ node, })
}

///|
pub impl Render for DynTextNode with fn rebuild(_self, _state) -> Unit {

}

///|
pub impl RenderHtml for DynTextNode with fn html_len(_self) -> Int {
  0
}

///|
pub impl RenderHtml for DynTextNode with fn to_html_with_buf(self, buf, _pos) -> Unit {
  buf.write_string((self.getter)())
}

// ----- Event types -----

///|
pub(all) enum EventType {
  Click
  Input
  Change
  Submit
  Keydown
  Keyup
}

///|
pub fn EventType::to_string(self : EventType) -> String {
  match self {
    Click => "click"
    Input => "input"
    Change => "change"
    Submit => "submit"
    Keydown => "keydown"
    Keyup => "keyup"
  }
}
