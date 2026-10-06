--[=[
                                          
             ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓         
            ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓        
            ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓          
           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      
           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓            
          ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓              
          ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓         
         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓       
         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓               
        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓     			  Bindable  
         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      			   v2.1.0
              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      https://devforum.roblox.com/t/4760861
              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓      
             ▓▓▓▓▓▓▓▓▓▓▓▓▓                
             ▓▓▓▓▓▓▓▓▓▓▓                  
            ▓▓▓▓▓▓▓▓▓▓                    
            ▓▓▓▓▓▓▓▓                      
           ▓▓▓▓▓▓▓▓                       
           ▓▓▓▓▓▓                         
          ▓▓▓▓▓                           
          ▓▓▓                             
                                         
]=]

-- types

export type Connection = {
	Disconnect: (self: Connection) -> (),
	Connected: boolean,
}

export type Bindable = {
	Connect: (self: Bindable, callback: (...any) -> ()) -> Connection,
	Once: (self: Bindable, callback: (...any) -> ()) -> Connection,
	Wait: (self: Bindable) -> ...any,
	Fire: (self: Bindable, ...any) -> (),
	DisconnectAll: (self: Bindable) -> (),
	Destroy: (self: Bindable) -> ()
}

export type Constructor = {
	new: () -> Bindable,
	Wrap: (signal: RBXScriptSignal) -> Bindable,
}

---------

-- init

const Constructor = {}
const Bindable = {}
Bindable.__index = Bindable

const Connection = {}
Connection.__index = Connection

---------

-- connection class

function Connection:Disconnect()
	if not self.Connected then return end
	self.Connected = false

	const bindable = self._bindable
	const prev = self._prev
	const next = self._next

	if prev then
		prev._next = next
	else
		bindable._head = next
	end

	if next then
		next._prev = prev
	else
		bindable._tail = prev
	end

	self._prev = nil
	self._next = nil
	self._bindable = nil
	self._callback = nil
end

---------

-- bindable class

function Bindable:Connect(callback: (...any) -> ()): Connection
	if typeof(callback) ~= "function" then
		error("Argument #1 must be a function", 2)
	end

	-- use a shared metatable to save memory by reusing a single disconnect func pointer
	const connection = setmetatable({
		Connected = true,
		_bindable = self,
		_callback = callback,
		_next = nil,
		_prev = nil,
	}, Connection) :: any

	if self._tail then
		self._tail._next = connection
		connection._prev = self._tail
		self._tail = connection
	else
		self._head = connection
		self._tail = connection
	end

	return connection
end


function Bindable:Once(callback: (...any) -> ()): Connection
	local connection: Connection
	connection = self:Connect(function(...: any)
		connection:Disconnect() 
		callback(...)
	end)
	return connection
end

function Bindable:Wait(): ...any
	const currentThread = coroutine.running()
	self:Once(function(...: any)
		task.spawn(currentThread, ...)
	end)

	return coroutine.yield()
end

function Bindable:Fire(...: any): ()
	const connected = {}
	local node = self._head

	while node do
		if node.Connected then
			table.insert(connected, node)
		end
		node = node._next
	end

	for _, connection in connected do
		if connection.Connected then
			task.spawn(connection._callback, ...)
		end
	end
end

function Bindable:DisconnectAll(): ()
	local connection = self._head 

	while connection ~= nil do
		const nextConnection = connection._next
		connection.Connected = false
		connection._prev = nil
		connection._next = nil
		connection._bindable = nil
		connection._callback = nil
		connection = nextConnection
	end

	self._head = nil
	self._tail = nil
end

function Bindable:Destroy(): ()
	self:DisconnectAll()
	
	-- break the internal ref tree to allow clean gc drops
	setmetatable(self, nil)
end

function Constructor.new(): Bindable
	const self = setmetatable({
		_head = nil,
		_tail = nil,
	}, Bindable)

	return (self :: any) :: Bindable
end

function Constructor.Wrap(signal: RBXScriptSignal): Bindable
	if typeof(signal) ~= "RBXScriptSignal" then
		error("Argument #1 must be a RBXScriptSignal", 2)
	end

	const wrapper = Constructor.new()
	local rbxConnection: RBXScriptConnection? = nil

	rbxConnection = signal:Connect(function(...: any)
		wrapper:Fire(...)
	end)

	-- leverage a custom override metatable to preserve class cleanliness
	const proxyMetatable = {
		__index = Bindable,
		Destroy = function(self: any)
			if rbxConnection then
				rbxConnection:Disconnect()
				rbxConnection = nil
			end
			-- reroute directly to base cleanup rules
			Bindable.Destroy(self)
		end
	}

	return setmetatable(wrapper, proxyMetatable) :: any
end



---------

return (Constructor :: any) :: Constructor