// Aitne WASM Runtime Glue
// Provides DOM/browser API imports for Aitne wasm-gc modules.
//
// Usage:
//   <script type="module" src="./runtime/wasm/glue.js"></script>
//   The glue auto-detects the wasm URL from the loading script's data-wasm attribute,
//   or falls back to AITNE_WASM_URL global, or "./app.wasm".

// --- DOM operations (mirrors src/ffi/dom.mbt) ---
function prim_document() {
  return document
}

function prim_get_body(doc) {
  return doc.body
}

function prim_get_element_by_id(doc, id) {
  return doc.getElementById(id) // null when missing — matches prim_is_null
}

function prim_create_element(doc, tag) {
  return doc.createElement(tag)
}

function prim_create_text_node(doc, text) {
  return doc.createTextNode(text)
}

function dom_create_comment(text) {
  return document.createComment(text)
}

function prim_create_template(html) {
  const tpl = document.createElement("template")
  tpl.innerHTML = html
  return tpl.content
}

function dom_null_node() {
  return null
}

function dom_append(parent, child) {
  parent.appendChild(child)
}

function dom_insert_before(parent, new_child, ref_child) {
  parent.insertBefore(new_child, ref_child)
}

function dom_remove_child(parent, child) {
  parent.removeChild(child)
}

function dom_remove_self(node) {
  if (node && node.parentNode) {
    node.parentNode.removeChild(node)
  }
}

function dom_remove(node) {
  node.remove()
}

function dom_clear_children(node) {
  while (node.firstChild) node.removeChild(node.firstChild)
}

function prim_clone_node(node) {
  return node.cloneNode(true)
}

function dom_remove_range(start, end) {
  const range = document.createRange()
  range.setStartAfter(start)
  range.setEndBefore(end)
  range.deleteContents()
}

function prim_node_eq(a, b) {
  return a === b
}

function prim_is_null(node) {
  return node === null || node === undefined
}

function element_is_null(el) {
  return el === null || el === undefined
}

function prim_first_child(node) {
  return node.firstChild
}

function prim_first_element_child(node) {
  return node.firstElementChild
}

function prim_next_sibling(node) {
  return node.nextSibling
}

function dom_parent(node) {
  return node.parentNode
}

function dom_tag_name(node) {
  return node.tagName?.toLowerCase() ?? ""
}

function dom_set_attr(el, key, val) {
  el.setAttribute(key, val)
}

function dom_set_attribute(el, key, value) {
  el.setAttribute(key, value)
}

function dom_remove_attr(el, key) {
  el.removeAttribute(key)
}

function dom_remove_attribute(el, key) {
  el.removeAttribute(key)
}

function dom_add_class(node, cls) {
  node.classList.add(cls)
}

function dom_set_text(node, text) {
  node.textContent = text
}

function set_property(el, prop_name, value) {
  el[prop_name] = value
}

function dom_set_prop(node, key, val) {
  node[key] = val
}

function remove_property(el, prop_name) {
  delete el[prop_name]
}

function get_property(el, prop_name) {
  return String(el[prop_name] || "")
}

function get_bool_property(el, key) {
  const v = el[key]
  return typeof v === "boolean" ? v : false
}

function dom_set_property_bool(el, key, value) {
  el[key] = value
}

function is_text_node(node) {
  return node.nodeType === 3
}

// --- Event operations (mirrors src/ffi/event.mbt) ---
function dom_add_event(node, ev, handler) {
  node.addEventListener(ev, handler)
}

function prim_add_event_listener(el, name, cb) {
  el.addEventListener(name, cb)
  return () => el.removeEventListener(name, cb)
}

function prim_add_event_listener_capture(el, name, cb) {
  el.addEventListener(name, cb, true)
  return () => el.removeEventListener(name, cb, true)
}

function prim_call_event_handle(handle) {
  handle()
}

function event_target_value(ev) {
  return ev.target ? (ev.target.value || "") : ""
}

function event_target_checked(ev) {
  return ev.target ? !!ev.target.checked : false
}

function event_default_prevented(ev) {
  return ev.defaultPrevented
}

function event_prevent_default(ev) {
  ev.preventDefault()
}

function event_button(ev) {
  return ev.button
}

function event_meta_key(ev) {
  return ev.metaKey
}

function event_alt_key(ev) {
  return ev.altKey
}

function event_ctrl_key(ev) {
  return ev.ctrlKey
}

function event_shift_key(ev) {
  return ev.shiftKey
}

function event_composed_path(ev) {
  return ev.composedPath()
}

function js_array_length(arr) {
  return arr.length
}

function js_array_get(arr, idx) {
  return arr[idx]
}

// --- Template operations (mirrors src/ffi/template.mbt) ---
function create_template() {
  return document.createElement("template")
}

function clone_node_shallow(tpl) {
  return tpl.cloneNode(false)
}

function clone_template_content(tpl) {
  return tpl.content.cloneNode(true)
}

function set_inner_html(tpl, html) {
  tpl.innerHTML = html
}

function first_child_skip_comments(node) {
  let curr = node.firstChild
  while (
    curr &&
    curr.nodeType === 8 &&
    (curr.textContent.startsWith("bo") || curr.textContent.startsWith("bc"))
  ) {
    curr = curr.nextSibling
  }
  return curr || null
}

function next_sibling_skip_comments(node) {
  let curr = node.nextSibling
  while (
    curr &&
    curr.nodeType === 8 &&
    (curr.textContent.startsWith("bo") || curr.textContent.startsWith("bc"))
  ) {
    curr = curr.nextSibling
  }
  return curr || null
}

function parent_node(node) {
  return node.parentNode || null
}

function is_comment_node(node) {
  return node.nodeType === 8
}

function console_error(msg1, node, msg2) {
  console.error(msg1, node, msg2)
}

// --- Window/timer operations (mirrors src/ffi/window.mbt) ---
function prim_window() {
  return window
}

function set_window_href(href) {
  window.location.href = href
}

function window_add_event_listener(ev_name, cb) {
  const f = (e) => cb(e)
  window.addEventListener(ev_name, f)
  return () => window.removeEventListener(ev_name, f)
}

function window_remove_event_listener(handle) {
  handle()
}

function window_event_listener(event, callback) {
  window.addEventListener(event, callback)
  return () => window.removeEventListener(event, callback)
}

function set_timeout(cb, ms) {
  return setTimeout(cb, ms)
}

function clear_timeout(handle) {
  clearTimeout(handle)
}

function set_interval(cb, ms) {
  return setInterval(cb, ms)
}

function clear_interval(handle) {
  clearInterval(handle)
}

function request_animation_frame(cb) {
  return requestAnimationFrame(cb)
}

function cancel_animation_frame(handle) {
  cancelAnimationFrame(handle)
}

// --- Router/location operations (mirrors src/ffi/router.mbt) ---
function current_origin() {
  return location.origin
}

function current_pathname() {
  return location.pathname
}

function current_search() {
  return location.search
}

function current_hash() {
  return location.hash
}

function history_push_state(url) {
  history.pushState(null, "", url)
}

function history_replace_state(url) {
  history.replaceState(null, "", url)
}

function on_popstate(cb) {
  const f = () => cb()
  window.addEventListener("popstate", f)
  return () => window.removeEventListener("popstate", f)
}

function node_is_anchor(node) {
  return node instanceof HTMLAnchorElement
}

function anchor_href(el) {
  return el.href
}

function anchor_target(el) {
  return el.target
}

function anchor_has_attr(el, name) {
  return el.hasAttribute(name)
}

function anchor_get_attr(el, name) {
  return el.getAttribute(name) ?? ""
}

function url_can_parse(href, base) {
  try {
    new URL(href, base)
    return true
  } catch (e) {
    return false
  }
}

function url_origin_from_base(href, base) {
  return new URL(href, base).origin
}

function url_path_from_base(href, base) {
  return new URL(href, base).pathname
}

function url_search_from_base(href, base) {
  return new URL(href, base).search
}

function url_hash_from_base(href, base) {
  return new URL(href, base).hash
}

// --- Reactive bridge (mirrors src/ffi/reactive.mbt) ---
function dom_create_effect(cb) {
  if (globalThis.reactive) globalThis.reactive.create_effect(cb)
}

// --- Cast operations (mirrors src/ffi/cast_wasm.mbt) ---
// These are identity casts at the wasm level — the glue does not need
// to provide them since they are inline WAT, not imports.
// But the JS target counterparts use these same function names.

// --- Assembled import object ---
const aitneImports = {
  // DOM
  prim_document,
  prim_get_body,
  prim_get_element_by_id,
  prim_create_element,
  prim_create_text_node,
  dom_create_comment,
  prim_create_template,
  dom_null_node,
  dom_append,
  dom_insert_before,
  dom_remove_child,
  dom_remove_self,
  dom_remove,
  dom_clear_children,
  prim_clone_node,
  dom_remove_range,
  prim_node_eq,
  prim_is_null,
  element_is_null,
  prim_first_child,
  prim_first_element_child,
  prim_next_sibling,
  dom_parent,
  dom_tag_name,
  dom_set_attr,
  dom_set_attribute,
  dom_remove_attr,
  dom_remove_attribute,
  dom_add_class,
  dom_set_text,
  set_property,
  dom_set_prop,
  remove_property,
  get_property,
  get_bool_property,
  dom_set_property_bool,
  is_text_node,
  // Events
  dom_add_event,
  prim_add_event_listener,
  prim_add_event_listener_capture,
  prim_call_event_handle,
  event_target_value,
  event_target_checked,
  event_default_prevented,
  event_prevent_default,
  event_button,
  event_meta_key,
  event_alt_key,
  event_ctrl_key,
  event_shift_key,
  event_composed_path,
  js_array_length,
  js_array_get,
  // Templates
  create_template,
  clone_node_shallow,
  clone_template_content,
  set_inner_html,
  first_child_skip_comments,
  next_sibling_skip_comments,
  parent_node,
  is_comment_node,
  console_error,
  // Window/timers
  prim_window,
  set_window_href,
  window_add_event_listener,
  window_remove_event_listener,
  window_event_listener,
  set_timeout,
  clear_timeout,
  set_interval,
  clear_interval,
  request_animation_frame,
  cancel_animation_frame,
  // Router
  current_origin,
  current_pathname,
  current_search,
  current_hash,
  history_push_state,
  history_replace_state,
  on_popstate,
  node_is_anchor,
  anchor_href,
  anchor_target,
  anchor_has_attr,
  anchor_get_attr,
  url_can_parse,
  url_origin_from_base,
  url_path_from_base,
  url_search_from_base,
  url_hash_from_base,
  // Reactive
  dom_create_effect,
  int_to_string: (n) => String(n),
}

// --- Boot loader ---
async function boot(wasmUrl) {
  let response
  try {
    response = await fetch(wasmUrl)
  } catch (err) {
    console.error(
      "[aitne] Failed to fetch WASM module. Is the dev server running?\n" +
        "  cd <project-root> && python3 -m http.server 8000\n" +
        "  Then open http://localhost:8000/<path-to-example>/\n" +
        "  Attempted URL: " + wasmUrl,
    )
    throw err
  }

  if (!response.ok) {
    throw new Error(
      `[aitne] WASM module not found (HTTP ${response.status}). ` +
        `Did you run 'moon build <example> --target=wasm-gc' first?\n` +
        `  Attempted URL: ${wasmUrl}`,
    )
  }

  const buffer = await response.arrayBuffer()
  const module = await WebAssembly.compile(buffer)

  // Build the string constants module from wasm imports.
  // Each "_" global import name IS its own value (a string constant).
  const allImports = WebAssembly.Module.imports(module)
  const stringConstants = allImports.filter((i) => i.module === "_")
  let constantsModule
  if (stringConstants.length > 0) {
    try {
      constantsModule = new WebAssembly.Module({
        kind: "module",
        imports: [],
        exports: ["_"],
        declarations: stringConstants.map((i) => ({
          type: "string",
          value: i.name,
        })),
        builtins: ["js-string"],
      })
    } catch (_e) {
      // Engine doesn't support descriptor form — build a plain object fallback
      const globals = {}
      for (const imp of stringConstants) {
        globals[imp.name] = imp.name
      }
      constantsModule = globals
    }
  }

  const importObject = {
    aitne: aitneImports,
    "moonbit:ffi": {
      make_closure: (fnref, closure) => fnref.bind(null, closure),
    },
    "wasm:js-string": {
      length: (s) => s.length,
      charCodeAt: (s, i) => s.charCodeAt(i),
      equals: (a, b) => a === b,
      concat: (a, b) => a + b,
      fromCharCodeArray: (_arr, _start, _len) => {
        // WASM GC arrays are inaccessible from JS.
        // Use `int_to_string` FFI or `String(n)` for number→string.
        return ""
      },
    },
    console: {
      log: (...args) => console.log(...args),
    },
    spectest: {
      print_char: (() => {
        let buf = ""
        return (c) => {
          if (c === 10) {
            buf = ""
          } else {
            buf += String.fromCharCode(c)
          }
        }
      })(),
    },
  }
  importObject._ = constantsModule

  const instance = await WebAssembly.instantiate(module, importObject)
  if (instance.exports._start) {
    instance.exports._start()
  }
  return instance
}

// --- Auto-boot when loaded as module ---
const wasmUrl =
  globalThis.AITNE_WASM_URL ||
  "./app.wasm"

boot(wasmUrl).catch((err) => {
  console.error("[aitne] Boot failed:", err.message || err)
})
