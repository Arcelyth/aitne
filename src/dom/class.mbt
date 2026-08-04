///|
using @reactive {type RenderEffect}

///|
pub fn[C] class_val(class : C) -> Class[C] {
  Class(class)
}

///|
pub(all) struct Class[C](C)

///|
pub impl[C : IntoClass] Attribute for Class[C] with fn html_len(_self) -> Int {
  0
}

///|
pub impl[C : IntoClass] Attribute for Class[C] with fn hydrate(
  self,
  el : @ffi.Element,
) -> AttrState {
  self.0.hydrate(el)
}

///|
pub impl[C : IntoClass] Attribute for Class[C] with fn to_html(
  _self,
  _b,
  _c,
  _s,
  _i,
) -> Unit {

}

///|
pub impl[C : IntoClass] Attribute for Class[C] with fn build(
  self,
  el : @ffi.Element,
) -> AttrState {
  self.0.build(el)
}

///|
pub impl[C : IntoClass] Attribute for Class[C] with fn rebuild(
  self,
  state : Ref[AttrState],
) -> Unit {
  self.0.rebuild(state)
}

///|
pub impl[C : IntoClass] Attribute for Class[C] with fn dry_resolve(self) -> Unit {
  self.0.dry_resolve()
}

///|
pub impl[C : IntoClass] Attribute for Class[C] with fn add_attr(
  self,
  attr : &Attribute,
) -> &Attribute {
  (self as &Attribute, attr)
}

///|
pub trait IntoClass {
  fn html_len(Self) -> Int
  fn to_html(Self, style : StringBuilder) -> Unit
  fn build(Self, el : @ffi.Element) -> AttrState
  fn rebuild(Self, state : Ref[AttrState]) -> Unit
  fn hydrate(Self, el : @ffi.Element) -> AttrState
  fn dry_resolve(Self) -> Unit
}

///|
pub impl IntoClass for String with fn html_len(self) -> Int {
  self.length()
}

///|
pub impl IntoClass for String with fn hydrate(self, el : @ffi.Element) -> AttrState {
  AttrState::Pair(AttrState::Element(el), AttrState::Str(self))
}

///|
pub impl IntoClass for String with fn to_html(self, style : StringBuilder) -> Unit {
  style.write_string(self)
}

///|
pub impl IntoClass for String with fn build(self, el : @ffi.Element) -> AttrState {
  @ffi.dom_set_attr(el, "class", self)
  AttrState::Pair(AttrState::Element(el), AttrState::Str(self))
}

///|
pub impl IntoClass for String with fn rebuild(self, state : Ref[AttrState]) -> Unit {
  match state.val {
    AttrState::Pair(AttrState::Element(el), AttrState::Str(old)) =>
      if self != old {
        @ffi.dom_set_attr(el, "class", self)
        state.val = AttrState::Pair(
          AttrState::Element(el),
          AttrState::Str(self),
        )
      }
    _ => ()
  }
}

///|
pub impl IntoClass for String with fn dry_resolve(_self) -> Unit {

}

///|
pub(all) struct RxClass[T](() -> T)

///|
pub fn[T] rx_class(f : () -> T) -> RxClass[T] {
  RxClass(f)
}

///|
pub impl[T : IntoClass] IntoClass for RxClass[T] with fn html_len(_self) -> Int {
  0
}

///|
pub impl[T : IntoClass] IntoClass for RxClass[T] with fn hydrate(
  self,
  el : @ffi.Element,
) -> AttrState {
  RenderEffect(
    RenderEffect::new(prev => {
      let val = (self.0)()
      match prev {
        Some(state) => {
          let r = Ref(state)
          val.rebuild(r)
          r.val
        }
        _ => val.hydrate(el)
      }
    }),
  )
}

///|
pub impl[T : IntoClass] IntoClass for RxClass[T] with fn to_html(
  _self,
  _style : StringBuilder,
) -> Unit {
  ()
}

///|
pub impl[T : IntoClass] IntoClass for RxClass[T] with fn dry_resolve(_self) -> Unit {
  ()
}

///|
pub impl[T : IntoClass] IntoClass for RxClass[T] with fn build(
  self,
  el : @ffi.Element,
) -> AttrState {
  RenderEffect(
    RenderEffect::new(prev => {
      let val = (self.0)()
      match prev {
        Some(state) => {
          let r = Ref(state)
          val.rebuild(r)
          r.val
        }
        _ => val.build(el)
      }
    }),
  )
}

///|
pub impl[T : IntoClass] IntoClass for RxClass[T] with fn rebuild(
  self,
  state : Ref[AttrState],
) -> Unit {
  match state.val {
    RenderEffect(re) => {
      let pre_val = re.val.take_value()
      state.val = RenderEffect(
        RenderEffect::new_with_value(
          prev => {
            let val = (self.0)()
            match prev {
              Some(state) => {
                let r = Ref(state)
                val.rebuild(r)
                r.val
              }
              _ => {
                println("Error: Unreachable")
                panic()
              }
            }
          },
          pre_val,
        ),
      )
    }
    _ => ()
  }
}
