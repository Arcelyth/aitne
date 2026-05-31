///|
// Simple signal id generator.
/// If you already have a runtime-wide id allocator, replace this.
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
pub fn[T] WriteSignal::new(value : T) -> WriteSignal[T] {
  WriteSignal::{
    inner: SignalInner::new(value)
  }
}

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
/// TODO: Implement `Debug` trait for ReadSignal[T]
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
pub fn[T] ReadSignal::new(value : T) -> ReadSignal[T] {
  ReadSignal::{
    inner: SignalInner::new(value)
  }
}

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

