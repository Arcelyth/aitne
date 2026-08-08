///|
let trigger_id_counter : Ref[UInt] = @ref.new(0U)

///|
fn next_trigger_id() -> UInt {
  let id = trigger_id_counter.val
  trigger_id_counter.val = id + 1U
  id
}

///|
pub struct Trigger {
  id : UInt
  subs : @hashset.HashSet[ASubscriber]
} derive(Debug)

///|
pub fn Trigger::new() -> Trigger {
  Trigger::{ id: next_trigger_id(), subs: @hashset.HashSet([]) }
}

///|
pub impl IsDisposed for Trigger with fn is_disposed(_self) -> Bool {
  false
}

///|
pub impl Notify for Trigger with fn notify(self) -> Unit {
  self.subs.each(s => {
    match s.sub {
      Some(sub) => sub.mark_stale()
      None => ()
    }
  })
}

///|
pub impl Notify for Array[Trigger] with fn notify(self) -> Unit {
  for t in self {
    t.notify()
  }
}

///|
pub impl ReactiveNode for Trigger with fn mark_stale(self) {
  self.mark_all_pending()
}

///|
pub impl ReactiveNode for Trigger with fn mark_pending(_self) {

}

///|
pub impl ReactiveNode for Trigger with fn mark_all_pending(self) {
  self.subs.each(fn(sub) {
    match sub.sub {
      Some(node) => node.mark_stale()
      None => ()
    }
  })
}

///|
#inline
pub impl ReactiveNode for Trigger with fn update_value(_self) {
  false
}

///|
pub impl Source for Trigger with fn add_sub(self, sub : ASubscriber) {
  self.subs.add(sub)
}

///|
pub impl Source for Trigger with fn remove_sub(self, sub : ASubscriber) {
  self.subs.remove(sub)
}

///|
pub impl Source for Trigger with fn clear_subs(self) {
  self.subs.clear()
}

///|
pub impl ToASource for Trigger with fn to_asource(self) {
  { id: self.id, src: Some(self) }
}

///|
pub impl Track for Trigger with fn track(self) -> Unit {
  guard !self.is_disposed() else { return }
  match Observer::get() {
    Some(sub) => {
      sub.add_source(self.to_asource())
      self.add_sub(sub)
    }
    _ => ()
  }
}
