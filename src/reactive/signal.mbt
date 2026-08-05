///|
/// Simple signal id generator.
let signal_id_counter : Ref[UInt] = @ref.new(0)

///|
#inline
fn next_signal_id() -> UInt {
  let id = signal_id_counter.val
  signal_id_counter.val = id + 1
  id
}

///|
/// The shared inner state of a signal.
pub struct SignalInner[T] {
  id : UInt
  mut value : T
  subs : @hashset.HashSet[ASubscriber]
}

///|
pub fn[T] SignalInner::new(value : T) -> @ref.Ref[SignalInner[T]] {
  @ref.new(SignalInner::{
    id: next_signal_id(),
    value,
    subs: @hashset.HashSet([]),
  })
}

// ----- WriteSignal -----

///|
pub struct WriteSignal[T] {
  inner : @ref.Ref[SignalInner[T]]
}

///|
pub impl[T] Hash for WriteSignal[T] with fn hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.inner.val.id)
}

///|
#inline
pub impl[T] Eq for WriteSignal[T] with fn equal(self, another : WriteSignal[T]) -> Bool {
  self.inner.val.id == another.inner.val.id
}

///|
/// Implement `Debug` trait for WriteSignal[T]
pub impl[T : Debug] Debug for WriteSignal[T] with fn to_repr(self) -> Repr {
  @debug.Repr::tuple([
    @debug.Repr::string("id"),
    @debug.Repr::string(self.inner.val.id.to_string()),
    @debug.Repr::string("value"),
    self.inner.val.value.to_repr(),
    @debug.Repr::string("subs"),
    to_repr(self.inner.val.subs),
  ])
}

///|
/// Implement `Default` trait for WriteSignal[T] 
pub impl[T : Default] Default for WriteSignal[T] with fn default() -> WriteSignal[
  T,
] {
  WriteSignal::new(T::default())
}

///|
/// Implement `ReactiveNode` trait for WriteSignal
pub impl[T] ReactiveNode for WriteSignal[T] with fn mark_stale(self) {
  self.mark_all_pending()
}

///|
pub impl[T] ReactiveNode for WriteSignal[T] with fn mark_pending(_self) {

}

///|
pub impl[T] ReactiveNode for WriteSignal[T] with fn mark_all_pending(self) {
  self.inner.val.subs.each(fn(sub) {
    match sub.sub {
      Some(node) => node.mark_stale()
      None => ()
    }
  })
}

///|
pub impl[T] ReactiveNode for WriteSignal[T] with fn update_value(_self) {
  false
}

///|
/// Implement `Notify` trait for WriteSignal
pub impl[T] Notify for WriteSignal[T] with fn notify(self) -> Unit {
  self.mark_stale()
}

///|
#inline
pub impl[T] IsDisposed for WriteSignal[T] with fn is_disposed(_self) -> Bool {
  false
}

///|
pub impl[T] Source for WriteSignal[T] with fn add_sub(self, sub : ASubscriber) {
  self.inner.val.subs.add(sub)
}

///|
pub impl[T] Source for WriteSignal[T] with fn remove_sub(
  self,
  sub : ASubscriber,
) {
  self.inner.val.subs.remove(sub)
}

///|
pub impl[T] Source for WriteSignal[T] with fn clear_subs(self) {
  self.inner.val.subs.clear()
}

///|
pub impl[T] ToASource for WriteSignal[T] with fn to_asource(self) {
  { id: self.inner.val.id, src: Some(self as &Source) }
}

///|
pub impl[T] Track for WriteSignal[T] with fn track(self) -> Unit {
  guard !self.is_disposed() else { return }
  match Observer::get() {
    Some(sub) => {
      sub.add_source(self.to_asource())
      self.add_sub(sub)
    }
    None => ()
  }
}

///|
pub fn[T] WriteSignal::new(value : T) -> WriteSignal[T] {
  WriteSignal::{ inner: SignalInner::new(value) }
}

///|
pub fn[T] WriteSignal::try_update(self : WriteSignal[T], f : (T) -> T) -> Unit? {
  self.inner.val.value = f(self.inner.val.value)
  self.mark_stale()
  Some(())
}

///|
pub fn[T] WriteSignal::update(self : WriteSignal[T], f : (T) -> T) -> Unit {
  let _ = self.try_update(f)
}

///|
pub fn[T] WriteSignal::try_set(self : WriteSignal[T], value : T) -> T? {
  let old_value = self.inner.val.value
  self.inner.val.value = value
  self.mark_stale()
  Some(old_value)
}

///|
pub fn[T] WriteSignal::set(self : WriteSignal[T], value : T) -> Unit {
  let _ = self.try_set(value)
}

///|
#inline
pub fn[T] WriteSignal::set_untracked(self : WriteSignal[T], value : T) -> Unit {
  let current_inner = self.inner.val
  self.inner.val = { ..current_inner, value, }
}

// ----- ReadSignal -----

///|
pub struct ReadSignal[T] {
  inner : @ref.Ref[SignalInner[T]]
}

///|
pub impl[T] Hash for ReadSignal[T] with fn hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.inner.val.id)
}

///|
#inline
pub impl[T] Eq for ReadSignal[T] with fn equal(self, another : ReadSignal[T]) -> Bool {
  self.inner.val.id == another.inner.val.id
}

///|
/// Implement `Debug` trait for ReadSignal[T]
pub impl[T : Debug] Debug for ReadSignal[T] with fn to_repr(self) -> Repr {
  @debug.Repr::tuple([
    @debug.Repr::string("id"),
    @debug.Repr::string(self.inner.val.id.to_string()),
    @debug.Repr::string("value"),
    self.inner.val.value.to_repr(),
    @debug.Repr::string("subs"),
    to_repr(self.inner.val.subs),
  ])
}

///|
/// Implement `Default` trait for ReadSignal[T] 
pub impl[T : Default] Default for ReadSignal[T] with fn default() -> ReadSignal[
  T,
] {
  ReadSignal::new(T::default())
}

///|
#inline
pub impl[T] IsDisposed for ReadSignal[T] with fn is_disposed(_self) -> Bool {
  false
}

///|
/// Implement `ReactiveNode` trait for ReadSignal
pub impl[T] ReactiveNode for ReadSignal[T] with fn mark_stale(self) {
  self.mark_all_pending()
}

///|
pub impl[T] ReactiveNode for ReadSignal[T] with fn mark_pending(_self) {

}

///|
pub impl[T] ReactiveNode for ReadSignal[T] with fn mark_all_pending(self) {
  self.inner.val.subs.each(fn(sub) {
    match sub.sub {
      Some(node) => node.mark_stale()
      None => ()
    }
  })
}

///|
#inline
pub impl[T] ReactiveNode for ReadSignal[T] with fn update_value(_self) {
  false
}

///|
pub impl[T] Source for ReadSignal[T] with fn add_sub(self, sub : ASubscriber) {
  self.inner.val.subs.add(sub)
}

///|
pub impl[T] Source for ReadSignal[T] with fn remove_sub(self, sub : ASubscriber) {
  self.inner.val.subs.remove(sub)
}

///|
pub impl[T] Source for ReadSignal[T] with fn clear_subs(self) {
  self.inner.val.subs.clear()
}

///|
pub impl[T] ToASource for ReadSignal[T] with fn to_asource(self) {
  { id: self.inner.val.id, src: Some(self as &Source) }
}

///|
pub impl[T] Track for ReadSignal[T] with fn track(self) -> Unit {
  guard !self.is_disposed() else { return }
  match Observer::get() {
    Some(sub) => {
      sub.add_source(self.to_asource())
      self.add_sub(sub)
    }
    None => ()
  }
}

///|
pub fn[T, U] ReadSignal::try_with(self : ReadSignal[T], f : (T) -> U) -> U? {
  self.track()
  Some(f(self.inner.val.value))
}

///|
pub fn[T] ReadSignal::try_get(self : ReadSignal[T]) -> T? {
  self.try_with(fn(v) { v })
}

///|
pub fn[T] ReadSignal::get(self : ReadSignal[T]) -> T {
  self.try_get().unwrap()
}

///|
#inline
pub fn[T] ReadSignal::get_untracked(self : ReadSignal[T]) -> T {
  self.inner.val.value
}

///|
pub fn[T] ReadSignal::new(value : T) -> ReadSignal[T] {
  ReadSignal::{ inner: SignalInner::new(value) }
}

// ----- RwSignal -----

///|
pub struct RwSignal[T] {
  inner : @ref.Ref[SignalInner[T]]
}

///|
pub impl[T] Hash for RwSignal[T] with fn hash_combine(self, hasher : Hasher) {
  hasher.combine_uint(self.inner.val.id)
}

///|
#inline
pub impl[T] Eq for RwSignal[T] with fn equal(self, another : RwSignal[T]) -> Bool {
  self.inner.val.id == another.inner.val.id
}

///|
pub impl[T : Debug] Debug for RwSignal[T] with fn to_repr(self) -> Repr {
  @debug.Repr::tuple([
    @debug.Repr::string("id"),
    @debug.Repr::string(self.inner.val.id.to_string()),
    @debug.Repr::string("value"),
    self.inner.val.value.to_repr(),
    @debug.Repr::string("subs"),
    to_repr(self.inner.val.subs),
  ])
}

///|
pub impl[T : Default] Default for RwSignal[T] with fn default() -> RwSignal[T] {
  RwSignal::new(T::default())
}

///|
/// Implement `ReactiveNode` for RwSignal
pub impl[T] ReactiveNode for RwSignal[T] with fn mark_stale(self) {
  self.mark_all_pending()
}

///|
#inline
pub impl[T] ReactiveNode for RwSignal[T] with fn mark_pending(_self) {

}

///|
pub impl[T] ReactiveNode for RwSignal[T] with fn mark_all_pending(self) {
  self.inner.val.subs.each(fn(sub) {
    match sub.sub {
      Some(node) => node.mark_stale()
      None => ()
    }
  })
}

///|
#inline
pub impl[T] ReactiveNode for RwSignal[T] with fn update_value(_self) {
  false
}

///|
#inline
pub impl[T] IsDisposed for RwSignal[T] with fn is_disposed(_self) -> Bool {
  false
}

///|
/// Implement `Notify` trait for WriteSignal
pub impl[T] Notify for RwSignal[T] with fn notify(self) -> Unit {
  self.mark_stale()
}

///|
pub impl[T] Source for RwSignal[T] with fn add_sub(self, sub : ASubscriber) {
  self.inner.val.subs.add(sub)
}

///|
pub impl[T] Source for RwSignal[T] with fn remove_sub(self, sub : ASubscriber) {
  self.inner.val.subs.remove(sub)
}

///|
pub impl[T] Source for RwSignal[T] with fn clear_subs(self) {
  self.inner.val.subs.clear()
}

///|
pub impl[T] ToASource for RwSignal[T] with fn to_asource(self) {
  { id: self.inner.val.id, src: Some(self as &Source) }
}

///|
pub impl[T] Track for RwSignal[T] with fn track(self) -> Unit {
  guard !self.is_disposed() else { return }
  match Observer::get() {
    Some(sub) => {
      sub.add_source(self.to_asource())
      self.add_sub(sub)
    }
    None => ()
  }
}

///|
pub fn[T] RwSignal::new(value : T) -> RwSignal[T] {
  RwSignal::{ inner: SignalInner::new(value) }
}

///|
#inline
pub fn[T] RwSignal::read_only(self : RwSignal[T]) -> ReadSignal[T] {
  ReadSignal::{ inner: self.inner }
}

///|
#inline
pub fn[T] RwSignal::write_only(self : RwSignal[T]) -> WriteSignal[T] {
  WriteSignal::{ inner: self.inner }
}

///|
pub fn[T] RwSignal::split(
  self : RwSignal[T],
) -> (ReadSignal[T], WriteSignal[T]) {
  (self.read_only(), self.write_only())
}

///|
pub fn[T] RwSignal::unite(
  read : ReadSignal[T],
  write : WriteSignal[T],
) -> RwSignal[T]? {
  if read.inner.val.id == write.inner.val.id {
    Some(RwSignal::{ inner: read.inner })
  } else {
    None
  }
}

///|
pub fn[T, U] RwSignal::try_with(self : RwSignal[T], f : (T) -> U) -> U? {
  self.track()
  Some(f(self.inner.val.value))
}

///|
pub fn[T, U] RwSignal::with_val(self : RwSignal[T], f : (T) -> U) -> U {
  self.try_with(f).unwrap()
}

///|
pub fn[T] RwSignal::try_get(self : RwSignal[T]) -> T? {
  self.try_with(fn(v) { v })
}

///|
pub fn[T] RwSignal::get(self : RwSignal[T]) -> T {
  self.try_get().unwrap()
}

///|
#inline
pub fn[T] RwSignal::get_untracked(self : RwSignal[T]) -> T {
  self.inner.val.value
}

///|
pub fn[T] RwSignal::try_update(self : RwSignal[T], f : (T) -> T) -> Unit? {
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
pub fn[T] RwSignal::try_set(self : RwSignal[T], value : T) -> T? {
  self.inner.val.value = value
  self.mark_stale()
  None
}

///|
pub fn[T] RwSignal::set(self : RwSignal[T], value : T) -> Unit {
  let _ = self.try_set(value)
}

///|
#inline
pub fn[T] RwSignal::set_untracked(self : RwSignal[T], value : T) -> Unit {
  let current_inner = self.inner.val
  self.inner.val = { ..current_inner, value, }
}

// ----- Signal functions -----

///|
pub fn[T] create_signal(value : T) -> (ReadSignal[T], WriteSignal[T]) {
  RwSignal::new(value).split()
}

///|
pub impl[T : TypeName] TypeName for RwSignal[T] with fn get_ty() -> String {
  "RwSignal_" + T::get_ty()
}

///|
pub impl[T : TypeName] TypeName for WriteSignal[T] with fn get_ty() -> String {
  "WriteSignal_" + T::get_ty()
}

///|
pub impl[T : TypeName] TypeName for ReadSignal[T] with fn get_ty() -> String {
  "ReadSignal_" + T::get_ty()
}
