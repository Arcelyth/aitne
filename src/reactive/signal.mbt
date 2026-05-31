///|
/// Simple signal id generator.
let signal_id_counter : Ref[UInt] = @ref.new(0)

fn next_signal_id() -> UInt {
  let id = signal_id_counter.val
  signal_id_counter.val = id + 1
  id
}

///|
/// The shared inner state of a signal.
pub struct SignalInner[T] {
  id    : UInt
  value : T
  subs  : @hashset.HashSet[ASubscriber]
}

///|
pub fn[T] SignalInner::new(value : T) -> @ref.Ref[SignalInner[T]] {
  @ref.new(SignalInner::{
    id: next_signal_id(),
    value: value,
    subs: @hashset.HashSet([])
  })
}

// ----- WriteSignal -----
///|
pub struct WriteSignal[T] {
  inner : @ref.Ref[SignalInner[T]]
}

///|
pub impl[T] Hash for WriteSignal[T] with hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.inner.val.id)
}

///|
pub impl[T] Eq for WriteSignal[T] with equal(self, another : WriteSignal[T]) -> Bool {
  self.inner.val.id == another.inner.val.id
}

///|
/// Implement `Debug` trait for WriteSignal[T]
pub impl[T : Debug] Debug for WriteSignal[T] with to_repr(self) -> Repr {
  @debug.Repr::tuple([
    @debug.Repr::string("id"),
    @debug.Repr::string(self.inner.val.id.to_string()),
    @debug.Repr::string("value"),
    self.inner.val.value.to_repr(),
    @debug.Repr::string("subs"),
    self.inner.val.subs.to_repr(),
  ])
}

///|
/// Implement `Default` trait for WriteSignal[T] 
pub impl[T : Default] Default for WriteSignal[T] with default() -> WriteSignal[T] {
  WriteSignal::new(T::default())
}

///|
/// Implement `ReactiveNode` trait for WriteSignal
pub impl[T] ReactiveNode for WriteSignal[T] with mark_stale(self) {
  self.mark_all_pending()
}

///|
pub impl[T] ReactiveNode for WriteSignal[T] with mark_pending(_self) { }

///|
pub impl[T] ReactiveNode for WriteSignal[T] with mark_all_pending(self) {
  self.inner.val.subs.each(fn(sub) {
    match sub.sub {
      Some(node) => node.mark_stale()
      None => ()
    }
  })
}

///|
pub impl[T] ReactiveNode for WriteSignal[T] with update_value(_self) { false }

///|
/// Implement `Notify` trait for WriteSignal
pub impl[T] Notify for WriteSignal[T] with notify(self) -> Unit {
  self.mark_stale()
}


///|
pub fn[T] WriteSignal::new(value : T) -> WriteSignal[T] {
  WriteSignal::{
    inner: SignalInner::new(value)
  }
}

///|
pub fn[T] WriteSignal::try_update(self : WriteSignal[T], f : (T) -> T) -> Option[Unit] {
  let current_inner = self.inner.val
  let new_value = f(current_inner.value)
  self.inner.val = { ..current_inner, value: new_value }
  self.mark_stale()
  Some(())
}

///|
pub fn[T] WriteSignal::update(self : WriteSignal[T], f : (T) -> T) -> Unit {
  let _ = self.try_update(f)
}

///|
pub fn[T] WriteSignal::try_set(self : WriteSignal[T], value : T) -> Option[T] {
  let current_inner = self.inner.val
  self.inner.val = { ..current_inner, value: value }
  self.mark_stale()
  None
}

///|
pub fn[T] WriteSignal::set(self : WriteSignal[T], value : T) -> Unit {
  let _ = self.try_set(value)
}

///|
pub fn[T] WriteSignal::set_untracked(self : WriteSignal[T], value : T) -> Unit {
  let current_inner = self.inner.val
  self.inner.val = { ..current_inner, value: value }
}

// ----- ReadSignal -----
///|
pub struct ReadSignal[T] {
  inner : @ref.Ref[SignalInner[T]]
}

///|
pub impl[T] Hash for ReadSignal[T] with hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.inner.val.id)
}

///|
pub impl[T] Eq for ReadSignal[T] with equal(self, another : ReadSignal[T]) -> Bool {
  self.inner.val.id == another.inner.val.id
}

///|
/// Implement `Debug` trait for ReadSignal[T]
pub impl[T : Debug] Debug for ReadSignal[T] with to_repr(self) -> Repr {
  @debug.Repr::tuple([
    @debug.Repr::string("id"),
    @debug.Repr::string(self.inner.val.id.to_string()),
    @debug.Repr::string("value"),
    self.inner.val.value.to_repr(),
    @debug.Repr::string("subs"),
    self.inner.val.subs.to_repr(),
  ])
}

///|
/// Implement `Default` trait for ReadSignal[T] 
pub impl[T : Default] Default for ReadSignal[T] with default() -> ReadSignal[T] {
  ReadSignal::new(T::default())
}

///|
pub fn[T, U] ReadSignal::try_with(self : ReadSignal[T], f: (T) -> U ) -> Option[U] {
//  track_signal_dependency(self.inner.val.subs)
  Some(f(self.inner.val.value))
}

///|
pub fn[T] ReadSignal::try_get(self: ReadSignal[T]) -> Option[T] {
  self.try_with(fn(v) { v })
}

///|
pub fn[T] ReadSignal::get(self: ReadSignal[T]) -> T {
  self.try_get().unwrap()
}

///|
pub fn[T] ReadSignal::get_untracked(self : ReadSignal[T]) -> T {
  self.inner.val.value
}

///|
pub fn[T] ReadSignal::new(value : T) -> ReadSignal[T] {
  ReadSignal::{
    inner: SignalInner::new(value)
  }
}

// ----- RwSignal -----
///|
pub struct RwSignal[T] {
  inner : @ref.Ref[SignalInner[T]]
}

///|
pub impl[T] Hash for RwSignal[T] with hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.inner.val.id)
}

///|
pub impl[T] Eq for RwSignal[T] with equal(self, another : RwSignal[T]) -> Bool {
  self.inner.val.id == another.inner.val.id
}

///|
pub impl[T : Debug] Debug for RwSignal[T] with to_repr(self) -> Repr {
  @debug.Repr::tuple([
    @debug.Repr::string("id"),
    @debug.Repr::string(self.inner.val.id.to_string()),
    @debug.Repr::string("value"),
    self.inner.val.value.to_repr(),
    @debug.Repr::string("subs"),
    self.inner.val.subs.to_repr(),
  ])
}

///|
pub impl[T : Default] Default for RwSignal[T] with default() -> RwSignal[T] {
  RwSignal::new(T::default())
}

///|
/// Implement `ReactiveNode` for RwSignal
pub impl[T] ReactiveNode for RwSignal[T] with mark_stale(self) {
  self.mark_all_pending()
}

///|
pub impl[T] ReactiveNode for RwSignal[T] with mark_pending(_self) { }

///|
pub impl[T] ReactiveNode for RwSignal[T] with mark_all_pending(self) {
  self.inner.val.subs.each(fn(sub) {
    match sub.sub {
      Some(node) => node.mark_stale()
      None => ()
    }
  })
}

///|
pub impl[T] ReactiveNode for RwSignal[T] with update_value(_self) { false }

///|
/// Implement `Notify` trait for WriteSignal
pub impl[T] Notify for RwSignal[T] with notify(self) -> Unit {
  self.mark_stale()
}

///|
pub fn[T] RwSignal::new(value : T) -> RwSignal[T] {
  RwSignal::{
    inner: SignalInner::new(value)
  }
}

///|
pub fn[T] RwSignal::read_only(self : RwSignal[T]) -> ReadSignal[T] {
  ReadSignal::{
    inner: self.inner
  }
}

///|
pub fn[T] RwSignal::write_only(self : RwSignal[T]) -> WriteSignal[T] {
  WriteSignal::{
    inner: self.inner
  }
}

///|
pub fn[T] RwSignal::split(self : RwSignal[T]) -> (ReadSignal[T], WriteSignal[T]) {
  (self.read_only(), self.write_only())
}

///|
pub fn[T] RwSignal::unite(
  read : ReadSignal[T],
  write : WriteSignal[T],
) -> Option[RwSignal[T]] {
  if read.inner.val.id == write.inner.val.id {
    Some(RwSignal::{
      inner: read.inner
    })
  } else {
    None
  }
}

///|
pub fn[T, U] RwSignal::try_with(self : RwSignal[T], f: (T) -> U) -> Option[U] {
  // track_signal_dependency(self.inner.val.subs)
  Some(f(self.inner.val.value))
}

///|
pub fn[T, U] RwSignal::with_val(self : RwSignal[T], f: (T) -> U) -> U {
  self.try_with(f).unwrap()
}

///|
pub fn[T] RwSignal::try_get(self : RwSignal[T]) -> Option[T] {
  self.try_with(fn(v) { v })
}

///|
pub fn[T] RwSignal::get(self : RwSignal[T]) -> T {
  self.try_get().unwrap()
}

///|
pub fn[T] RwSignal::get_untracked(self : RwSignal[T]) -> T {
  self.inner.val.value
}

///|
pub fn[T] RwSignal::try_update(self : RwSignal[T], f : (T) -> T) -> Option[Unit] {
  let current_inner = self.inner.val
  let new_value = f(current_inner.value)
  self.inner.val = { ..current_inner, value: new_value }
  self.mark_stale()
  Some(())
}

///|
pub fn[T] RwSignal::update(self : RwSignal[T], f : (T) -> T) -> Unit {
  let _ = self.try_update(f)
}

///|
pub fn[T] RwSignal::try_set(self : RwSignal[T], value : T) -> Option[T] {
  let current_inner = self.inner.val
  self.inner.val = { ..current_inner, value: value }
  self.mark_stale()
  None
}

///|
pub fn[T] RwSignal::set(self : RwSignal[T], value : T) -> Unit {
  let _ = self.try_set(value)
}

///|
pub fn[T] RwSignal::set_untracked(self : RwSignal[T], value : T) -> Unit {
  let current_inner = self.inner.val
  self.inner.val = { ..current_inner, value: value }
}

// ----- Signal functions -----
///|
pub fn[T] create_signal(value : T) -> (ReadSignal[T], WriteSignal[T]) {
  RwSignal::new(value).split()
}
