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

///|
pub trait Attribute {
  fn html_len(Self) -> Int
  fn to_html(Self, buf : StringBuilder, class : StringBuilder, style : StringBuilder) -> Unit
  fn build(Self, Element) -> AttrState
  fn rebuild(Self, Ref[AttrState]) -> Unit
}

///|
pub enum AttrState {
  None
  Static(Node)
  Dynamic(Effect)
  Event(EventHandle)
}

///|
pub(all) struct AttrStateList {
  states : Array[AttrState]
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
  
  self.attrs.to_html(buf, class_buf, style_buf)

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

// ----- 
