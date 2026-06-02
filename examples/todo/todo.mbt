using @dom { type Html, div, h1, button, text, input, ul, li, event_target_value }

// TODO: dynamic bindings
fn todo_app() -> Html {
  let (input_val, set_input_val) = @reactive.create_signal("")
  
  let (todo, set_todo) = @reactive.create_signal(["Example."])

  div().children([
    h1().children([text("Todo List")]),
    
    div().children([
      input()
        .attr("type", "text")
        .on(Input, fn(ev) {
          set_input_val.set(event_target_value(ev))
        }),
      button()
        .on(Click, fn(_ev) {
          let text = input_val.get()
          if text != "" {
            set_todo.set(todo.get() + [text])
          }
          set_input_val.set("")
        })
        .children([text("Add")])
    ]),

    ul().children([
      Html::For(
        fn() { todo.get() },
        
        fn(item) { item }, 
        
        fn(item) {
          li().children([
             text(item),
             
             button()
               .on(Click, fn(_) {
                  let new_list = todo.get().filter(fn(t) { t != item })
                  set_todo.set(new_list)
               })
               .children([text("Delete")])
          ])
        }
      )
    ])
  ])
}


