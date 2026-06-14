///|
pub(all) struct HtmlElement[T, A, C] {
  tag : T
  attrs : A
  children : C
}

///|
pub trait ElementType {
  fn tag(Self) -> String 
  fn is_self_closing(Self) -> Bool
}

// ----- Impl Render for HtmlElement
///|
pub impl[T: ElementType, A: Attribute, C: Render] Render for HtmlElement[T, A, C] with build(self) -> RenderState {
  let el = dom_create_element(self.tag.tag())

  let attrs = self.attrs.build(el)

  let children = self.children.build()

  children.mount(el_as_node(el), dom_null_node())

  RenderState::Element({
    el,
    attrs,
    children,
  })
}

///|
pub impl[T: ElementType, A: Attribute, C: Render] Render for HtmlElement[T, A, C] with rebuild(self, state : Ref[RenderState]) -> Unit {
  match state.val {
    RenderState::Element(el_state) => {
      let attr_ref = @ref.new(el_state.attrs)
      self.attrs.rebuild(attr_ref)
      el_state.attrs = attr_ref.val

      let children_ref = @ref.new(el_state.children)
      self.children.rebuild(children_ref)
      el_state.children = children_ref.val
    }
    _ => {()} 
  }
}

// ----- 

// ----- Impl RenderHtml for HtmlElement
///|
pub impl[T: ElementType, A: Attribute, C: RenderHtml] RenderHtml for HtmlElement[T, A, C] with html_len(self) -> Int {
  let tag_len = self.tag.tag().length()
  let attrs_len = self.attrs.html_len()
  
  if self.tag.is_self_closing() {
    // <tag attrs />
    3 + tag_len + attrs_len
  } else {
    // <tag attrs>children</tag>
    2 + tag_len + attrs_len + self.children.html_len() + 3 + tag_len
  }
}

///|
pub impl[T: ElementType, A: Attribute, C: RenderHtml] RenderHtml for HtmlElement[T, A, C] with to_html_with_buf(self, buf, position) -> Unit {
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

pub fn[T : ElementType, A : Attribute, C : Render] HtmlElement::children(
  self : HtmlElement[T, A, C],
  children : Array[&View]
) -> HtmlElement[T, A, Array[&View]] {
  HtmlElement::{ tag: self.tag, attrs: self.attrs, children: children}
}

pub struct EventAttr {
  ev_name : EventType
  handler : (Event) -> Unit
}

pub impl Attribute for EventAttr with build(self, el) -> AttrState {
  dom_add_event(el_as_node(el), self.ev_name.to_string(), self.handler)
  AttrState::None 
}
pub impl Attribute for EventAttr with rebuild(_self, _state) -> Unit {}
pub impl Attribute for EventAttr with html_len(_self) -> Int { 0 }
pub impl Attribute for EventAttr with to_html(_self, _b, _cb, _sb, _ib) -> Unit {}
pub impl Attribute for EventAttr with dry_resolve(_self) -> Unit {}

pub fn[T : ElementType, A : Attribute, C : Render] HtmlElement::on(
  self : HtmlElement[T, A, C],
  ev : EventType,
  handler : (Event) -> Unit
) -> HtmlElement[T, AttrPair[A, EventAttr], C] {
  {
    tag: self.tag,
    attrs: AttrPair::{ 
      left: self.attrs, 
      right: EventAttr::{ ev_name: ev, handler } 
    },
    children: self.children
  }
}

pub impl Render for Array[&View] with build(self) -> RenderState {
  let states = []
  for kid in self {
    states.push(kid.build())
  }
  RenderState::Fragment({ children: states })
}

pub impl Render for Array[&View] with rebuild(self, state : Ref[RenderState]) -> Unit {
  match state.val {
    RenderState::Fragment(frag) => {
      for i in 0..<self.length() {
        let child_ref = @ref.new(frag.children[i])
        self[i].rebuild(child_ref)
        frag.children[i] = child_ref.val
      }
    }
    _ => ()
  }
}

pub impl RenderHtml for Array[&View] with html_len(self) -> Int {
  let mut len = 0
  for kid in self { len += kid.html_len() }
  len
}

pub impl RenderHtml for Array[&View] with to_html_with_buf(self, buf, pos) -> Unit {
  for kid in self { kid.to_html_with_buf(buf, pos) }
}

pub struct TextNode { val : String }
pub fn text(s : String) -> TextNode { TextNode::{ val: s } }

pub impl Render for TextNode with build(self) -> RenderState {
  let node = prim_create_text_node(document(), self.val)
  RenderState::Text({ node })
}

pub impl Render for TextNode with rebuild(_self, _state) -> Unit {}
pub impl RenderHtml for TextNode with html_len(self) -> Int { self.val.length() }
pub impl RenderHtml for TextNode with to_html_with_buf(self, buf, _pos) -> Unit {
  buf.write_string(self.val)
}

pub struct DynTextNode { getter : () -> String }
pub fn text_dyn(f : () -> String) -> DynTextNode { DynTextNode::{ getter: f } }

pub impl Render for DynTextNode with build(self) -> RenderState {
  let node = prim_create_text_node(document(), (self.getter)())
  @reactive.create_effect(fn() {
    dom_set_text(text_as_node(node), (self.getter)())
  })
  RenderState::Text({ node })
}
pub impl Render for DynTextNode with rebuild(_self, _state) -> Unit {}
pub impl RenderHtml for DynTextNode with html_len(_self) -> Int { 0 }
pub impl RenderHtml for DynTextNode with to_html_with_buf(self, buf, _pos) -> Unit {
  buf.write_string((self.getter)())
}

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
    Click   => "click"
    Input   => "input"
    Change  => "change"
    Submit  => "submit"
    Keydown => "keydown"
    Keyup   => "keyup"
  }
}
