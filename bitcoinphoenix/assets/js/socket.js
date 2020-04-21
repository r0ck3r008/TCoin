// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("room:lobby", {})
let chatInput         = document.querySelector("#chat-input")
let button = document.querySelector("#simulate")
let messagesContainer = document.querySelector("#messages")
let clients = document.querySelector("#clients")
let no_of_blocks=document.querySelector("#no_of_blocks")
let no_of_transactions=document.querySelector("#no_of_transactions")
let miners = document.querySelector("#miners")
let mining_difficulty = document.querySelector("#mining_difficulty")

button.addEventListener("click", event => {
  button.innerHTML="Simulating"
setInterval(function(){ 
  channel.push("new_msg", {body: "s"})
}, 6000)
})

channel.on("new_msg", payload => {
  //<canvas id="txChart"></canvas>
  var txarray = tx_chart.data.datasets[0].data
  var number_of_blocks = mine_chart.data.datasets[0].data
  var coins_transacted = coins_transacted_chart.data.datasets[0].data
  var coins_mined = coins_mined_chart.data.datasets[0].data

  // console.log(payload)
  txarray.unshift(payload.body["number_of_transactions"])
  number_of_blocks.unshift(payload.body["number_of_blocks"])
  coins_transacted.unshift(payload.body["number_of_coins_transacted"])
  coins_mined.unshift(payload.body["number_of_coins_mined"])

  // console.log(payload.body["number_of_transactions"])
  tx_chart.data.datasets[0].data = txarray
  mine_chart.data.datasets[0].data = number_of_blocks
  coins_transacted_chart.data.datasets[0].data = coins_transacted
  coins_mined_chart.data.datasets[0].data = coins_mined

  tx_chart.update()
  mine_chart.update()
  coins_transacted_chart.update()
  coins_mined_chart.update()

  no_of_blocks.innerHTML=payload.body["number_of_blocks"]
  
  no_of_transactions.innerHTML=payload.body["number_of_transactions"]
  miners.innerHTML=payload.body["miners"]
  
  clients.innerHTML=payload.body["clients"]
  
  mining_difficulty.innerHTML=3
  //messageItem.innerText = `[${Date()}] ${payload.body}`
  //messageItem.innerText=square(2)
  //messagesContainer.appendChild(messageItem)
})

function square(number) {
  return number * number;
}

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
