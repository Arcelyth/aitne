///|
pub fn from_file(path : String, show~ : Bool = false) -> Option[String] {
  let res = try? @fs.read_file_to_string(path)
  match res {
    Ok(content) => {
      let lexer = Lexer::new(content) 
      let tokens = lexer.tokenizer()
      if show {
        debug(tokens)
      }
      let parser = Parser::new(tokens)

      let asts = try! parser.parse()
      if show {
        debug(asts)
      }
     
      let codegen = CodeGen::new(asts) 
      
      Some(codegen.generate())
    }
    Err(_) => None 
  }
}
