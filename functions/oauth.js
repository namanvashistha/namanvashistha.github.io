export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (url.pathname === "/api/auth") {
      const params = new URLSearchParams(url.search);
      const provider = params.get("provider");

      if (provider !== "github") {
        return new Response("Unknown provider", { status: 400 });
      }

      const githubUrl = new URL("https://github.com/login/oauth/authorize");
      githubUrl.searchParams.set("client_id", env.GITHUB_CLIENT_ID);
      githubUrl.searchParams.set("scope", "public_repo,user:email");
      githubUrl.searchParams.set("state", crypto.randomUUID());

      return Response.redirect(githubUrl.toString(), 302);
    }

    if (url.pathname === "/api/callback") {
      const params = new URLSearchParams(url.search);
      const code = params.get("code");

      if (!code) {
        return new Response("Missing code", { status: 400 });
      }

      const tokenResponse = await fetch("https://github.com/login/oauth/access_token", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "User-Agent": "cloudflare-worker-oauth",
        },
        body: JSON.stringify({
          client_id: env.GITHUB_CLIENT_ID,
          client_secret: env.GITHUB_CLIENT_SECRET,
          code,
        }),
      });

      const tokenData = await tokenResponse.json();

      if (tokenData.error) {
        return new Response(JSON.stringify(tokenData), { status: 400, headers: { "Content-Type": "application/json" } });
      }

      const content = `
        <!doctype html>
        <html><body>
        <script>
          (function() {
            function receiveMessage(e) {
              console.log("receiveMessage %o", e);
              
              // trust target
              // if (e.origin !== "window.location.origin") { return; }
              
              // send message to main window with the app
              window.opener.postMessage(
                'authorization:github:success:${JSON.stringify({
                  token: tokenData.access_token,
                  provider: "github",
                })}', 
                e.origin
              );
            }
            window.addEventListener("message", receiveMessage, false);
            
            window.opener.postMessage("authorizing:github", "*");
          })()
        </script>
        </body></html>
      `;

      return new Response(content, {
        headers: { "Content-Type": "text/html" },
      });
    }

    return new Response("Not found", { status: 404 });
  }
};
