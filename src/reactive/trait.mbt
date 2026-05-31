///|
pub trait Notify {
  fn notify(Self) -> Unit
}

///|
/// Can report whether it has been disposed.
pub trait IsDisposed {
  fn is_disposed(Self) -> Bool
}



