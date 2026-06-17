///|
using @hashmap {type HashMap}

///|
using @hashset {type HashSet}

///|
using @any {type Any}

///|
pub struct Owner {
  id : Int
}

///|
/// Per-owner runtime state.
pub struct OwnerState {
  parent : Int?
  mut cleanups : Array[() -> Unit]
  mut children : HashSet[Int]
  contexts : HashMap[String, Any]
  mut disposed : Bool
}

///|
/// Id allocator.
let next_owner_id : @ref.Ref[Int] = @ref.new(0)

///|
/// Current owner.
let current_owner : @ref.Ref[Int?] = @ref.new(None)

///|
/// Registry: owner id -> state.
let owner_registry : @ref.Ref[HashMap[Int, @ref.Ref[OwnerState]]] = @ref.new(
  HashMap([]),
)

///|
fn next_id() -> Int {
  let id = next_owner_id.val
  next_owner_id.val = id + 1
  id
}

///|
pub fn owner_state_of(id : Int) -> @ref.Ref[OwnerState]? {
  owner_registry.val.get(id)
}

///|
fn owner_exists(id : Int) -> Bool {
  match owner_state_of(id) {
    Some(state) => !state.val.disposed
    None => false
  }
}

///|
fn remove_owner_from_registry(id : Int) -> Unit {
  owner_registry.val.remove(id)
}

///|
fn remove_child_from_parent(parent_id : Int, child_id : Int) -> Unit {
  match owner_state_of(parent_id) {
    Some(parent_state) => parent_state.val.children.remove(child_id)
    None => ()
  }
}

///|
fn create_owner(parent : Int?) -> Owner {
  let id = next_id()

  let state = @ref.new(OwnerState::{
    parent,
    cleanups: [],
    children: HashSet([]),
    contexts: HashMap([]),
    disposed: false,
  })

  owner_registry.val[id] = state

  match parent {
    Some(pid) =>
      match owner_state_of(pid) {
        Some(pstate) => if !pstate.val.disposed { pstate.val.children.add(id) }
        None => ()
      }
    None => ()
  }

  Owner::{ id, }
}

///|
/// Creates a new owner under the current owner, if there is one.
/// Otherwise creates a root owner.
pub fn Owner::new() -> Owner {
  let parent = match Owner::current() {
    Some(owner) => Some(owner.id)
    None => None
  }
  create_owner(parent)
}

///|
/// Creates a child owner under `self`.
pub fn Owner::child(self : Owner) -> Owner {
  create_owner(Some(self.id))
}

///|
/// Returns the current owner, if any.
pub fn Owner::current() -> Owner? {
  match current_owner.val {
    Some(id) => if owner_exists(id) { Some(Owner::{ id, }) } else { None }
    None => None
  }
}

///|
/// Returns the current owner, if none create a default owner.
pub fn Owner::current_with_default() -> Owner {
  match Owner::current() {
    Some(owner) => owner
    None => create_owner(None)
  }
}

///|
/// Sets this owner as current.
pub fn Owner::set(self : Owner) -> Unit {
  if owner_exists(self.id) {
    current_owner.val = Some(self.id)
  }
}

///|
/// Clears current owner if it is `self`.
pub fn Owner::unset(self : Owner) -> Unit {
  match current_owner.val {
    Some(id) => if id == self.id { current_owner.val = None }
    None => ()
  }
}

///|
/// Runs `fun` under this owner, then restores the previous owner.
pub fn[T] Owner::with_(self : Owner, fun : () -> T) -> T {
  let prev = current_owner.val
  current_owner.val = Some(self.id)

  let result = fun()

  current_owner.val = prev
  result
}

///|
/// Runs cleanup callbacks and disposes children first,
/// but keeps this owner alive for reuse.
fn Owner::drain_owner(self : Owner) -> Unit {
  match owner_state_of(self.id) {
    Some(state) => {
      let children = state.val.children
      let cleanups = state.val.cleanups

      state.val.children = HashSet([])
      state.val.cleanups = []

      for child_id in children {
        if owner_exists(child_id) {
          Owner::{ id: child_id }.cleanup()
        }
      }

      for task in cleanups {
        task()
      }
    }
    None => ()
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
      match owner_state_of(owner.id) {
        Some(state) => if !state.val.disposed { state.val.cleanups.push(fun) }
        None => ()
      }
    None => ()
  }
}

///|
/// Permanently disposes this owner and all descendants,
/// then removes it from the registry.
pub fn Owner::cleanup(self : Owner) -> Unit {
  match owner_state_of(self.id) {
    Some(state) => {
      if state.val.disposed {
        return
      }

      state.val.disposed = true

      let parent = state.val.parent

      let children = state.val.children
      let cleanups = state.val.cleanups

      state.val.children = HashSet([])
      state.val.cleanups = []

      for child_id in children {
        if owner_exists(child_id) {
          Owner::{ id: child_id }.cleanup()
        }
      }

      for task in cleanups {
        task()
      }

      match parent {
        Some(pid) => remove_child_from_parent(pid, self.id)
        None => ()
      }

      remove_owner_from_registry(self.id)

      match current_owner.val {
        Some(id) => if id == self.id { current_owner.val = None }
        None => ()
      }
    }
    None => ()
  }
}

///|
/// Stores a context value on this owner.
///
/// The value is associated with its type name (`T::get_ty()`),
/// allowing descendants of this owner to retrieve it later using
/// `use_context`, `with_context`, `take_context`, or
/// `update_context`.
///
/// If a context with the same type already exists on this owner,
/// it will be replaced.
///
/// Context lookup follows the owner hierarchy upward,
/// so values provided by parent owners are visible to children.
pub fn[T : TypeName] Owner::provide_context(self : Owner, value : T) -> Unit {
  match owner_state_of(self.id) {
    Some(state) => {
      let any = @any.of(value)
      state.val.contexts.set(T::get_ty(), any)
    }
    None => ()
  }
}

///|
/// Searches for a context value of type `T` on this owner and its
/// ancestors, then invokes `callback` with the retrieved value.
///
/// Lookup starts from the current owner and walks upward through
/// parent owners until a matching context is found.
///
/// Returns:
///
/// * `Some(result)` if a matching context exists.
/// * `None` if no matching context can be found.
///
pub fn[T : TypeName, R] Owner::with_context(
  self : Owner,
  callback : (T) -> R,
) -> R? {
  let ty = T::get_ty()
  let mut current_id = Some(self.id)

  while !(current_id is None) {
    let id = current_id.unwrap()
    match owner_state_of(id) {
      Some(state) =>
        if !state.val.disposed {
          match state.val.contexts.get(ty) {
            Some(any_val) =>
              match any_val.try_to() {
                Some(val) => return Some(callback(val))
                None => current_id = state.val.parent
              }
            None => current_id = state.val.parent
          }
        } else {
          break
        }
      None => break
    }
  }

  None
}

///|
/// Retrieves a context value of type `T`.
///
/// Lookup starts from this owner and continues through all ancestors.
///
/// Returns:
///
/// * `Some(value)` if a matching context exists.
/// * `None` otherwise.
///
/// This is equivalent to:
///
/// ```
/// owner.with_context(fn(v : T) { v })
/// ```
pub fn[T : TypeName] Owner::use_context(self : Owner) -> T? {
  self.with_context(fn(val : T) { val })
}

///|
/// Removes and returns a context value of type `T`.
///
/// Lookup starts from this owner and continues upward through
/// all ancestor owners.
///
/// Once a matching context is found:
///
/// * The value is removed from the owner that contains it.
/// * The removed value is returned.
///
/// Returns:
///
/// * `Some(value)` if a matching context exists.
/// * `None` otherwise.
///
/// Unlike `use_context`, the context will no longer be available
/// after a successful call.
pub fn[T : TypeName] Owner::take_context(self : Owner) -> T? {
  let ty = T::get_ty()
  let mut current_id = Some(self.id)

  while !(current_id is None) {
    let id = current_id.unwrap()
    match owner_state_of(id) {
      Some(state) =>
        if !state.val.disposed {
          match state.val.contexts.get(ty) {
            Some(any_val) =>
              match any_val.try_to() {
                Some(val) => {
                  state.val.contexts.remove(ty)
                  return Some(val)
                }
                None => current_id = state.val.parent
              }
            None => current_id = state.val.parent
          }
        } else {
          break
        }
      None => break
    }
  }

  None
}

///|
/// Retrieves a context value of type `T`, applies `cb`,
/// and stores the updated value back into the owner.
///
/// Lookup starts from this owner and walks upward through
/// ancestor owners.
///
/// Returns:
///
/// * `Some(result)` if the context exists.
/// * `None` otherwise.
pub fn[T : TypeName, R] Owner::update_context(
  self : Owner,
  cb : (T) -> R,
) -> R? {
  let ty = T::get_ty()
  let mut current_id = Some(self.id)

  while !(current_id is None) {
    let id = current_id.unwrap()
    match owner_state_of(id) {
      Some(state) =>
        if !state.val.disposed {
          match state.val.contexts.get(ty) {
            Some(any_val) =>
              match any_val.try_to() {
                Some(val) => {
                  let result = cb(val)
                  state.val.contexts.set(ty, @any.of(val))
                  return Some(result)
                }
                None => current_id = state.val.parent
              }
            None => current_id = state.val.parent
          }
        } else {
          break
        }
      None => break
    }
  }

  None
}

///|
/// Searches for a context value in both directions.
///
/// The search order is:
///
/// 1. Current owner.
/// 2. Parent owners.
/// 3. Descendant owners (breadth-first).
///
/// This is useful for special framework-level services where
/// ownership direction is not important.
///
/// Returns:
///
/// * `Some(value)` if a matching context is found.
/// * `None` otherwise.
///
/// Normal application code should generally prefer
/// `use_context`, which only searches ancestors.
pub fn[T : TypeName] Owner::use_context_bidirectional(self : Owner) -> T? {
  match self.use_context() {
    Some(val) => Some(val)
    None => self.find_context_in_children()
  }
}

///|
/// Searches descendant owners for a context value of type `T`.
///
/// The search uses breadth-first traversal (BFS),
/// visiting immediate children before deeper descendants.
///
/// This function is used internally by
/// `use_context_bidirectional`.
fn[T : TypeName] Owner::find_context_in_children(self : Owner) -> T? {
  let ty = T::get_ty()

  match owner_state_of(self.id) {
    Some(state) => {
      let to_search = []

      for child_id in state.val.children {
        to_search.push(child_id)
      }

      let mut i = 0
      while i < to_search.length() {
        let next_id = to_search[i]
        i = i + 1

        match owner_state_of(next_id) {
          Some(child_state) =>
            if !child_state.val.disposed {
              match child_state.val.contexts.get(ty) {
                Some(any_val) =>
                  match any_val.try_to() {
                    Some(val) => return Some(val)
                    None => ()
                  }
                None => ()
              }

              for grandchild_id in child_state.val.children {
                to_search.push(grandchild_id)
              }
            }
          None => ()
        }
      }

      None
    }
    None => None
  }
}
