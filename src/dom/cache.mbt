///|
/// This a DOM cache for reducing ffi.
pub struct DomCache {
  mut window : @ffi.Window?
  mut document : @ffi.Document?
}

///|
let cache : Ref[DomCache] = { val: { window: None, document: None } }

///|
pub fn window() -> @ffi.Window {
  match cache.val.window {
    Some(w) => w
    None => {
      let w = @ffi.prim_window()
      cache.val.window = Some(w)
      w
    }
  }
}

///|
pub fn document() -> @ffi.Document {
  match cache.val.document {
    Some(d) => d
    None => {
      let d = @ffi.prim_document()
      cache.val.document = Some(d)
      d
    }
  }
}
