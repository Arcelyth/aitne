///|
pub trait Source: ReactiveNode {
  fn add_sub(Self, subscriber : ASubscriber) -> Unit
  fn remove_sub(Self, subscriber : ASubscriber) -> Unit
  fn clear_subs(Self) -> Unit
}

///|
pub extend &Source with ReactiveNode::{
  mark_stale,
  mark_pending,
  mark_all_pending,
  update_value,
}

///|
pub struct ASource {
  id : UInt
  src : &Source?
}

///|
pub impl Hash for ASource with fn hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.id)
}

///|
pub impl Eq for ASource with fn equal(self, other : ASource) -> Bool {
  self.id == other.id
}

///|
/// Implement `Debug` trait for WriteSignal[T]
pub impl Debug for ASource with fn to_repr(self) -> Repr {
  @debug.Repr::tuple([
    @debug.Repr::string("id"),
    @debug.Repr::string(self.id.to_string()),
  ])
}

///|
pub impl ReactiveNode for ASource with fn mark_stale(self) -> Unit {
  match self.src {
    Some(src) => src.mark_stale()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASource with fn mark_pending(self) -> Unit {
  match self.src {
    Some(src) => src.mark_pending()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASource with fn mark_all_pending(self) -> Unit {
  match self.src {
    Some(src) => src.mark_all_pending()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASource with fn update_value(self) -> Bool {
  match self.src {
    Some(src) => src.update_value()
    None => false
  }
}

///|
pub impl Source for ASource with fn add_sub(self, subscriber : ASubscriber) -> Unit {
  match self.src {
    Some(src) => src.add_sub(subscriber)
    None => ()
  }
}

///|
pub impl Source for ASource with fn remove_sub(self, subscriber : ASubscriber) -> Unit {
  match self.src {
    Some(src) => src.remove_sub(subscriber)
    None => ()
  }
}

///|
pub impl Source for ASource with fn clear_subs(self) -> Unit {
  match self.src {
    Some(src) => src.clear_subs()
    None => ()
  }
}

///|
pub extend ASource with ReactiveNode::{update_value}

///|
pub extend ASource with Source::{remove_sub}
