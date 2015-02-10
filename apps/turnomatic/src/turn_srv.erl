-module(turn_srv).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/1, start_link/0, get_count/0, get_ticket/0, get_status/0, serve_next/0]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {request_count, now_serving, line_up = []}).
%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link(Count) ->
	gen_server:start_link({local, ?SERVER}, ?MODULE, [Count], []).

start_link() ->
    start_link(1).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init([Count]) ->
    {ok, #state{request_count = Count, now_serving = Count}, 0}.

%% see current count 
handle_call(get_count, _From, State) ->
	{reply, {ok, State#state.request_count}, State}; 

%% get ticket and increment count
handle_call(get_ticket, From, State) ->
	RequestCount = State#state.request_count,
	CurrentLineUp = State#state.line_up,
	{reply, {ok, RequestCount+1}, State#state{request_count = RequestCount + 1, line_up = [From|CurrentLineUp]}};
	
%% view count, current serving and line in front of you
handle_call(get_status, _From, State) ->
	{reply, {ok, State}, State};

%% called by queues, tells the Server to send the next person in line	
handle_call(serve_next, _From, State) ->
	NowServing = State#state.now_serving,
	LineUp = State#state.line_up,
	case LineUp =/= [] of	% if someone sends serve_next in error
		true  ->
			FirstInLine = lists:last(LineUp),
			io:format("Process: ~p you can go to an open window~n", [FirstInLine]),
			{reply, {ok, Status}, State#state{now_serving = NowServing + 1, line_up = lists:droplast(LineUp)}};
		false ->
			io:format("Error: nobody to serve!!n", []),
			{reply, {no_line, State}, State}
	end;
	
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

get_count() ->
	gen_server:call(?MODULE, get_count).
	
get_ticket() ->
	gen_server:call(?MODULE, get_ticket).
	
get_status() ->
	gen_server:call(?MODULE, get_status).
	
serve_next() ->
	gen_server:call(?MODULE, serve_next).