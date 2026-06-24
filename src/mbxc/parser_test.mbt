/////|
//test "lexer_parser_test" {
//  let src =
//    #|fn comp() -> &View {
//    #|  // create a signal <ohh>
//    #|  let (count, set_count) = @reactive.create_signal(0)
//    #|  <div 
//    #|    max="10" 
//    #|    style="background-color: red;" 
//    #|    on:click={() => 1} >{() => #{<div />}#}</div>
//    #|}
//  let lexer = Lexer::new(src)
//  let tokens = lexer.tokenizer()
//
//  inspect(
//    tokens,
//    content="[RawText(fn comp() -> &View {\n  // create a signal <ohh>\n  let (count, set_count) = @reactive.create_signal(0)\n  ), Start, Ident(div), Ident(max), Equal, AttrValue(\"10\"), Ident(style), Equal, AttrValue(\"background-color: red;\"), Ident(on), Colon, Ident(click), Equal, CodeBlock(() => 1), End, BraceOpen, RawText(() => ), HashBraceOpen, Start, Ident(div), SlashEnd, HashBraceClose, BraceClose, Start, Slash, Ident(div), End, RawText(\n})]",
//  )
//
//  let parser = Parser::new(tokens)
//  let ast = parser.parse()
//
//  assert_eq(ast, [
//    MbxAST::PureCode(
//      "fn comp() -> &View {\n  // create a signal <ohh>\n  let (count, set_count) = @reactive.create_signal(0)\n  ",
//    ),
//    MbxAST::ElementNode(
//      "div",
//      [
//        MbxAttribute::{
//          name: "max",
//          scope: None,
//          value: AttrVal::Static("\"10\""),
//        },
//        MbxAttribute::{
//          name: "style",
//          scope: None,
//          value: AttrVal::Static("\"background-color: red;\""),
//        },
//        MbxAttribute::{
//          name: "click",
//          scope: Some("on"),
//          value: AttrVal::Dynamic("() => 1"),
//        },
//      ],
//      [MbxAST::TextNode(" \n    Hello, World \n  ")],
//    ),
//    MbxAST::PureCode("\n}"),
//  ])
//}
