# Environment

- [Deno](https://deno.land/): 1.0.0
- [Elm](https://elm-lang.org/): 0.19.0
- Node: 10.17.0

# Launch

```
$ ./server
```

# Client

using [httpie](https://httpie.org/)

```shell
$ http http://localhost:8000/echo/hello
HTTP/1.1 200 OK
content-length: 5

hello


$ http http://localhost:8000/add/1/2
HTTP/1.1 200 OK
content-length: 1

3


$ http POST http://localhost:8000/sum values:='[1, 2, 3, 4]'
HTTP/1.1 200 OK
content-length: 2

10


$ http http http://localhost:8000/hoge
HTTP/1.1 404 Not Found
content-length: 12

404 NotFound
```
