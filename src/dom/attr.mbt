pub enum AttrState {
  None
  Str(String)
  Dynamic(String)
  Element(Element)
  Pair(AttrState, AttrState) 
}

pub trait AttributeKey {
  fn get_key(Self) -> String
}

pub trait AttributeValue {
  fn html_len(Self) -> Int
  fn to_html(Self, key : String, buf : StringBuilder) -> Unit
  fn build(Self, key : String, el : Element) -> AttrState
  fn rebuild(Self, key : String, state : Ref[AttrState]) -> Unit
  fn dry_resolve(Self) -> Unit
}

pub trait Attribute {
  fn html_len(Self) -> Int
  fn to_html(Self, buf : StringBuilder, class : StringBuilder, style : StringBuilder, inner_html : StringBuilder) -> Unit
  fn build(Self, el : Element) -> AttrState
  fn rebuild(Self, state : Ref[AttrState]) -> Unit
  fn dry_resolve(Self) -> Unit
}

pub impl Attribute for Unit with html_len(_self) -> Int { 0 }
pub impl Attribute for Unit with to_html(_self, _b, _c, _s, _i) -> Unit {}
pub impl Attribute for Unit with build(_self, _el) -> AttrState { AttrState::None }
pub impl Attribute for Unit with rebuild(_self, _state) -> Unit {}
pub impl Attribute for Unit with dry_resolve(_self) -> Unit {}

pub impl AttributeValue for Unit with html_len(_self) -> Int { 0 }
pub impl AttributeValue for Unit with to_html(_self, _k, _b) -> Unit {}
pub impl AttributeValue for Unit with build(_self, _k, _el) -> AttrState { AttrState::None }
pub impl AttributeValue for Unit with rebuild(_self, _k, _state) -> Unit {}
pub impl AttributeValue for Unit with dry_resolve(_self) -> Unit {}

pub impl AttributeValue for String with html_len(self) -> Int { self.length() }

pub impl AttributeValue for String with to_html(self, key : String, buf : StringBuilder) -> Unit {
  buf.write(' ')
  buf.write(key)
  buf.write("=\"")
  buf.write(@escape.escape_double_quoted(self))
  buf.write('"')
}

pub impl AttributeValue for String with build(self, key : String, el : Element) -> AttrState { 
  dom_set_attr(el, key, self)
  AttrState::Pair(AttrState::Element(el), AttrState::Str(self))
}
pub impl AttributeValue for String with rebuild(self, key : String, state : Ref[AttrState]) -> Unit {
  match state.val {
    AttrState::Pair(Element(el), AttrState::Str(pre_v)) => {
      if self != pre_v {
        dom_set_attr(el, key, self)
        state.val = AttrState::Pair(AttrState::Element(el), AttrState::Str(self))
      }
    }
    _ => () 
  }
}
pub impl AttributeValue for String with dry_resolve(_self) -> Unit {}

pub struct AttrPair[A, B] {
  left : A
  right : B
}

pub impl[A : Attribute, B : Attribute] Attribute for AttrPair[A, B] with html_len(self) -> Int {
  self.left.html_len() + self.right.html_len()
}

pub impl[A : Attribute, B : Attribute] Attribute for AttrPair[A, B] with to_html(self, buf, class, style, inner_html) -> Unit {
  self.left.to_html(buf, class, style, inner_html)
  self.right.to_html(buf, class, style, inner_html)
}

pub impl[A : Attribute, B : Attribute] Attribute for AttrPair[A, B] with build(self, el) -> AttrState {
  AttrState::Pair(self.left.build(el), self.right.build(el))
}

pub impl[A : Attribute, B : Attribute] Attribute for AttrPair[A, B] with rebuild(self, state) -> Unit {
  match state.val {
    AttrState::Pair(left_state, right_state) => {
      let l_ref = Ref::{ val: left_state }
      let r_ref = Ref::{ val: right_state }
      self.left.rebuild(l_ref)
      self.right.rebuild(r_ref)
      state.val = AttrState::Pair(l_ref.val, r_ref.val)
    }
    _ => ()
  }
}

pub impl[A : Attribute, B : Attribute] Attribute for AttrPair[A, B] with dry_resolve(self) -> Unit {
  self.left.dry_resolve()
  self.right.dry_resolve()
}

pub trait AddAttr {
  fn add_attr(Self, new_attr : &Attribute) -> AttrPair[Self, &Attribute]
}

pub impl[K : AttributeKey, V : AttributeValue] AddAttr for Attr[K, V] with add_attr(self, new_attr : &Attribute) -> AttrPair[Attr[K, V], &Attribute] {
  AttrPair::{ left: self, right: new_attr}
}

pub(all) struct Attr[K, V] {
  key : K
  value : V
}

pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with html_len(self) -> Int {
  self.key.get_key().length() + 3 + self.value.html_len()
}

pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with to_html(self, buf, _class, _style, _inner_html) -> Unit {
  self.value.to_html(self.key.get_key(), buf)
}

pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with build(self, el) -> AttrState {
  self.value.build(self.key.get_key(), el)
}

pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with rebuild(self, state) -> Unit {
  self.value.rebuild(self.key.get_key(), state)
}

pub impl[K : AttributeKey, V : AttributeValue] Attribute for Attr[K, V] with dry_resolve(self) -> Unit {
  self.value.dry_resolve()
}
