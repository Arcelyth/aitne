using @hashmap { type HashMap }
using @hashset { type HashSet }

///|
pub struct Owner {
  id : Int
}

///|
/// Per-owner runtime state.
pub struct OwnerState {
  parent : Option[Int]
  mut cleanups : Array[() -> Unit]
  mut children : HashSet[Int]
  mut disposed : Bool
}

///|
/// Id allocator.
let next_owner_id : @ref.Ref[Int] = @ref.new(0)

///|
/// Current owner.
let current_owner : @ref.Ref[Option[Int]] = @ref.new(None)

///|
/// Registry: owner id -> state.
let owner_registry : @ref.Ref[HashMap[Int, @ref.Ref[OwnerState]]] = @ref.new(HashMap([]))

///|
fn next_id() -> Int {
  let id = next_owner_id.val
  next_owner_id.val = id + 1
  id
}

///|
fn owner_state_of(id : Int) -> Option[@ref.Ref[OwnerState]] {
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
    Some(parent_state) => {
       parent_state.val.children.remove(child_id)
    }
    None => ()
  }
}

///|
fn create_owner(parent : Option[Int]) -> Owner {
  let id = next_id()

  let state = @ref.new(OwnerState::{
    parent: parent,
    cleanups: [],
    children: HashSet([]),
    disposed: false,
  })

  owner_registry.val[id] = state

  match parent {
    Some(pid) => {
      match owner_state_of(pid) {
        Some(pstate) => {
          if !pstate.val.disposed {
            pstate.val.children.add(id)
          }
        }
        None => ()
      }
    }
    None => ()
  }

  Owner::{ id: id }
}

///|
/// Creates a new owner under the current owner, if there is one.
/// Otherwise creates a root owner.
pub fn Owner::new() -> Owner {
  let parent =
    match Owner::current() {
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
pub fn Owner::current() -> Option[Owner] {
  match current_owner.val {
    Some(id) => {
      if owner_exists(id) {
        Some(Owner::{ id: id })
      } else {
        None
      }
    }
    None => None
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
    Some(id) => {
      if id == self.id {
        current_owner.val = None
      }
    }
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
    Some(owner) => {
      match owner_state_of(owner.id) {
        Some(state) => {
          if !state.val.disposed {
            state.val.cleanups.push(fun)
          }
        }
        None => ()
      }
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
        Some(id) => {
          if id == self.id {
            current_owner.val = None
          }
        }
        None => ()
      }
    }
    None => ()
  }
}
