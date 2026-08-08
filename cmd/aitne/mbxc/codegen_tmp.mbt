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
          MbxAST::PureCode(s) =>
            if s.to_owned().trim() != "" {
              dom_kids.push(ci)
            }
          MbxAST::DynamicCode(dc) => {
            let mut has_el = false
            for c in dc {
              match c {
                MbxAST::ElementNode(_) => {
                  has_el = true
                  break
                }
                _ => ()
              }
            }
            if !has_el && dc.length() > 0 {
              match dc[0] {
                MbxAST::PureCode(s) | MbxAST::RawText(s) =>
                  if is_code_closure(s) {
                    let snap : Array[DomStep] = []
                    for st in ctx.steps {
                      snap.push(st)
                    }
                    ctx.binds.push(new_text_bind(snap, s.to_owned()))
                    continue
                  }
                _ => ()
              }
            }
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
              // Text binding at top level (not inside an element) —
              // still capture the binding but no <!> placeholder.
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
    MbxAST::PureCode(s) => {
      // Re-parsed expressions produce PureCode for text between
      // elements. Treat whitespace-only PureCode as skippable,
      // same as RawText whitespace.
      let t = s.to_owned()
      if t.trim() == "" {
        return
      }
      ctx.ok = false
    }
    MbxAST::StyleNode(_) => ctx.ok = false
  }
}

///|
/// Heuristic: checks whether a code expression likely reads a reactive
/// signal by looking for `.get(` patterns.  If the expression is static
/// (e.g. `() => row_id.to_string()` where row_id is a plain Int), we
/// skip creating an Effect for the text binding.
fn has_signal_read(code : String) -> Bool {
  // Fast check: does the code contain `.get(` or `.selected(`?
  // These are the primary ways to read reactive values.
  code.contains(".get(") || code.contains(".selected(")
}

///|
fn emit_one_step(step : DomStep, code : StringBuilder) -> Unit {
  match step {
    FirstChild => code.write("@Arcelyth/aitne/src/ffi.prim_first_child(")
    NextSibling => code.write("@Arcelyth/aitne/src/ffi.prim_next_sibling(")
  }
}

///|
fn compile_template_island(
  nodes : Array[MbxAST],
  tmpl_counter : Ref[Int],
  cache_decls : StringBuilder,
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
  let cache_var = "__tmpl_cache_" + tid.to_string()
  let safe = escape_moonbit_str(ctx.html.to_string())

  // Emit module-level cache variable (created once, reused across calls)
  cache_decls <+
    "let \{cache_var} : Ref[@Arcelyth/aitne/src/ffi.TemplateElement?] = Ref(None)\n"

  // Emit inline code that uses the module-level cache
  let c = StringBuilder::new()
  c <+ "let \{tmpl_var} = match \{cache_var}.val {\n"
  c <+ "  Some(t) => t\n"
  c <+ "  None => {\n"
  c <+ "    let _t = @Arcelyth/aitne/src/ffi.create_template()\n"
  c <+ "    @Arcelyth/aitne/src/ffi.set_inner_html(_t, \"\{safe}\")\n"
  c <+ "    \{cache_var}.val = Some(_t)\n"
  c <+ "    _t\n"
  c <+ "  }\n"
  c <+ "}\n"
  c <+ "\n  {\n"
  c <+
    "    let _frag = @Arcelyth/aitne/src/ffi.clone_template_content(\{tmpl_var})\n"
  c <+
    "    let _root = @Arcelyth/aitne/src/ffi.prim_first_element_child(@Arcelyth/aitne/src/ffi.cast_element_to_node(_frag))\n"

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
        c <+
          "    let \{vn} = @Arcelyth/aitne/src/ffi.cast_element_to_node(_root)\n"
      } else {
        c <+ "    let \{vn} = "
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
  // Collect reactive bindings to merge into a single RenderEffect.
  // Each entry: (kind, vn, code, text_var_name_for_kind_0)
  let merged : Array[(Int, String, String, String)] = []
  let mut text_counter = 0

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
        let tv = "_t_text_" + text_counter.to_string()
        text_counter = text_counter + 1
        c.write(
          "    let \{tv} = @Arcelyth/aitne/src/ffi.prim_create_text_node(@Arcelyth/aitne/src/dom.document(), (",
        )
        c.write(b.code)
        c.write(")())\n")
        c.write("    @Arcelyth/aitne/src/ffi.dom_append(")
        c.write(vn)
        c.write(", @Arcelyth/aitne/src/ffi.cast_text_to_node(\{tv}))\n")
        if is_code_closure(b.code) && has_signal_read(b.code) {
          merged.push((0, vn, b.code, tv))
        }
      }
      1 =>
        if is_code_closure(b.code) {
          c.write(
            "    @Arcelyth/aitne/src/ffi.dom_set_attr(@Arcelyth/aitne/src/ffi.cast_node_to_element(",
          )
          c.write(vn)
          c.write("), \"class\", (")
          c.write(b.code)
          c.write(")())\n")
          merged.push((1, vn, b.code, ""))
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

  // Emit a single merged RenderEffect for all reactive bindings.
  if merged.length() > 0 {
    c.write("    let _ = @reactive.RenderEffect::new(fn(prev) {\n")
    // Read all reactive values
    for i = 0; i < merged.length(); i = i + 1 {
      let (_, _, code, _) = merged[i]
      c.write("      let val_\{i} = (")
      c.write(code)
      c.write(")()\n")
    }
    c.write("      match prev {\n")
    c.write("        Some((")
    for i = 0; i < merged.length(); i = i + 1 {
      if i > 0 {
        c.write(", ")
      }
      c.write("old_\{i}")
    }
    c.write(")) => {\n")
    // Update each if changed
    for i = 0; i < merged.length(); i = i + 1 {
      let (kind, vn, _, tv) = merged[i]
      if kind == 0 {
        c.write("          if val_\{i} != old_\{i} {\n")
        c.write(
          "            @Arcelyth/aitne/src/ffi.dom_set_text(@Arcelyth/aitne/src/ffi.cast_text_to_node(\{tv}), val_\{i})\n",
        )
        c.write("          }\n")
      } else {
        c.write("          if val_\{i} != old_\{i} {\n")
        c.write(
          "            @Arcelyth/aitne/src/ffi.dom_set_attr(@Arcelyth/aitne/src/ffi.cast_node_to_element(\{vn}), \"class\", val_\{i})\n",
        )
        c.write("          }\n")
      }
    }
    c.write("          (")
    for i = 0; i < merged.length(); i = i + 1 {
      if i > 0 {
        c.write(", ")
      }
      c.write("val_\{i}")
    }
    c.write(")\n")
    c.write("        }\n")
    c.write("        None => (")
    for i = 0; i < merged.length(); i = i + 1 {
      if i > 0 {
        c.write(", ")
      }
      c.write("val_\{i}")
    }
    c.write(")\n")
    c.write("      }\n")
    c.write("    })\n")
  }

  c.write(
    "    @Arcelyth/aitne/src/dom.raw_node(@Arcelyth/aitne/src/ffi.cast_element_to_node(_root))\n  }\n",
  )
  c.to_string()
}

///|
/// Re-lex an Expr attribute value to find embedded ElementNode trees.
/// If the expression contains exactly one top-level ElementNode (plus
/// optional PureCode prefix/suffix), and that element is a template
/// candidate, generates inline template code and returns the rewritten
/// expression.  Returns `None` if the expression cannot be optimized.
fn try_inline_templates_in_expr(
  expr_str : StringView,
  tmpl_counter : Ref[Int],
  cache_decls : StringBuilder,
) -> String? {
  let expr = expr_str.to_owned()
  let lexer = Lexer::new(expr)
  let tokens = lexer.tokenizer() catch { _ => return None }

  // Parse the re-lexed tokens into AST nodes using the same logic as
  // gen_expr_code in codegen.mbt.
  let len = tokens.length()

  fn parse_nodes_inline(
    tokens : Array[Token],
    idx : Ref[Int],
    len : Int,
  ) -> Array[MbxAST] {
    let nodes = []
    while idx.val < len {
      let tok = tokens[idx.val]
      match tok {
        Token::TagClose(_) => break
        Token::BraceOpen => {
          idx.val += 1
          let mut brace_depth = 1
          let local_children = []
          let code_buf = StringBuilder::new()
          while brace_depth > 0 && idx.val < len {
            match tokens[idx.val] {
              Token::BraceOpen => {
                brace_depth += 1
                code_buf.write("{")
                idx.val += 1
              }
              Token::BraceClose => {
                brace_depth -= 1
                if brace_depth > 0 {
                  code_buf.write("}")
                }
                idx.val += 1
              }
              Token::TagOpen(_) | Token::TagSelfClose(_) => {
                let code_str = code_buf.to_string()
                if code_str.length() > 0 {
                  local_children.push(MbxAST::PureCode(code_str))
                }
                code_buf.reset()
                let tag_tok = tokens[idx.val]
                idx.val += 1
                match tag_tok {
                  Token::TagSelfClose(t) =>
                    local_children.push(MbxAST::ElementNode(t.tag, t.attrs, []))
                  Token::TagOpen(t) => {
                    let kids = parse_nodes_inline(tokens, idx, len)
                    if idx.val < len {
                      match tokens[idx.val] {
                        Token::TagClose(c) => if c.tag == t.tag { idx.val += 1 }
                        _ => ()
                      }
                    }
                    local_children.push(
                      MbxAST::ElementNode(t.tag, t.attrs, kids),
                    )
                  }
                  _ => ()
                }
              }
              Token::RawText(text) => {
                code_buf.write(text.to_owned())
                idx.val += 1
              }
              Token::CodeBlock(code) => {
                code_buf.write(code.to_owned())
                idx.val += 1
              }
              _ => idx.val += 1
            }
          }
          let code_str = code_buf.to_string()
          if code_str.length() > 0 {
            local_children.push(MbxAST::PureCode(code_str))
          }
          nodes.push(MbxAST::DynamicCode(local_children))
        }
        _ => {
          idx.val += 1
          match tok {
            Token::RawText(s) => nodes.push(MbxAST::PureCode(s))
            Token::CodeBlock(s) => nodes.push(MbxAST::PureCode(s))
            Token::TagSelfClose(t) =>
              nodes.push(MbxAST::ElementNode(t.tag, t.attrs, []))
            Token::TagOpen(t) => {
              let children = parse_nodes_inline(tokens, idx, len)
              if idx.val < len {
                match tokens[idx.val] {
                  Token::TagClose(c) => if c.tag == t.tag { idx.val += 1 }
                  _ => ()
                }
              }
              nodes.push(MbxAST::ElementNode(t.tag, t.attrs, children))
            }
            _ => ()
          }
        }
      }
    }
    nodes
  }

  let nodes = parse_nodes_inline(tokens, Ref(0), len)

  // Count ElementNodes among top-level nodes.
  let mut el_count = 0
  for i = 0; i < nodes.length(); i = i + 1 {
    match nodes[i] {
      MbxAST::ElementNode(_, _, _) => el_count += 1
      _ => ()
    }
  }
  guard el_count > 0 else { return None }

  // Rebuild the expression string, replacing any top-level
  // ElementNode with the template-based code block.
  let result = StringBuilder::new()
  for i = 0; i < nodes.length(); i = i + 1 {
    match nodes[i] {
      MbxAST::ElementNode(tag, _, _) => {
        guard is_builtin(tag) else { return None }
        let island = [nodes[i]]
        let code = compile_template_island(island, tmpl_counter, cache_decls)
        guard code != "" else { return None }
        result.write(code)
      }
      MbxAST::PureCode(s) => result.write(s.to_owned())
      MbxAST::RawText(s) => result.write(s.to_owned())
      MbxAST::DynamicCode(children) => {
        result.write("{")
        for c in children {
          match c {
            MbxAST::PureCode(s) => result.write(s.to_owned())
            MbxAST::RawText(s) => result.write(s.to_owned())
            MbxAST::ElementNode(etag, _, _) => {
              guard is_builtin(etag) else { return None }
              let island = [c]
              let code = compile_template_island(
                island, tmpl_counter, cache_decls,
              )
              guard code != "" else { return None }
              result.write(code)
            }
            _ => ()
          }
        }
        result.write("}")
      }
      _ => ()
    }
  }
  Some(result.to_string())
}

///|
/// Pre-processing pass: recursively walks the AST and tries to extract
/// template-candidate element trees from Expr attributes of non-built-in
/// elements (e.g. <tr> inside <ForEach children={...}>).  Modifies the
/// AST in-place so that the main compilation pass sees template-based
/// code instead of inline View trees.
fn preprocess_ast(
  ast : Array[MbxAST],
  tc : Ref[Int],
  cache_decls : StringBuilder,
) -> Unit {
  fn preprocess_node(
    node : MbxAST,
    tc : Ref[Int],
    cache_decls : StringBuilder,
  ) -> Unit {
    match node {
      MbxAST::ElementNode(tag, attrs, children) => {
        // Try to extract templates from Expr attrs of non-built-in elements
        if !is_builtin(tag) {
          for j = 0; j < attrs.length(); j = j + 1 {
            let (attr, val) = attrs[j]
            match val {
              AttrValue::Expr(expr_str) =>
                match try_inline_templates_in_expr(expr_str, tc, cache_decls) {
                  Some(new_expr) => attrs[j] = (attr, AttrValue::Expr(new_expr))
                  None => ()
                }
              _ => ()
            }
          }
        }
        // Recurse into element children
        for child in children {
          preprocess_node(child, tc, cache_decls)
        }
      }
      MbxAST::DynamicCode(inner) =>
        for child in inner {
          preprocess_node(child, tc, cache_decls)
        }
      _ => ()
    }
  }

  for node in ast {
    preprocess_node(node, tc, cache_decls)
  }
}

///|
pub fn CodeGenTmp::generate(self : CodeGenTmp) -> String {
  let cache_decls = StringBuilder::new()

  // Pre-process: extract template candidates from Expr attributes
  // of non-built-in elements BEFORE island accumulation.
  // This increments self.tmpl_id for each extracted template.
  preprocess_ast(self.ast, self.tmpl_id, cache_decls)

  let fc = StringBuilder::new()
  let island : Ref[Array[MbxAST]] = Ref([])
  // Share the same counter so template variable names are unique.
  let tc : Ref[Int] = self.tmpl_id
  fn flush(
    self : CodeGenTmp,
    fc : StringBuilder,
    ir : Ref[Array[MbxAST]],
    tc : Ref[Int],
  ) {
    let isl = ir.val
    if isl.length() > 0 {
      let code = compile_template_island(isl, tc, cache_decls)
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
      MbxAST::ElementNode(tag, _, _) =>
        // Non-built-in elements (custom components like <Btn>, <ForEach>)
        // cannot be part of a template island. Flush the current island
        // first, then process the non-built-in element via standard codegen.
        // (Expr attrs have already been processed by preprocess_ast.)
        if !is_builtin(tag) {
          flush(self, fc, island, tc)
          let single = [node]
          let fb = CodeGen::new(path=self.path)
          fc.write(fb.generate(single))
          fc.write(fb.output_style())
        } else {
          let isl = island.val
          isl.push(node)
          island.val = isl
        }
      _ => {
        let isl = island.val
        isl.push(node)
        island.val = isl
      }
    }
  }
  flush(self, fc, island, tc)
  // Emit module-level template cache declarations first,
  // then the main generated code.
  let result = StringBuilder::new()
  result.write(cache_decls.to_string())
  result.write(fc.to_string())
  result.to_string()
}
