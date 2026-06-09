/// Global memo id generator.
let memo_id_counter : Ref[UInt] = @ref.new(0)

///|
fn next_memo_id() -> UInt {
  let id = memo_id_counter.val
  memo_id_counter.val = id + 1
  id
}

///|
pub struct Memo[T] {
  id : UInt
  mut value : Option[T]
  mut state : ReactiveNodeState 
  /// Upstream sources used by this memo.
  sources : HashSet[ASource]
  /// Downstream subscribers depending on this memo.
  subscribers : HashSet[ASubscriber]
  /// Whether this memo has been disposed.
  mut disposed : Bool
  /// Owner used to clean up temporary subscriptions while recomputing.
  owner : Owner
  /// Compute function. Previous value is passed in as None on first run.
  compute : (Option[T]) -> T
  /// Returns true when the value changed.
  changed : (Option[T], Option[T]) -> Bool
}

///|
/// Source side of the reactive graph.
pub impl[T] Source for Memo[T] with add_sub(self, subscriber : ASubscriber) -> Unit {
  self.subscribers.add(subscriber)
}

///|
pub impl[T] Source for Memo[T] with remove_sub(self, subscriber : ASubscriber) -> Unit {
  self.subscribers.remove(subscriber)
}

///|
pub impl[T] Source for Memo[T] with clear_subs(self) -> Unit {
  self.subscribers.clear()
}

///|
/// Reactive node: mark dirty and propagate check to dependents.
pub impl[T] ReactiveNode for Memo[T] with mark_stale(self) -> Unit {
  guard !self.disposed else { return }

  self.state = ReactiveNodeState::Stale
  self.mark_all_pending()
}

///|
/// Reactive node: mark this node as needing a check.
pub impl[T] ReactiveNode for Memo[T] with mark_pending(self) -> Unit {
  guard !self.disposed else { return }

  if self.state != ReactiveNodeState::Stale {
    self.state = ReactiveNodeState::Pending
  }
  self.mark_all_pending()
}

///|
/// Reactive node: propagate check to downstream subscribers.
pub impl[T] ReactiveNode for Memo[T] with mark_all_pending(self) -> Unit {
  guard !self.disposed else { return }

  let subs = self.subscribers.copy()
  for sub in subs {
    sub.mark_pending()
  }
}

///|
/// Reactive node: ensure the memo is updated if needed.
pub impl[T] ReactiveNode for Memo[T] with update_value(self) -> Bool {
  Memo::update_value(self)
}

///|
/// Subscriber side of the reactive graph.
pub impl[T] Subscriber for Memo[T] with add_source(self, source : ASource) -> Unit {
  self.sources.add(source)
}

///|
pub impl[T] Subscriber for Memo[T] with clean_sources(self, subscriber : ASubscriber) -> Unit {
  for source in self.sources {
    source.remove_sub(subscriber)
  }
  self.sources.clear()
}


///|
/// Notify is just mark_stale for memo.
pub impl[T] Notify for Memo[T] with notify(self) -> Unit {
  self.mark_stale()
}

///|
/// Create a memo with default equality comparison.
pub fn[T : Eq] Memo::new(f : (Option[T]) -> T) -> Memo[T] {
  Memo::new_with_compare(
    f,
    fn(old : Option[T], new : Option[T]) -> Bool {
      old != new
    },
  )
}

///|
/// Create a memo with a custom comparison function.
///
/// `changed(old, new)` should return true when the value is different.
pub fn[T] Memo::new_with_compare(
  f : (Option[T]) -> T,
  changed : (Option[T], Option[T]) -> Bool,
) -> Memo[T] {
  let memo = Memo::{
    id: next_memo_id(),
    value: None,
    state: ReactiveNodeState::Stale,
    sources: HashSet([]),
    subscribers: HashSet([]),
    disposed: false,
    owner: Owner::new(),
    compute: f,
    changed: changed,
  }

  // Auto-dispose with the current owner, if any.
  on_cleanup(fn() {
    memo.dispose()
  })

  memo
}

///|
/// Create a memo where the compute function also receives ownership of the previous value.
///
/// This is useful when moving/cloning the previous value is expensive.
pub fn[T] Memo::new_owning(
  f : (Option[T]) -> T,
  changed : (Option[T], Option[T]) -> Bool,
) -> Memo[T] {
  Memo::new_with_compare(f, changed)
}

///|
/// Dispose the memo and detach all reactive edges.
pub fn[T] Memo::dispose(self : Memo[T]) -> Unit {
  guard !self.disposed else { return }

  self.disposed = true

  let sub : ASubscriber = self.to_asubscriber()
  self.clean_sources(sub)
  self.clear_subs()

  self.value = None
  self.state = ReactiveNodeState::Clean
}

///|
pub fn[T] Memo::is_disposed(self : Memo[T]) -> Bool {
  self.disposed
}

///|
pub fn[T] Memo::to_asource(self : Memo[T]) -> ASource {
  ASource::{
    id: self.id,
    src: Some(self as &Source),
  }
}

///|
pub fn[T] Memo::to_asubscriber(self : Memo[T]) -> ASubscriber {
  {
    id: self.id,
    sub: Some(self as &Subscriber),
  }
}

///|
/// Track this memo as a dependency of the current observer.
pub fn[T] Memo::track(self : Memo[T]) -> Unit {
  guard !self.disposed else { return }

  match Observer::get() {
    Some(sub) => {
      sub.add_source(self.to_asource())
      self.add_sub(sub)
    }
    None => ()
  }
}

///|
/// Ensure the memo is up to date if needed.
///
/// Returns true if the memo was recomputed and its value changed.
pub fn[T] Memo::update_value(self : Memo[T]) -> Bool {
  guard !self.disposed else { return false }

  // Fast path.
  match self.state {
    ReactiveNodeState::Clean => {
      return false
    }
    ReactiveNodeState::Stale => {
      // Recompute immediately.
      ()
    }
    ReactiveNodeState::Pending => {
      let sources = self.sources.copy()
      let mut any_dirty = false
      
      for source in sources {
        if source.update_value() || self.state == ReactiveNodeState::Stale {
          any_dirty = true
          break 
        }
      }

      if !any_dirty {
        self.state = ReactiveNodeState::Clean
        return false
      }
    }
  }

  let prev = self.value
  let sub : ASubscriber = self.to_asubscriber()
  self.clean_sources(sub)

  let new_value = self.owner.with_cleanup(fn() {
    Observer::with_replace(Some(sub), fn() {
      (self.compute)(prev)
    })
  })

  let new_opt = Some(new_value)
  let changed = (self.changed)(prev, new_opt)

  self.value = new_opt
  self.state = ReactiveNodeState::Clean

  if changed {
    let subs = self.subscribers.copy()
    for s in subs {
      if !Observer::tobe(s) {
        s.notify()
      }
    }
  }

  changed
}

///|
/// Read the current memo value, computing it if needed.
pub fn[T] Memo::get(self : Memo[T]) -> T {
  self.track()

  // Lazily compute on first read or when dirty/check state requires it.
  let _ = self.update_value()

  match self.value {
    Some(v) => v
    None => panic()
  }
}

///|
/// Read the current memo value without tracking.
pub fn[T] Memo::get_untracked(self : Memo[T]) -> T {
  let _ = self.update_value()

  match self.value {
    Some(v) => v
    None => panic()
  }
}

///|
/// Apply a function to the memo value while tracking.
pub fn[T, U] Memo::with_(self : Memo[T], f : (T) -> U) -> U {
  let v = self.get()
  f(v)
}

///|
/// Apply a function to the memo value without tracking.
pub fn[T, U] Memo::with_untracked(self : Memo[T], f : (T) -> U) -> U {
  let v = self.get_untracked()
  f(v)
}

///|
/// Return whether the cached value exists.
pub fn[T] Memo::has_value(self : Memo[T]) -> Bool {
  match self.value {
    Some(_) => true
    None => false
  }
}
