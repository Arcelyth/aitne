///|
using @reactive {type Owner}

///|
/// An event listener attribute bound to an element.
pub struct On {
  event : EventDesp
  owner : Owner
  fun : (@ffi.Event) -> Unit
}

///|
/// Create an event listener attribute.
pub fn on(event : EventDesp, fun : (@ffi.Event) -> Unit) -> On {
  On::{ event, owner: Owner::current_with_default(), fun }
}

///|
/// Attach this event listener to an element (no capture).
fn On::attach(self : On, el : @ffi.Element) -> RemoveEventHandler {
  let wrapped_fun = fn(ev : @ffi.Event) {
    Owner::with_(self.owner, fn() { (self.fun)(ev) })
  }
  add_event_listener(el, self.event.name, wrapped_fun)
}

///|
/// Attach this event listener with capture phase.
fn On::attach_capture(self : On, el : @ffi.Element) -> RemoveEventHandler {
  let wrapped_fun = fn(ev : @ffi.Event) {
    Owner::with_(self.owner, fn() { (self.fun)(ev) })
  }
  add_event_listener_capture(el, self.event.name, wrapped_fun)
}

///|
pub impl Attribute for On with fn html_len(_self) -> Int {
  0
}

///|
pub impl Attribute for On with fn to_html(_self, _b, _c, _s, _i) -> Unit {

}

///|
pub impl Attribute for On with fn build(self, el : @ffi.Element) -> AttrState {
  let cleanup = if self.event.capture {
    self.attach_capture(el)
  } else {
    self.attach(el)
  }
  AttrState::Pair(AttrState::Element(el), AttrState::EventBound(cleanup))
}

///|
pub impl Attribute for On with fn rebuild(self, state : Ref[AttrState]) -> Unit {
  match state.val {
    AttrState::Pair(AttrState::Element(el), AttrState::EventBound(old_cleanup)) => {
      // Remove old listener and attach new one
      old_cleanup.invoke()
      let new_cleanup = if self.event.capture {
        self.attach_capture(el)
      } else {
        self.attach(el)
      }
      state.val = AttrState::Pair(
        AttrState::Element(el),
        AttrState::EventBound(new_cleanup),
      )
    }
    _ => ()
  }
}

///|
pub impl Attribute for On with fn dry_resolve(_self) -> Unit {

}

///|
pub impl Attribute for On with fn add_attr(self, attr : &Attribute) -> &Attribute {
  (self as &Attribute, attr)
}

///|
pub(all) struct EventDesp {
  name : String
  bubbles : Bool
  capture : Bool
}
