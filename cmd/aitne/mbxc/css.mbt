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
/// Read a CSS file, validates it against `style_root` parameters, and generates output.
//pub fn from_css_file(
//  path : String,
//  show? : Bool = false,
//  to? : String? = None,
//  tmp? : Bool = false,
//  style_root : Array[String],
//) -> String? {
//  let res = try? @fs.read_file_to_string(path)
//  match res {
//    Ok(content) => {
//      let gen = compile_css(content, path, )
//      if show {
//        println(gen)
//      }
//      match to {
//        Some(target) => {
//          let res2 = try? @fs.write_string_to_file(target, gen)
//          match res2 {
//            Ok(_) => Some(gen)
//            Err(e) => {
//              debug(e)
//              None
//            }
//          }
//        }
//        None => Some(gen)
//      }
//    }
//    Err(e) => {
//      debug(e)
//      None
//    }
//  }
//}
//
