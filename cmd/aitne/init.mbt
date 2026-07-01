///|
const USER_AGENT = "aitne-cli"

///|
/// Get templates from local
fn list_templates_local() -> Unit {
  let templates = ["starter"]
  println("Templates: ")
  templates.each(t => println("  - \{t}"))
}

///|
/// Get templates from github, it may failed because of github api rate limitation
async fn list_templates_remote() -> Unit {
  println("Fetching available templates from aitne-dev...")

  let headers = Map::new()
  headers.set("user-agent", "aitne-cli")
  headers.set("accept", "application/vnd.github+json")
  headers.set("accept-encoding", "identity")
  headers.set("connection", "close")

  let (resp, body) = @http.get(
    "https://api.github.com/orgs/aitne-dev/repos",
    headers~,
  )

  if resp.code == 200 {
    let resp_json = body.json()
    match resp_json {
      Array(repos) => {
        println("Templates: ")
        for repo in repos {
          match repo {
            Object(obj) =>
              match obj.get("name") {
                Some(String(name)) =>
                  if name.has_prefix("template-") {
                    let tmpl = name[9:name.length()]
                    println("  - \{tmpl}")
                  }
                _ => ()
              }
            _ => ()
          }
        }
      }
      _ => ()
    }
  } else {
    println(
      "Error: GitHub API returned status code \{resp.code} (\{resp.reason})",
    )
  }
}

///|
async fn fetch_latest_tag(tmpl_name : String) -> String {
  let path = "https://api.github.com/repos/aitne-dev/template-\{tmpl_name}/releases/latest"

  let headers = Map::new()
  headers.set("user-agent", USER_AGENT)
  headers.set("accept", "application/vnd.github+json")
  headers.set("accept-encoding", "identity")
  headers.set("connection", "close")

  match (try? @http.get(path, headers~)) {
    Ok((resp, body)) =>
      if resp.code == 200 {
        match body.json() {
          Object(obj) =>
            match obj.get("tag_name") {
              Some(String(tag)) => return tag
              _ => ()
            }
          _ => ()
        }
      }
    Err(_) => ()
  }
  "main"
}

///|
async fn[X] download_template_stream(
  group : @async.TaskGroup[X],
  tmpl_name : String,
  target_dir : String,
) -> Result[Unit, String] {
  let tag = fetch_latest_tag(tmpl_name)
  let url = "https://codeload.github.com/aitne-dev/template-\{tmpl_name}/tar.gz/\{tag}"

  println("Downloading asset stream from codeload...")

  let headers = Map::new()
  headers.set("user-agent", USER_AGENT)

  match (try? @http.get(url, headers~)) {
    Ok((resp, body)) =>
      if resp.code == 200 {
        let tmp_tar = "\{target_dir}/tmp_template.tar.gz"

        if !@fs.path_exists(target_dir) {
          @fs.create_dir(target_dir)
        }

        try {
          if not(@fs.path_exists(target_dir)) {
            @fs.create_dir(target_dir)
          }

          @fs.write_bytes_to_file(tmp_tar, body.binary())
        } catch {
          e => return Err("Failed to write temporary tarball to disk")
        }

        println("Extracting template archive...")

        extract_tarball(group, tmp_tar, target_dir)
      } else {
        Err("Failed to download template asset, status code: \{resp.code}")
      }
    Err(_) => Err("Connection broke while pulling repository tarball.")
  }
}

///|
async fn[X] extract_tarball(
  group : @async.TaskGroup[X],
  tmp_tar_path : String,
  target_dir : String,
) -> Result[Unit, String] {
  let cmd : StringView = "tar"

  let args_raw : Array[String] = [
    "-xzf".to_string(),
    tmp_tar_path,
    "-C".to_string(),
    target_dir,
    "--strip-components=1".to_string(),
  ]
  let args : ArrayView[String] = args_raw

  match (try? @process.spawn(group, cmd, args)) {
    Ok(process) => {
      let _status = process.wait()
      Ok(())
    }
    Err(_) => Err("Failed to execute spawn: internal task group process error.")
  }
}

///|
pub async fn init_project(project_name : String, template : String) -> Unit {
  let target_path = "./\{project_name}"

  println(
    "Creating new Aitne project '\{project_name}' using template '\{template}'...",
  )

  let _ = @async.with_task_group(async fn(group) {
    match download_template_stream(group, template, target_path) {
      Ok(_) => {
        println("Successfully initialized Aitne project at: \{target_path}")
        println("Run the following to start:")
        println("  cd \{project_name}")
      }
      Err(e) => println("Error: Scaffold initialization failed -> \{e}")
    }
  })
}
