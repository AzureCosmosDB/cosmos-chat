namespace cosmoschat.Services
{
    public class ChatService 
    {

        private static List<ChatSession> chatSessions;

        private readonly CosmosService cosmos;
        

        public ChatService(IConfiguration configuration)
        {

            cosmos = new CosmosService(configuration);

        }

        /**
        Data here maintained in chatSessions List object.
        Any call made here is reflected in this object and is saved to Cosmos.
        
        Calls Here
        1. Get list of Chat Sessions for left-hand nav (called when instance created).
        2. User clicks on Chat Session, go get messages for that chat session.
        3. User clicks + to create a new Chat Session.
        4. User Inputs a chat session from "New Chat" to something else.
        5. User deletes a chat session.
        6. User types a question (prompt) into web page and hits enter.
            6.1 Save prompt in chatSessions.Messages[] 
            6.2 Save response in chatSessions.Messages[]
        **/


        // Returns list of chat session ids and names for left-hand nav to bind to (display ChatSessionName and ChatSessionId as hidden)
        public async Task<List<ChatSession>> GetAllChatSessionsAsync()
        {
            chatSessions = await cosmos.GetChatSessionsListAsync();
           
            return chatSessions;
        }


        //Returns the chat messages to display on the main web page when the user selects a chat from the left-hand nav
        public async Task<List<ChatMessage>> GetChatSessionMessagesAsync(string chatSessionId)
        {
            List<ChatMessage> chatMessages = new List<ChatMessage>();

            if (chatSessions.Count == 0) return null;

            int index = chatSessions.FindIndex(s => s.ChatSessionId == chatSessionId);
            
            if (chatSessions[index].Messages.Count == 0)
            { 
                //Messages are not cached, go read from database
                chatMessages = await cosmos.GetChatSessionMessagesAsync(chatSessionId);

                //cache results
                 chatSessions[index].Messages = chatMessages;

            }
            else
            {
                //load from cache
                chatMessages = chatSessions[index].Messages;
            }
            return chatMessages;

        }

        //User creates a new Chat Session in left-hand nav
        public async Task CreateNewChatSessionAsync()
        {
            ChatSession chatSession = new ChatSession();

            chatSessions.Add(chatSession);
            
            await cosmos.InsertChatSessionAsync(chatSession);
                       
        }

        //User Inputs a chat from "New Chat" to user defined
        public async Task RenameChatSessionAsync(string chatSessionId, string newChatSessionName)
        {
            
            int index = chatSessions.FindIndex(s => s.ChatSessionId == chatSessionId);

            chatSessions[index].ChatSessionName = newChatSessionName;

            await cosmos.UpdateChatSessionAsync(chatSessions[index]);

        }

        //User deletes a chat session from left-hand nav
        public async Task DeleteChatSessionAsync(string chatSessionId)
        {
            int index = chatSessions.FindIndex(s => s.ChatSessionId == chatSessionId);

            chatSessions.RemoveAt(index);

            await cosmos.DeleteChatSessionAsync(chatSessionId);


        }


        // Post messsage to the chat session and insert into Cosmos.
        public async Task <ChatMessage> AddChatMessageAsync(string chatSessionId, string sender, string text)
        {
            ChatMessage chatMessage = new ChatMessage(chatSessionId, sender, text);

            int index = chatSessions.FindIndex(s => s.ChatSessionId == chatSessionId);

            chatSessions[index].AddMessage(chatMessage);

            return await cosmos.InsertChatMessageAsync(chatMessage);

        }
    }
}
