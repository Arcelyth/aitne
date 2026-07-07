///|
/// A conditional signal that only notifies subscribers when a change
/// in the source signal's value changes whether a key is "selected".
///
/// This provides an O(1) alternative to O(n) patterns like:
///
/// ```moonbit nocheck
/// // O(n) — every row re-checks on every change
/// for row in rows {
///   let is_selected = selected_row.get() == row.id
/// }
/// ```
///
/// With `Selector` each row only re-renders when its OWN selection
/// status changes:
///
/// ```moonbit nocheck
/// let sel = Selector::new(fn() { selected_row.get() })
/// // ...
///
/// let is_selected = sel.selected(row.id) // O(1), only notifies if status flips
/// ```
pub(all) struct Selector[T] {
  /// Per-key signals used purely for notification — their boolean
  /// value is never read; `selected()` computes the result from
  /// the RenderEffect's stored value.
  subs : HashMap[T, RwSignal[Bool]]
  /// RenderEffect that eagerly watches the source function and
  /// fires per-key signals when the selection status toggles.
  effect : Ref[RenderEffect[T]]
}

///|
pub fn[T : Eq + Hash] Selector::new(source : () -> T) -> Selector[T] {
  let subs : HashMap[T, RwSignal[Bool]] = HashMap([])
  let effect = RenderEffect::new_isomorphic((prev : T?) => {
    let next_val = source()
    match prev {
      Some(prev_val) =>
        if prev_val != next_val {
          subs.each(fn(key : T, signal : RwSignal[Bool]) {
            if key == next_val || key == prev_val {
              signal.update(fn(_) { true })
            }
          })
        }
      None =>
        subs.each(fn(key : T, signal : RwSignal[Bool]) {
          if key == next_val {
            signal.update(fn(_) { true })
          }
        })
    }
    next_val
  })
  Selector::{ subs, effect }
}

///|
/// Reactively checks whether `key` is currently selected.
///
/// This method:
///
/// 1. Lazily creates a per-key `RwSignal[Bool]` if one doesn't exist.
/// 2. **Tracks** the per-key signal so the calling observer re-runs
///    only when this specific key's selection status toggles.
/// 3. Return whether `key` matches the current source value by
///    reading the RenderEffect's stored value.
///
/// This is the O(1) guarantee: each key only re-renders when its
/// own status actually changes.
pub fn[T : Eq + Hash] Selector::selected(self : Selector[T], key : T) -> Bool {
  let read = match self.subs.get(key) {
    Some(s) => s
    None => {
      let s = RwSignal::new(false)
      self.subs.set(key, s)
      s
    }
  }

  read.track()

  match self.effect.val.value {
    Some(v) => key == v
    _ => false
  }
}

///|
/// Remove per-key tracking for `key`.
///
/// After removal, `selected(key)` will still return the correct
/// boolean but existing observers will no longer be notified
/// when the key's status changes.
pub fn[T : Eq + Hash] Selector::remove(self : Selector[T], key : T) -> Unit {
  self.subs.remove(key)
}

///|
/// Remove per-key tracking for ALL keys.
pub fn[T] Selector::clear(self : Selector[T]) -> Unit {
  self.subs.clear()
}
