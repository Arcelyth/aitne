///|
test "lexer_parser_test" {
  let src =
    #|fn comp() -> &View {
    #|  // create a signal <ohh>
    #|  let (count, set_count) = @reactive.create_signal(0)
    #|  <div 
    #|    max="10" 
    #|    style="background-color: red;" 
    #|    on:click={() => 1} > 
    #|    Hello, World 
    #|  </div>
    #|}
  let lexer = Lexer::new(src)
  let tokens = lexer.tokenizer()

  assert_eq(tokens, [
    Token::RawText(
      "fn comp() -> &View {\n  // create a signal <ohh>\n  let (count, set_count) = @reactive.create_signal(0)\n  ",
    ),
    Token::Start,
    Token::Ident("div"),
    Token::Ident("max"),
    Token::Equal,
    Token::AttrValue("\"10\""),
    Token::Ident("style"),
    Token::Equal,
    Token::AttrValue("\"background-color: red;\""),
    Token::Ident("on"),
    Token::Colon,
    Token::Ident("click"),
    Token::Equal,
    Token::CodeBlock("{() => 1}"),
    Token::End,
    Token::RawText(" \n    Hello, World \n  "),
    Token::Start,
    Token::Slash,
    Token::Ident("div"),
    Token::End,
    Token::RawText("\n}"),
  ])

  let parser = Parser::new(tokens)
  let ast = parser.parse()

  assert_eq(ast, [
    MbxAST::PureCode(
      "fn comp() -> &View {\n  // create a signal <ohh>\n  let (count, set_count) = @reactive.create_signal(0)\n  ",
    ),
    MbxAST::ElementNode(
      "div",
      [
        MbxAttribute::{
          name: "max",
          scope: None,
          value: AttrVal::Static("\"10\""),
        },
        MbxAttribute::{
          name: "style",
          scope: None,
          value: AttrVal::Static("\"background-color: red;\""),
        },
        MbxAttribute::{
          name: "click",
          scope: Some("on"),
          value: AttrVal::Dynamic("{() => 1}"),
        },
      ],
      [MbxAST::TextNode(" \n    Hello, World \n  ")],
    ),
    MbxAST::PureCode("\n}"),
  ])
}
