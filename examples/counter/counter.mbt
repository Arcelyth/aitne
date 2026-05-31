
pub fn counter() -> @dom.Html {
  let (count, set_count) = @reactive.create_signal(0)

  @dom.div().children([
    @dom.h1().children([
      @dom.text("Counter")
    ]),

    @dom.p().children([
      @dom.text_dyn(fn() {
        count.get().to_string()
      })
    ]),

    @dom.button()
      .children([
        @dom.text("+1")
      ])
      .on(Click, fn(_e) {
        set_count.update(fn(v) { v + 1 })
      }),

    @dom.button()
      .children([
        @dom.text("-1")
      ])
      .on(Click, fn(_e) {
        set_count.update(fn(v) { v - 1 })
      }),
  ])
}
