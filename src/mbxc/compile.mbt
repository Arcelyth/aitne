///|
pub fn from_file(
  path : String,
  show? : Bool = false,
  to? : String? = None,
) -> String? {
  let res = try? @fs.read_file_to_string(path)
  match res {
    Ok(content) => {
      let lexer = Lexer::new(content)
      let tokens = try! lexer.tokenizer()
      if show {
        debug(tokens)
      }
      let parser = Parser::new(tokens)

      let asts = try! parser.parse()
      if show {
        debug(asts)
      }

      let codegen = CodeGen::new(asts)
      let gen = codegen.generate()
      match to {
        Some(target) => {
          let res2 = try? @fs.write_string_to_file(target, gen)
          match res2 {
            Ok(_) => Some(gen)
            Err(e) => {
              debug(e)
              None
            }
          }
        }
        None => Some(gen)
      }
    }
    Err(e) => {
      debug(e)
      None
    }
  }
}
