///|
using @reactive {type Memo, type RwSignal, trait TypeName, provide_context}

///|
pub(all) struct Url {
  origin : String
  path : String
  search : String
  search_params : Params
  hash : String
} derive(Debug, Eq)

///|
/// Read the current browser URL.
pub fn Url::current() -> Url {
  let search = @ffi.current_search()
  Url::{
    origin: @ffi.current_origin(),
    path: @ffi.current_pathname(),
    search,
    search_params: Params::from_search(search),
    hash: @ffi.current_hash(),
  }
}

///|
pub fn Url::to_full_path(self : Url) -> String {
  if self.search == "" {
    self.path + self.hash
  } else {
    self.path + "?" + self.search + self.hash
  }
}

///|
pub impl TypeName for Url with fn get_ty() -> String {
  "Url"
}

///|
/// Reactive browser location state.
pub(all) struct Location {
  pathname : Memo[String]
  search : Memo[String]
  hash : Memo[String]
} derive(Debug)

///|
/// Create a reactive Location instance from the current browser URL.
pub fn Location::current() -> Location {
  let (pathname_src, _) = @reactive.create_signal(@ffi.current_pathname())
  let (search_src, _) = @reactive.create_signal(@ffi.current_search())
  let (hash_src, _) = @reactive.create_signal(@ffi.current_hash())

  Location::{
    pathname: Memo::new(fn(_) { pathname_src.get() }),
    search: Memo::new(fn(_) { search_src.get() }),
    hash: Memo::new(fn(_) { hash_src.get() }),
  }
}

///|
pub fn Location::new(url : RwSignal[Url]) -> Location {
  Location::{
    pathname: Memo::new(fn(_) { url.with_val(url => url.path) }),
    search: Memo::new(fn(_) { url.with_val(url => url.search) }),
    hash: Memo::new(fn(_) { url.with_val(url => url.hash) }),
  }
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
) -> (@ffi.Event) -> Unit {
  fn(ev : @ffi.Event) {
    if @ffi.event_default_prevented(ev) {
      return
    }
    if @ffi.event_button(ev) != 0 ||
      @ffi.event_meta_key(ev) ||
      @ffi.event_alt_key(ev) ||
      @ffi.event_ctrl_key(ev) ||
      @ffi.event_shift_key(ev) {
      return
    }

    let origin = @ffi.current_origin()
    let path = @ffi.event_composed_path(ev)

    let mut a : @ffi.Element? = None

    for i in 0..<@ffi.js_array_length(path) {
      let n = @ffi.js_array_get(path, i)

      if @ffi.node_is_anchor(n) {
        a = Some(@ffi.node_as_element(n))
      }
    }

    match a {
      Some(anchor) => {
        let href = @ffi.anchor_href(anchor)
        let target = @ffi.anchor_target(anchor)
        if target != "" {
          return
        }
        if href == "" {
          return
        }

        let rel = @ffi.anchor_get_attr(anchor, "rel")
        if @ffi.anchor_has_attr(anchor, "download") || rel.contains("external") {
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

        @ffi.event_prevent_default(ev)

        let to = path_name +
          (if url.search == "" { "" } else { "?" }) +
          url.search +
          url.hash

        let replace = @ffi.get_bool_property(anchor, "replace")

        let change = LocationChange::{
          value: to,
          replace,
          scroll: !@ffi.anchor_has_attr(anchor, "noscroll") &&
          !@ffi.anchor_has_attr(anchor, "data-noscroll"),
        }

        nav_fn(url, change)
      }
      None => ()
    }
  }
}

///|
/// Browser URL provider that keeps the current URL synchronized
/// with the browser history and navigation events.
pub(all) struct BrowserUrl {
  url : RwSignal[Url]
  path_stack : Array[Url]
  is_back : RwSignal[Bool]
}

///|
pub fn BrowserUrl::current() -> Url {
  Url::current()
}

///|
/// Creates a new browser URL provider initialized from the
/// current browser location.
pub fn BrowserUrl::new() -> BrowserUrl {
  BrowserUrl::{
    url: RwSignal::new(Url::current()),
    path_stack: [],
    is_back: RwSignal::new(false),
  }
}

///|
/// Completes a navigation operation by updating the browser history,
/// recording the navigation stack.
pub fn BrowserUrl::complete_navigation(
  self : BrowserUrl,
  change : LocationChange,
) -> Unit {
  let add_to_stack = match self.path_stack.last() {
    Some(p) => p.to_full_path() != change.value
    None => true
  }

  if change.replace {
    @ffi.history_replace_state(change.value)
  } else {
    @ffi.history_push_state(change.value)
  }

  let cur_url = BrowserUrl::current()
  if add_to_stack {
    self.path_stack.push(cur_url)
  }
  self.is_back.set(false)

  if change.scroll {
    // TODO:
  }
}

///|
/// Parses a URL using a base URL and converts it into a reactive
/// router URL representation.
///
/// Returns an error if the URL cannot be parsed.
pub fn parse_url_with_base(href : String, base : String) -> Result[Url, String] {
  if !@ffi.url_can_parse(href, base) {
    return Err("invalid url")
  }

  let search = strip_leading_qmark(@ffi.url_search_from_base(href, base))
  Ok(Url::{
    origin: @ffi.url_origin_from_base(href, base),
    path: @ffi.url_path_from_base(href, base),
    search,
    search_params: Params::from_search(search),
    hash: @ffi.url_hash_from_base(href, base),
  })
}

///|
/// Initializes browser navigation handling.
///
/// This registers:
/// - click interception for client-side routing
/// - popstate handling for browser back/forward navigation
/// - automatic cleanup when the current reactive owner is disposed
pub fn BrowserUrl::init(self : BrowserUrl, base : String?) -> Unit {
  let base = match base {
    Some(v) => v
    None => ""
  }

  fn navigate(new_url : Url, change : LocationChange) -> Unit {
    self.url.set(new_url)
    self.complete_navigation(change)
  }

  let click_cb = handle_anchor_click(base, parse_url_with_base, navigate)

  let click_handle = @ffi.window_event_listener("click", click_cb)

  fn popstate_cb(_) -> Unit {
    let new_url = BrowserUrl::current()
    let is_nav_back = self.path_stack.length() == 1 ||
      (
        self.path_stack.length() >= 2 &&
        self.path_stack.get(self.path_stack.length() - 2) == Some(new_url)
      )
    if is_nav_back {
      let _ = self.path_stack.pop()
    }

    self.is_back.set(is_nav_back)
    self.url.set(new_url)
  }

  let popstate_handle = @ffi.window_event_listener("popstate", popstate_cb)

  @reactive.on_cleanup(() => {
    @ffi.prim_call_event_handle(click_handle)
    @ffi.prim_call_event_handle(popstate_handle)
  })
}

///|
pub fn BrowserUrl::redirect(self : BrowserUrl, loc : String) -> Unit {
  let current_orig = @ffi.current_origin()

  let url = match parse_url_with_base(loc, current_orig) {
    Ok(u) => u
    Err(_) => return
  }

  if url.origin == current_orig {
    let full_path = url.to_full_path()
    let change = LocationChange::{
      value: full_path,
      replace: true,
      scroll: true,
    }

    let _ = @ffi.request_animation_frame(fn() {
      self.url.set(url)
      self.complete_navigation(change)
    })
  } else {
    let absolute_url = url.origin + url.to_full_path()
    @ffi.set_window_href(absolute_url)
  }
}

///|
fn strip_leading_qmark(str : String) -> String {
  if str.has_prefix("?") {
    str[1:].to_owned()
  } else {
    str
  }
}

///|
pub impl TypeName for BrowserUrl with fn get_ty() -> String {
  "BrowserUrl"
}
