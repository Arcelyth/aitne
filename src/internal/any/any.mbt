///|
priv type Object

///|
fn[T] Object::of(value : T) -> Object = "%identity"

///|
fn[T] Object::to(self : Object) -> T = "%identity"

///|
priv trait ToAny {
  fn id() -> Unit = _
  fn get_id(() -> Self) -> TypeId = _
}

///|
impl ToAny with fn id() -> Unit {

}

///|
impl ToAny with fn get_id(_ : () -> Self) -> TypeId {
  Self::id
}

///|
impl[T] ToAny for Ref[T]

///|
fn[T] any_to_string(value : T) -> String = "%any.to_string"

///|
fn[T] type_name(value : () -> T) -> String {
  let string = any_to_string(value)
  guard string is [.. "<obj:() -> ", .. name, '>'] else {
    abort(
      "@Arcelyth/aitne/src/internal/any.type_name: unexpected any.to_string() format: \{string}",
    )
  }
  name.to_owned()
}

///|
struct Any(TypeInfo, Object)

///|
/// Reads the type token and display name saved when this value was boxed.
pub fn Any::type_info(self : Any) -> TypeInfo {
  self.0
}

///|
/// Reads the function-based token used by the conversion methods.
/// Its identity depends on the compiler; see README.md for backend limitations.
pub fn Any::type_id(self : Any) -> TypeId {
  self.0.0
}

///|
/// Reads the compiler-provided type name saved alongside the payload.
/// Conversions compare type tokens, not this text.
pub fn Any::type_name(self : Any) -> String {
  self.0.1
}

///|
#warnings("-unused_constructor")
struct TypeId(() -> Unit)

///|
struct TypeInfo(TypeId, String)

///|
/// Selects the comparison token from a metadata pair.
pub fn TypeInfo::id(self : TypeInfo) -> TypeId {
  self.0
}

///|
/// Selects the diagnostic name from a metadata pair.
pub fn TypeInfo::name(self : TypeInfo) -> String {
  self.1
}

///|
let any_id : TypeId = ToAny::get_id((panic : () -> Ref[Any]))

///|
/// Keeps the payload in a Ref[T], then erases the reference's static type.
/// The container also records T's comparison token and diagnostic name.
/// Passing an Any through this function preserves the existing container.
#as_free_fn
pub fn[T] Any::of(value : T) -> Any {
  let r : Ref[T] = Ref(value)
  let id : TypeId = ToAny::get_id((panic : () -> Ref[T]))
  if physical_equal(id, any_id) {
    let r : Ref[Any] = Object::of(r).to()
    return r.val
  }
  let name : String = type_name((panic : () -> T))
  let info : TypeInfo = TypeInfo(id, name)
  Any(info, Object::of(r))
}

///|
/// Reads the erased box as Ref[T] without consulting its metadata.
/// The caller must ensure T is the payload's original type; a wrong T causes
/// undefined behavior. Use to or try_to when a token check is needed.
pub fn[T] Any::unsafe_coerce(self : Any) -> T {
  let r : Ref[T] = self.1.to()
  r.val
}

///|
/// Describes a failed token check in to: expect identifies the requested T,
/// while actual contains the metadata saved with the payload.
pub suberror TypeMismatch {
  TypeMismatch(expect~ : TypeInfo, actual~ : TypeInfo)
}

///|
pub impl Show for TypeMismatch with fn output(
  self : TypeMismatch,
  logger : &Logger,
) -> Unit {
  let TypeMismatch(expect~, actual~) = self
  logger.write_string(
    "TypeMismatch: expected type '\{expect.name()}' but found type '\{actual.name()}'",
  )
}

///|
pub impl ToJson for TypeMismatch with fn to_json(self : TypeMismatch) -> Json {
  let TypeMismatch(expect~, actual~) = self
  { "TypeMismatch": { "expect": expect.name(), "actual": actual.name() } }
}

///|
/// Reads the payload after comparing its token with T's token.
/// A failed comparison raises TypeMismatch with both sets of metadata.
/// Requesting Any yields the container itself instead of its payload.
pub fn[T] Any::to(self : Any) -> T raise TypeMismatch {
  let id : TypeId = ToAny::get_id((panic : () -> Ref[T]))
  if physical_equal(id, any_id) {
    let r : Ref[T] = Object::of(Ref(self)).to()
    return r.val
  }
  guard physical_equal(self.type_id(), id) else {
    let name = type_name((panic : () -> T))
    raise TypeMismatch::TypeMismatch(expect=TypeInfo(id, name), actual=self.0)
  }
  let r : Ref[T] = self.1.to()
  r.val
}

///|
/// Uses the same token check as to, but represents a mismatch with None.
/// A request for Any produces Some(self).
pub fn[T] Any::try_to(self : Any) -> T? {
  let id : TypeId = ToAny::get_id((panic : () -> Ref[T]))
  if physical_equal(id, any_id) {
    let r : Ref[T] = Object::of(Ref(self)).to()
    return Some(r.val)
  }
  guard physical_equal(self.type_id(), id) else { return None }
  let r : Ref[T] = self.1.to()
  Some(r.val)
}

///|
/// Runs f and boxes its result when T's token matches the payload's token.
/// Otherwise, keeps this container and leaves f uncalled. 
/// Callback errors escape to the caller. Unlike to, 
/// this method has no special case for Any.
pub fn[T, R] Any::map(self : Any, f : (T) -> R raise?) -> Any raise? {
  let id : TypeId = ToAny::get_id((panic : () -> Ref[T]))
  if physical_equal(self.type_id(), id) {
    let r : Ref[T] = self.1.to()
    Any::of(f(r.val))
  } else {
    self
  }
}

///|
pub extend TypeMismatch with Show::{output, to_string}

///|
pub extend TypeMismatch with ToJson::{to_json}
