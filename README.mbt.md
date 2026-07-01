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

Simple router usage in MBX format:
```mbx
///|
pub fn app() -> &View {
  <Router base="/">
    <Routes fallback={() => <NotFound />}>
        <Route path="/" view={() => <Home />} />
        <ParentRoute 
            path="/users" 
            view={() => <UsersPage />}> 
           <Route path="/:id" view={() => <UserDetailPage />}/> 
        </ParentRoute>
        <ParentRoute 
            path="/t"
            view={() => <TryPage />}> 
           <Route path="/t1" view={() => <TryPage />} /> 
        </ParentRoute>
    </Routes>
  </Router>
}

///|
fn main {
  let _ = @dom.mount_to_body(() => <App />)
}
```

## CLI Tool

*`aitne` CLI tool depends on async library which not support Windows now* <br>

To create a new project use `aitne init your_project` or use `aitne init your_project -t template_name` to choose a template. <br>

Using `aitne run` to start a local web server, default on port `8000`. <br>

Run `aitne -h` to see the usage.


## Eirene

Eirene is a simple web server built in MoonBit, specifically designed to serve static assets and handle Single Page Application (SPA) routing fallbacks for the Aitne ecosystem. <br>
An example 'eirene.toml' config file:
```toml
[app]
name = "examples"
mode = "development"
entry_html = "index.html"

[build]
target = "js"
src_dir = "src"
out_dir = "."

[server]
host = "127.0.0.1"
port = 8000
```


*This library still work in progress, not production ready!*
