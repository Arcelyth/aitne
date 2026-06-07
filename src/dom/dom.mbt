type Window
type Document
type Element
type Event
type TimeoutHandle
type IntervalHandle
type AnimationFrameHandle
type Node

///|
pub extern "js" fn prim_window() -> Window =
  #|() => window

///|
pub extern "js" fn prim_document() -> Document =
  #|() => document

///|
pub extern "js" fn prim_create_element(doc : Document, tag : String) -> Node = 
  #|(doc, tag) => doc.createElement(tag)

///|
pub extern "js" fn prim_create_text_node(doc : Document, text : String) -> Node = 
  #|(doc, text) => doc.createTextNode(text)

///|
pub extern "js" fn prim_get_element_by_id(doc : Document, id : String) -> Option[Node] = 
  #|(doc, id) => { let el = doc.getElementById(id); return el === null ? undefined : el; }

///|
pub extern "js" fn prim_get_body(doc : Document) -> Node = 
  #|(doc) => doc.body
  
///|
pub extern "js" fn prim_node_eq(a : Node, b : Node) -> Bool =
  #|(a, b) => a === b

///|
pub extern "js" fn set_property(el : Element, prop_name : String, value : String) -> Unit =
  #|(el, prop_name, value) => { el[prop_name] = value; }

///|
pub extern "js" fn remove_property(el : Element, prop_name : String) -> Unit =
  #|(el, prop_name) => { delete el[prop_name]; }

///|
pub extern "js" fn get_property(el : Element, prop_name : String) -> String =
  #|(el, prop_name) => String(el[prop_name] || "")

///|
pub extern "js" fn event_target_value(ev : Event) -> String =
  #|(ev) => ev.target ? (ev.target.value || "") : ""

///|
pub extern "js" fn event_target_checked(ev : Event) -> Bool =
  #|(ev) => ev.target ? !!ev.target.checked : false

///|
pub extern "js" fn set_timeout(cb : () -> Unit, ms : Int) -> TimeoutHandle =
  #|(cb, ms) => setTimeout(cb, ms)

///|
pub extern "js" fn clear_timeout(handle : TimeoutHandle) -> Unit =
  #|(handle) => clearTimeout(handle)

///|
pub extern "js" fn set_interval(cb : () -> Unit, ms : Int) -> IntervalHandle =
  #|(cb, ms) => setInterval(cb, ms)

///|
pub extern "js" fn clear_interval(handle : IntervalHandle) -> Unit =
  #|(handle) => clearInterval(handle)

///|
pub extern "js" fn request_animation_frame(cb : () -> Unit) -> AnimationFrameHandle =
  #|(cb) => requestAnimationFrame(cb)

///|
pub extern "js" fn cancel_animation_frame(handle : AnimationFrameHandle) -> Unit =
  #|(handle) => cancelAnimationFrame(handle)

///|
pub extern "js" fn window_add_event_listener(ev_name : String, cb : (Event) -> Unit) -> Unit =
  #|(name, cb) => window.addEventListener(name, cb)

///|
pub extern "js" fn window_remove_event_listener(ev_name : String, cb : (Event) -> Unit) -> Unit =
  #|(name, cb) => window.removeEventListener(name, cb)

///|
pub extern "js" fn dom_create_comment(text : String) -> Node = 
  #|(text) => document.createComment(text)

///|
pub extern "js" fn dom_insert_before(parent : Node, new_child : Node, ref_child : Node) -> Unit =
  #|(parent, new_child, ref_child) => { parent.insertBefore(new_child, ref_child); }

///|
pub extern "js" fn dom_remove_child(parent : Node, child : Node) -> Unit =
  #|(parent, child) => { parent.removeChild(child); }

///|
extern "js" fn prim_next_sibling(node : Node) -> Node =
  #|(node) => node.nextSibling

///|
extern "js" fn prim_is_null(node : Node) -> Bool =
  #|(node) => node === null || node === undefined


///|
pub extern "js" fn dom_set_text(node : Node, text : String) -> Unit =
  #|(node, text) => { node.textContent = text; }

///|
pub extern "js" fn dom_set_attr(node : Node, key : String, val : String) -> Unit =
  #|(node, key, val) => { node.setAttribute(key, val); }

///|
pub extern "js" fn dom_add_class(node : Node, cls : String) -> Unit =
  #|(node, cls) => { node.classList.add(cls); }

///|
pub extern "js" fn dom_append(parent : Node, child : Node) -> Unit =
  #|(parent, child) => { parent.appendChild(child); }

///|
pub extern "js" fn dom_add_event(node : Node, ev : String, handler : (Event) -> Unit) -> Unit =
  #|(node, ev, handler) => { node.addEventListener(ev, handler); }

///|
pub extern "js" fn prim_first_child(node : Node) -> Node =
  #|(node) => node.firstChild

///|
pub extern "js" fn prim_create_template(html : String) -> Node =
  #|(html) => { const tpl = document.createElement('template'); tpl.innerHTML = html; return tpl.content; }

///|
pub extern "js" fn prim_clone_node(node : Node) -> Node =
  #|(node) => node.cloneNode(true)

///|
pub fn dom_create_element(tag : String) -> Node {
  prim_create_element(document(), tag)
}

///|
pub fn dom_create_text_node(text : String) -> Node {
  prim_create_text_node(document(), text)
}

///|
pub fn dom_get_element_by_id(id : String) -> Option[Node] {
  prim_get_element_by_id(document(), id)
}

///|
pub fn dom_get_body() -> Node {
  prim_get_body(document())
}

///|
pub fn on_window_event(ev_name : String, cb : (Event) -> Unit) -> () -> Unit {
  window_add_event_listener(ev_name, cb)
  fn() {
    window_remove_event_listener(ev_name, cb)
  }
}

///|
pub fn option_node_eq(a : Option[Node], b : Option[Node]) -> Bool {
  match (a, b) {
    (Some(n1), Some(n2)) => prim_node_eq(n1, n2)
    (None, None) => true
    _ => false
  }
}

///|
pub fn dom_next_sibling(node : Node) -> Option[Node] {
  let n = prim_next_sibling(node)
  if prim_is_null(n) {
    None
  } else {
    Some(n)
  }
}

///|
pub(all) enum EventType {
  Click
  Input
  Change
  Submit
  Keydown
  Keyup
}

///|
pub fn EventType::to_string(self : EventType) -> String {
  match self {
    Click   => "click"
    Input   => "input"
    Change  => "change"
    Submit  => "submit"
    Keydown => "keydown"
    Keyup   => "keyup"
  }
}

///|
pub(all) enum Html {
  Element(ElementBuilder)
  Text(String)
  DynText(() -> String)
  For(() -> Array[String], (String) -> String, (String) -> Html)
  RawNode(Node)
}

///|
pub struct ElementBuilder {
  tag: String
  classes: Array[String]
  attrs: Array[(String, String)]
  events: Array[(String, (Event) -> Unit)]
  children: Array[Html]
}

///|
fn el(tag : String) -> Html {
  Html::Element({
    tag, 
    classes: [],
    attrs: [],
    events: [],
    children: [],
  })
}

///|
pub fn Html::class_(self : Html, cls : String) -> Html {
  match self {
    Element(b) => Element({ ..b, classes: b.classes + [cls] })
    other => other
  }
}

///|
pub fn Html::attr(self : Html, key : String, val : String) -> Html {
  match self {
    Element(b) => Element({ ..b, attrs: b.attrs + [(key, val)] })
    other => other
  }
}

///|
pub fn Html::bool_attr(self : Html, key : String, _val : Bool) -> Html {
  match self {
    Element(b) => Element({ ..b, attrs: b.attrs + [(key, "")] })
    other => other
  }
}

///|
pub fn Html::on(self : Html, ev : EventType, handler : (Event) -> Unit) -> Html {
  match self {
    Element(b) => Element({ ..b, events: b.events + [(ev.to_string(), handler)] })
    other => other
  }
}

///|
pub fn Html::children(self : Html, kids : Array[Html]) -> Html {
  match self {
    Element(b) => Element({ ..b, children: kids })
    other => other
  }
}

///|
pub fn create_template(html : String) -> Node {
  prim_create_template(html)
}

///|
pub fn clone_node(template : Node) -> Node {
  prim_clone_node(template)
}

fn walk_path(root : Node, path : Array[Int]) -> Node {
  let mut current = root
  for i in 0..<path.length(){
    let idx = path[i]
    let mut child = prim_first_child(current)
    
    if prim_is_null(child) && idx == 0 {
      let empty_text = dom_create_text_node("")
      dom_append(current, empty_text)
      child = empty_text
    }
    
    current = child
    for _ in 0..<idx {
      current = prim_next_sibling(current)
    }
  }
  current
}

///|
pub fn insert_dynamic(root : Node, path : Array[Int], value_fn : () -> String) -> Unit {
  let target_node = walk_path(root, path)
  
  dom_set_text(target_node, value_fn())
  
  @reactive.create_effect(fn() {
    dom_set_text(target_node, value_fn())
  })
}

///|
pub fn on(root : Node, path : Array[Int], ev_name : String, handler : (Event) -> Unit) -> Unit {
  let target_node = walk_path(root, path)
  dom_add_event(target_node, ev_name, handler)
}

///|
pub fn mount_to_id(id : String, app : Html) -> Unit {
  match dom_get_element_by_id(id) {
    Some(parent) => {let _ = app.mount(parent, None)}
    None => ()
  }
}

///|
pub fn mount_to_body(app : Html) -> Unit {
  let body = dom_get_body()
  let _ = app.mount(body, None)
}

///|
pub fn Html::mount(self : Html, parent : Node, before_node : Option[Node]) -> Node {
  
  fn insert(node: Node) {
    match before_node {
      Some(ref_node) => dom_insert_before(parent, node, ref_node)
      None => dom_append(parent, node)
    }
  }

  match self {
    Text(s) => {
      let node = dom_create_text_node(s)
      insert(node)
      node
    }
    DynText(f) => {
      let node = dom_create_text_node(f())
      insert(node)
      @reactive.create_effect(fn() {
        dom_set_text(node, f())
      })
      node
    }
    Element(b) => {
      let node = dom_create_element(b.tag)
      for cls in b.classes { dom_add_class(node, cls) }
      b.attrs.each(fn(p) { dom_set_attr(node, p.0, p.1) })
      b.events.each(fn(p) { dom_add_event(node, p.0, p.1) })
      for child in b.children { 
        let _ = child.mount(node, None) 
      }
      insert(node)
      node
    }
    For(data_signal, key_fn, view_fn) => {
      mount_dynamic_list(parent, before_node, data_signal, key_fn, view_fn)
    }
    RawNode(node) => {
      insert(node)
      node
    }
  }
}

///|
pub fn mount_dynamic_list(
  parent : Node, 
  external_before : Option[Node], 
  data_signal : () -> Array[String], 
  key_fn : (String) -> String, 
  view_fn : (String) -> Html
) -> Node {
  let start_anchor = dom_create_comment("For-Start")
  let end_anchor = dom_create_comment("For-End")
  
  match external_before {
    Some(ref_node) => {
      dom_insert_before(parent, start_anchor, ref_node)
      dom_insert_before(parent, end_anchor, ref_node)
    }
    None => {
      dom_append(parent, start_anchor)
      dom_append(parent, end_anchor)
    }
  }

  let cached_nodes : Ref[@hashmap.HashMap[String, Node]] = @ref.new(@hashmap.HashMap([])) 

  @reactive.create_effect(fn() {
    let new_data = data_signal()
    let old_cache = cached_nodes.val
    let new_cache: Ref[@hashmap.HashMap[String, Node]] = @ref.new(@hashmap.HashMap([])) 

    let mut current_dom_cursor = dom_next_sibling(start_anchor)

    for item in new_data {
      let key = key_fn(item)
      
      // Check if rendered this data before
      let mut found_node : Option[Node] = None
     
      old_cache.eachi((_, k, v) => { 
          if k == key { found_node = Some(v); return; }
      })

      match found_node {
        Some(existing_node) => {
          // If this data has rendered before and not at the same location then move it
          if option_node_eq(current_dom_cursor, Some(existing_node)) {
             dom_insert_before(parent, existing_node, current_dom_cursor.unwrap_or(end_anchor))
          } else {
             current_dom_cursor = dom_next_sibling(existing_node)
          }
          new_cache.val.set(key, existing_node)
        }
        None => {
          // Add the new data 
          let new_node = view_fn(item).mount(parent, current_dom_cursor)
          new_cache.val.set(key, new_node)
        }
      }
    }

    // Remove the trash data
    old_cache.eachi((_, old_k, old_v) => {
      let mut is_kept = false
      new_cache.val.eachi((_, k, _) => { if k == old_k {is_kept = true; return } })
      if !is_kept {
        // Remove the from the real dom 
        dom_remove_child(parent, old_v)
      }
    })

    cached_nodes.val = new_cache.val
  })

  start_anchor 
}

///|
pub fn div()    -> Html { el("div")    }
///|
pub fn p()      -> Html { el("p")      }
///|
pub fn span()   -> Html { el("span")   }
///|
pub fn h1()     -> Html { el("h1")     }
///|
pub fn h2()     -> Html { el("h2")     }
///|
pub fn h3()     -> Html { el("h3")     }
///|
pub fn button() -> Html { el("button") }
///|
pub fn input()  -> Html { el("input")  }
///|
pub fn ul()     -> Html { el("ul")     }
///|
pub fn li()     -> Html { el("li")     }
///|
pub fn a()      -> Html { el("a")      }
///|
pub fn form()   -> Html { el("form")   }
///|
pub fn label()  -> Html { el("label")  }

///|
pub fn text(s : String) -> Html { Html::Text(s) }
///|
pub fn text_dyn(f : () -> String) -> Html { Html::DynText(f) }
///|
pub fn unit_view() -> Html { Html::Text("") }


