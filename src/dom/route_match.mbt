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
  path : String
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
        Some((_, child)) => {
          (Some(child), child_remaining)
        }
        None => {
          if remaining == "" || remaining == "/" {
            (None, remaining)
          } else {
            return (None, path)
          }
        }
      }
    }
    None => {
      if remaining == "" || remaining == "/" {
        (None, remaining)
      } else {
        return (None, path)
      }
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
