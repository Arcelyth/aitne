///|
using @reactive {type Trigger}

///|
let route_id : Ref[UInt] = @ref.new(0U)

///|
fn next_route_id() -> UInt {
  let id = route_id.val
  route_id.val = id + 1U
  id
}

///|
pub(all) struct NestedRoute[V] {
  id : UInt
  path : String
  child : NestedRoute[V]?
  view : V
}

///|
pub fn[V] NestedRoute::new(path : String, view : V) -> NestedRoute[V] {
  NestedRoute::{ id: next_route_id(), path, child: None, view }
}

///|
pub fn[V] NestedRoute::child(
  self : NestedRoute[V],
  child : NestedRoute[V],
) -> NestedRoute[V] {
  { ..self, child: Some(child) }
}

///|
pub(all) struct NestedMatch[V] {
  id : UInt
  matched : String
  params : Array[(String, String)]
  child : NestedMatch[V]?
  view_fn : V
}

///|
pub fn[V] NestedMatch::build(
  self : NestedMatch[V],
  url : Url,
  base : String?,
  loaders : Ref[Array[() -> Trigger]],
  outlets : Ref[Array[RouteContext]],
  outer_owner : Owner,
) -> Unit {
  let params : RwSignal[Params] = RwSignal::new(to_params(self.params))
  let url_sig = RwSignal::new(url)
  let matched = RwSignal::new(self.matched)

  // TODO: handle outlets 
  let (parent_params, parent_matches) = outlets.val
    .map(r => (r.params, r.matched))
    .unzip()

  let params_with_parents = Memo::new(_ => {
    parent_params
    .iter()
    .flat_map(fn(p) { p.get().iter() })
    .concat(params.get().iter())
    .collect()
  })
  let matched_with_parents = Memo::new(_ => {
    parent_matches
    .iter()
    .flat_map(fn(m) { m.get().iter() })
    .concat(matched.get().iter())
    .collect()
  })

  let trigger = Trigger::new()

  let outlet = RouteContext::{
    id: self.id,
    url: url_sig,
    trigger,
    params,
    matched,
    view_fn: Ref(_ => ()),
    base,
    child: None,
    owner: Ref(None),
    preload_owner: outer_owner.child(),
  }

  if outlets.val.length() > 0 {
    outlets.val[outlets.val.length() - 1].child = Some(outlet)
  }
  outlets.val += [outlet]

  loaders.val += [
    {
      provide_context(params_with_parents)
      provide_context(url_sig)
      provide_context(matched_with_parents)
      outlet.preload_owner.with_(() => {
        provide_context(params_with_parents)
        provide_context(url_sig)
        provide_context(matched_with_parents)
      })
      outlet.view_fn.val = used_owner => {
        outlet.owner.val = Some(used_owner)
        used_owner.with_(() => {
          provide_context(outlet.child)
          provide_context(params_with_parents)
          provide_context(url_sig)
          provide_context(matched_with_parents)
        })
      }
      () => trigger
    },
  ]

  match self.child {
    Some(c) => c.build(url, base, loaders, outlets, outer_owner)
    _ => ()
  }
}

///|
pub fn[V] NestedMatch::rebuild(
  self : NestedMatch[V],
  url : Url,
  base : String?,
  level : Int,
  outer_owner : Owner,
) -> Int {
  level
}

///|
fn split_segments(path : String) -> Array[String] {
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
fn join_prefix(segs : Array[String], end : Int) -> String {
  if end <= 0 {
    return ""
  }
  let mut out = ""
  let mut i = 0
  while i < end {
    out = out + "/" + segs[i]
    i = i + 1
  }
  out
}

///|
fn join_suffix(segs : Array[String], start : Int) -> String {
  if start >= segs.length() {
    return ""
  }
  let mut out = ""
  let mut i = start
  while i < segs.length() {
    out = out + "/" + segs[i]
    i = i + 1
  }
  out
}

///|
pub fn[V] NestedRoute::match_nested(
  self : NestedRoute[V],
  path : String,
) -> ((UInt, NestedMatch[V])?, String) {
  let route_segs = split_segments(self.path)
  let path_segs = split_segments(path)

  if route_segs.length() > path_segs.length() {
    return (None, path)
  }

  let params : Array[(String, String)] = []
  let mut i = 0
  let mut is_wildcard = false
  let mut match_len = route_segs.length()

  while i < route_segs.length() {
    let pat = route_segs[i]
    let seg = path_segs[i]

    if pat == "*" {
      let rest = join_suffix(path_segs, i)
      params.push(("*", rest))
      is_wildcard = true
      match_len = path_segs.length()
      break
    } else if pat.has_prefix(":") {
      params.push((pat[1:].to_owned(), seg))
    } else if pat != seg {
      return (None, path)
    }
    i = i + 1
  }

  let matched = if match_len == 0 {
    "/"
  } else {
    join_prefix(path_segs, match_len)
  }

  let remaining = if is_wildcard {
    ""
  } else {
    join_suffix(path_segs, match_len)
  }

  let (child_match, final_remaining) = match self.child {
    Some(child_route) => {
      let (inner, child_remaining) = child_route.match_nested(remaining)
      match inner {
        Some((_, child)) => (Some(child), child_remaining)
        None =>
          if remaining == "" || remaining == "/" {
            (None, remaining)
          } else {
            return (None, path)
          }
      }
    }
    None =>
      if remaining == "" || remaining == "/" {
        (None, remaining)
      } else {
        return (None, path)
      }
  }

  let id = self.id
  let matched_route = NestedMatch::{
    id,
    matched,
    params,
    child: child_match,
    view_fn: self.view,
  }

  (Some((id, matched_route)), final_remaining)
}

///|
pub fn begins_with_query_or_hash(text : String) -> Bool {
  if text.length() == 0 {
    false
  } else {
    let c = text[0]
    c == '#' || c == '?'
  }
}

///|
pub fn has_scheme(path : String) -> Bool {
  if path.has_prefix("//") ||
    path.has_prefix("tel:") ||
    path.has_prefix("mailto:") {
    true
  } else {
    match path.find("://") {
      None => false
      Some(idx) => {
        let prefix = path[0:idx]
        if prefix.length() == 0 {
          return false
        }
        let mut all_alnum = true
        let mut i = 0
        while i < prefix.length() {
          let c = prefix[i]
          let is_alnum = (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9')
          if !is_alnum {
            all_alnum = false
            break
          }
          i = i + 1
        }
        all_alnum
      }
    }
  }
}

///|
pub fn normalize(path : String, omit_slash : Bool) -> String {
  let mut start = 0
  while start < path.length() && path[start] == '/' {
    start = start + 1
  }
  let s = path[start:].to_owned()

  let mut end = s.length()
  let mut trailing_count = 0
  while end > 0 && s[end - 1] == '/' {
    trailing_count = trailing_count + 1
    end = end - 1
  }

  let s = if trailing_count > 0 { s[:end + 1].to_owned() } else { s }

  if s == "" || omit_slash || begins_with_query_or_hash(s) {
    s
  } else {
    "/" + s
  }
}

///|
pub fn resolve_path(base : String, path : String, from : String?) -> String {
  if has_scheme(path) {
    path
  } else {
    let base_path = normalize(base, false)
    let from_path = from.map(fn(f) { normalize(f, false) })

    let result = match from_path {
      Some(from_path) =>
        if path.has_prefix("/") {
          base_path
        } else if !from_path.has_prefix(base_path) {
          base_path + from_path
        } else {
          from_path
        }
      None => base_path
    }

    let result_empty = result == ""
    let prefix = if result_empty { "/" } else { result }
    prefix + normalize(path, result_empty)
  }
}

///|
pub fn use_resolved_path(path : String) -> Memo[String] {
  let rctx : RouterContext? = use_context()
  let ctx = match rctx {
    Some(c) => c
    None => {
      println("[Error] call use_resolved_path outside the range of router")
      panic()
    }
  }

  let mctx : Matched? = use_context()
  let matched_signal = match mctx {
    Some(m) => Some(m.0)
    None => None
  }

  Memo::new(fn(_) {
    if path.has_prefix("/") {
      path
    } else {
      let from = match matched_signal {
        Some(sig) => Some(sig.get())
        None => None
      }

      ctx.resolve_path(path, from)
    }
  })
}

///|
pub fn normalize_path(path : String) -> String {
  if path == "" {
    return ""
  }

  let q_idx = path.find("?")
  let h_idx = path.find("#")

  let end_idx = match (q_idx, h_idx) {
    (Some(q), Some(h)) => if q < h { q } else { h }
    (Some(q), None) => q
    (None, Some(h)) => h
    (None, None) => path.length()
  }

  let pathname = path[0:end_idx].to_owned()

  let segments = []

  let mut start = 0
  let mut i = 0

  while i < pathname.length() {
    if pathname[i] == '/' {
      segments.push(pathname[start:i].to_owned())
      start = i + 1
    }
    i = i + 1
  }

  let tail = pathname[start:]
  segments.push(tail.to_owned())

  let segments = segments.rev()

  let init = if segments.length() > 0 && segments[0] == ".." { "/" } else { "" }

  let mut del = 0
  let mut res = init

  for seg in segments {
    if seg == ".." {
      del = del + 1
    } else if seg == "." {
      ()
    } else if del > 0 {
      del = del - 1
    } else {
      res = seg + "/" + res
    }
  }

  if res.length() > 0 {
    res = res[:res.length() - 1].to_owned()
  }

  if !res.has_prefix("/") {
    res = "/" + res
  }

  while res.length() > 1 && res.has_suffix("/") {
    res = res[:res.length() - 1].to_owned()
  }

  res
}
