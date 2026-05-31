///|
let effect_id_counter : Ref[UInt] = @ref.new(0)

///|
fn next_effect_id() -> UInt {
  let id = effect_id_counter.val
  effect_id_counter.val = id + 1U
  id
}

///|
pub struct Effect {
  id : UInt
  callback : () -> Unit
}

///|
fn Effect::run(effect : Ref[Effect]) -> Unit {
  let sub : ASubscriber = {
    id: effect.val.id,
    sub: Some(effect as &Subscriber)
  }

  Observer::with_replace(Some(sub), fn() {
    (effect.val.callback)()
  })
}

///|
pub fn create_effect(f : () -> Unit) -> Unit {
  let effect = @ref.new(Effect::{
    id: next_effect_id(),
    callback: f,
  })

  Effect::run(effect)
}

///|
pub impl ReactiveNode for Ref[Effect] with mark_stale(self) {
  Effect::run(self)
}

///|
#inline
pub impl ReactiveNode for Ref[Effect] with mark_pending(_self) { }

///|
pub impl ReactiveNode for Ref[Effect] with mark_all_pending(self) {
  ReactiveNode::mark_stale(self)
}

///|
#inline
pub impl ReactiveNode for Ref[Effect] with update_value(_self) { false }

///|
pub impl Subscriber for Ref[Effect] with add_source(_self, _source : ASource) -> Unit {
  ()
}

///|
pub impl Subscriber for Ref[Effect] with clean_sources(_self, _subscriber : ASubscriber) -> Unit {
  ()
}
