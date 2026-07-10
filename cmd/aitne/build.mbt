///|
async fn handle_build() -> Unit {
  println("aitne mbxc")
  let mut style_root = []
  let content = match get_config(None) {
    Some(c) => c
    None => return
  }
  match (try? @eirene.load_config(content)) {
    Ok(cfg) => style_root = cfg.build.style_root
    Err(err) => debug("Config Error: \{to_repr(err)}")
  }

  let style_dir = "./dist"
  let res = try? walk_and_compile(".", None, style_dir, style_root)
  match res {
    Ok(_) => ()
    Err(e) => debug(e)
  }

  println("aitne mbxc done")
  let _ = @async.with_task_group(async fn(group) {
    match (try? @process.spawn(group, "moon", ["build"])) {
      Ok(process) => {
        let _status = process.wait()
        println("moon build done")
        match (try? delete_gen_mbt()) {
          Ok(_) => ()
          Err(e) => println("Failed to delete temporary files")
        }
      }
      Err(_) => println("Failed to build.")
    }
  })
}

/////|
//async fn handle_build() -> Unit {
//  let _ = @async.with_task_group(async fn(group) {
//    println("aitne mbxc")
//    match (try? @process.spawn(group, "aitne", ["mbxc"])) {
//      Ok(process) => {
//        let _status = process.wait()
//        println("aitne mbxc done")
//        match (try? @process.spawn(group, "moon", ["build"])) {
//          Ok(process) => {
//            let _status = process.wait()
//            println("moon build done")
//            match (try? delete_gen_mbt()) {
//              Ok(_) => ()
//              Err(e) => println("Failed to delete temporary files")
//            }
//          }
//          Err(_) => println("Failed to build.")
//        }
//      }
//      Err(_) => println("Failed to build.")
//    }
//  })
//}

///|
pub fn delete_gen_mbt(dir? : String = ".") -> Unit raise @fs.IOError {
  let entries = try? @fs.read_dir(dir)
  match entries {
    Ok(files) =>
      for file in files {
        if file == "." || file == ".." {
          continue
        }

        let path = dir + "/" + file

        if @fs.is_dir(path) {
          delete_gen_mbt(dir=path)
        } else if file.ends_with(".mbx.mbt") {
          @fs.remove_file(path)
        }
      }
    Err(e) => debug(e)
  }
}
