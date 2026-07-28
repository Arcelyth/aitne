///|
using @dom {trait View, for_each}

///|
using @ffi {event_target_value}

///|
fn todo_app() -> &View {
  let (input_val, set_input_val) = @reactive.create_signal("")
  let (todo, set_todo) = @reactive.create_signal(["Example."])

  let add_item = _ => {
    let text = input_val.get()
    if text != "" {
      set_todo.set(todo.get() + [text])
    }
    set_input_val.set("")
  }

  let remove_item = item => {
    let new_list = todo.get().filter(fn(t) { t != item })
    set_todo.set(new_list)
  }

  @Arcelyth/aitne/src/dom.div(children=[
    @Arcelyth/aitne/src/dom.h1(children=["Todo List"]),
    @Arcelyth/aitne/src/dom.div(children=[
      @Arcelyth/aitne/src/dom.text_dyn(() => todo.get().length().to_string()),
    ]),
    @Arcelyth/aitne/src/dom.div(children=[
      @Arcelyth/aitne/src/dom.input()
      .value(input_val)
      .attr("type", "text")
      .on(Input, ev => set_input_val.set(event_target_value(ev))),
      @Arcelyth/aitne/src/dom.button(children=["Add"]).on(Click, add_item),
    ]),
    @Arcelyth/aitne/src/dom.ul(children=[
      for_each(each=() => todo.get().iter(), key=x => { return x }, children=item => {
        @Arcelyth/aitne/src/dom.li(children=[
          @Arcelyth/aitne/src/dom.text_dyn(() => item),
          @Arcelyth/aitne/src/dom.button(children=["\"Delete\""]).on(Click, _ => {
            remove_item(item)
          }),
        ])
      }),
    ]),
  ])
}
