using Microsoft.AspNetCore.SignalR;
using Newtonsoft.Json;

namespace cosmoschat.Services
{

    public class ChatHub : Hub
    {
        public const string HubUrl = "/chat";

        
        public async Task BroadcastSession()
        {
            await Clients.All.SendAsync("BroadcastSession");
        }

        public async Task BroadcastMessage(string chatSessionId, string id, string sender, string text, DateTime postedOn)
        {
            var json = JsonConvert.SerializeObject(new ChatMessage(chatSessionId, id, sender, text, postedOn));
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
