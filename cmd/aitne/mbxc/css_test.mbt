///|
test "compile_css: path-based scoping and exclusions" {
  let roots = ["src/global", "assets/shared"]

  debug_inspect(
    compile_css(".btn { color: blue; }", "src/c/b/apple.css", roots),
    content=(
      #|".btn_src_c_b { color: blue; }"
    ),
  )

  debug_inspect(
    compile_css(".btn { color: blue; }", "src/global/ui/button.css", roots),
    content=(
      #|".btn_src_global_ui { color: blue; }"
    ),
  )

  debug_inspect(
    compile_css(".main { color: blue; }", "src/global/index.css", roots),
    content=(
      #|".main { color: blue; }"
    ),
  )
}
