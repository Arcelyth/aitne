///|
let __tmpl_cache_0 : Ref[@Arcelyth/aitne/src/ffi.TemplateElement?] = Ref(None)

///|
let __tmpl_cache_1 : Ref[@Arcelyth/aitne/src/ffi.TemplateElement?] = Ref(None)

///|
using @dom {trait View, for_each}

///|
let adjectives : Array[String] = [
  "pretty", "large", "big", "small", "tall", "short", "long", "handsome", "plain",
  "quaint", "clean", "elegant", "easy", "angry", "crazy", "helpful", "mushy", "odd",
  "unsightly", "adorable", "important", "inexpensive", "cheap", "expensive", "fancy",
]

///|
let colors : Array[String] = [
  "red", "yellow", "blue", "green", "pink", "brown", "purple", "white", "black",
  "orange",
]

///|
let nouns : Array[String] = [
  "table", "chair", "house", "bbq", "desk", "car", "pony", "cookie", "sandwich",
  "burger", "pizza", "mouse", "keyboard",
]

///|
struct Row {
  id : Int
  label : @reactive.ReadSignal[String]
  set_label : @reactive.WriteSignal[String]
}

///|
let next_id : Ref[Int] = Ref(1)

///|
let seed : Ref[Int] = Ref(12345)

///|
#inline
fn pseudo_random(max : Int) -> Int {
  seed.val = (seed.val * 1103515245 + 12345) & 0x7fffffff
  seed.val % max
}

///|
fn build_data(count : Int) -> Array[Row] {
  let res = []
  for i = 0; i < count; i = i + 1 {
    let adj = adjectives[pseudo_random(adjectives.length())]
    let col = colors[pseudo_random(colors.length())]
    let nou = nouns[pseudo_random(nouns.length())]
    let label_str = adj + " " + col + " " + nou
    let (label, set_label) = @reactive.create_signal(label_str)
    res.push(Row::{ id: next_id.val, label, set_label })
    next_id.val += 1
  }
  res
}

///|
fn btn(id~ : String, text~ : String, on_click~ : (@ffi.Event) -> Unit) -> &View {
  let __tmpl_1 = match __tmpl_cache_1.val {
    Some(t) => t
    None => {
      let _t = @Arcelyth/aitne/src/ffi.create_template()
      @Arcelyth/aitne/src/ffi.set_inner_html(
        _t, "<div class=\"col-sm-6 smallpad\"><button class=\"btn btn-primary btn-block\" type=\"button\"></button></div>",
      )
      __tmpl_cache_1.val = Some(_t)
      _t
    }
  }
  let _frag = @Arcelyth/aitne/src/ffi.clone_template_content(__tmpl_1)
  let _root = @Arcelyth/aitne/src/ffi.prim_first_element_child(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_frag),
  )
  let _n0 = @Arcelyth/aitne/src/ffi.prim_first_child(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
  )
  @Arcelyth/aitne/src/ffi.dom_set_attr(
    @Arcelyth/aitne/src/ffi.cast_node_to_element(_n0),
    "id",
    id,
  )
  let _ = @Arcelyth/aitne/src/dom.add_event_listener(
    @Arcelyth/aitne/src/ffi.cast_node_to_element(_n0),
    "click",
    on_click,
  )
  let _t_text_0 = @Arcelyth/aitne/src/ffi.prim_create_text_node(
    @Arcelyth/aitne/src/dom.document(),
    (() => text)(),
  )
  @Arcelyth/aitne/src/ffi.dom_append(
    _n0,
    @Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text_0),
  )
  @Arcelyth/aitne/src/dom.raw_node(
    @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
  )
}

///|
fn app() -> &View {
  let (data, set_data) = @reactive.create_signal([])
  let (selected, set_selected) = @reactive.create_signal(-1)

  let run = _ => set_data.set(build_data(1000))

  let run_lots = _ => set_data.set(build_data(10000))

  let add = _ => set_data.update(d => d.add(build_data(1000)))

  let update = _ => {
    let d = data.get()
    for i = 0; i < d.length(); i = i + 10 {
      let row = d[i]
      row.set_label.update(r => r + " !!!")
    }
  }

  let clear = _ => set_data.set([])

  let swap_rows = _ => {
    let d = data.get()
    if d.length() > 998 {
      let list = []
      for i = 0; i < d.length(); i = i + 1 {
        list.push(d[i])
      }
      let item = list[1]
      list[1] = list[998]
      list[998] = item
      set_data.set(list)
    }
  }

  let selector = @reactive.Selector::new(() => selected.get())
  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.div(children=[
      @Arcelyth/aitne/src/dom.div(children=[
        @Arcelyth/aitne/src/dom.div(children=[
          @Arcelyth/aitne/src/dom.h1(children=["Aitne"]),
        ]).class("col-md-6"),
        @Arcelyth/aitne/src/dom.div(children=[
          @Arcelyth/aitne/src/dom.div(children=[
            btn(id="run", text="Create 1,000 rows", on_click=run),
            btn(id="runlots", text="Create 10,000 rows", on_click=run_lots),
            btn(id="add", text="Append 1,000 rows", on_click=add),
            btn(id="update", text="Update every 10th row", on_click=update),
            btn(id="clear", text="Clear", on_click=clear),
            btn(id="swaprows", text="Swap Rows", on_click=swap_rows),
          ]).class("row"),
        ]).class("col-md-6"),
      ]).class("row"),
    ]).class("jumbotron"),
    @Arcelyth/aitne/src/dom.table(children=[
      @Arcelyth/aitne/src/dom.tbody(children=[
        for_each(
          each=() => data.get().iter(),
          key=row => { return row.id.to_string() },
          children=row => {
            let row_id = row.id
            let __tmpl_0 = match __tmpl_cache_0.val {
              Some(t) => t
              None => {
                let _t = @Arcelyth/aitne/src/ffi.create_template()
                @Arcelyth/aitne/src/ffi.set_inner_html(
                  _t, "<tr><td class=\"col-md-1\"></td><td class=\"col-md-4\"><a></a></td><td class=\"col-md-1\"><a><span class=\"glyphicon glyphicon-remove\" aria-hidden=\"true\"></span></a></td><td class=\"col-md-6\"></td></tr>",
                )
                __tmpl_cache_0.val = Some(_t)
                _t
              }
            }
            let _frag = @Arcelyth/aitne/src/ffi.clone_template_content(__tmpl_0)
            let _root = @Arcelyth/aitne/src/ffi.prim_first_element_child(
              @Arcelyth/aitne/src/ffi.cast_element_to_node(_frag),
            )
            let _n0 = @Arcelyth/aitne/src/ffi.cast_element_to_node(_root)
            let _n1 = @Arcelyth/aitne/src/ffi.prim_first_child(
              @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
            )
            let _n2 = @Arcelyth/aitne/src/ffi.prim_first_child(
              @Arcelyth/aitne/src/ffi.prim_next_sibling(
                @Arcelyth/aitne/src/ffi.prim_first_child(
                  @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
                ),
              ),
            )
            let _n3 = @Arcelyth/aitne/src/ffi.prim_first_child(
              @Arcelyth/aitne/src/ffi.prim_next_sibling(
                @Arcelyth/aitne/src/ffi.prim_next_sibling(
                  @Arcelyth/aitne/src/ffi.prim_first_child(
                    @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
                  ),
                ),
              ),
            )
            @Arcelyth/aitne/src/ffi.dom_set_attr(
              @Arcelyth/aitne/src/ffi.cast_node_to_element(_n0),
              "class",
              (() => if selector.selected(row_id) { "danger" } else { "" })(),
            )
            let _t_text_0 = @Arcelyth/aitne/src/ffi.prim_create_text_node(
              @Arcelyth/aitne/src/dom.document(),
              (() => row_id.to_string())(),
            )
            @Arcelyth/aitne/src/ffi.dom_append(
              _n1,
              @Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text_0),
            )
            let _ = @Arcelyth/aitne/src/dom.add_event_listener(
              @Arcelyth/aitne/src/ffi.cast_node_to_element(_n2),
              "click",
              _ => set_selected.set(row_id),
            )
            let _t_text_1 = @Arcelyth/aitne/src/ffi.prim_create_text_node(
              @Arcelyth/aitne/src/dom.document(),
              (() => row.label.get())(),
            )
            @Arcelyth/aitne/src/ffi.dom_append(
              _n2,
              @Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text_1),
            )
            let _ = @Arcelyth/aitne/src/dom.add_event_listener(
              @Arcelyth/aitne/src/ffi.cast_node_to_element(_n3),
              "click",
              _ => {
                let filtered = data.get().filter(fn(r) { r.id != row_id })
                set_data.set(filtered)
              },
            )
            let _ = @reactive.RenderEffect::new(fn(prev) {
              let val_0 = (() => {
                if selector.selected(row_id) {
                  "danger"
                } else {
                  ""
                }
              })()
              let val_1 = (() => row.label.get())()
              match prev {
                Some((old_0, old_1)) => {
                  if val_0 != old_0 {
                    @Arcelyth/aitne/src/ffi.dom_set_attr(
                      @Arcelyth/aitne/src/ffi.cast_node_to_element(_n0),
                      "class",
                      val_0,
                    )
                  }
                  if val_1 != old_1 {
                    @Arcelyth/aitne/src/ffi.dom_set_text(
                      @Arcelyth/aitne/src/ffi.cast_text_to_node(_t_text_1),
                      val_1,
                    )
                  }
                  (val_0, val_1)
                }
                None => (val_0, val_1)
              }
            })
            @Arcelyth/aitne/src/dom.raw_node(
              @Arcelyth/aitne/src/ffi.cast_element_to_node(_root),
            )
          },
        ),
      ]),
    ]).class("table table-hover table-striped test-data"),
    @Arcelyth/aitne/src/dom.span()
    .class("preloadicon glyphicon glyphicon-remove")
    .attr("aria-hidden", "true"),
  ]).class("container")
}

///|
fn main {
  let _ = @dom.mount_to_body(() => app())
}
