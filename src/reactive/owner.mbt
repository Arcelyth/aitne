///|
using @hashmap {type HashMap}

///|
using @hashset {type HashSet}

///|
using @any {type Any}

///|
/// Per-owner runtime state. Mutable fields are lazily allocated (Option).
pub struct Owner {
  id : Int
  mut parent : Owner?
  mut cleanups : Array[() -> Unit]?
  mut children : HashMap[Int, Owner]?
  mut contexts : HashMap[String, Any]?
  mut disposed : Bool
}

///|
pub impl Debug for Owner with fn to_repr(self) {
  @debug.Repr::tuple([
    @debug.Repr::string("Owner"),
    @debug.Repr::string(self.id.to_string()),
  ])
}

///|
/// Id allocator.
let next_owner_id : @ref.Ref[Int] = @ref.new(0)

///|
/// Current owner.
let current_owner : @ref.Ref[Owner?] = @ref.new(None)

///|
/// Registry: owner id -> owner.
let owner_registry : @ref.Ref[HashMap[Int, Owner]] = @ref.new(HashMap([]))

///|
fn next_id() -> Int {
  let id = next_owner_id.val
  next_owner_id.val = id + 1
  id
}

///|
pub fn owner_state_of(id : Int) -> Owner? {
  owner_registry.val.get(id)
}

///|
pub fn owner_exists(id : Int) -> Bool {
  match owner_state_of(id) {
    Some(owner) => !owner.disposed
    None => false
  }
}

///|
fn remove_owner_from_registry(id : Int) -> Unit {
  owner_registry.val.remove(id)
}

///|
pub fn remove_child_from_parent(parent_id : Int, child_id : Int) -> Unit {
  match owner_state_of(parent_id) {
    Some(parent) =>
      match parent.children {
        Some(children) => children.remove(child_id)
        None => ()
      }
    None => ()
  }
}

///|
pub fn Owner::new() -> Owner {
  let id = next_id()
  let owner = Owner::{
    id,
    parent: None,
    cleanups: None,
    children: None,
    contexts: None,
    disposed: false,
  }

  owner_registry.val[id] = owner

  match Owner::current() {
    Some(parent) =>
      if !parent.disposed {
        match parent.children {
          Some(c) => c.set(id, owner)
          None => {
            let c = HashMap([])
            c.set(id, owner)
            parent.children = Some(c)
          }
        }
        owner.parent = Some(parent)
      }
    None => ()
  }

  owner
}

///|
/// Creates a child owner under `self`.
pub fn Owner::child(self : Owner) -> Owner {
  let id = next_id()
  let owner = Owner::{
    id,
    parent: Some(self),
    cleanups: None,
    children: None,
    contexts: None,
    disposed: false,
  }

  owner_registry.val[id] = owner

  if !self.disposed {
    match self.children {
      Some(c) => c.set(id, owner)
      None => {
        let c = HashMap([])
        c.set(id, owner)
        self.children = Some(c)
      }
    }
  }

  owner
}

///|
/// Returns the current owner, if any.
#inline
pub fn Owner::current() -> Owner? {
  match current_owner.val {
    Some(owner) => if !owner.disposed { Some(owner) } else { None }
    None => None
  }
}

///|
/// Returns the current owner, if none create a default owner.
pub fn Owner::current_with_default() -> Owner {
  match Owner::current() {
    Some(owner) => owner
    None => Owner::new()
  }
}

///|
/// Sets this owner as current.
pub fn Owner::set(self : Owner) -> Unit {
  if !self.disposed {
    current_owner.val = Some(self)
  }
}

///|
/// Clears current owner if it is `self`.
pub fn Owner::unset(self : Owner) -> Unit {
  match current_owner.val {
    Some(owner) => if owner.id == self.id { current_owner.val = None }
    None => ()
  }
}

///|
/// Runs `fun` under this owner, then restores the previous owner.
pub fn[T] Owner::with_(self : Owner, fun : () -> T) -> T {
  let prev = current_owner.val
  current_owner.val = Some(self)
  let result = fun()
  current_owner.val = prev
  result
}

///|
/// Runs cleanup callbacks and disposes children first,
/// but keeps this owner alive for reuse.
fn Owner::drain_owner(self : Owner) -> Unit {
  if self.disposed {
    return
  }

  let cleanups = match self.cleanups {
    Some(c) => c
    None => []
  }

  match self.children {
    Some(c) => c.each(fn(_, child) { if !child.disposed { child.cleanup() } })
    None => ()
  }
  self.children = None
  self.cleanups = None

  let mut j = 0
  while j < cleanups.length() {
    cleanups[j]()
    j = j + 1
  }
}

///|
/// Runs all cleanup callbacks and cleans all children first,
/// then executes `fun` under this owner.
///
/// This is a soft cleanup: the owner itself remains usable.
pub fn[T] Owner::with_cleanup(self : Owner, fun : () -> T) -> T {
  self.drain_owner()
  self.with_(fun)
}

///|
/// Registers a cleanup callback on the current owner.
/// If there is no current owner, this is a no-op.
pub fn on_cleanup(fun : () -> Unit) -> Unit {
  match Owner::current() {
    Some(owner) =>
      if !owner.disposed {
        match owner.cleanups {
          Some(c) => c.push(fun)
          None => owner.cleanups = Some([fun])
        }
      }
    None => ()
  }
}

///|
/// Permanently disposes this owner and all descendants.
pub fn Owner::cleanup(self : Owner) -> Unit {
  if self.disposed {
    return
  }

  self.disposed = true

  let parent = self.parent
  let cleanups = match self.cleanups {
    Some(c) => c
    None => []
  }

  match self.children {
    Some(c) => c.each(fn(_, child) { if !child.disposed { child.cleanup() } })
    None => ()
  }
  self.children = None
  self.cleanups = None

  let mut j = 0
  while j < cleanups.length() {
    cleanups[j]()
    j = j + 1
  }

  match parent {
    Some(p) =>
      match p.children {
        Some(pchildren) => pchildren.remove(self.id)
        None => ()
      }
    None => ()
  }

  remove_owner_from_registry(self.id)

  match current_owner.val {
    Some(owner) => if owner.id == self.id { current_owner.val = None }
    None => ()
  }
}

///|
/// Disposes this owner without removing from parent's children array
/// or the global registry. For use in bulk-clear paths where the parent's
/// children array is cleared afterwards and registry entries are
/// batch-removed.
pub fn Owner::cleanup_light(self : Owner) -> Unit {
  if self.disposed {
    return
  }

  self.disposed = true

  let cleanups = match self.cleanups {
    Some(c) => c
    None => []
  }

  match self.children {
    Some(c) =>
      c.each(fn(_, child) { if !child.disposed { child.cleanup_light() } })
    None => ()
  }
  self.children = None
  self.cleanups = None

  let mut j = 0
  while j < cleanups.length() {
    cleanups[j]()
    j = j + 1
  }
}

///|
pub fn[T : TypeName] Owner::provide_context(self : Owner, value : T) -> Unit {
  match owner_state_of(self.id) {
    Some(owner) => {
      let any = @any.of(value)
      match owner.contexts {
        Some(ctx) => ctx.set(T::get_ty(), any)
        None => {
          let ctx = HashMap([])
          ctx.set(T::get_ty(), any)
          owner.contexts = Some(ctx)
        }
      }
    }
    None => ()
  }
}

///|
pub fn[T : TypeName, R] Owner::with_context(
  self : Owner,
  callback : (T) -> R,
) -> R? {
  let ty = T::get_ty()
  let mut curr : Owner? = Some(self)

  while !(curr is None) {
    let owner = curr.unwrap()
    if !owner.disposed {
      match owner.contexts {
        None => curr = owner.parent
        Some(ctx) =>
          match ctx.get(ty) {
            Some(any_val) =>
              match any_val.try_to() {
                Some(val) => return Some(callback(val))
                None => curr = owner.parent
              }
            None => curr = owner.parent
          }
      }
    } else {
      break
    }
  }

  None
}

///|
pub fn[T : TypeName] Owner::use_context(self : Owner) -> T? {
  self.with_context(fn(val : T) { val })
}

///|
pub fn[T : TypeName] Owner::take_context(self : Owner) -> T? {
  let ty = T::get_ty()
  let mut curr : Owner? = Some(self)

  while !(curr is None) {
    let owner = curr.unwrap()
    if !owner.disposed {
      match owner.contexts {
        None => curr = owner.parent
        Some(map) =>
          match map.get(ty) {
            Some(any_val) =>
              match any_val.try_to() {
                Some(val) => {
                  map.remove(ty)
                  return Some(val)
                }
                None => curr = owner.parent
              }
            None => curr = owner.parent
          }
      }
    } else {
      break
    }
  }

  None
}

///|
pub fn[T : TypeName, R] Owner::update_context(
  self : Owner,
  cb : (T) -> R,
) -> R? {
  let ty = T::get_ty()
  let mut curr : Owner? = Some(self)

  while !(curr is None) {
    let owner = curr.unwrap()
    if !owner.disposed {
      match owner.contexts {
        None => curr = owner.parent
        Some(map) =>
          match map.get(ty) {
            Some(any_val) =>
              match any_val.try_to() {
                Some(val) => {
                  let result = cb(val)
                  map.set(ty, @any.of(val))
                  return Some(result)
                }
                None => curr = owner.parent
              }
            None => curr = owner.parent
          }
      }
    } else {
      break
    }
  }

  None
}

///|
pub fn[T : TypeName] Owner::use_context_bidirectional(self : Owner) -> T? {
  match self.use_context() {
    Some(val) => Some(val)
    None => self.find_context_in_children()
  }
}

///|
fn[T : TypeName] Owner::find_context_in_children(self : Owner) -> T? {
  let ty = T::get_ty()
  if self.disposed {
    return None
  }

  let to_search : Array[Owner] = []

  match self.children {
    Some(children) => children.each(fn(_, child) { to_search.push(child) })
    None => ()
  }

  let mut i = 0
  while i < to_search.length() {
    let child = to_search[i]
    i = i + 1

    if !child.disposed {
      match child.contexts {
        Some(map) =>
          match map.get(ty) {
            Some(any_val) =>
              match any_val.try_to() {
                Some(val) => return Some(val)
                None => ()
              }
            None => ()
          }
        None => ()
      }

      match child.children {
        Some(grandchildren) =>
          grandchildren.each(fn(_, gc) { to_search.push(gc) })
        None => ()
      }
    }
  }

  None
}
