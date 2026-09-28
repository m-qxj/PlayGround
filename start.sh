#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
/usr/bin/time -p pwd
export PROJECT_ROOT
PROJECT_ROOT="$(/usr/bin/time -p pwd)"
export PORT
PORT="${PORT:-3000}"
/usr/bin/time -p bash -c 'echo "PORT=$PORT PROJECT_ROOT=$PROJECT_ROOT"'
export STATIC_DIR
STATIC_DIR="$PROJECT_ROOT"
/usr/bin/time -p test -d "$STATIC_DIR"
if /usr/bin/time -p test -f "$PROJECT_ROOT/package.json"; then
  if /usr/bin/time -p test -f "$PROJECT_ROOT/package-lock.json"; then
    /usr/bin/time -p npm ci --no-audit --no-fund
  else
    /usr/bin/time -p npm install --no-audit --no-fund
  fi
  if /usr/bin/time -p node -e "process.exit(require('./package.json').scripts && require('./package.json').scripts.build ? 0 : 1)"; then
    /usr/bin/time -p npm run build
    if /usr/bin/time -p test -d "$PROJECT_ROOT/dist"; then
      STATIC_DIR="$PROJECT_ROOT/dist"
    fi
  fi
fi
/usr/bin/time -p test -f "$STATIC_DIR/index.html"
export WEB_DIR
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$WEB_DIR"
export PROJECT_ROOT STATIC_DIR WEB_DIR PORT
/usr/bin/time -p node -e 'const fs=require("fs");const path=require("path");const project=process.env.PROJECT_ROOT||process.cwd();const dir=process.env.STATIC_DIR||process.cwd();const web=process.env.WEB_DIR;fs.writeFileSync(path.join(web,"deployment-output.json"),JSON.stringify({project,directory:dir}));console.log("wrote deployment-output.json: "+path.join(web,"deployment-output.json"));'
/usr/bin/time -p node -e '
const http=require("http"),fs=require("fs"),path=require("path");
const root=process.env.STATIC_DIR||process.cwd();
const port=Number(process.env.PORT||3000);
const mime={".html":"text/html",".js":"application/javascript",".css":"text/css",".json":"application/json",".svg":"image/svg+xml",".png":"image/png",".jpg":"image/jpeg",".webp":"image/webp",".wasm":"application/wasm",".glb":"model/gltf-binary",".txt":"text/plain"};
const server=http.createServer((req,res)=>{
  try{
    const url=new URL(req.url,"http://localhost");
    let p=decodeURIComponent(url.pathname);
    if(p.includes("\0")){res.writeHead(400);res.end();return;}
    let file=path.resolve(root,"."+p);
    if(file!==path.resolve(root)&&!file.startsWith(path.resolve(root)+path.sep)){res.writeHead(404);res.end();return;}
    try{if(fs.statSync(file).isDirectory())file=path.join(file,"index.html");}catch{}
    if(!fs.existsSync(file)){file=path.join(root,"index.html");}
    const ext=path.extname(file);
    res.setHeader("Content-Type",mime[ext]||"application/octet-stream");
    res.setHeader("Cache-Control","no-cache");
    res.end(fs.readFileSync(file));
  }catch(e){res.writeHead(404);res.end("Not found");}
});
server.listen(port,"0.0.0.0",()=>console.log("serving "+root+" on :"+port));
'
