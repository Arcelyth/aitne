using @dom {type Html, div, h1, p, button, text, text_dyn}

pub fn counter() -> Html {
  let (count, set_count) = @reactive.create_signal(0)

  div().children([
    h1().children([
      text("Counter")
    ]),

    p().children([
      text_dyn(fn() {
        count.get().to_string()
      })
    ]),

    button()
      .children([
        text("+1")
      ])
      .on(Click, fn(_e) {
        set_count.update(fn(v) { v + 1 })
      }),

    button()
      .children([
        text("-1")
      ])
      .on(Click, fn(_e) {
        set_count.update(fn(v) { v - 1 })
      }),
  ])
}
