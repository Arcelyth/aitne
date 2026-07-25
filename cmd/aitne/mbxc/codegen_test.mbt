///|
test "CodeGen::generate dynamic code block" {
  let cg = CodeGen::new()

  let ast_dyn_closure : Array[MbxAST] = [
    MbxAST::DynamicCode([MbxAST::PureCode("() => count.get().to_string()")]),
  ]

  let result_closure = cg.generate(ast_dyn_closure)
  let expected_closure =
    #|@Arcelyth/aitne/src/dom.text_dyn(
    #|        () => count.get().to_string()
    #|      )

  inspect(result_closure, content=expected_closure)
}

///|
test "CodeGen::output_style" {
  let cg = CodeGen::new(path="index.mbx")
  let ast : Array[MbxAST] = [MbxAST::StyleNode(".btn { color: red; }")]

  let _ = cg.generate(ast)
  inspect(cg.output_style() != "", content="true")
}
