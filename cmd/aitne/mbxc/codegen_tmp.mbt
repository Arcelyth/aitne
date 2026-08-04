///|
pub(all) struct CodeGenTmp {
  ast : Array[MbxAST]
  buf : StringBuilder
  style : StringBuilder
  last_buf : StringBuilder
  path : String
  tmpl_id : Ref[Int]
}

///|
pub fn CodeGenTmp::new(ast : Array[MbxAST], path? : String = "") -> CodeGenTmp {
  {
    ast,
    buf: StringBuilder::new(),
    style: StringBuilder::new(),
    last_buf: StringBuilder::new(),
    path,
    tmpl_id: Ref(0),
  }
}

///|
fn is_builtin(tag : StringView) -> Bool {
  let s = tag.to_owned()
  s.length() > 0 && s[0] >= 'a' && s[0] <= 'z' && builtin_elements.contains(s)
}

///|
/// Records how to locate a DOM node inside the cloned template tree.
priv enum DomStep {
  FirstChild
  NextSibling
}

///|
fn steps_key(steps : Array[DomStep]) -> String {
  let mut s = ""
  for i = 0; i < steps.length(); i = i + 1 {
    match steps[i] {
      FirstChild => s += "f"
      NextSibling => s += "n"
    }
  }
  s
}

///|
/// Represents a dynamic binding attached to a DOM node.
///
/// A binding stores:
/// - the location of the target node
/// - binding type (text/class/attribute/event)
/// - generated expression code
priv struct TBind {
  steps : Array[DomStep]
  kind : Int
  name : String
  code : String
}

///|
fn new_text_bind(steps : Array[DomStep], code : String) -> TBind {
  { steps, kind: 0, name: "", code }
}

///|
fn new_class_bind(steps : Array[DomStep], code : String) -> TBind {
  { steps, kind: 1, name: "class", code }
}

///|
fn new_attr_bind(steps : Array[DomStep], name : String, code : String) -> TBind {
  { steps, kind: 2, name, code }
}

///|
fn new_event_bind(
  steps : Array[DomStep],
  name : String,
  code : String,
) -> TBind {
  { steps, kind: 3, name, code }
}

///|
priv struct WalkCtx {
  html : StringBuilder
  binds : Array[TBind]
  mut ok : Bool
  mut steps : Array[DomStep]
}

///|
fn walk(node : MbxAST, ctx : WalkCtx) -> Unit {
  guard ctx.ok else { return }
  match node {
    MbxAST::ElementNode(tag, attrs, children) => {
      guard is_builtin(tag) else {
        ctx.ok = false
        return
      }
      let tag_str = tag.to_owned()
      let el_steps : Array[DomStep] = []
      for s in ctx.steps {
        el_steps.push(s)
      }
      ctx.html.write("<")
      ctx.html.write(tag_str)
      for i = 0; i < attrs.length(); i = i + 1 {
        let (attr, val) = attrs[i]
        let name = attr.name.to_owned()
        let scope = match attr.ns {
          Some(s) => s.to_owned()
          None => ""
        }
        let full = if scope == "" { name } else { scope + ":" + name }
        match val {
          AttrValue::Str(s) => {
            ctx.html.write(" ")
            ctx.html.write(full)
            ctx.html.write("=\"")
            ctx.html.write(@escape.escape_safe(s.to_owned()))
            ctx.html.write("\"")
          }
          AttrValue::Expr(code) => {
            let c = code.to_owned()
            if scope == "on" {
              ctx.binds.push(new_event_bind(el_steps, name, c))
            } else if scope == "" && name == "class" {
              ctx.binds.push(new_class_bind(el_steps, c))
            } else {
              ctx.binds.push(new_attr_bind(el_steps, full, c))
            }
          }
        }
      }
      if children.length() == 0 {
        ctx.html.write("></")
        ctx.html.write(tag_str)
        ctx.html.write(">")
        return
      }
      ctx.html.write(">")
      // Only count children that produce DOM output (skip whitespace-only text)
      let dom_kids : Array[Int] = []
      for ci = 0; ci < children.length(); ci = ci + 1 {
        match children[ci] {
          MbxAST::RawText(t) =>
            if t.to_owned().trim() != "" {
              dom_kids.push(ci)
            }
          _ => dom_kids.push(ci)
        }
      }
      let base_len = ctx.steps.length()
      for ki = 0; ki < dom_kids.length(); ki = ki + 1 {
        let ci = dom_kids[ki]
        // Build: base + FirstChild + NextSibling*ki
        let new_steps : Array[DomStep] = []
        for j = 0; j < base_len; j = j + 1 {
          new_steps.push(ctx.steps[j])
        }
        new_steps.push(FirstChild)
        for _k = 0; _k < ki; _k = _k + 1 {
          new_steps.push(NextSibling)
        }
        let saved = ctx.steps
        ctx.steps = new_steps
        walk(children[ci], ctx)
        ctx.steps = saved
      }
      ctx.html.write("</")
      ctx.html.write(tag_str)
      ctx.html.write(">")
    }
    MbxAST::RawText(text) => {
      let t = text.to_owned()
      if t.trim() == "" {
        return
      }
      ctx.html.write(@escape.escape_safe(t))
    }
    MbxAST::DynamicCode(children) => {
      let mut has_el = false
      for c in children {
        match c {
          MbxAST::ElementNode(_) => {
            has_el = true
            break
          }
          _ => ()
        }
      }
      if !has_el && children.length() > 0 {
        match children[0] {
          MbxAST::PureCode(s) | MbxAST::RawText(s) =>
            if is_code_closure(s) {
              ctx.html.write("<!>")
              let snap : Array[DomStep] = []
              for st in ctx.steps {
                snap.push(st)
              }
              ctx.binds.push(new_text_bind(snap, s.to_owned()))
              return
            }
          _ => ()
        }
      }
      ctx.ok = false
    }
    MbxAST::PureCode(_) => ctx.ok = false
    MbxAST::StyleNode(_) => ctx.ok = false
  }
}

///|
fn emit_one_step(step : DomStep, code : StringBuilder) -> Unit {
  match step {
    FirstChild => code.write("@Arcelyth/aitne/src/ffi.prim_first_child(")
    NextSibling => code.write("@Arcelyth/aitne/src/ffi.prim_next_sibling(")
  }
}

///|
fn CodeGenTmp::compile_island(
  _self : CodeGenTmp,
  nodes : Array[MbxAST],
  tmpl_counter : Ref[Int],
) -> String {
  let ctx = WalkCtx::{
    html: StringBuilder::new(),
    binds: [],
    ok: true,
    steps: [],
  }
  for i = 0; i < nodes.length(); i = i + 1 {
    guard ctx.ok else { break }
    // Root element is _root itself, so steps start empty for first node
    let new_steps : Array[DomStep] = []
    for k = 0; k < i; k = k + 1 {
      new_steps.push(NextSibling)
    }
    ctx.steps = new_steps
    walk(nodes[i], ctx)
  }
  guard ctx.ok else { return "" }

  let tid = tmpl_counter.val
  tmpl_counter.val = tid + 1
  let tmpl_var = "__tmpl_" + tid.to_string()
  let safe = escape_moonbit_str(ctx.html.to_string())

  let c = StringBuilder::new()
  c.write("let ")
  c.write(tmpl_var)
  c.write(
    " = { let _t = @Arcelyth/aitne/src/ffi.create_template(); @Arcelyth/aitne/src/ffi.set_inner_html(_t, \"",
  )
  c.write(safe)
  c.write("\"); _t }\n")
  c.write("\n  {\n")
  c.write("    let _frag = @Arcelyth/aitne/src/ffi.clone_template_content(")
  c.write(tmpl_var)
  c.write(")\n")
  c.write(
    "    let _root = @Arcelyth/aitne/src/ffi.prim_first_element_child(@Arcelyth/aitne/src/ffi.cast_element_to_node(_frag))\n",
  )

  // Flat approach: each unique step sequence gets a full chain from root
  // Node caching: identical step sequences share the same variable
  let var_map : Array[(String, String)] = []
  let mut vc = 0

  for bi = 0; bi < ctx.binds.length(); bi = bi + 1 {
    let b = ctx.binds[bi]
    let key = steps_key(b.steps)
    let mut vn = ""
    for vi = 0; vi < var_map.length(); vi = vi + 1 {
      if var_map[vi].0 == key {
        vn = var_map[vi].1
        break
      }
    }
    if vn == "" {
      vn = "_n" + vc.to_string()
      vc = vc + 1
      var_map.push((key, vn))
      if b.steps.length() == 0 {
        c.write("    let ")
        c.write(vn)
        c.write(" = @Arcelyth/aitne/src/ffi.cast_element_to_node(_root)\n")
      } else {
        c.write("    let ")
        c.write(vn)
        c.write(" = ")
        let mut si = b.steps.length()
        while si > 0 {
          si = si - 1
          emit_one_step(b.steps[si], c)
        }
        c.write("@Arcelyth/aitne/src/ffi.cast_element_to_node(_root)")
        for _k = 0; _k < b.steps.length(); _k = _k + 1 {
          c.write(")")
        }
        c.write("\n")
      }
    }
  }
  for bi = 0; bi < ctx.binds.length(); bi = bi + 1 {
    let b = ctx.binds[bi]
    let key = steps_key(b.steps)
    let mut vn = ""
    for vi = 0; vi < var_map.length(); vi = vi + 1 {
      if var_map[vi].0 == key {
        vn = var_map[vi].1
        break
      }
    }

    match b.kind {
      0 => {
        c.write("    let _t_parent = @Arcelyth/aitne/src/ffi.dom_parent(")
        c.write(vn)
        c.write(")\n")
        c.write(
          "    let _t_text = @Arcelyth/aitne/src/ffi.prim_create_text_node(@Arcelyth/aitne/src/dom.document(), (",
        )
        c.write(b.code)
        c.write(")())\n")
        c.write(
          "    @Arcelyth/aitne/src/ffi.dom_insert_before(_t_parent, @Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text), ",
        )
        c.write(vn)
        c.write(")\n")
        c.write("    @Arcelyth/aitne/src/ffi.dom_remove(")
        c.write(vn)
        c.write(")\n")
        if is_code_closure(b.code) {
          c.write("    let _ = @reactive.Effect::new(fn(_) {\n")
          c.write(
            "      @Arcelyth/aitne/src/ffi.dom_set_text(@Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text), (",
          )
          c.write(b.code)
          c.write(")())\n")
          c.write("    })\n")
        }
      }
      1 =>
        if is_code_closure(b.code) {
          c.write("    let _ = @reactive.Effect::new(fn(_) {\n")
          c.write(
            "      @Arcelyth/aitne/src/ffi.dom_set_attr(@Arcelyth/aitne/src/ffi.cast_node_to_element(",
          )
          c.write(vn)
          c.write("), \"class\", (")
          c.write(b.code)
          c.write(")())\n")
          c.write("    })\n")
        } else {
          c.write(
            "    @Arcelyth/aitne/src/ffi.dom_set_attr(@Arcelyth/aitne/src/ffi.cast_node_to_element(",
          )
          c.write(vn)
          c.write("), \"class\", ")
          c.write(b.code)
          c.write(")\n")
        }
      2 =>
        if is_code_closure(b.code) {
          c.write(
            "    @Arcelyth/aitne/src/ffi.dom_set_attr(@Arcelyth/aitne/src/ffi.cast_node_to_element(",
          )
          c.write(vn)
          c.write("), \"")
          c.write(escape_moonbit_str(b.name))
          c.write("\", (")
          c.write(b.code)
          c.write(")())\n")
        } else {
          c.write(
            "    @Arcelyth/aitne/src/ffi.dom_set_attr(@Arcelyth/aitne/src/ffi.cast_node_to_element(",
          )
          c.write(vn)
          c.write("), \"")
          c.write(escape_moonbit_str(b.name))
          c.write("\", ")
          c.write(b.code)
          c.write(")\n")
        }
      3 => {
        c.write(
          "    let _ = @Arcelyth/aitne/src/dom.add_event_listener(@Arcelyth/aitne/src/ffi.cast_node_to_element(",
        )
        c.write(vn)
        c.write("), \"")
        c.write(b.name)
        c.write("\", ")
        c.write(b.code)
        c.write(")\n")
      }
      _ => ()
    }
  }
  c.write(
    "    @Arcelyth/aitne/src/dom.raw_node(@Arcelyth/aitne/src/ffi.cast_element_to_node(_root))\n  }\n",
  )
  c.to_string()
}

///|
pub fn CodeGenTmp::generate(self : CodeGenTmp) -> String {
  let fc = StringBuilder::new()
  let island : Ref[Array[MbxAST]] = Ref([])
  let tc : Ref[Int] = Ref(0)

  fn flush(
    self : CodeGenTmp,
    fc : StringBuilder,
    ir : Ref[Array[MbxAST]],
    tc : Ref[Int],
  ) {
    let isl = ir.val
    if isl.length() > 0 {
      let code = self.compile_island(isl, tc)
      if code == "" {
        let fb = CodeGen::new(path=self.path)
        fc.write(fb.generate(isl))
        fc.write(fb.output_style())
      } else {
        fc.write(code)
      }
      ir.val = []
    }
  }

  for node in self.ast {
    match node {
      MbxAST::PureCode(code) => {
        flush(self, fc, island, tc)
        fc.write(code.to_owned())
      }
      MbxAST::StyleNode(styles) => {
        flush(self, fc, island, tc)
        let expanded = expand_css(styles.to_owned(), self.path)
        compile_css(
          expanded,
          self.path,
          Ref(self.style),
          Ref(self.buf),
          Ref(self.last_buf),
        )
        fc.write(self.buf.to_string())
        self.buf.reset()
      }
      _ => {
        let isl = island.val
        isl.push(node)
        island.val = isl
      }
    }
  }
  flush(self, fc, island, tc)
  fc.to_string()
}
