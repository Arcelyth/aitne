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


