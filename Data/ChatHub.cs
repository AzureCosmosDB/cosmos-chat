using Microsoft.AspNetCore.SignalR;
using System;
using System.Net.NetworkInformation;
using System.Threading.Tasks;
using cosmoschat.Data;
using Newtonsoft.Json;

namespace cosmoschat.Data
{

    public class ChatHub : Hub
    {
        public const string HubUrl = "/chat";


        public async Task BroadcastMessage(string chatSessionId, string sender, string text,DateTime postedOn)
        {       
            var json = JsonConvert.SerializeObject(new ChatRow(sender, text, postedOn));
            await Clients.All.SendAsync("BroadcastMessage", chatSessionId, json);
        }

        public override Task OnConnectedAsync()
        {
            Console.WriteLine($"{Context.ConnectionId} connected");
            return base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception e)
        {
            Console.WriteLine($"Disconnected {e?.Message} {Context.ConnectionId}");
            await base.OnDisconnectedAsync(e);
        }
    }

}
