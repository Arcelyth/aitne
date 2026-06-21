using @dom { trait View, div, h1, button, text, input, ul, li, for_node, text_dyn}
using @ffi {event_target_value}

fn todo_app() -> &View {
  let (input_val, set_input_val) = @reactive.create_signal("")
  let (todo, set_todo) = @reactive.create_signal(["Example."])

  let add_item = (_) => {
    let text = input_val.get()
    if text != "" {
      set_todo.set(todo.get() + [text])
    }
    set_input_val.set("")
  }

  let remove_item = (item) => {
    let new_list = todo.get().filter(fn(t) { t != item })
    set_todo.set(new_list)
  }

  div().children([
    h1().children([text("Todo List")]),
    div().children([
      text_dyn(fn() {
        todo.get().length().to_string()
      })
    ]),
    div().children([
      input()
        .attr("type", "text")
        .value(input_val)
        .on(Input, (ev) => {
          set_input_val.set(event_target_value(ev))
        }),
      button()
        .on(Click, add_item)
        .children([text("Add")])
    ]),

    ul().children([
      for_node(
        () => { todo.get() },
        (item) => { return item }, 
        (item) => {
          li().children([
             text(item),
             
             button()
               .on(Click, (_) => remove_item(item))
               .children([text("Delete")])
          ])
        }
      )
    ])
  ])
}


