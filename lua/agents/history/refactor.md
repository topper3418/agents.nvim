## initial notes

 - [/] init function should ensure the tables and add the system prompt
 - [/] sessions table, session_id, name, created_at, is_active
 - [/] robust function to select which session is active, there can be only one
 - [/] messages table, role, content, tool_calls, session_id
 - [/] tool calls table, id, tool_name, message_id, tool_call_id, results
 - [ ] instead of clear, it'll be /new. new_chat_chatid will be the name by default and it'll be made active
 - add message should be able to stay the same in the api
 - [ ] command to name the session, no args given lets the llm decide
 - [ ] command to list session, shows the name and id of the chat
 - [ ] command to switch session, takes the name or id and makes it active
 - tool call id seems to be a necessary thing for now to trace back to the message
 - [ ] load from file function replaced with the connection
 - [ ] save history not necessary anymore, we save and load from the db as we go


## future updates
 - [ ] consider saving session-specific params
