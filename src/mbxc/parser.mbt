///|
suberror MbxcError {
  LexerError(String)
  ParserError(String)
} derive(Debug, Show)

///|
pub(all) enum Token {
  Start // <
  End // >
  DocStart // <!
  ComStart // <!-- 
  ComEnd // -->
  SlashEnd // />
  Slash // /
  Equal // =
  Colon // :
  Ident(StringView)
  AttrValue(StringView)
  RawText(StringView)
  CodeBlock(StringView)
} derive(Debug, Eq, Show)

///|
pub enum MbxState {
  M // MoonBit Code
  MS // MoonBit String
  X // MBX Tag
  XC // MBX Comment
} derive(Debug, Eq)

///|
pub(all) struct Lexer {
  src : String
  mut cur : Int
  mut state : MbxState
  mut tag_depth : Int
}

///|
pub fn Lexer::new(src : String) -> Lexer {
  Lexer::{ src, cur: 0, state: MbxState::M, tag_depth: 0 }
}

///|
pub fn Lexer::is_end(self : Lexer) -> Bool {
  self.cur >= self.src.length()
}

///|
pub fn Lexer::peek(self : Lexer, count : Int) -> UInt16? {
  if self.cur + count >= self.src.length() {
    None
  } else {
    Some(self.src[self.cur + count])
  }
}

///|
#inline
fn is_ident_char(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-'
}

///|
pub fn Lexer::next_token(self : Lexer) -> Token? raise MbxcError {
  guard !self.is_end() else { return None }
  let c = self.src[self.cur]

  match self.state {
    MbxState::MS => {
      let start = self.cur
      self.cur += 1

      while !self.is_end() && self.src[self.cur] != '\"' {
        // handle escape
        if self.src[self.cur] == '\\' && self.cur + 1 < self.src.length() {
          self.cur += 2
        } else {
          self.cur += 1
        }
      }
      if self.is_end() {
        raise LexerError("Unclosed string literal in MoonBit block")
      }
      self.cur += 1
      self.state = MbxState::M
      return Some(Token::RawText(self.src[start:self.cur]))
    }
    MbxState::XC =>
      match (self.peek(0), self.peek(1), self.peek(2)) {
        (Some('-'), Some('-'), Some('>')) => {
          self.cur += 3
          self.state = MbxState::M
          return Some(Token::ComEnd)
        }
        _ => {
          let start = self.cur
          while !self.is_end() {
            match (self.peek(0), self.peek(1), self.peek(2)) {
              (Some('-'), Some('-'), Some('>')) => break
              _ => self.cur += 1
            }
          }

          if self.is_end() {
            raise LexerError("Unclosed comment: expected '-->'")
          }

          return Some(Token::RawText(self.src[start:self.cur]))
        }
      }
    MbxState::M => {
      if c == '\"' {
        self.cur += 1
        self.state = MbxState::MS
        return self.next_token()
      }
      if c == '<' {
        match self.peek(1) {
          Some(next) if next >= 'a' && next <= 'z' => {
            self.tag_depth += 1
            self.cur += 1
            self.state = MbxState::X
            return Some(Token::Start)
          }
          Some('/') => {
            if self.tag_depth > 0 {
              self.tag_depth -= 1
            }
            self.cur += 1
            self.state = MbxState::X
            return Some(Token::Start)
          }
          Some('!') =>
            match (self.peek(2), self.peek(3)) {
              (Some('-'), Some('-')) => {
                self.cur += 4
                self.state = MbxState::XC
                return Some(Token::ComStart)
              }
              _ => {
                self.cur += 2
                self.state = MbxState::X
                return Some(Token::DocStart)
              }
            }
          _ => ()
        }
      }

      if c == '{' && self.tag_depth > 0 {
        let start = self.cur
        let mut brace_count = 1
        self.cur += 1
        while !self.is_end() && brace_count > 0 {
          let current = self.src[self.cur]
          if current == '{' {
            brace_count += 1
          } else if current == '}' {
            brace_count -= 1
          }
          self.cur += 1
        }
        return Some(Token::CodeBlock(self.src[start:self.cur]))
      }

      let start = self.cur
      self.cur += 1
      while !self.is_end() &&
            self.src[self.cur] != '<' &&
            self.src[self.cur] != '\"' {
        if self.src[self.cur] == '/' && self.peek(1) == Some('/') {
          // handle moonbit comment
          self.cur += 2
          while !self.is_end() && self.src[self.cur] != '\n' {
            self.cur += 1
          }
          if !self.is_end() {
            self.cur += 1
          }
        }
        self.cur += 1
      }
      return Some(Token::RawText(self.src[start:self.cur]))
    }
    MbxState::X =>
      match c {
        ' ' | '\n' | '\r' | '\t' => {
          self.cur += 1
          return self.next_token()
        }
        '{' => {
          let start = self.cur
          let mut brace_count = 1
          self.cur += 1
          while !self.is_end() && brace_count > 0 {
            let current = self.src[self.cur]
            if current == '{' {
              brace_count += 1
            } else if current == '}' {
              brace_count -= 1
            }
            self.cur += 1
          }
          if brace_count > 0 {
            raise LexerError(
              "Unclosed code block in tag attributes: expected '}'",
            )
          }
          return Some(Token::CodeBlock(self.src[start:self.cur]))
        }
        '>' => {
          self.cur += 1
          self.state = MbxState::M
          return Some(Token::End)
        }
        '=' => {
          self.cur += 1
          return Some(Token::Equal)
        }
        ':' => {
          self.cur += 1
          return Some(Token::Colon)
        }
        '/' =>
          match self.peek(1) {
            Some('>') => {
              self.cur += 2
              self.state = MbxState::M
              if self.tag_depth > 0 {
                self.tag_depth -= 1
              }
              return Some(Token::SlashEnd)
            }
            _ => {
              self.cur += 1
              return Some(Token::Slash)
            }
          }
        '\"' | '\'' => {
          let quote = c
          let start = self.cur
          self.cur += 1
          while !self.is_end() && self.src[self.cur] != quote {
            self.cur += 1
          }
          if self.is_end() {
            raise LexerError(
              "Unclosed attribute value: expected matching quote",
            )
          }
          self.cur += 1
          return Some(Token::AttrValue(self.src[start:self.cur]))
        }
        _ if is_ident_char(c) => {
          let start = self.cur
          while !self.is_end() && is_ident_char(self.src[self.cur]) {
            self.cur += 1
          }
          return Some(Token::Ident(self.src[start:self.cur]))
        }
        _ => {
          self.cur += 1
          return self.next_token()
        }
      }
  }
}

///|
pub fn Lexer::tokenizer(self : Lexer) -> Array[Token] raise MbxcError {
  let tokens = []
  while true {
    match self.next_token() {
      Some(t) => tokens.push(t)
      None => break
    }
  }
  tokens
}

///|
pub(all) enum MbxAST {
  PureCode(StringView)
  TextNode(StringView)
  DynamicNode(StringView)
  ElementNode(StringView, Array[MbxAttribute], Array[MbxAST])
} derive(Debug, Show, Eq)

///|
pub(all) struct MbxAttribute {
  name : StringView
  scope : StringView?
  value : AttrVal
} derive(Debug, Show, Eq)

///|
pub(all) enum AttrVal {
  Static(StringView)
  Dynamic(StringView)
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
fn Parser::parse_attributes(self : Parser) -> Array[MbxAttribute] {
  let attrs = []
  while !self.is_end() {
    match self.peek() {
      Some(Token::Ident(name)) => {
        self.advance()
        let mut ns = None
        let mut final_name = name

        match self.peek() {
          Some(Token::Colon) => {
            self.advance()
            match self.peek() {
              Some(Token::Ident(sub_name)) => {
                self.advance()
                ns = Some(final_name)
                final_name = sub_name
              }
              _ => ()
            }
          }
          _ => ()
        }

        match self.peek() {
          Some(Token::Equal) => {
            self.advance()
            match self.peek() {
              Some(Token::AttrValue(v)) => {
                self.advance()
                attrs.push({
                  name: final_name,
                  scope: ns,
                  value: AttrVal::Static(v),
                })
              }
              Some(Token::CodeBlock(c)) => {
                self.advance()
                attrs.push({
                  name: final_name,
                  scope: ns,
                  value: AttrVal::Dynamic(c),
                })
              }
              _ => ()
            }
          }
          _ =>
            attrs.push({
              name: final_name,
              scope: ns,
              value: AttrVal::Static(""),
            })
        }
      }
      _ => break
    }
  }
  attrs
}

///|
pub fn Parser::parse_node(self : Parser) -> MbxAST? raise MbxcError {
  guard !self.is_end() else { return None }

  match self.peek().unwrap() {
    Token::RawText(code) => {
      self.advance()
      Some(MbxAST::PureCode(code))
    }
    Token::Start => {
      self.advance()
      match self.peek() {
        Some(Token::Ident(tag)) => {
          self.advance()
          let attrs = self.parse_attributes()

          match self.peek() {
            Some(Token::SlashEnd) => {
              self.advance()
              Some(MbxAST::ElementNode(tag, attrs, []))
            }
            Some(Token::End) => {
              self.advance()
              let children = []

              while !self.is_end() {
                match self.peek() {
                  Some(Token::Start) => {
                    let mut is_closing = false

                    if self.cur + 1 < self.tokens.length() {
                      match self.tokens[self.cur + 1] {
                        Token::Slash => {
                          is_closing = true
                          self.cur += 2

                          match self.peek() {
                            Some(Token::Ident(close_tag)) => {
                              if close_tag != tag {
                                raise ParserError(
                                  "Mismatched tag! Expected </\{tag}>, found </\{close_tag}>",
                                )
                              }
                              self.advance()

                              match self.peek() {
                                Some(Token::End) => self.advance()
                                _ =>
                                  raise ParserError(
                                    "Expected '>' to close tag </\{tag}>",
                                  )
                              }
                            }
                            _ =>
                              raise ParserError("Expected tag name after '</'")
                          }
                        }
                        _ => ()
                      }
                    }

                    if is_closing {
                      break
                    } else {
                      match self.parse_node() {
                        Some(child) => children.push(child)
                        None => ()
                      }
                    }
                  }
                  Some(Token::CodeBlock(c)) => {
                    self.advance()
                    children.push(MbxAST::DynamicNode(c))
                  }
                  Some(Token::RawText(t)) => {
                    self.advance()
                    children.push(MbxAST::TextNode(t))
                  }
                  _ =>
                    match self.parse_node() {
                      Some(child) => children.push(child)
                      None => ()
                    }
                }
              }
              Some(MbxAST::ElementNode(tag, attrs, children))
            }
            _ =>
              raise ParserError(
                "Expected '>' or '/>' after attributes in <\{tag}>",
              )
          }
        }
        _ => raise ParserError("Expected valid tag name after '<'")
      }
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

