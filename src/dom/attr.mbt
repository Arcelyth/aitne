///|
/// The runtime state stored alongside a rendered element so 
/// that attribute rebuilds can diff old vs. new values.
pub enum AttrState {
  None
  Str(String)
  Bool(Bool)
  Element(@ffi.Element)
  Pair(AttrState, AttrState)
  RenderEffect(Ref[RenderEffect[AttrState]])
  EventBound(RemoveEventHandler)
}

///|
/// Key half of an attribute — usually the attribute / property name.
pub trait AttributeKey {
  fn get_key(Self) -> String
}

///|
/// Value half of an attribute.
pub trait AttributeValue {
  fn html_len(Self) -> Int
  fn to_html(Self, key : String, buf : StringBuilder) -> Unit
  fn build(Self, key : String, el : @ffi.Element) -> AttrState
  fn rebuild(Self, key : String, state : Ref[AttrState]) -> Unit
  fn dry_resolve(Self) -> Unit
}

///|
/// A complete attribute (key + value pair) that can be attached to an `HtmlElement`.
pub trait Attribute {
  fn html_len(Self) -> Int
  fn to_html(
    Self,
    buf : StringBuilder,
    class : StringBuilder,
    style : StringBuilder,
    inner_html : StringBuilder,
  ) -> Unit
  fn build(Self, el : @ffi.Element) -> AttrState
  fn rebuild(Self, state : Ref[AttrState]) -> Unit
  fn dry_resolve(Self) -> Unit
  fn add_attr(Self, attr : &Attribute) -> &Attribute
}

// ----- Unit attribute (empty) -----

///|
pub impl Attribute for Unit with fn html_len(_self) -> Int {
  0
}

///|
pub impl Attribute for Unit with fn to_html(_self, _b, _c, _s, _i) -> Unit {

}

///|
pub impl Attribute for Unit with fn build(_self, _el) -> AttrState {
  AttrState::None
}

///|
pub impl Attribute for Unit with fn rebuild(_self, _state) -> Unit {

}

///|
pub impl Attribute for Unit with fn dry_resolve(_self) -> Unit {

}

///|
pub impl Attribute for Unit with fn add_attr(_self, attr : &Attribute) -> &Attribute {
  attr
}

// ----- Unit attribute value -----

///|
pub impl AttributeValue for Unit with fn html_len(_self) -> Int {
  0
}

///|
pub impl AttributeValue for Unit with fn to_html(_self, _k, _b) -> Unit {

}

///|
pub impl AttributeValue for Unit with fn build(_self, _k, _el) -> AttrState {
  AttrState::None
}

///|
pub impl AttributeValue for Unit with fn rebuild(_self, _k, _state) -> Unit {

}

///|
pub impl AttributeValue for Unit with fn dry_resolve(_self) -> Unit {

}

// ----- String attribute key -----

///|
pub impl AttributeKey for String with fn get_key(self) -> String {
  self
}

// ----- Bool attribute value -----

///|
pub impl AttributeValue for Bool with fn html_len(_self) -> Int {
  0
}

///|
pub impl AttributeValue for Bool with fn to_html(
  self,
  key : String,
  buf : StringBuilder,
) -> Unit {
  if self {
    buf.write_char(' ')
    buf.write_string(key)
  }
}

///|
pub impl AttributeValue for Bool with fn build(self, key : String, el : @ffi.Element) -> AttrState {
  if self {
    @ffi.dom_set_attr(el, key, "")
  }
  AttrState::Pair(AttrState::Element(el), AttrState::Bool(self))
}

///|
pub impl AttributeValue for Bool with fn rebuild(
  self,
  key : String,
  state : Ref[AttrState],
) -> Unit {
  match state.val {
    AttrState::Pair(Element(el), AttrState::Bool(pre_v)) =>
      if self != pre_v {
        if self {
          @ffi.dom_set_attr(el, key, "")
        } else {
          @ffi.dom_remove_attr(el, key)
        }
        state.val = AttrState::Pair(
          AttrState::Element(el),
          AttrState::Bool(self),
        )
      }
    _ => ()
  }
}

///|
pub impl AttributeValue for Bool with fn dry_resolve(_self) -> Unit {

}

// ----- String attribute value -----

///|
pub impl AttributeValue for String with fn html_len(self) -> Int {
  self.length()
}

///|
pub impl AttributeValue for String with fn to_html(
  self,
  key : String,
  buf : StringBuilder,
) -> Unit {
  buf.write_char(' ')
  buf.write_string(key)
  buf.write_string("=\"")
  buf.write_string(@escape.escape_double_quoted(self))
  buf.write_char('"')
}

///|
pub impl AttributeValue for String with fn build(
  self,
  key : String,
  el : @ffi.Element,
) -> AttrState {
  @ffi.dom_set_attr(el, key, self)
  AttrState::Pair(AttrState::Element(el), AttrState::Str(self))
}

///|
pub impl AttributeValue for String with fn rebuild(
  self,
  key : String,
  state : Ref[AttrState],
) -> Unit {
  match state.val {
    AttrState::Pair(Element(el), AttrState::Str(pre_v)) =>
      if self != pre_v {
        @ffi.dom_set_attr(el, key, self)
        state.val = AttrState::Pair(
          AttrState::Element(el),
          AttrState::Str(self),
        )
      }
    _ => ()
  }
}

///|
pub impl AttributeValue for String with fn dry_resolve(_self) -> Unit {

}

// ----- Attr[K, V] — a single key-value attribute -----

///|
pub(all) struct Attr[K, V](K, V)

///|
pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with fn html_len(
  self,
) -> Int {
  self.0.get_key().length() + 3 + self.1.html_len()
}

///|
pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with fn to_html(
  self,
  buf,
  _class,
  _style,
  _inner_html,
) -> Unit {
  self.1.to_html(self.0.get_key(), buf)
}

///|
pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with fn build(
  self,
  el,
) -> AttrState {
  self.1.build(self.0.get_key(), el)
}

///|
pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with fn rebuild(
  self,
  state,
) -> Unit {
  self.1.rebuild(self.0.get_key(), state)
}

///|
pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with fn dry_resolve(
  self,
) -> Unit {
  self.1.dry_resolve()
}

///|
pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with fn add_attr(
  self,
  attr : &Attribute,
) -> &Attribute {
  (self as &Attribute, attr)
}

// ----- Pair (A, B) — compose two attributes -----

///|
pub impl[A : Attribute, B : Attribute] Attribute for (A, B) with fn html_len(
  self,
) -> Int {
  self.0.html_len() + self.1.html_len()
}

///|
pub impl[A : Attribute, B : Attribute] Attribute for (A, B) with fn to_html(
  self,
  buf,
  class,
  style,
  inner_html,
) -> Unit {
  self.0.to_html(buf, class, style, inner_html)
  self.1.to_html(buf, class, style, inner_html)
}

///|
pub impl[A : Attribute, B : Attribute] Attribute for (A, B) with fn build(
  self,
  el,
) -> AttrState {
  AttrState::Pair(self.0.build(el), self.1.build(el))
}

///|
pub impl[A : Attribute, B : Attribute] Attribute for (A, B) with fn rebuild(
  self,
  state,
) -> Unit {
  match state.val {
    AttrState::Pair(s0, s1) => {
      let r0 = Ref::{ val: s0 }
      let r1 = Ref::{ val: s1 }
      self.0.rebuild(r0)
      self.1.rebuild(r1)
      state.val = AttrState::Pair(r0.val, r1.val)
    }
    _ => ()
  }
}

///|
pub impl[A : Attribute, B : Attribute] Attribute for (A, B) with fn dry_resolve(
  self,
) -> Unit {
  self.0.dry_resolve()
  self.1.dry_resolve()
}

///|
pub impl[A : Attribute, B : Attribute] Attribute for (A, B) with fn add_attr(
  self,
  attr : &Attribute,
) -> &Attribute {
  (self as &Attribute, attr)
}
