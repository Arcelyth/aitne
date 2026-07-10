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
/// Convert a normalized directory string into a clean single-underscore isolated suffix.
fn make_suffix_from_dir(dir : String) -> String {
  let sb = StringBuilder::new()
  let len = dir.length()
  let mut i = 0
  let mut last_was_underscore = false

  while i < len {
    let c = dir[i].unsafe_to_char()
    if ('a' <= c && c <= 'z') ||
      ('A' <= c && c <= 'Z') ||
      ('0' <= c && c <= '9') {
      sb.write_char(c)
      last_was_underscore = false
    } else if c == '/' || c == '\\' || c == '.' || c == '-' || c == '_' {
      if !last_was_underscore && i > 0 && i < len - 1 {
        sb.write_char('_')
        last_was_underscore = true
      }
    }
    i += 1
  }

  let res = sb.to_string()
  let res_len = res.length()
  if res_len > 0 && res[res_len - 1].unsafe_to_char() == '_' {
    res[0:res_len - 1].to_owned()
  } else {
    res
  }
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

  let suffix = make_suffix_from_dir(current_dir)
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
