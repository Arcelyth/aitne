///|
pub fn[T : TypeName] provide_context(value : T) -> Unit {
  match Owner::current() {
    Some(owner) => owner.provide_context(value)
    None => ()
  }
}

///|
pub fn[T : TypeName] use_context() -> T? {
  match Owner::current() {
    Some(owner) => owner.use_context()
    None => None
  }
}

///|
pub trait TypeName {
  fn get_ty() -> String
}

///|
pub impl TypeName for Int with fn get_ty() -> String {
  "Int"
}

///|
pub impl TypeName for String with fn get_ty() -> String {
  "String"
}

///|
pub impl TypeName for Bool with fn get_ty() -> String {
  "Bool"
}

///|
pub impl TypeName for Unit with fn get_ty() -> String {
  "Unit"
}
