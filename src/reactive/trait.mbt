///|
pub trait Notify {
  fn notify(Self) -> Unit
}

///|
/// Can report whether it has been disposed.
pub trait IsDisposed {
  fn is_disposed(Self) -> Bool
}

///|
pub trait ToASource: IsDisposed {
  fn to_asource(Self) -> ASource
}

///|
pub trait Track: Source + ToASource {
  fn track(Self) -> Unit
}

