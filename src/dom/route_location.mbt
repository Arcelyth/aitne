///|
using @reactive {type Memo, type WriteSignal, type RwSignal}

///|
pub(all) struct Url {
  origin : String
  path : String
  search : String
  search_params : Params
  hash : String
}

///|
/// Read the current browser URL.
pub fn Url::current() -> Url {
  let search = current_search()
  Url::{
    origin: current_origin(),
    path: current_pathname(),
    search,
    search_params: Params::from_search(search),
    hash: current_hash(),
  }
}

///|
/// Reactive browser location state.
pub(all) struct Location {
  pathname : Memo[String]
  search : Memo[String]
  hash : Memo[String]
  set_pathname : WriteSignal[String]
  set_search : WriteSignal[String]
  set_hash : WriteSignal[String]
}

///|
/// Create a reactive Location instance from the current browser URL.
pub fn Location::new() -> Location {
  let (pathname_src, set_pathname_src) = @reactive.create_signal(
    current_pathname(),
  )
  let (search_src, set_search_src) = @reactive.create_signal(current_search())
  let (hash_src, set_hash_src) = @reactive.create_signal(current_hash())

  Location::{
    pathname: Memo::new(fn(_) { pathname_src.get() }),
    search: Memo::new(fn(_) { search_src.get() }),
    hash: Memo::new(fn(_) { hash_src.get() }),
    set_pathname: set_pathname_src,
    set_search: set_search_src,
    set_hash: set_hash_src,
  }
}

///|
/// Synchronize the location state with the browser URL.
pub fn Location::sync(self : Location) -> Unit {
  self.set_pathname.set(current_pathname())
  self.set_search.set(current_search())
  self.set_hash.set(current_hash())
}

///|
///
pub struct LocationChange {
  value : String
  replace : Bool
  scroll : Bool
} derive(Default)

///|
pub fn handle_anchor_click(
  base : String,
  // TODO: maybe add error type in the future
  parse_with_base : (String, String) -> Result[Url, String],
  nav_fn : (Url, LocationChange) -> Unit,
) -> (Event) -> Unit {
  fn(ev : Event) {
    if event_default_prevented(ev) {
      return
    }
    if event_button(ev) != 0 ||
      event_meta_key(ev) ||
      event_alt_key(ev) ||
      event_ctrl_key(ev) ||
      event_shift_key(ev) {
      return
    }

    let origin = current_origin()
    let path = event_composed_path(ev)

    let mut a : Element? = None

    for i in 0..<js_array_length(path) {
      let n = js_array_get(path, i)

      if node_is_anchor(n) {
        a = Some(node_as_element(n))
      }
    }

    match a {
      Some(anchor) => {
        let href = anchor_href(anchor)
        let target = anchor_target(anchor)
        if target != "" {
          return
        }
        if href == "" {
          return
        }

        let rel = anchor_get_attr(anchor, "rel")
        if anchor_has_attr(anchor, "download") || rel.contains("external") {
          return
        }

        let url = match parse_with_base(href, origin) {
          Ok(u) => u
          Err(_) => return
        }

        if url.origin != origin {
          return
        }

        let path_name = @escape.escape_text_minimal(url.path)
        if base != "" && path_name != "" && !path_name.has_prefix(base) {
          return
        }

        event_prevent_default(ev)

        let to = path_name +
          (if url.search == "" { "" } else { "?" }) +
          url.search +
          url.hash

        let replace = get_bool_property(anchor, "replace")

        let change = LocationChange::{
          value: to,
          replace,
          scroll: !anchor_has_attr(anchor, "noscroll") &&
          !anchor_has_attr(anchor, "data-noscroll"),
        }

        nav_fn(url, change)
      }
      None => ()
    }
  }
}
