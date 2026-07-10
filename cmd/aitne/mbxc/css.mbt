///|
pub fn compile_css(
  content : String,
  path : String,
  style_root : Array[String],
) -> String {
  let current_dir = normalize_dir(get_dir(path))

  // Exact directory validation matching (subdirectories are NOT excluded)
  let mut skip_scoping = false
  for root in style_root {
    if current_dir == normalize_dir(root) {
      skip_scoping = true
      break
    }
  }

  if skip_scoping {
    return content
  }

  let suffix = make_suffix_from_dir(current_dir)
  let sb = StringBuilder::new()
  let mut i = 0
  let len = content.length()

  let mut in_block = false
  let mut in_pseudo = false
  let mut in_attr = false
  let mut in_string = false
  let mut string_char = '"'

  while i < len {
    let c = content[i]

    if i + 1 < len && c == '/' && content[i + 1] == '*' {
      sb.write_string("/*")
      i += 2
      while i + 1 < len && !(content[i] == '*' && content[i + 1] == '/') {
        sb.write_char(content[i].unsafe_to_char())
        i += 1
      }
      if i + 1 < len {
        sb.write_string("*/")
        i += 2
      }
      continue
    }

    if in_block {
      sb.write_char(c.unsafe_to_char())
      if in_string {
        if c == '\\' && i + 1 < len {
          i += 1
          sb.write_char(content[i].unsafe_to_char())
        } else if c.unsafe_to_char() == string_char {
          in_string = false
        }
      } else if c == '"' || c == '\'' {
        in_string = true
        string_char = c.unsafe_to_char()
      } else if c == '}' {
        in_block = false
      }
      i += 1
      continue
    }

    if c == '{' {
      sb.write_char('{')
      in_block = true
      in_pseudo = false
      in_attr = false
      i += 1
      continue
    }
    if c == '[' {
      sb.write_char('[')
      in_attr = true
      i += 1
      continue
    }
    if c == ']' {
      sb.write_char(']')
      in_attr = false
      i += 1
      continue
    }
    if c == ':' {
      sb.write_char(':')
      in_pseudo = true
      i += 1
      continue
    }
    if c == ' ' ||
      c == ',' ||
      c == '>' ||
      c == '+' ||
      c == '~' ||
      c == '\n' ||
      c == '\t' ||
      c == '\r' {
      sb.write_char(c.unsafe_to_char())
      in_pseudo = false
      i += 1
      continue
    }

    if in_attr || in_pseudo {
      sb.write_char(c.unsafe_to_char())
      i += 1
      continue
    }

    // Bare tags are skipped here entirely and hit the final else fallback
    if c == '.' {
      sb.write_char('.')
      i += 1
      let mut ident = ""
      while i < len && is_ident(content[i].unsafe_to_char()) {
        ident += content[i].unsafe_to_char().to_string()
        i += 1
      }
      if ident != "" {
        if suffix != "" {
          sb.write_string(ident + "_" + suffix)
        } else {
          sb.write_string(ident)
        }
      }
    } else if c == '#' {
      sb.write_char('#')
      i += 1
      let mut ident = ""
      while i < len && is_ident(content[i].unsafe_to_char()) {
        ident += content[i].unsafe_to_char().to_string()
        i += 1
      }
      if ident != "" {
        if suffix != "" {
          sb.write_string(ident + "_" + suffix)
        } else {
          sb.write_string(ident)
        }
      }
    } else {
      sb.write_char(c.unsafe_to_char())
      i += 1
    }
  }

  sb.to_string()
}

///|
/// Read a CSS file, validates it against `style_root` parameters, and generates output.
pub fn from_css_file(
  path : String,
  show? : Bool = false,
  to? : String? = None,
  tmp? : Bool = false,
  style_root : Array[String],
) -> String? {
  let res = try? @fs.read_file_to_string(path)
  match res {
    Ok(content) => {
      let gen = compile_css(content, path, style_root)
      if show {
        println(gen)
      }
      match to {
        Some(target) => {
          let res2 = try? @fs.write_string_to_file(target, gen)
          match res2 {
            Ok(_) => Some(gen)
            Err(e) => {
              debug(e)
              None
            }
          }
        }
        None => Some(gen)
      }
    }
    Err(e) => {
      debug(e)
      None
    }
  }
}
