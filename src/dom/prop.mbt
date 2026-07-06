///|
using @reactive {type ReadSignal}

///|
/// A DOM property attribute
pub struct Property[P] {
  key : String
  value : P
}

///|
pub fn[P : IntoProperty] prop(key : String, value : P) -> Property[P] {
  Property::{ key, value }
}

///|
pub impl[P : IntoProperty] Attribute for Property[P] with fn html_len(_self) -> Int {
  0
}

///|
pub impl[P : IntoProperty] Attribute for Property[P] with fn to_html(
  _self,
  _b,
  _c,
  _s,
  _i,
) -> Unit {

}

///|
pub impl[P : IntoProperty] Attribute for Property[P] with fn build(
  self,
  el : @ffi.Element,
) -> AttrState {
  self.value.build(el, self.key)
}

///|
pub impl[P : IntoProperty] Attribute for Property[P] with fn rebuild(
  self,
  state : Ref[AttrState],
) -> Unit {
  self.value.rebuild(state, self.key)
}

///|
pub impl[P : IntoProperty] Attribute for Property[P] with fn dry_resolve(self) -> Unit {
  self.value.dry_resolve()
}

///|
pub impl[P : IntoProperty] Attribute for Property[P] with fn add_attr(
  self,
  attr : &Attribute,
) -> &Attribute {
  (self as &Attribute, attr)
}

///|
pub trait IntoProperty {
  fn html_len(Self) -> Int
  fn to_html(
    Self,
    buf : StringBuilder,
    class : StringBuilder,
    style : StringBuilder,
    inner_html : StringBuilder,
  ) -> Unit
  fn build(Self, el : @ffi.Element, key : String) -> AttrState
  fn rebuild(Self, state : Ref[AttrState], key : String) -> Unit
  fn dry_resolve(Self) -> Unit
}

// ----- String property -----

///|
pub impl IntoProperty for String with fn html_len(self) -> Int {
  self.length()
}

///|
pub impl IntoProperty for String with fn to_html(
  self,
  buf,
  _class,
  _style,
  _inner_html,
) -> Unit {
  buf.write_string(self)
}

///|
pub impl IntoProperty for String with fn build(self, el, key) -> AttrState {
  @ffi.dom_set_prop(@ffi.el_as_node(el), key, self)
  AttrState::Element(el)
}

///|
pub impl IntoProperty for String with fn rebuild(self, state, key) -> Unit {
  match state.val {
    AttrState::Element(el) => @ffi.dom_set_prop(@ffi.el_as_node(el), key, self)
    _ => ()
  }
}

///|
pub impl IntoProperty for String with fn dry_resolve(_self) -> Unit {

}

// ----- Reactive signal property (updates via effect) -----

///|
pub impl[S : Show] IntoProperty for ReadSignal[S] with fn html_len(_self) -> Int {
  0
}

///|
pub impl[S : Show] IntoProperty for ReadSignal[S] with fn to_html(
  _self,
  _buf,
  _class,
  _style,
  _inner_html,
) -> Unit {

}

///|
pub impl[S : Show] IntoProperty for ReadSignal[S] with fn build(self, el, key) -> AttrState {
  let _ = @reactive.Effect::new(fn(_) {
    let val = self.get()
    @ffi.dom_set_prop(@ffi.el_as_node(el), key, val.to_string())
  })
  AttrState::None
}

///|
pub impl[S : Show] IntoProperty for ReadSignal[S] with fn rebuild(
  _self,
  _state,
  _key,
) -> Unit {

}

///|
pub impl[S : Show] IntoProperty for ReadSignal[S] with fn dry_resolve(_self) -> Unit {

}
