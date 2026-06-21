///|
pub extern "js" fn el_as_node(el : Element) -> Node =
  #|(el) => el

///|
pub extern "js" fn text_as_node(t : Text) -> Node =
  #|(t) => t

///|
pub extern "js" fn comment_as_node(c : Comment) -> Node =
  #|(c) => c

///|
pub extern "js" fn node_as_element(node : Node) -> Element =
  #|(node) => node

///|
pub extern "js" fn prim_document() -> Document =
  #|() => document

///|
pub extern "js" fn prim_get_body(doc : Document) -> Node =
  #|(doc) => doc.body

///|
pub extern "js" fn prim_get_element_by_id(doc : Document, id : String) -> Node? =
  #|(doc, id) => { let el = doc.getElementById(id); return el === null ? undefined : el; }

///|
pub extern "js" fn prim_create_element(doc : Document, tag : String) -> Element =
  #|(doc, tag) => doc.createElement(tag)

///|
pub extern "js" fn prim_create_text_node(doc : Document, text : String) -> Text =
  #|(doc, text) => doc.createTextNode(text)

///|
pub extern "js" fn dom_create_comment(text : String) -> Node =
  #|(text) => document.createComment(text)

///|
pub extern "js" fn prim_create_template(html : String) -> Node =
  #|(html) => { const tpl = document.createElement('template'); tpl.innerHTML = html; return tpl.content; }

///|
pub extern "js" fn dom_null_node() -> Node =
  #|() => null

///|
pub extern "js" fn dom_append(parent : Node, child : Node) -> Unit =
  #|(parent, child) => parent.appendChild(child)

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
pub extern "js" fn dom_remove_self(node : Node) -> Unit =
  #|(node) => {
  #|  if (node && node.parentNode) {
  #|    node.parentNode.removeChild(node);
  #|  }
  #|}

///|
pub extern "js" fn dom_remove(node : Node) -> Unit =
  #|(node) => node.remove()

///|
pub extern "js" fn dom_clear_children(node : Node) -> Unit =
  #|(node) => { while (node.firstChild) node.removeChild(node.firstChild); }

///|
pub extern "js" fn prim_clone_node(node : Node) -> Node =
  #|(node) => node.cloneNode(true)

///|
pub extern "js" fn prim_node_eq(a : Node, b : Node) -> Bool =
  #|(a, b) => a === b

///|
pub extern "js" fn prim_is_null(node : Node) -> Bool =
  #|(node) => node === null || node === undefined

///|
pub extern "js" fn dom_is_null(node : Node) -> Bool =
  #|(node) => node === null || node === undefined

///|
pub extern "js" fn prim_first_child(node : Node) -> Node =
  #|(node) => node.firstChild

///|
pub extern "js" fn prim_next_sibling(node : Node) -> Node =
  #|(node) => node.nextSibling

///|
pub extern "js" fn dom_parent(node : Node) -> Node =
  #|(node) => node.parentNode

///|
pub extern "js" fn dom_tag_name(node : Node) -> String =
  #|(node) => node.tagName?.toLowerCase() ?? ""

// ----- Attributes

///|
pub extern "js" fn dom_set_attr(
  el : Element,
  key : String,
  val : String,
) -> Unit =
  #|(el, key, val) => { el.setAttribute(key, val); }

///|
pub extern "js" fn dom_set_attribute(
  el : Element,
  key : String,
  value : String,
) -> Unit =
  #|(el, key, value) => el.setAttribute(key, value)

///|
pub extern "js" fn dom_remove_attr(el : Element, key : String) -> Unit =
  #|(el, key) => { el.removeAttribute(key); }

///|
pub extern "js" fn dom_remove_attribute(el : Element, key : String) -> Unit =
  #|(el, key) => el.removeAttribute(key)

// -----

///|
pub extern "js" fn dom_add_class(node : Node, cls : String) -> Unit =
  #|(node, cls) => { node.classList.add(cls); }

///|
pub extern "js" fn dom_set_text(node : Node, text : String) -> Unit =
  #|(node, text) => { node.textContent = text; }

// ----- Properties

///|
pub extern "js" fn set_property(
  el : Element,
  prop_name : String,
  value : String,
) -> Unit =
  #|(el, prop_name, value) => { el[prop_name] = value; }

///|
pub extern "js" fn dom_set_prop(
  node : Node,
  key : String,
  val : String,
) -> Unit =
  #|(node, key, val) => { node[key] = val; }

///|
pub extern "js" fn remove_property(el : Element, prop_name : String) -> Unit =
  #|(el, prop_name) => { delete el[prop_name]; }

///|
pub extern "js" fn get_property(el : Element, prop_name : String) -> String =
  #|(el, prop_name) => String(el[prop_name] || "")

///|
pub extern "js" fn get_bool_property(el : Element, key : String) -> Bool =
  #|(el, key) => {
  #|  const v = el[key];
  #|  return typeof v === "boolean" ? v : false;
  #|}

///|
pub extern "js" fn dom_set_property_bool(
  el : Element,
  key : String,
  value : Bool,
) -> Unit =
  #|(el, key, value) => el[key] = value

// -----
