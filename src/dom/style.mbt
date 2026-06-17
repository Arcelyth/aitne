///|
/// A style attribute value, serialized differently from normal
/// string attributes (accumulated into a style buffer rather
/// than written inline).
pub struct Style[S](S)

///|
pub fn[S : IntoStyle] style_val(s : S) -> Style[S] {
  Style(s)
}

///|
pub impl[S : IntoStyle] Attribute for Style[S] with fn html_len(_self) -> Int {
  0
}

///|
pub impl[S : IntoStyle] Attribute for Style[S] with fn to_html(
  self,
  _b,
  _c,
  style : StringBuilder,
  _i,
) -> Unit {
  self.0.to_html(style)
}

///|
pub impl[S : IntoStyle] Attribute for Style[S] with fn build(self, el : Element) -> AttrState {
  self.0.build(el)
}

///|
pub impl[S : IntoStyle] Attribute for Style[S] with fn rebuild(
  self,
  state : Ref[AttrState],
) -> Unit {
  self.0.rebuild(state)
}

///|
pub impl[S : IntoStyle] Attribute for Style[S] with fn dry_resolve(self) -> Unit {
  self.0.dry_resolve()
}

///|
pub impl[S : IntoStyle] Attribute for Style[S] with fn add_attr(
  self,
  attr : &Attribute,
) -> &Attribute {
  (self as &Attribute, attr)
}

///|
pub trait IntoStyle {
  fn html_len(Self) -> Int
  fn to_html(Self, style : StringBuilder) -> Unit
  fn build(Self, el : Element) -> AttrState
  fn rebuild(Self, state : Ref[AttrState]) -> Unit
  fn dry_resolve(Self) -> Unit
}

///|
pub impl IntoStyle for String with fn html_len(self) -> Int {
  self.length()
}

///|
pub impl IntoStyle for String with fn to_html(self, style : StringBuilder) -> Unit {
  style.write_string(self)
}

///|
pub impl IntoStyle for String with fn build(self, el : Element) -> AttrState {
  dom_set_attr(el, "style", self)
  AttrState::Pair(AttrState::Element(el), AttrState::Str(self))
}

///|
pub impl IntoStyle for String with fn rebuild(self, state : Ref[AttrState]) -> Unit {
  match state.val {
    AttrState::Pair(AttrState::Element(el), AttrState::Str(old)) =>
      if self != old {
        dom_set_attr(el, "style", self)
        state.val = AttrState::Pair(
          AttrState::Element(el),
          AttrState::Str(self),
        )
      }
    _ => ()
  }
}

///|
pub impl IntoStyle for String with fn dry_resolve(_self) -> Unit {

}
