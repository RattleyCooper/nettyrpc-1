import netty, nettyrpc
import std/[times, parseopt, strutils, strformat, terminal]
import tables


var 
  clientId: uint32


### This is a somewhat simple chat client, very broken
### -p is Port
### -n is Name
### -i is Ip

proc getParams: (string, string, int) =
  for kind, key, val in getOpt():
    case key:
    of "p", "port":
      result[2] = parseint(val)
    of "ip", "i":
      result[1] = val
    of "name", "n":
      result[0] = val


proc set_client_id(theClientId: uint32) {.networked.} =
  ## Set the client's internal clientId to the server-side connection id.
  echo "setting client id: " & $theClientId
  clientId = theClientId

proc display_chat(name, message: string) {.networked.} =
  ## Display chat message from the server.
  eraseLine()
  echo fmt"{getClockStr()} {name} says: {message}"


proc send_chat(name, msg: string) =
  # If you want client actions to take place instantly, create a procedure 
  # to handle client-side logic and then dispatch the RPC.
  eraseLine()
  echo fmt"{getClockStr()} You said: {msg}"
  rpc("send_chat", (name: name, msg: msg))

proc inputLoop(input: ptr Channel[string]) {.thread.} =
  echo "Started input loop"
  var msg = ""
  while true:
    msg.add stdin.readLine()
    input[].send(msg)
    msg.setLen(0)

let 
  (name, ip, port) = getParams()
  client = newReactor()
nettyrpc.client = client.connect(ip, port)
nettyrpc.reactor = client

rpc("join")  # Join the server.

var 
  worker: Thread[ptr Channel[string]]
  input: Channel[string]
input.open
worker.createThread(inputLoop, input.addr)
echo fmt"Hello {name}"

echo "starting tick"
while true:
  client.rpcTick()
  let (gotInput, msg) = input.tryRecv
  if gotInput:
    send_chat(name, msg)
