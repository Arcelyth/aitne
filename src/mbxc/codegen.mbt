///|
let package_path = "@Arcelyth/aitne/src"

///|
pub struct CodeGen {
  buf : StringBuilder
}

///|
pub fn CodeGen::new() -> CodeGen {
  { buf: StringBuilder::new() }
}

///|
pub fn CodeGen::generate(self : CodeGen, ast_nodes : Array[MbxAST]) -> String {
  for i = 0; i < ast_nodes.length(); i = i + 1 {
    self.gen_node(ast_nodes[i])
  }
  self.buf.to_string()
}

///|
fn capitalize_event(event : String) -> String {
  match event {
    "click" => "Click"
    "input" => "Input"
    "change" => "Change"
    "blur" => "Blur"
    _ => event
  }
}

///|
fn CodeGen::gen_node(self : CodeGen, node : MbxAST) -> Unit {
  match node {
    MbxAST::PureCode(code) => self.buf.write(code)
    MbxAST::RawText(text) => {
      let trim_t = text.trim()
      self.buf.write("\"")
      self.buf.write(escape_moonbit_str(trim_t.to_owned()))
      self.buf.write("\"")
    }
    MbxAST::DynamicCode(local_children) => {
      let mut contains_element = false
      for child in local_children {
        match child {
          MbxAST::ElementNode(_) => {
            contains_element = true
            break
          }
          _ => ()
        }
      }

      if contains_element {
        for child in local_children {
          self.gen_node(child)
        }
      } else {
        self.buf.write("\{package_path}/dom.text_dyn(\n        ")
        for child in local_children {
          self.gen_node(child)
        }
        self.buf.write("\n      )")
      }
    }
    MbxAST::ElementNode(tag, attrs, children) => {
      if @dom.builtin_elements.contains(tag.to_owned()) {
        self.buf.write("\{package_path}/dom.")
      }
      self.buf.write(tag)
      self.buf.write("()")

      let valid_children = []
      for i = 0; i < children.length(); i = i + 1 {
        let child = children[i]
        match child {
          MbxAST::PureCode(t) =>
            if t.to_owned().trim().length() > 0 {
              valid_children.push(child)
            }
          MbxAST::RawText(t) =>
            if t.to_owned().trim().length() > 0 {
              valid_children.push(child)
            }
          _ => valid_children.push(child)
        }
      }

      if valid_children.length() > 0 {
        self.buf.write("\n  .children([\n    ")
        for i = 0; i < valid_children.length(); i = i + 1 {
          if i > 0 {
            self.buf.write(",\n    ")
          }
          self.gen_node(valid_children[i])
        }
        self.buf.write("\n  ])")
      }

      attrs.each((attr, val) => self.gen_attr(attr, val))
    }
  }
}

///|
fn CodeGen::gen_attr(
  self : CodeGen,
  attr : TokenAttr,
  val : StringView,
) -> Unit {
  let name = attr.name.to_owned()
  let scope = match attr.ns {
    Some(s) => s.to_owned()
    None => ""
  }

  if scope == "on" {
    self.buf.write("\n  .on(")
    self.buf.write(capitalize_event(name))
    self.buf.write(", ")
    self.buf.write(val)
    self.buf.write(")")
  } else if scope == "" && name == "value" {
    self.buf.write("\n  .value(")
    self.buf.write(val)
    self.buf.write(")")
  } else {
    self.buf.write("\n  .attr(\"")
    if scope != "" {
      self.buf.write(scope)
      self.buf.write(":")
    }
    self.buf.write(name)
    self.buf.write("\", ")

    self.buf.write("\"")
    self.buf.write(escape_moonbit_str(val.to_owned()))
    self.buf.write("\"")
    self.buf.write(")")
  }
}
