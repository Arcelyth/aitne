///|
/// This a DOM cache for reducing ffi.
pub struct DomCache {
  mut window : Option[Window]
  mut document : Option[Document]
}

///|
let cache : Ref[DomCache] = { val: { window: None, document: None } }

///|
pub fn window() -> Window {
  match cache.val.window {
    Some(w) => w
    None => {
      let w = prim_window()
      cache.val.window = Some(w)
      w
    }
  }
}

///|
pub fn document() -> Document {
  match cache.val.document {
    Some(d) => d
    None => {
      let d = prim_document()
      cache.val.document = Some(d)
      d
    }
  }
}


