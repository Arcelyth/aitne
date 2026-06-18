///|
using @dom {trait View, div, h1, h2, h3, p, a, span, text, nav, ul, li, main_, footer}

///|
fn navbar() -> &View {
  nav()
    .style("background: #1e293b; padding: 1rem 2rem; display: flex; gap: 1.5rem; align-items: center; border-bottom: 1px solid #334155;")
    .children([
      a()
        .attr("href", "/")
        .style("color: #2dd4bf; font-weight: 700; font-size: 1.25rem; text-decoration: none;")
        .children([text("Aitne Router")]),
      a()
        .attr("href", "/users")
        .style("color: #94a3b8; text-decoration: none; font-size: 0.875rem;")
        .children([text("Users")]),
      a()
        .attr("href", "/about")
        .style("color: #475569; text-decoration: none; font-size: 0.875rem;")
        .children([text("About (404 demo)")]),
    ])
}

///|
fn page_layout(title : String, content : &View) -> &View {
  div()
    .style("min-height: 100vh; background: #0f172a; font-family: system-ui, -apple-system, sans-serif;")
    .children([
      navbar(),
      main_()
        .style("max-width: 48rem; margin: 0 auto; padding: 2rem 1rem;")
        .children([
          h1()
            .style("color: #f1f5f9; font-size: 1.875rem; font-weight: 700; margin-bottom: 1.5rem;")
            .children([text(title)]),
          content,
        ]),
      footer()
        .style("text-align: center; padding: 1.5rem; color: #475569; font-size: 0.75rem; border-top: 1px solid #1e293b;")
        .children([text("Built with MoonBit — Aitne Framework")]),
    ])
}

///|
/// Home page — root route `/`.
pub fn home_page() -> &View {
  page_layout(
    "Home",
    div()
      .style("display: flex; flex-direction: column; gap: 1rem;")
      .children([
        p()
          .style("color: #94a3b8; line-height: 1.7;")
          .children([text("This demo showcases the Aitne router with a nested route chain. Click through the pages below — all navigation is client-side via the History API, with zero full-page reloads.")]),

        // Route chain diagram
        div()
          .style("background: #1e293b; border: 1px solid #334155; border-radius: 0.75rem; padding: 1.25rem; font-family: monospace;")
          .children([
            h3()
              .style("color: #e2e8f0; font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;")
              .children([text("Route Chain")]),
            code_block("/", "→ home_page()"),
            code_block("  /users", "→ users_page()  (parent_route)"),
            code_block("    /:id", "→ user_detail_page()  (dynamic :id)"),
            p()
              .style("color: #475569; font-size: 0.75rem; margin-top: 0.75rem;")
              .children([text("Any path not in the chain renders the 404 fallback.")]),
          ]),

        // Feature list
        h2()
          .style("color: #e2e8f0; font-size: 1.25rem; font-weight: 600; margin-top: 0.5rem;")
          .children([text("Router Features")]),
        ul()
          .style("color: #94a3b8; line-height: 1.8; padding-left: 1.5rem;")
          .children([
            li().children([text("Static routes — exact path matching")]),
            li().children([text("Dynamic segments — :id captures URL params")]),
            li().children([text("Nested routes — parent_route with child routes")]),
            li().children([text("Fallback — 404 for unmatched paths")]),
            li().children([text("Client-side navigation — history.pushState")]),
          ]),

        // Quick links
        h2()
          .style("color: #e2e8f0; font-size: 1.25rem; font-weight: 600; margin-top: 0.5rem;")
          .children([text("Try It")]),
        div()
          .style("display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem;")
          .children([
            quick_link("/", "Home"),
            quick_link("/users", "Users"),
            quick_link("/users/1", "User #1"),
            quick_link("/users/2", "User #2"),
            quick_link("/about", "404 Demo"),
            quick_link("/xyz", "Also 404"),
          ]),
      ]),
  )
}

///|
/// Users list page — parent route `/users`.
pub fn users_page() -> &View {
  page_layout(
    "Users",
    div()
      .style("display: flex; flex-direction: column; gap: 1rem;")
      .children([
        p()
          .style("color: #94a3b8; line-height: 1.7;")
          .children([text("Each card links to /users/:id — a dynamic child route that captures the id segment from the URL.")]),
        user_grid(),
      ]),
  )
}

///|
pub fn user_detail_page() -> &View {
  page_layout(
    "User Profile",
    div()
      .style("display: flex; flex-direction: column; gap: 1rem;")
      .children([
        div()
          .style("background: #1e293b; border: 1px solid #334155; border-radius: 0.75rem; padding: 1.5rem;")
          .children([
            p()
              .style("color: #94a3b8; line-height: 1.7;")
              .children([text("This page was matched by the dynamic :id segment. The router extracted the id parameter from the URL path.")]),
            p()
              .style("color: #64748b; line-height: 1.7; margin-top: 0.75rem; font-size: 0.875rem;")
              .children([text("In a full implementation, use_params() or the route context would provide access to the captured :id value so the page can fetch the correct user data.")]),
          ]),
        a()
          .attr("href", "/users")
          .style("display: inline-flex; align-items: center; color: #2dd4bf; text-decoration: none; font-size: 0.875rem; margin-top: 0.5rem;")
          .children([text("← Back to Users")]),
      ]),
  )
}

///|
/// 404 Not Found — fallback for unmatched routes.
pub fn not_found_page() -> &View {
  div()
    .style("min-height: 100vh; background: #0f172a; display: flex; flex-direction: column; align-items: center; justify-content: center; font-family: system-ui, -apple-system, sans-serif;")
    .children([
      h1()
        .style("font-size: 6rem; font-weight: 800; color: #1e293b; margin: 0;")
        .children([text("404")]),
      p()
        .style("color: #94a3b8; font-size: 1.125rem; margin: 0.5rem 0 2rem 0;")
        .children([text("This path doesn't match any route in the chain.")]),
      div()
        .style("display: flex; gap: 1rem;")
        .children([
          a()
            .attr("href", "/")
            .style("display: inline-block; padding: 0.75rem 1.5rem; background: #2563eb; color: #ffffff; font-weight: 600; border-radius: 0.75rem; text-decoration: none; font-size: 0.875rem;")
            .children([text("Go Home")]),
          a()
            .attr("href", "/users")
            .style("display: inline-block; padding: 0.75rem 1.5rem; background: #1e293b; color: #94a3b8; font-weight: 600; border-radius: 0.75rem; text-decoration: none; font-size: 0.875rem; border: 1px solid #334155;")
            .children([text("Browse Users")]),
        ]),
    ])
}

///|
fn code_block(path : String, desc : String) -> &View {
  div()
    .style("display: flex; gap: 0.75rem; padding: 0.25rem 0; font-size: 0.8rem;")
    .children([
      span()
        .style("color: #2dd4bf; min-width: 8rem;")
        .children([text(path)]),
      span()
        .style("color: #64748b;")
        .children([text(desc)]),
    ])
}

///|
fn quick_link(href : String, label : String) -> &View {
  a()
    .attr("href", href)
    .style("display: flex; align-items: center; gap: 0.5rem; background: #1e293b; border-radius: 0.5rem; padding: 0.75rem 1rem; text-decoration: none; border: 1px solid #334155; font-size: 0.875rem;")
    .children([
      span().style("color: #e2e8f0;").children([text(label)]),
    ])
}

///|
fn user_grid() -> &View {
  div()
    .style("display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;")
    .children([
      user_card("Alice Chen", "1", "Full-stack developer", "#3b82f6"),
      user_card("Bob Park", "2", "UX designer", "#8b5cf6"),
      user_card("Cara Diaz", "3", "DevOps engineer", "#ec4899"),
      user_card("Dane Kim", "4", "Product manager", "#f59e0b"),
    ])
}

///|
fn user_card(name : String, id : String, role : String, color : String) -> &View {
  a()
    .attr("href", "/users/" + id)
    .style("display: block; background: #1e293b; border-radius: 0.75rem; padding: 1.25rem; text-decoration: none; border: 1px solid #334155;")
    .children([
      div()
        .style("width: 2.25rem; height: 2.25rem; border-radius: 9999px; display: flex; align-items: center; justify-content: center; font-size: 1rem; font-weight: 700; margin-bottom: 0.5rem;")
        .style("background: " + color + "; color: #ffffff;")
        .children([text(name)]),
      h3()
        .style("color: #f1f5f9; font-size: 0.95rem; font-weight: 600; margin-bottom: 0.2rem;")
        .children([text(name)]),
      p()
        .style("color: #64748b; font-size: 0.8rem;")
        .children([text(role)]),
    ])
}
