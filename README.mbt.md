# Aitne

A lightweight and high-performance web framework with fine-grained reactivity. Inspired by [leptos](https://github.com/leptos-rs/leptos) and [solidjs](https://github.com/solidjs/solid). Support MBX (JSX-like) format to develop.

## Examples

Todo list: 
```moonbit
///|
using @dom {
  trait View,
  div,
  h1,
  button,
  text,
  input,
  ul,
  li,
  for_node,
  text_dyn,
}

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

  div().children([
    h1().children([text("Todo List")]),
    div().children([text_dyn(fn() { todo.get().length().to_string() })]),
    div().children([
      input()
      .attr("type", "text")
      .value(input_val)
      .on(Input, ev => set_input_val.set(event_target_value(ev))),
      button().on(Click, add_item).children([text("Add")]),
    ]),
    ul().children([
      for_node(() => todo.get(), item => { return item }, item => {
        li().children([
          text(item),
          button().on(Click, _ => remove_item(item)).children([text("Delete")]),
        ])
      }),
    ]),
  ])
}
```

## MBX Format (JSX-like)
 \[*Experimental*\]

Todo list in MBX format:
```mbx
using @dom {
  trait View,
  div,
  h1,
  button,
  text,
  input,
  ul,
  li,
  for_node,
  text_dyn,
}

using @ffi {event_target_value}

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

  <div>
    <h1> Todo List </h1>
    <div>{() => todo.get().length().to_string() }</div>
    <div>
      <input 
        type="text" 
        value={input_val} 
        on:input={ev => set_input_val.set(event_target_value(ev))} 
      />
      <button on:click={add_item}> Add </button>
    </div>
    <ul>
      {for_node(() => todo.get(), item => {return item }, (item) => {
        <li>
          {() => item}
          <button on:click={_ => remove_item(item)}> "Delete" </button>
        </li>
      })}
    </ul>
  </div>

}
```

Use command `moon run cmd/mbxc` to compile all the `.mbx` files. <br>

*This library still work in progress, not production ready!*
