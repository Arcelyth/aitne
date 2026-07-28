///|
using @hashmap {type HashMap}

///|
fn sanitize_field_name(cls : String) -> String {
  let sb = StringBuilder::new()
  let len = cls.length()
  let mut i = 0
  while i < len {
    let c = cls[i].unsafe_to_char()
    if (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '_' {
      sb.write_char(c)
    } else if c == '-' {
      sb.write_char('_')
    }
    i += 1
  }
  let res = sb.to_string()
  if res.length() == 0 {
    "_class"
  } else {
    let first = res[0].unsafe_to_char()
    if (first >= '0' && first <= '9') || (first >= 'A' && first <= 'Z') {
      "_" + res
    } else {
      res
    }
  }
}

///|
pub fn gen_style_struct(
  classes : Array[String],
  suffix : String,
  struct_name : String,
  code : Ref[StringBuilder],
  def_code : Ref[StringBuilder],
) -> Unit {
  let code_sb = code.val
  let def_sb = def_code.val

  let unique_classes = []
  let seen_classes = HashMap([])
  for cls in classes {
    if !seen_classes.contains(cls) {
      seen_classes.set(cls, true)
      unique_classes.push(cls)
    }
  }

  let fields : Array[(String, String)] = []
  let seen_fields = HashMap([])

  for cls in unique_classes {
    let base_field = sanitize_field_name(cls)
    let mut field = base_field
    let mut count = 1
    while seen_fields.contains(field) {
      count += 1
      field = base_field + "_" + count.to_string()
    }
    seen_fields.set(field, true)

    let val = if suffix != "" { cls + "_" + suffix } else { cls }
    fields.push((field, val))
  }

  def_sb.write_string("struct ")
  def_sb.write_string(struct_name)
  def_sb.write_string(" {\n")
  for item in fields {
    let (f_name, _) = item
    def_sb.write_string("  ")
    def_sb.write_string(f_name)
    def_sb.write_string(" : String\n")
  }
  def_sb.write_string("}\n\n")

  code_sb.write_string(struct_name)
  code_sb.write_string("::{\n")
  for item in fields {
    let (f_name, f_val) = item
    code_sb.write_string("  ")
    code_sb.write_string(f_name)
    code_sb.write_string(": \"")
    code_sb.write_string(f_val)
    code_sb.write_string("\",\n")
  }
  code_sb.write_string("}")
}

///|
pub fn compile_css(
  content : String,
  path : String,
  style : Ref[StringBuilder],
  code : Ref[StringBuilder],
  def_code : Ref[StringBuilder],
) -> Unit {
  let current_dir = normalize_dir(get_dir(path))
  let suffix = hash_string(current_dir)
  let sb = style.val
  let mut i = 0
  let len = content.length()

  let classes : Array[String] = []

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

    if c == '.' {
      sb.write_char('.')
      i += 1
      let mut ident = ""
      while i < len && is_ident(content[i].unsafe_to_char()) {
        ident += content[i].unsafe_to_char().to_string()
        i += 1
      }
      if ident != "" {
        classes.push(ident)
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

  let struct_hash = hash_string(path + ":" + content)
  let struct_name = "Style_" + struct_hash

  gen_style_struct(classes, suffix, struct_name, code, def_code)
}

///|
fn slice_string(s : String, start : Int, end : Int) -> String {
  let buf = StringBuilder::new()
  for i = start; i < end; i = i + 1 {
    match s[i].to_char() {
      Some(a) => buf.write_char(a)
      _ => ()
    }
  }
  buf.to_string()
}

///|
fn dirname(path : String) -> String {
  let mut last_slash = -1
  let len = path.length()
  for i = 0; i < len; i = i + 1 {
    if path[i] == '/' || path[i] == '\\' {
      last_slash = i
    }
  }
  if last_slash == -1 {
    ""
  } else {
    slice_string(path, 0, last_slash)
  }
}

///|
fn resolve_path(base_file_path : String, rel_path : String) -> String {
  let is_abs = rel_path.length() > 0 &&
    (rel_path[0] == '/' || rel_path[0] == '\\')
  let dir = if is_abs { "" } else { dirname(base_file_path) }

  let combined = if dir.length() == 0 { rel_path } else { dir + "/" + rel_path }

  let parts : Array[String] = []
  let mut start = 0
  let clen = combined.length()

  for i = 0; i <= clen; i = i + 1 {
    if i == clen || combined[i] == '/' || combined[i] == '\\' {
      if i > start {
        let part = slice_string(combined, start, i)
        if part == "." {

        } else if part == ".." {
          if parts.length() > 0 && parts[parts.length() - 1] != ".." {
            ignore(parts.pop())
          } else if !is_abs {
            parts.push("..")
          }
        } else {
          parts.push(part)
        }
      }
      start = i + 1
    }
  }

  let res = StringBuilder::new()
  if is_abs {
    res.write_string("/")
  }
  for i = 0; i < parts.length(); i = i + 1 {
    if i > 0 {
      res.write_string("/")
    }
    res.write_string(parts[i])
  }
  res.to_string()
}

///|
fn read_file(file_path : String) -> String {
  @fs.read_file_to_string(file_path) catch {
    _ => ""
  }
}

///|
/// Replace !"path.css" or !'path.css' with the content of the file .
pub fn expand_css(orig : String, path : String) -> String {
  let buf = StringBuilder::new()
  let len = orig.length()
  let mut i = 0

  while i < len {
    let c = orig[i]

    if c == '/' && i + 1 < len && orig[i + 1] == '*' {
      buf.write_char('/')
      buf.write_char('*')
      i += 2
      while i < len {
        if orig[i] == '*' && i + 1 < len && orig[i + 1] == '/' {
          buf.write_char('*')
          buf.write_char('/')
          i += 2
          break
        }
        match orig[i].to_char() {
          Some(c) => buf.write_char(c)
          None => ()
        }
        i += 1
      }
    } else if c == '!' &&
      i + 1 < len &&
      (orig[i + 1] == '"' || orig[i + 1] == '\'') {
      let quote = orig[i + 1]
      i += 2

      let path_buf = StringBuilder::new()
      while i < len {
        let ch = orig[i]
        if ch == '\\' && i + 1 < len {
          match orig[i + 1].to_char() {
            Some(c) => path_buf.write_char(c)
            None => ()
          }
          i += 2
        } else if ch == quote {
          i += 1
          break
        } else {
          match ch.to_char() {
            Some(c) => path_buf.write_char(c)
            None => ()
          }

          i += 1
        }
      }

      let rel_import_path = path_buf.to_string()
      let resolved_path = resolve_path(path, rel_import_path)

      let file_content = read_file(resolved_path)

      let expanded_content = expand_css(file_content, resolved_path)
      buf.write_string(expanded_content)
    } else if c == '"' || c == '\'' {
      let quote = c
      match quote.to_char() {
        Some(c) => buf.write_char(c)
        None => ()
      }

      i += 1

      while i < len {
        let ch = orig[i]
        if ch == '\\' && i + 1 < len {
          buf.write_char('\\')
          match orig[i + 1].to_char() {
            Some(c) => buf.write_char(c)
            None => ()
          }

          i += 2
        } else if ch == quote {
          match quote.to_char() {
            Some(c) => buf.write_char(c)
            None => ()
          }
          i += 1
          break
        } else {
          match ch.to_char() {
            Some(c) => buf.write_char(c)
            None => ()
          }
          i += 1
        }
      }
    } else {
      match c.to_char() {
        Some(c) => buf.write_char(c)
        None => ()
      }

      i += 1
    }
  }

  buf.to_string()
}
