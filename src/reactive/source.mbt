///|
pub trait Source: ReactiveNode {
  fn add_sub(Self, subscriber: ASubscriber) -> Unit
  fn remove_sub(Self, subscriber: ASubscriber) -> Unit
  fn clear_subs(Self) -> Unit
}

///|
pub struct ASource {
  id : UInt
  src : Option[&Source]
}

///|
pub impl Hash for ASource with hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.id)
}

///|
pub impl ReactiveNode for ASource with mark_stale(self) -> Unit {
  match self.src {
    Some(src) => src.mark_stale()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASource with mark_pending(self) -> Unit {
  match self.src {
    Some(src) => src.mark_pending()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASource with mark_all_pending(self) -> Unit {
  match self.src {
    Some(src) => src.mark_all_pending()
    None => ()
  }
}

///|
pub impl ReactiveNode for ASource with update_value(self) -> Bool {
  match self.src {
    Some(src) => src.update_value()
    None => false
  }
}

///|
pub impl Source for ASource with add_sub(self, subscriber : ASubscriber) -> Unit {
  match self.src {
    Some(src) => src.add_sub(subscriber)
    None => ()
  }
}

///|
pub impl Source for ASource with remove_sub(self, subscriber : ASubscriber) -> Unit {
  match self.src {
    Some(src) => src.remove_sub(subscriber)
    None => ()
  }
}

///|
pub impl Source for ASource with clear_subs(self) -> Unit {
  match self.src {
    Some(src) => src.clear_subs()
    None => ()
  }
  
}

