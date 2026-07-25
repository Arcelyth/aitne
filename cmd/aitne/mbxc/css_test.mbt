///|
// Uncomment this when enable style-root as a feature.
//test "compile_css: path-based scoping and exclusions" {
//  let roots = ["src/global", "assets/shared"]
//
//  debug_inspect(
//    compile_css(".btn { color: blue; }", "src/c/b/apple.css", roots),
//    content=(
//      #|".btn_src_c_b { color: blue; }"
//    ),
//  )
//
//  debug_inspect(
//    compile_css(".btn { color: blue; }", "src/global/ui/button.css", roots),
//    content=(
//      #|".btn_src_global_ui { color: blue; }"
//    ),
//  )
//
//  debug_inspect(
//    compile_css(".main { color: blue; }", "src/global/index.css", roots),
//    content=(
//      #|".main { color: blue; }"
//    ),
//  )
//}

///|
test "gen_style_struct" {
  let classes = ["btn", "nav-links", "card_title"]
  let suffix = "a1b2c3d4"
  let code = Ref(StringBuilder::new())
  let def_code = Ref(StringBuilder::new())

  gen_style_struct(classes, suffix, "Style_test", code, def_code)

  debug_inspect(
    def_code.val.to_string(),
    content=(
      #|"struct Style_test {\n  btn : String\n  nav_links : String\n  card_title : String\n}\n\n"
    ),
  )

  debug_inspect(
    code.val.to_string(),
    content=(
      #|"Style_test::{\n  btn: \"btn_a1b2c3d4\",\n  nav_links: \"nav-links_a1b2c3d4\",\n  card_title: \"card_title_a1b2c3d4\",\n}"
    ),
  )
}

///|
test "compile_css_and_gen_style_struct" {
  let css =
    #|.btn {
    #|  color: red;
    #|}
    #|.nav-links {
    #|  display: flex;
    #|}

  let style = Ref(StringBuilder::new())
  let code = Ref(StringBuilder::new())
  let def_code = Ref(StringBuilder::new())

  compile_css(css, "src/components/Header.mbx", style, code, def_code)

  let compiled_style = style.val.to_string()
  let generated_code = code.val.to_string()
  let generated_def = def_code.val.to_string()

  assert_true(compiled_style.contains(".btn_"))
  assert_true(compiled_style.contains(".nav-links_"))

  assert_true(generated_def.contains("struct Style_"))
  assert_true(generated_def.contains("btn : String"))
  assert_true(generated_def.contains("nav_links : String"))

  assert_true(generated_code.contains("btn: \"btn_"))
  assert_true(generated_code.contains("nav_links: \"nav-links_"))
}
