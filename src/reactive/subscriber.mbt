///|
pub trait Subscriber: ReactiveNode {
  fn add_source(Self, source : ASource) -> Unit
  fn clean_sources(Self, subscriber: ASubscriber) -> Unit
}

///|
pub struct ASubscriber {
  id: UInt
  sub: Option[&Subscriber]
}

///|
pub impl Hash for ASubscriber with hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.id)
}

///|
pub impl Eq for ASubscriber with equal(self, other: ASubscriber) -> Bool {
  self.id == other.id
}

/// Implement `Debug` trait for WriteSignal[T]
pub impl Debug for ASubscriber with to_repr(self) -> Repr {
 @debug.Repr::tuple([
    @debug.Repr::string("id"),
    @debug.Repr::string(self.id.to_string()),
  ])
}

///|
pub impl ReactiveNode for ASubscriber with mark_stale(self) -> Unit {
  match self.sub {
    Some(sub) => sub.mark_stale()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASubscriber with mark_pending(self) -> Unit {
  match self.sub {
    Some(sub) => sub.mark_pending()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASubscriber with mark_all_pending(self) -> Unit {
  match self.sub {
    Some(sub) => sub.mark_all_pending()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASubscriber with update_value(self) -> Bool {
  match self.sub {
    Some(sub) => sub.update_value()
    None => false
  }
}

///|
pub impl Subscriber for ASubscriber with add_source(self, source : ASource) -> Unit {
  match self.sub {
    Some(sub) => sub.add_source(source)
    None => ()
  }
}

///|
pub impl Subscriber for ASubscriber with clean_sources(self, subscriber : ASubscriber) -> Unit {
  match self.sub {
    Some(sub) => sub.clean_sources(subscriber)
    None => ()
  }
}

///|
pub impl Notify for ASubscriber with notify(self) -> Unit {
  self.mark_stale()
}
