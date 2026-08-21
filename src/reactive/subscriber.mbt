///|
pub trait Subscriber: ReactiveNode {
  fn add_source(Self, source : ASource) -> Unit
  fn clean_sources(Self, subscriber : ASubscriber) -> Unit
}

///|
pub extend &Subscriber with ReactiveNode::{
  mark_stale,
  mark_pending,
  mark_all_pending,
  update_value,
}

///|
pub struct ASubscriber {
  id : UInt
  sub : &Subscriber?
}

///|
extend ASubscriber with ReactiveNode::{mark_stale}

///|
pub impl Hash for ASubscriber with fn hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.id)
}

///|
pub impl Eq for ASubscriber with fn equal(self, other : ASubscriber) -> Bool {
  self.id == other.id
}

///|
/// Implement `Debug` trait for WriteSignal[T]
pub impl Debug for ASubscriber with fn to_repr(self) -> Repr {
  @debug.Repr::tuple([
    @debug.Repr::string("id"),
    @debug.Repr::string(self.id.to_string()),
  ])
}

///|
pub impl ReactiveNode for ASubscriber with fn mark_stale(self) -> Unit {
  match self.sub {
    Some(sub) => sub.mark_stale()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASubscriber with fn mark_pending(self) -> Unit {
  match self.sub {
    Some(sub) => sub.mark_pending()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASubscriber with fn mark_all_pending(self) -> Unit {
  match self.sub {
    Some(sub) => sub.mark_all_pending()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASubscriber with fn update_value(self) -> Bool {
  match self.sub {
    Some(sub) => sub.update_value()
    None => false
  }
}

///|
pub impl Subscriber for ASubscriber with fn add_source(self, source : ASource) -> Unit {
  match self.sub {
    Some(sub) => sub.add_source(source)
    None => ()
  }
}

///|
pub impl Subscriber for ASubscriber with fn clean_sources(
  self,
  subscriber : ASubscriber,
) -> Unit {
  match self.sub {
    Some(sub) => sub.clean_sources(subscriber)
    None => ()
  }
}

///|
pub impl Notify for ASubscriber with fn notify(self) -> Unit {
  self.mark_stale()
}

///|
pub impl ReactiveNode for @hashset.HashSet[ASubscriber] with fn mark_stale(self) -> Unit {
  self.each(s => {
    match s.sub {
      Some(sub) => sub.mark_stale()
      None => ()
    }
  })
}

///|
pub impl ReactiveNode for @hashset.HashSet[ASubscriber] with fn mark_pending(
  self,
) -> Unit {
  self.each(s => {
    match s.sub {
      Some(sub) => sub.mark_pending()
      None => ()
    }
  })
}

///|
pub impl ReactiveNode for @hashset.HashSet[ASubscriber] with fn mark_all_pending(
  self,
) -> Unit {
  self.each(s => {
    match s.sub {
      Some(sub) => sub.mark_all_pending()
      None => ()
    }
  })
}

///|
pub impl ReactiveNode for @hashset.HashSet[ASubscriber] with fn update_value(
  self,
) -> Bool {
  let mut updated = false
  self.each(s => {
    match s.sub {
      Some(sub) => if sub.update_value() { updated = true }
      None => ()
    }
  })
  updated
}

///|
pub impl Notify for @hashset.HashSet[ASubscriber] with fn notify(self) -> Unit {
  self.each(s => s.mark_stale())
}

///|
pub extend ASubscriber with Notify::{notify}

///|
pub extend ASubscriber with ReactiveNode::{mark_pending}

///|
pub extend ASubscriber with Subscriber::{add_source}
