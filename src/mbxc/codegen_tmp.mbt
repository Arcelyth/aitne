//|
///|
/// Generates MoonBit source code from the parsed MBX AST.
/// Each contiguous group of template nodes is compiled into a static
/// DOM template plus runtime binding instructions.
pub(all) struct CodeGenTmp {
  ast : Array[MbxAST]
}

///|
///
pub fn CodeGenTmp::new(ast : Array[MbxAST]) -> CodeGenTmp {
  CodeGenTmp::{ ast, }
}

///|
/// Converts a node path into a string representation.
fn path_to_str(path : Array[Int]) -> String {
  let mut s = "["
  let len = path.length()
  for i = 0; i < len; i = i + 1 {
    s += path[i].to_string()
    if i < len - 1 {
      s += ", "
    }
  }
  s += "]"
  s
}

///|
fn escape_moonbit_str(s : String) -> String {
  let mut res = ""
  for c in s.iter() {
    match c {
      '"' => res += "\\\""
      '\\' => res += "\\\\"
      '\n' => res += "\\n"
      '\r' => res += "\\r"
      '\t' => res += "\\t"
      _ => res += c.to_string()
    }
  }
  res
}


///|
/// Compiles a single template island into generated MoonBit code.
///
/// The process consists of:
///
/// 1. Walking the AST subtree.
/// 2. Producing a static HTML template string.
/// 3. Collecting dynamic bindings.
/// 4. Generating runtime instructions for:
///    - dynamic attributes
///    - event listeners
///    - dynamic child nodes
///
/// The generated block returns the cloned root DOM node.
fn CodeGenTmp::compile_island(
  _self : CodeGenTmp,
  nodes : Array[MbxAST],
) -> String {
  let mut html = ""
  let bindings : Array[String] = []

  fn walk(node : MbxAST, path : Array[Int]) {
    match node {
      MbxAST::ElementNode(tag, attrs, children) => {
        let tag_str = tag.to_owned()
        html += "<" + tag_str

        for attr in attrs {
          let attr_name = attr.name.to_owned()
          match attr.value {
            AttrVal::Static(v) =>
              html += " " +
                attr_name +
                "=\"" +
                @escape.escape_safe(v.to_owned()) +
                "\""
            AttrVal::Dynamic(code_view) => {
              let code = code_view.to_owned()
              let path_str = path_to_str(path)
              match attr.scope {
                Some(ns) if ns.to_owned() == "on" =>
                  bindings.push(
                    "  @Arcelyth/aitne/src/dom.on(_root, \{path_str}, \"\{attr_name}\", \{code})",
                  )
                _ =>
                  bindings.push(
                    "  @Arcelyth/aitne/src/dom.set_attr(_root, \{path_str}, \"\{attr_name}\", \{code})",
                  )
              }
            }
          }
        }

        if children.length() == 0 {
          html += "></" + tag_str + ">"
        } else {
          html += ">"
          let mut i = 0
          for child in children {
            let new_path = []
            for p in path {
              new_path.push(p)
            }
            new_path.push(i)

            walk(child, new_path)
            i += 1
          }
          html += "</" + tag_str + ">"
        }
      }
      MbxAST::TextNode(t) => html += @escape.escape_safe(t.to_owned())
      MbxAST::DynamicNode(code_view) => {
        html += ""
        let code = code_view.to_owned()
        let path_str = path_to_str(path)
        bindings.push(
          "    @Arcelyth/aitne/src/dom.insert_dynamic(_root, \{path_str}, \{code})",
        )
      }
      MbxAST::PureCode(_) => ()
    }
  }

  let mut root_idx = 0
  for node in nodes {
    walk(node, [root_idx])
    root_idx += 1
  }

  let safe_html = escape_moonbit_str(html)
  let mut block = "\n  {\n"
  block += "    let _tpl = @Arcelyth/aitne/src/dom.create_template(\"\{safe_html}\")\n"
  block += "    let _root = @Arcelyth/aitne/src/dom.clone_node(_tpl)\n"

  for bind in bindings {
    block += "  " + bind + "\n"
  }

  block += "   @Arcelyth/aitne/src/dom.Html::RawNode(_root)\n  }\n"
  return block
}

///|
/// Generates the final MoonBit source output.
///
/// AST nodes are split into two categories:
///
/// - PureCode:
///   emitted directly into the output stream.
///
/// - Template Nodes:
///   accumulated into an island and compiled through
///   `compile_island()`.
///
/// This allows ordinary MoonBit code and MBX templates
/// to coexist within the same source file.
pub fn CodeGenTmp::generate(self : CodeGenTmp) -> String {
  let mut final_code = ""
  let mut current_island : Array[MbxAST] = []

  fn flush_island() {
    if current_island.length() > 0 {
      final_code += self.compile_island(current_island)
      current_island = []
    }
  }

  for node in self.ast {
    match node {
      MbxAST::PureCode(code) => {
        flush_island()
        final_code += code.to_owned()
      }
      _ => current_island.push(node)
    }
  }

  flush_island()
  final_code
}
