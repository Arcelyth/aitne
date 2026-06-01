///|
pub struct ObserverState {
  subscriber : ASubscriber
  untracked  : Bool
}

let observer_context : @ref.Ref[Option[ObserverState]] = @ref.new(None)

///| 
pub(all) struct Observer {}

///|
pub fn Observer::get() -> Option[ASubscriber] {
  match observer_context.val {
    Some(state) => {
      if state.untracked {
        None
      } else {
        Some(state.subscriber)
      }
    }
    None => None
  }
}

///|
pub fn Observer::tobe(observer : ASubscriber) -> Bool {
  match observer_context.val {
    Some(state) => state.subscriber == observer
    None => false
  }
}

///|
pub fn Observer::set(observer : Option[ASubscriber]) -> Unit {
  observer_context.val = match observer {
    Some(sub) => Some({ subscriber: sub, untracked: false })
    None => None
  }
}

///|
pub fn[T] Observer::with_take(f : () -> T) -> T {
  let prev = observer_context.val
  observer_context.val = None
  
  let result = f()
  
  observer_context.val = prev
  result
}

///|
pub fn[T] Observer::with_replace(observer : Option[ASubscriber], f : () -> T) -> T {
  let prev = observer_context.val
  
  observer_context.val = match observer {
    Some(sub) => Some({ subscriber: sub, untracked: false })
    None => None
  }
  
  let result = f()
  
  observer_context.val = prev
  result
}

///|
pub fn[T] Observer::with_untracked(f : () -> T) -> T {
  let prev = observer_context.val
  
  match prev {
    Some(state) => {
      observer_context.val = Some({ ..state, untracked: true })
    }
    None => ()
  }
  
  let result = f()
  
  observer_context.val = prev
  result
}
