using @dom {
  trait View,
  div,
  h1,
  button,
  table,
  tbody,
  tr,
  td,
  a,
  span,
  for_node,
  rx_class,
}

let adjectives : Array[String] = ["pretty", "large", "big", "small", "tall", "short", "long", "handsome", "plain", "quaint", "clean", "elegant", "easy", "angry", "crazy", "helpful", "mushy", "odd", "unsightly", "adorable", "important", "inexpensive", "cheap", "expensive", "fancy"]

let colors : Array[String] = ["red", "yellow", "blue", "green", "pink", "brown", "purple", "white", "black", "orange"]

let nouns : Array[String] = ["table", "chair", "house", "bbq", "desk", "car", "pony", "cookie", "sandwich", "burger", "pizza", "mouse", "keyboard"]

struct Row {
  id : Int
  label : @reactive.ReadSignal[String]
  set_label : @reactive.WriteSignal[String]
}

let next_id : Ref[Int] = Ref(1)
let seed : Ref[Int] = Ref(12345)

fn pseudo_random(max : Int) -> Int {
  seed.val = (seed.val * 1103515245 + 12345) & 0x7fffffff
  seed.val % max
}

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

fn btn(id~: String, text~: String, on_click~: (@ffi.Event) -> Unit) -> &View {
    @Arcelyth/aitne/src/dom.div(children=[@Arcelyth/aitne/src/dom.button(children=[@Arcelyth/aitne/src/dom.text_dyn(
        () => text
      )])
  .on(Click, on_click)
  .attr("type", "button")
  .class("btn btn-primary btn-block")
  .attr("id", id)])
  .class("col-sm-6 smallpad")
}

fn app() -> &View {
  let (data, set_data) = @reactive.create_signal([])
  let (selected, set_selected) = @reactive.create_signal(-1)

  let run = _ => {
    set_data.set(build_data(1000))
  }

  let run_lots = _ => {
    set_data.set(build_data(10000))
  }

  let add = _ => {
    set_data.set(data.get() + build_data(1000))
  }

  let update = _ => {
    let d = data.get()
    for i = 0; i < d.length(); i = i + 10 {
      let row = d[i]
      row.set_label.set(row.label.get() + " !!!")
    }
  }

  let clear = _ => {
    set_data.set([])
  }

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
  @Arcelyth/aitne/src/dom.div(children=[@Arcelyth/aitne/src/dom.div(children=[@Arcelyth/aitne/src/dom.div(children=[@Arcelyth/aitne/src/dom.div(children=[@Arcelyth/aitne/src/dom.h1(children=["Aitne"])])
  .class("col-md-6"), @Arcelyth/aitne/src/dom.div(children=[@Arcelyth/aitne/src/dom.div(children=[btn(text="Create 1,000 rows", on_click=run, id="run"), btn(text="Create 10,000 rows", on_click=run_lots, id="runlots"), btn(text="Append 1,000 rows", on_click=add, id="add"), btn(text="Update every 10th row", on_click=update, id="update"), btn(text="Clear", on_click=clear, id="clear"), btn(text="Swap Rows", on_click=swap_rows, id="swaprows")])
  .class("row")])
  .class("col-md-6")])
  .class("row")])
  .class("jumbotron"), @Arcelyth/aitne/src/dom.table(children=[@Arcelyth/aitne/src/dom.tbody(children=[for_node(() => data.get(), row => { return row.id.to_string() }, row => {
          let row_id = row.id
          @Arcelyth/aitne/src/dom.tr(children=[@Arcelyth/aitne/src/dom.td(children=[@Arcelyth/aitne/src/dom.text_dyn(
        () => row_id.to_string()
      )])
  .class("col-md-1"), @Arcelyth/aitne/src/dom.td(children=[@Arcelyth/aitne/src/dom.a(children=[@Arcelyth/aitne/src/dom.text_dyn(
        () => row.label.get()
      )])
  .on(Click, _ => set_selected.set(row_id))])
  .class("col-md-4"), @Arcelyth/aitne/src/dom.td(children=[@Arcelyth/aitne/src/dom.a(children=[@Arcelyth/aitne/src/dom.span()
  .class("glyphicon glyphicon-remove")
  .attr("aria-hidden", "true")])
  .on(Click, _ => {
                let filtered = data.get().filter(fn(r) { r.id != row_id })
                set_data.set(filtered)
              })])
  .class("col-md-1"), @Arcelyth/aitne/src/dom.td()
  .class("col-md-6")])
  .class(@Arcelyth/aitne/src/dom.rx_class(() => if selector.selected(row_id) {"danger"} else {""}))
        })])])
  .class("table table-hover table-striped test-data"), @Arcelyth/aitne/src/dom.span()
  .class("preloadicon glyphicon glyphicon-remove")
  .attr("aria-hidden", "true")])
  .class("container")
}

fn main {
  let _ = @dom.mount_to_body(() => app())
}
