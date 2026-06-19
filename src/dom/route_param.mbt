///|
/// Route parameters container.
/// Support path parameters (e.g. :id) and query parameters (?a=1&b=2).
pub struct Params(Array[(String, Array[String])]) derive(Eq)

///|
/// Creates an empty parameter collection.
pub fn Params::empty() -> Params {
  Params([])
}

///|
/// Add a parameter value.
/// Multiple values can exist under the same key.
pub fn Params::add(self : Params, key : String, value : String) -> Unit {
  match self.0.search_by(p => p.0 == key) {
    Some(idx) => self.0[idx].1.push(value)
    None => self.0.push((key, [value]))
  }
}

///|
/// Add a parameter value.
/// Replace any existing value under the same key.
pub fn Params::replace(self : Params, key : String, value : String) -> Unit {
  match self.0.search_by(p => p.0 == key) {
    Some(idx) => {
      self.0.clear()
      self.0[idx].1.push(value)
    }
    None => self.0.push((key, [value]))
  }
}

///|
/// Return the last value associated with the given key.
pub fn Params::get(self : Params, key : String) -> String? {
  for pair in self.0 {
    if pair.0 == key {
      if pair.1.length() > 0 {
        return Some(pair.1[pair.1.length() - 1])
      }
    }
  }
  None
}

///|
/// Return all values associated with the given key.
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
/// Check whether a parameter exists.
pub fn Params::contains(self : Params, key : String) -> Bool {
  self.get(key) is Some(_)
}

///|
/// Merge two parameter collections.
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
/// Parse a URL query string into Params.
///
/// Example:
/// "?page=1&sort=asc"
pub fn Params::from_search(search : String) -> Params {
  let params = Params::empty()

  if search == "" {
    return params
  }

  let q = if search.has_prefix("?") { search[1:] } else { search }

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
pub fn Params::iter(self : Params) -> Iter[(String, String)] {
  self.0
  .iter()
  .flat_map(fn(pair) {
    let (k, vs) = pair
    vs.iter().map(fn(v) { (k, v) })
  })
}

///|
pub fn to_params(tp : Array[(String, String)]) -> Params {
  let res : Array[(String, Array[String])] = []
  
  for pair in tp {
    let (k, v) = pair
    let mut found_idx = -1
    
    let mut i = 0
    while i < res.length() {
      if res[i].0 == k {
        found_idx = i
        break
      }
      i += 1
    }
    
    if found_idx != -1 {
      res[found_idx].1.push(v)
    } else {
      res.push((k, [v]))
    }
  }
  
  Params(res)
}
