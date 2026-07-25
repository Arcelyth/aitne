///|
fn is_ident(c : Char) -> Bool {
  ('a' <= c && c <= 'z') ||
  ('A' <= c && c <= 'Z') ||
  ('0' <= c && c <= '9') ||
  c == '_' ||
  c == '-'
}

///|
/// Extract the containing directory from a file path string.
fn get_dir(path : String) -> String {
  let len = path.length()
  let mut last_slash = -1
  let mut i = len - 1
  while i >= 0 {
    let c = path[i].unsafe_to_char()
    if c == '/' || c == '\\' {
      last_slash = i
      break
    }
    i -= 1
  }
  if last_slash != -1 {
    path[0:last_slash].to_owned()
  } else {
    ""
  }
}

///|
/// Normalize directory names by stripping relative prefixes like `./` or trailing slashes.
fn normalize_dir(dir : String) -> String {
  let len = dir.length()
  let mut start = 0
  if len >= 2 &&
    dir[0].unsafe_to_char() == '.' &&
    (dir[1].unsafe_to_char() == '/' || dir[1].unsafe_to_char() == '\\') {
    start = 2
  }
  let mut end = len
  while end > start &&
        (
          dir[end - 1].unsafe_to_char() == '/' ||
          dir[end - 1].unsafe_to_char() == '\\'
        ) {
    end -= 1
  }
  if start < end {
    dir[start:end].to_owned()
  } else {
    ""
  }
}

///|
/// Convert a normalized directory string into a clean hash-based isolated suffix (FNV-1a 32-bit).
fn hash_string(dir : String) -> String {
  let mut hash : UInt = 0x811c9dc5
  let prime : UInt = 0x01000193

  let len = dir.length()
  let mut i = 0
  while i < len {
    let c = dir[i].unsafe_to_char().to_int().reinterpret_as_uint()
    hash = (hash ^ c) * prime
    i += 1
  }

  let hex_digits = "0123456789abcdef"
  let sb = StringBuilder::new()
  let mut shift = 28
  while shift >= 0 {
    let digit = ((hash >> shift) & 0xF).reinterpret_as_int()
    sb.write_char(hex_digits[digit].unsafe_to_char())
    shift -= 4
  }
  sb.to_string()
}

///|
fn scope_class_string(
  s : String,
  path : String,
  style_root : Array[String],
) -> String {
  let current_dir = normalize_dir(get_dir(path))

  let mut skip_scoping = false
  for root in style_root {
    if current_dir == normalize_dir(root) {
      skip_scoping = true
      break
    }
  }

  if skip_scoping {
    return s
  }

  let suffix = hash_string(current_dir)
  if suffix == "" {
    return s
  }

  let classes = s.split(" ")
  let mut result = ""

  for c in classes {
    let trimmed = c.to_owned()
    if trimmed != "" {
      if result != "" {
        result += " "
      }
      result += trimmed + "_" + suffix
    }
  }

  result
}
