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
fn capitalize_event(s : String) -> String {
  if s.length() == 0 {
    return ""
  }
  let c = s[0]
  let upper = if c >= 'a' && c <= 'z' {
    match Int::to_char(c.to_int() - 32) {
      Some(a) => a.to_string()
      _ => c.to_string()
    }
  } else {
    c.to_string()
  }
  upper + s[1:].to_owned()
}

///|
fn CodeGen::gen_node(self : CodeGen, node : MbxAST) -> Unit {
  match node {
    MbxAST::PureCode(code) => self.buf.write(code)
    MbxAST::TextNode(text) => {
      let s = text.to_owned()
      if s.trim().length() > 0 {
        self.buf.write("\{package_path}/dom.text(\"")
        self.buf.write(@escape.escape_safe(s.trim().to_owned()))
        self.buf.write("\")")
      }
    }
    MbxAST::DynamicNode(code) => {
      self.buf.write("\{package_path}/dom.text_dyn(")
      self.buf.write(code)
      self.buf.write(")")
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
          MbxAST::TextNode(t) =>
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

      for i = 0; i < attrs.length(); i = i + 1 {
        self.gen_attr(attrs[i])
      }
    }
  }
}

///|
fn CodeGen::gen_attr(self : CodeGen, attr : MbxAttribute) -> Unit {
  let name = attr.name.to_owned()
  let scope = match attr.scope {
    Some(s) => s.to_owned()
    None => ""
  }

  if scope == "on" {
    // on:click -> .on(Click, fn(_e) { ... })
    self.buf.write("\n  .on(")
    self.buf.write(capitalize_event(name))
    self.buf.write(", ")
    match attr.value {
      AttrVal::Static(s) => self.buf.write(s)
      AttrVal::Dynamic(c) => self.buf.write(c)
    }
    self.buf.write(")")
  } else {
    self.buf.write("\n  .attr(\"")
    if scope != "" {
      self.buf.write(scope)
      self.buf.write(":")
    }
    self.buf.write(name)
    self.buf.write("\", ")

    match attr.value {
      AttrVal::Static(s) => {
        self.buf.write("\"")
        self.buf.write(@escape.escape_safe(s.to_owned()))
        self.buf.write("\"")
      }
      AttrVal::Dynamic(c) => self.buf.write(c)
    }
    self.buf.write(")")
  }
}
