import { listenAndServe } from "https://deno.land/std/http/server.ts";
import "./elm/dist/main.js";

type Response = { body: string; status: number };

const app = (window as any).app;

const port = 8000;
console.log(`listen... 0.0.0.0:${port}`);

const options = { port };

listenAndServe(options, async (req) => {
  const getResponse: Promise<Response> = new Promise((resolve) =>
    app.ports.response.subscribe((r: Response) => {
      console.log(`Response: ${r.status} ${r.body}`);
      resolve(r);
    })
  );

  // Read Body.
  const buf = new Uint8Array(req.contentLength!);
  let bufSlice = buf;
  let totRead = 0;
  while (true) {
    const nread = await req.body.read(bufSlice);
    if (nread === null) break;
    totRead += nread;
    if (totRead >= req.contentLength!) break;
    bufSlice = bufSlice.subarray(nread);
  }
  const bodyStr = new TextDecoder().decode(bufSlice);

  console.log(`Request: ${req.method} ${req.url} ${bodyStr}`);
  app.ports.request.send({
    url: `http://localhost${req.url}`,
    method: req.method,
    body: bodyStr,
  });

  const { body, status } = await getResponse;

  req.respond({ body: body, status: status });
});
