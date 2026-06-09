## initial notes

 - [/] init function should ensure the tables and add the system prompt
 - [/] sessions table, session_id, name, created_at, is_active
 - [/] robust function to select which session is active, there can be only one
 - [/] messages table, role, content, tool_calls, session_id
 - X tool calls table, id, tool_name, message_id, tool_call_id, results
   - It turns out this one is bad, the openai api expects the tool calls to 
     be embedded in the message, so we'll just store them as json in the 
     messages table for now. If we find we need to query them separately we 
     can always add a separate table later and backfill it.
 - [/] instead of clear, it'll be /new. new_chat_chatid will be the name by default and it'll be made active
   - the user chooses the name, it's required. for this phase. 
 - add message should be able to stay the same in the api
 - X command to name the session, no args given lets the llm decide
 - [/] command to list session, shows the name and id of the chat
 - [/] command to switch session, takes the name or id and makes it active
 - tool call id seems to be a necessary thing for now to trace back to the message
 - [/] load from file function replaced with the connection
 - [/] save history not necessary anymore, we save and load from the db as we go

