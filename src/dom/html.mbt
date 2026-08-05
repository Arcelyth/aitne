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
  self.items.push(attr)
  self
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
pub impl Attribute for AttrList with fn hydrate(self, el : @ffi.Element) -> AttrState {
  let mut cur = AttrState::None
  for item in self.items {
    cur = AttrState::Pair(cur, item.hydrate(el))
  }
  cur
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
pub impl Attribute for AttrList with fn build(self, el : @ffi.Element) -> AttrState {
  let mut cur = AttrState::None
  for item in self.items {
    cur = AttrState::Pair(cur, item.build(el))
  }
  cur
}

///|
pub impl Attribute for AttrList with fn rebuild(self, state : Ref[AttrState]) -> Unit {
  let mut rem = state.val
  let r = Ref::{ val: AttrState::None }
  for item in self.items {
    match rem {
      AttrState::Pair(first, rest) => {
        r.val = first
        item.rebuild(r)
        rem = rest
        state.val = AttrState::Pair(r.val, rem)
      }
      _ => ()
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
  children.mount(@ffi.el_as_node(el), @ffi.dom_null_node())
  RenderState::Element(ElementState::{ el, attrs, children })
}

///|
pub impl[T : ElementType, C : Render] Render for HtmlElement[T, C] with fn rebuild(
  self,
  state : Ref[RenderState],
) -> Unit {
  match state.val {
    RenderState::Element(el_state) => {
      let attr_ref = Ref::{ val: el_state.attrs }
      self.attrs.rebuild(attr_ref)
      el_state.attrs = attr_ref.val

      let children_ref = Ref::{ val: el_state.children }
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
  let tag_name = self.tag.tag()
  let tag_len = tag_name.length()
  let attrs_len = self.attrs.html_len()
  if self.tag.is_self_closing() {
    3 + tag_len + attrs_len
  } else {
    5 + tag_len * 2 + attrs_len + self.children.html_len()
  }
}

///|
pub impl[T : ElementType, C : RenderHtml] RenderHtml for HtmlElement[T, C] with fn hydrate(
  self,
  cursor : Cursor,
  pos : PositionState,
) -> RenderState {
  if pos.get() == Position::FirstChild {
    cursor.child()
  } else {
    cursor.sibling()
  }

  if pos.get() == Position::NextChildAfterText {
    cursor.sibling()
  }

  let node = cursor.current()
  let el = @ffi.cast_node_to_element(node)
  let attrs = self.attrs.hydrate(el)

  let children = if self.tag.is_self_closing() {
    RenderState::None
  } else {
    pos.set(Position::FirstChild)
    let children_state = self.children.hydrate(cursor, pos)

    if pos.get() != Position::FirstChild {
      cursor.parent()
    }
    children_state
  }

  pos.set(Position::NextChild)

  RenderState::Element(ElementState::{ el, attrs, children })
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

  let class_str = class_buf.to_string()
  if !class_str.is_empty() {
    buf.write_string(" class=\"")
    buf.write_string(class_str)
    buf.write_string("\"")
  }
  let style_str = style_buf.to_string()
  if !style_str.is_empty() {
    buf.write_string(" style=\"")
    buf.write_string(style_str)
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
pub fn[T, C] HtmlElement::children(
  self : HtmlElement[T, C],
  kids : Array[&View],
) -> HtmlElement[T, Array[&View]] {
  HtmlElement::{ tag: self.tag, attrs: self.attrs, children: kids }
}

///|
/// Add an attribute to this element.
pub fn[T, C] HtmlElement::add_attr(
  self : HtmlElement[T, C],
  attr : &Attribute,
) -> HtmlElement[T, C] {
  let _ = self.attrs.push(attr)
  self
}

///|
/// Shorthand: set a DOM property.
#alias(attr)
pub fn[T, C, P : IntoProperty] HtmlElement::prop(
  self : HtmlElement[T, C],
  key : String,
  value : P,
) -> HtmlElement[T, C] {
  self.add_attr(prop(key, value))
}

///|
pub fn[T, C, Cl : IntoClass] HtmlElement::class(
  self : HtmlElement[T, C],
  class : Cl,
) -> HtmlElement[T, C] {
  self.add_attr(class_val(class))
}

///|
/// Shorthand: bind a reactive value to the "value" property.
pub fn[T, C, P : IntoProperty] HtmlElement::value(
  self : HtmlElement[T, C],
  getter : P,
) -> HtmlElement[T, C] {
  self.prop("value", getter)
}

///|
/// Attach an event listener.
pub fn[T, C] HtmlElement::on(
  self : HtmlElement[T, C],
  ev : EventType,
  fun : (@ffi.Event) -> Unit,
) -> HtmlElement[T, C] {
  let desp = EventDesp::{ name: ev.to_string(), bubbles: true, capture: false }
  self.add_attr(on(desp, fun))
}

///|
/// Set inline styles.
pub fn[T, C, S : IntoStyle] HtmlElement::style(
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
      let child_ref = Ref::{ val: RenderState::None }
      for i in 0..<len {
        child_ref.val = frag.children[i]
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
pub impl RenderHtml for Array[&View] with fn hydrate(
  self,
  cursor : Cursor,
  pos : PositionState,
) -> RenderState {
  let states = []

  for kid in self {
    states.push(RenderHtml::hydrate(kid, cursor, pos))
  }

  RenderState::Fragment(FragmentState::{ children: states })
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
  let node = @ffi.prim_create_text_node(document(), self.val)
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
pub impl RenderHtml for TextNode with fn hydrate(
  _self,
  cursor : Cursor,
  pos : PositionState,
) -> RenderState {
  if pos.get() == Position::FirstChild {
    cursor.child()
  } else {
    cursor.sibling()
  }

  if pos.get() == Position::NextChildAfterText {
    cursor.sibling()
  }

  let curr_node = cursor.current()
  let node = if @ffi.is_text_node(curr_node) {
    @ffi.cast_node_to_text(curr_node)
  } else {
    failed_to_cast_text_node(curr_node)
  }

  pos.set(Position::NextChildAfterText)

  RenderState::Text(TextState::{ node, })
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
  let getter = self.getter
  let node = @ffi.prim_create_text_node(document(), getter())
  let _ = @reactive.Effect::new(fn(_) {
    @ffi.dom_set_text(@ffi.text_as_node(node), getter())
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
pub impl RenderHtml for DynTextNode with fn hydrate(
  self,
  cursor : Cursor,
  pos : PositionState,
) -> RenderState {
  if pos.get() == Position::FirstChild {
    cursor.child()
  } else {
    cursor.sibling()
  }

  if pos.get() == Position::NextChildAfterText {
    cursor.sibling()
  }

  let curr_node = cursor.current()
  let node = if @ffi.is_text_node(curr_node) {
    @ffi.cast_node_to_text(curr_node)
  } else {
    failed_to_cast_text_node(curr_node)
  }

  let getter = self.getter
  let _ = @reactive.Effect::new(fn(_) {
    @ffi.dom_set_text(@ffi.text_as_node(node), getter())
  })

  pos.set(Position::NextChildAfterText)

  RenderState::Text(TextState::{ node, })
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

///|
/// HtmlElement implements View when its children implement both Render and RenderHtml.
pub impl[T : ElementType, C : Render + RenderHtml] View for HtmlElement[T, C] with fn style(
  self,
  s : &IntoStyle,
) -> &View {
  self.style(s)
}

///|
/// Text nodes implement View.
pub impl View for TextNode with fn style(self, _i) -> &View {
  self
}

///|
/// Dynamic text nodes implement View.
pub impl View for DynTextNode with fn style(self, _i) -> &View {
  self
}

///|
pub struct RawNodeView {
  node : @ffi.Node
}

///|
pub fn raw_node(node : @ffi.Node) -> RawNodeView {
  RawNodeView::{ node, }
}

///|
pub impl Render for RawNodeView with fn build(self) -> RenderState {
  RenderState::RawNode(self.node)
}

///|
pub impl Render for RawNodeView with fn rebuild(
  _self,
  _state : Ref[RenderState],
) -> Unit {

}

///|
pub impl RenderHtml for RawNodeView with fn html_len(_self) -> Int {
  0
}

///|
pub impl RenderHtml for RawNodeView with fn to_html_with_buf(
  _self,
  _buf,
  _position,
) -> Unit {

}

///|
pub impl RenderHtml for RawNodeView with fn hydrate(
  self,
  _cursor : Cursor,
  _pos : PositionState,
) -> RenderState {
  RenderState::RawNode(self.node)
}

///|
pub impl View for RawNodeView with fn style(self, _i) -> &View {
  self
}
