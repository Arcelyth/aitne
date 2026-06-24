///|
suberror MbxcError {
  LexerError(String)
  ParserError(String)
} derive(Debug, Show)

///|
pub(all) enum MbxAST {
  PureCode(StringView)
  // name, attrs, children
  ElementNode(StringView, HashMap[TokenAttr, StringView], Array[MbxAST])
} derive(Debug, Show, Eq)

///|
pub(all) struct Parser {
  tokens : Array[Token]
  mut cur : Int
}

///|
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  Parser::{ tokens, cur: 0 }
}

///|
fn Parser::is_end(self : Parser) -> Bool {
  self.cur >= self.tokens.length()
}

///|
fn Parser::peek(self : Parser, step? : Int = 0) -> Token? {
  if self.is_end() {
    None
  } else {
    Some(self.tokens[self.cur + step])
  }
}

///|
fn Parser::advance(self : Parser) -> Unit {
  self.cur += 1
}

///|
fn Parser::parse_node(self : Parser) -> MbxAST? raise MbxcError {
  guard !self.is_end() else { return None }

  match self.peek().unwrap() {
    Token::RawText(code) => {
      self.advance()
      Some(MbxAST::PureCode(code))
    }
    Token::CodeBlock(code) => {
      self.advance()
      Some(MbxAST::PureCode(code))
    }
    Token::TagSelfClose(tag_self) => {
      self.advance()
      Some(MbxAST::ElementNode(tag_self.tag, tag_self.attrs, []))
    }
    Token::TagClose(tag_close) =>
      raise ParserError("Unexpected closing tag: </\{tag_close.tag}>")
    Token::TagOpen(tag_open) => {
      let tag_name = tag_open.tag
      let attrs = tag_open.attrs
      self.advance()

      let children = []
      let mut closed = false

      while !self.is_end() {
        match self.peek().unwrap() {
          Token::TagClose(tag_close) =>
            if tag_close.tag == tag_name {
              self.advance()
              closed = true
              break
            } else {
              raise ParserError(
                "Mismatched closing tag: expected </\{tag_name}>, got </\{tag_close.tag}>",
              )
            }
          _ =>
            match self.parse_node() {
              Some(child_ast) => children.push(child_ast)
              None => ()
            }
        }
      }

      if !closed {
        raise ParserError("Unclosed tag: <\{tag_name}>")
      }

      Some(MbxAST::ElementNode(tag_name, attrs, children))
    }
    _ => {
      self.advance()
      None
    }
  }
}

///|
pub fn Parser::parse(self : Parser) -> Array[MbxAST] raise MbxcError {
  let ast_list = []

  while !self.is_end() {
    match self.parse_node() {
      Some(ast) => ast_list.push(ast)
      None => ()
    }
  }

  ast_list
}
