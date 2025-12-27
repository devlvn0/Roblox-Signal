# Simple Roblox Signal
Simple Roblox Signal Library  
Mimics the behavior of default roblox RBXScriptSignals (such as BindableEvents), but without creating instances!  
*And a few more features on top of that.*  

## Documentation
### Creating a new Signal:
```luau
-- Added this just for context
local Signal = require(ReplicatedStorage:WaitForChild("Signal"))

-- And creating a new Signal is as easy as that!
local newSignal, fireFunc, destroyFunc = Signal.new()
```
### Connecting Functions
There are, like in default RBXScriptSignals, multiple ways to connect functions to your signals.  
As this library mimics the default RBXScriptSignals, all of the following methods will be the same, with the exception of the `:Wait()` method.  
  
**Using :Connect()**  
Syntax: `:Connect(func: (any) -> ()) -> Connection`  
```luau
local newConnection = newSignal:Connect(function(...)
    print("Hello World!", ...)
    -- Do some more stuff
end)
```
  
  
**Using :ConnectParallel()**  
*Not sure if this works though*  
Syntax: `:ConnectParallel(func: (any) -> ()) -> Connection`  
```luau
-- Basically the same as :Connect() but for running code in parallel luau
local newConnection = newSignal:ConnectParallel(function(...)
    print("Hello World!", ...)
    -- Do some more stuff
end)
```

**Using :ConnectCondition()**  
Syntax: `:Connect(condition: T, func: (any) -> ()) -> Connection`
```luau
-- Basically the same as :Connect() but with an additional condition argument
-- Will automatically disconnect the function when the condition is true
-- Directly setting it to true will work like :Once()

local num = 0
local newConnection = newSignal:ConnectCondition(num >= 10, function(...)
    num += 1
    -- Do some more stuff
end)
```
  
**Using :Once()**  
Syntax: `:Once(func: (any) -> ()) -> Connection`  
```luau
-- And again, basically the same as the default :Once() method
local newConnection = newSignal:Once(function(...)
    print("Hello World!", ...)
    -- Do some more stuff
end)
```

**Using :Wait()**  
Syntax: `:Wait(timeOut: number?) -> any`
```luau
-- Now this one works the same as the default roblox one, however it has a "timeOut" parameter.
local returnedA, returnedB, returnedC = newSignal:Wait(10)

-- This can be used, like in :WaitForChild(), to automatically stop the yielding after a set time.
-- This is useful avoid infinite yields, that sometimes occur from the default :Wait(),
-- in some specific scenarios.
```

### Disconnecting a Signal Connection
Syntax: `:Disconnect() -> ()`
```luau
-- Works exactly like roblox' Signals.
local connection = newSignal:Connect(function()
    -- Do anything
end)

connection:Disconnect()
```

Syntax: `:Destroy() -> ()`
```luau
-- Just a synonym for :Disconnect(). Used for useful libraries like Janitor,
-- so that you dont need to specify which function to run.
local connection = newSignal:Connect(function()
    -- Do anything
end)

connection:Disconnect()
```

*Maybe add a timed disconnect at some point?*

### Firing the Signal
Firing the signal is really easy, as it works the same way as the default roblox one.
Here is an example:
```luau
fireFunc("Hello", "World", "!")
-- This will now fire all connected functions and pass the 3 strings to them.
```

### Destroying the Signal
Destroying is also simple, as it's just one function:
```luau
destroyFunc()
```
