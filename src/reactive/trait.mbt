///|
/// Can be notified when an upstream reactive source changes.
pub trait Notify {
  fn notify(Self) -> Unit
}

///|
/// Can report whether the underlying reactive node has already been disposed.
pub trait IsDisposed {
  fn is_disposed(Self) -> Bool
}

///|
/// Converts a concrete reactive source into a type-erased source.
pub trait ToASource: IsDisposed {
  fn to_asource(Self) -> ASource
}

///|
/// Converts a concrete subscriber into a type-erased subscriber.
pub trait ToASubscriber {
  fn to_asubscriber(Self) -> ASubscriber
}

///|
/// Tracks the current observer as a dependency of this source.
///
/// Implementations typically:
/// 1. read the current observer,
/// 2. register the observer as a subscriber,
/// 3. register this source on the observer.
pub trait Track: Source + ToASource {
  fn track(Self) -> Unit
}
