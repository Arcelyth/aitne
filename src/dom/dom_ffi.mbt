///|
pub type Window

///|
pub type Document

///|
pub type Element

///|
pub type Event

///|
pub type TimeoutHandle

///|
pub type IntervalHandle

///|
pub type AnimationFrameHandle

///|
pub type Node

///|
pub type Text

///|
pub type Comment

///|
pub type EventHandle

// --- Js Upcast ---

///|
pub extern "js" fn el_as_node(el : Element) -> Node =
  #|(el) => el

///|
pub extern "js" fn text_as_node(t : Text) -> Node =
  #|(t) => t

///|
pub extern "js" fn comment_as_node(c : Comment) -> Node =
  #|(c) => c

// -----

///|
pub extern "js" fn prim_create_element(doc : Document, tag : String) -> Element =
  #|(doc, tag) => doc.createElement(tag)

///|
pub extern "js" fn dom_null_node() -> Node =
  #|() => null

///|
pub extern "js" fn prim_create_text_node(doc : Document, text : String) -> Text =
  #|(doc, text) => doc.createTextNode(text)

///|
pub extern "js" fn dom_set_attr(
  el : Element,
  key : String,
  val : String,
) -> Unit =
  #|(el, key, val) => { el.setAttribute(key, val); }

///|
pub extern "js" fn dom_remove_attr(el : Element, key : String) -> Unit =
  #|(el, key) => { el.removeAttribute(key); }

///|
pub extern "js" fn dom_append(parent : Node, child : Node) -> Unit =
  #|(parent, child) => parent.appendChild(child)

///|
pub extern "js" fn prim_window() -> Window =
  #|() => window

///|
pub extern "js" fn prim_document() -> Document =
  #|() => document

///|
pub extern "js" fn prim_get_element_by_id(doc : Document, id : String) -> Node? =
  #|(doc, id) => { let el = doc.getElementById(id); return el === null ? undefined : el; }

///|
pub extern "js" fn prim_get_body(doc : Document) -> Node =
  #|(doc) => doc.body

///|
pub extern "js" fn prim_node_eq(a : Node, b : Node) -> Bool =
  #|(a, b) => a === b

///|
pub extern "js" fn set_property(
  el : Element,
  prop_name : String,
  value : String,
) -> Unit =
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
pub extern "js" fn request_animation_frame(
  cb : () -> Unit,
) -> AnimationFrameHandle =
  #|(cb) => requestAnimationFrame(cb)

///|
pub extern "js" fn cancel_animation_frame(
  handle : AnimationFrameHandle,
) -> Unit =
  #|(handle) => cancelAnimationFrame(handle)

///|
pub extern "js" fn window_add_event_listener(
  ev_name : String,
  cb : (Event) -> Unit,
) -> Unit =
  #|(name, cb) => window.addEventListener(name, cb)

///|
pub extern "js" fn window_remove_event_listener(
  ev_name : String,
  cb : (Event) -> Unit,
) -> Unit =
  #|(name, cb) => window.removeEventListener(name, cb)

///|
pub extern "js" fn dom_create_comment(text : String) -> Node =
  #|(text) => document.createComment(text)

///|
pub extern "js" fn dom_insert_before(
  parent : Node,
  new_child : Node,
  ref_child : Node,
) -> Unit =
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
pub extern "js" fn dom_add_class(node : Node, cls : String) -> Unit =
  #|(node, cls) => { node.classList.add(cls); }

///|
pub extern "js" fn dom_add_event(
  node : Node,
  ev : String,
  handler : (Event) -> Unit,
) -> Unit =
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
pub extern "js" fn dom_set_prop(
  node : Node,
  key : String,
  val : String,
) -> Unit =
  #|(node, key, val) => { node[key] = val; }

///|
pub extern "js" fn dom_parent(node : Node) -> Node =
  #|(node) => node.parentNode

///|
pub extern "js" fn dom_remove(node : Node) -> Unit =
  #|(node) => node.remove()

///|
pub extern "js" fn dom_tag_name(node : Node) -> String =
  #|(node) => node.tagName?.toLowerCase() ?? ""

///|
pub extern "js" fn dom_is_null(node : Node) -> Bool =
  #|(node) => node === null || node === undefined

///|
pub extern "js" fn dom_set_attribute(
  el : Element,
  key : String,
  value : String,
) -> Unit =
  #|(el, key, value) => el.setAttribute(key, value)

///|
pub extern "js" fn dom_remove_attribute(el : Element, key : String) -> Unit =
  #|(el, key) => el.removeAttribute(key)

///|
pub extern "js" fn dom_set_property_bool(
  el : Element,
  key : String,
  value : Bool,
) -> Unit =
  #|(el, key, value) => el[key] = value

///|
pub extern "js" fn dom_create_effect(cb : () -> Unit) -> Unit =
  #|(cb) => { if (globalThis.reactive) globalThis.reactive.create_effect(cb); }

///|
pub extern "js" fn prim_add_event_listener(
  el : Element,
  name : String,
  cb : (Event) -> Unit,
) -> EventHandle =
  #|(el, name, cb) => {
  #|  el.addEventListener(name, cb);
  #|  return () => el.removeEventListener(name, cb);
  #|}

///|
pub extern "js" fn prim_add_event_listener_capture(
  el : Element,
  name : String,
  cb : (Event) -> Unit,
) -> EventHandle =
  #|(el, name, cb) => {
  #|  el.addEventListener(name, cb, true);
  #|  return () => el.removeEventListener(name, cb, true);
  #|}

///|
pub extern "js" fn prim_call_event_handle(handle : EventHandle) -> Unit =
  #|(handle) => { handle(); }
