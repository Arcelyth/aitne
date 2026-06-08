///|
/// Runtime observer state.
///
/// Stores the currently active subscriber participating
/// in dependency tracking, together with an `untracked`
/// flag that temporarily disables tracking.
pub struct ObserverState {
  subscriber : ASubscriber
  untracked  : Bool
}

///|
/// Global observer context.
///
/// Holds the subscriber currently collecting dependencies.
let observer_context : @ref.Ref[Option[ObserverState]] = @ref.new(None)

///|
/// Reactive observer utilities.
///
/// An observer represents the currently executing reactive
/// computation (effect, memo, computed value, etc.) that is
/// collecting dependencies from reactive sources.
pub(all) struct Observer {}

///|
/// Returns the current subscriber.
///
/// If tracking is disabled (`untracked == true`) or there
/// is no active observer, returns `None`.
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
/// Returns whether the given subscriber is the current observer.
pub fn Observer::tobe(observer : ASubscriber) -> Bool {
  match observer_context.val {
    Some(state) => state.subscriber == observer
    None => false
  }
}

///|
/// Sets the current observer.
///
/// Passing `None` clears the observer context.
pub fn Observer::set(observer : Option[ASubscriber]) -> Unit {
  observer_context.val = match observer {
    Some(sub) => Some({ subscriber: sub, untracked: false })
    None => None
  }
}

///|
/// Temporarily removes the current observer while executing `f`.
///
/// Dependency tracking is completely disabled inside `f`.
/// The previous observer is restored afterwards.
pub fn[T] Observer::with_take(f : () -> T) -> T {
  let prev = observer_context.val
  observer_context.val = None
  
  let result = f()
  
  observer_context.val = prev
  result
}

///|
/// Executes `f` with the given observer temporarily installed.
///
/// The previous observer context is restored after execution,
/// even if another observer was previously active.
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
/// Executes `f` in an untracked context.
///
/// If an observer is currently active, dependency collection
/// is suspended for the duration of `f`. Reads performed
/// inside `f` will not create reactive subscriptions.
///
/// This is equivalent to SolidJS `untrack()` and Leptos
/// `untrack()`.
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
