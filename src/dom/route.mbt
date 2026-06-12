using @reactive { type Memo, type Owner, on_cleanup, type WriteSignal}

///|
pub struct Params(Array[(String, Array[String])]) derive(Eq)

///|
pub fn Params::empty() -> Params {
  Params([])
}

///|
pub fn Params::add(self : Params, key : String, value : String) -> Unit {
  self.0.push((key, [value]))
}

///|
pub fn Params::get(self : Params, key : String) -> Option[String] {
  for pair in self.0 {
    if pair.0 == key {
      if pair.1.length() > 0 {
        return Some(pair.1[0])
      }
    }
  }
  None
}

///|
pub fn Params::get_all(self : Params, key : String) -> Array[String] {
  let values = []
  for pair in self.0 {
    if pair.0 == key {
      for v in pair.1 {
        values.push(v)
      }
    }
  }
  values
}

///|
pub fn Params::contains(self : Params, key : String) -> Bool {
  self.get(key) is Some(_)
}

///|
pub fn Params::merge(self : Params, other : Params) -> Params {
  let new_arr = []
  for pair in self.0 {
    new_arr.push(pair)
  }
  for pair in other.0 {
    new_arr.push(pair)
  }
  Params(new_arr)
}

///|
pub fn Params::from_search(search : String) -> Params {
  let params = Params::empty()

  if search == "" {
    return params
  }

  let q = if search.has_prefix("?") {
    search[1:]
  } else {
    search
  }

  if q == "" {
    return params
  }

  let pairs = q.split("&")
  for pair in pairs {
    if pair == "" {
      continue
    }

    let kv = pair.split("=").to_array()
    if kv.length() == 1 {
      params.add(kv[0].to_owned(), "")
    } else if kv.length() >= 2 {
      params.add(kv[0].to_owned(), kv[1].to_owned())
    }
  }

  params
}

///|
pub(all) struct Url {
  origin: String
  path: String
  search: String
  search_params: Params
  hash: String
}

///|
pub fn Url::current() -> Url {
  let search = current_search()
  Url::{
    origin: current_origin(),
    path: current_pathname(),
    search: search,
    search_params: Params::from_search(search),
    hash: current_hash(),
  }
}

///|
pub(all) struct Location {
  pathname : Memo[String]
  search : Memo[String]
  hash : Memo[String]

  set_pathname : WriteSignal[String] 
  set_search : WriteSignal[String]
  set_hash : WriteSignal[String] 
}

///|
pub fn Location::new() -> Location {
  let (pathname_src, set_pathname_src) = @reactive.create_signal(current_pathname())
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
pub fn Location::sync(self : Location) -> Unit {
  self.set_pathname.set(current_pathname())
  self.set_search.set(current_search())
  self.set_hash.set(current_hash())
}

///|
pub struct RouterContext {
  location : Location
  params : Memo[Params]
  set_params : WriteSignal[Params] 
}

///|
let router_context : @ref.Ref[Option[RouterContext]] = @ref.new(None)

///|
fn create_router_context() -> RouterContext {
  let location = Location::new()
  let (params_src, set_params_src) = @reactive.create_signal(Params::empty())

  let ctx = RouterContext::{
    location: location,
    params: Memo::new(fn(_) { params_src.get() }),
    set_params: set_params_src,
  }

  let _ = on_popstate(fn() {
    ctx.location.sync()
  })

  ctx
}

///|
pub fn ensure_router_context() -> RouterContext {
  match router_context.val {
    Some(ctx) => ctx
    None => {
      let ctx = create_router_context()
      router_context.val = Some(ctx)
      ctx
    }
  }
}

///|
pub fn use_pathname() -> String {
  match router_context.val {
    Some(ctx) => ctx.location.pathname.get()
    None => current_pathname()
  }
}

///|
pub fn use_params() -> Params {
  match router_context.val {
    Some(ctx) => ctx.params.get()
    None => Params::empty()
  }
}

///|
pub fn navigate(path : String) -> Unit {
  history_push_state(path)
  match router_context.val {
    Some(ctx) => ctx.location.sync()
    None => ()
  }
}

///|
pub fn replace(path : String) -> Unit {
  history_replace_state(path)
  match router_context.val {
    Some(ctx) => ctx.location.sync()
    None => ()
  }
}

///|
pub struct Route {
  path : String
  view : (Html) -> Html
  children : Array[Route]
}

///|
pub fn Route::new(path : String, view : () -> Html) -> Route {
  Route::{
    path: path,
    view: fn(_outlet : Html) -> Html { view() },
    children: [],
  }
}

///|
pub fn Route::parent(
  path : String,
  view : (Html) -> Html,
  children : Array[Route],
) -> Route {
  Route::{
    path: path,
    view: view,
    children: children,
  }
}

///|
pub struct PathMatch {
  matched : Bool
  consumed : Int
  params : Params
}

///|
pub struct RenderedRoute {
  html : Html
  params : Params
}

///|
pub fn split_path(path : String) -> Array[String] {
  let parts = path.split("/")
  let segs = []

  for part in parts {
    if part != "" {
      segs.push(part.to_owned())
    }
  }

  segs
}

///|
pub fn join_segments(segments : Array[String], start : Int) -> String {
  let mut out = ""
  let mut first = true
  let mut i = start

  while i < segments.length() {
    if !first {
      out = out + "/"
    }
    out = out + segments[i]
    first = false
    i = i + 1
  }

  out
}

///|
pub fn match_path(pattern : String, segments : Array[String], start : Int) -> PathMatch {
  let pat = split_path(pattern)

  if pat.length() == 0 {
    return PathMatch::{ matched: true, consumed: 0, params: Params::empty() }
  }

  if start + pat.length() > segments.length() {
    return PathMatch::{ matched: false, consumed: 0, params: Params::empty() }
  }

  let params = Params::empty()

  let mut i = 0
  while i < pat.length() {
    let p = pat[i]
    let s = segments[start + i]

    if p == "*" {
      params.add("*", join_segments(segments, start + i))
      return PathMatch::{
        matched: true,
        consumed: segments.length() - start,
        params: params,
      }
    } else if p.has_prefix(":") {
      params.add(p[1:].to_owned(), s)
    } else if p != s {
      return PathMatch::{ matched: false, consumed: 0, params: Params::empty() }
    }

    i = i + 1
  }

  PathMatch::{ matched: true, consumed: pat.length(), params: params }
}

///|
pub fn match_routes(
  routes : Array[Route],
  segments : Array[String],
  start : Int,
  inherited_params : Params,
  outlet : Html,
) -> Option[RenderedRoute] {
  for route in routes {
    let pm = match_path(route.path, segments, start)
    if !pm.matched {
      continue
    }

    let merged = inherited_params.merge(pm.params)
    let next = start + pm.consumed

    if route.children.length() == 0 {
      if next == segments.length() {
        return Some(RenderedRoute::{
          html: (route.view)(outlet),
          params: merged,
        })
      } else {
        continue
      }
    }

    match match_routes(route.children, segments, next, merged, outlet) {
      Some(child) => {
        return Some(RenderedRoute::{
          html: (route.view)(child.html),
          params: child.params,
        })
      }
      None => {
        if next == segments.length() {
          return Some(RenderedRoute::{
            html: (route.view)(outlet),
            params: merged,
          })
        }
      }
    }
  }

  None
}

///|
pub(all) struct RouterBuilder {
  routes : Array[Route]
  fallback : () -> Html
}

///|
pub fn router(routes : Array[Route], fallback : () -> Html) -> Html {
  Html::Router(RouterBuilder::{
    routes: routes,
    fallback: fallback,
  })
}

///|
pub fn routes(routes : Array[Route], fallback : () -> Html) -> Html {
  router(routes, fallback)
}

///|
pub fn link(href : String, child : Html) -> Html {
  a()
    .attr("href", href)
    .on(Click, fn(ev) {
      event_prevent_default(ev)
      navigate(href)
    })
    .children([child])
}

