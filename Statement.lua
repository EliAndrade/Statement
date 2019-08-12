local Statement = {}

Statement.states = {}
Statement.stack = {}
Statement.actualShader = nil

Statement.blockUpdatePos = 1
Statement.blockMousePos = 1
Statement.blockKeysPos = 1
Statement.blockDrawPos = 1
Statement.blockWindowPos = 1

Statement.canUpdateTop = true
Statement.canvas = nil
Statement.timer = 0
Statement.maxTimer = 15
Statement.DEBUG_MODE = true 

--//Set states table to be used//--
function Statement:setStatesTable(table)
	self.states = table
end

--//Set transition shader if the next push has a transition time//--
function Statement:setTransitionShader(shader)
	self.actualShader = shader
end

--//Push a state to the stack, returns true if there was no error//--
function Statement:push(name, ...)
	local state = self.states[name]
	if state == nil then
		error("State "..tostring(name).." do not exist!")
	end

	--/Check if it is already at stack
	for i, v in ipairs(self.stack) do
		if v == state then
			if self.DEBUG_MODE then
				error(string.format("State %s is already at stack!\n", state.STATE_NAME or "Unnamed"))
			end
			io.write(string.format("State %s is already at stack!\n", state.STATE_NAME or "Unnamed"))
			--Return false as state was already at stack
			return false
		end
	end
	
	--/Call StackOver function
	if #self.stack > 0 then
		if self.stack[#self.stack].onStackOver then
			self.stack[#self.stack]:onStackOver(self)
		end 
	end
	
	--/Push onto stack
	table.insert(self.stack, state)
	
	--/Call start function
	if state.onStart then
		state:onStart(self, unpack({...}))
	end
	
	--/Update blocking positions
	if state.blockUpdate then
		self.blockUpdatePos = #self.stack
	end
	if state.blockKeys then
		self.blockKeysPos = #self.stack
	end
	if state.blockDraw then
		self.blockDrawPos = #self.stack
	end
	
	if state.blockWindow then
		self.blockWindowPos = #self.stack
	end
	
		
	--/Check for transition
	if state.STATE_TRANSITION_TIME then
		self.maxTimer = state.STATE_TRANSITION_TIME
		self.timer = state.STATE_TRANSITION_TIME
		self.canUpdateTop = false
		
		local w, h = love.window.getMode()
		self.canvas = love.graphics.newCanvas(w, h)
	end
	
	
	--/Return true as state was not at stack
	return true
end


--//Pop a state from the stack, returns state or nil if stack is empty//--
function Statement:pop()
	--/Check if stack is empty
	if #self.stack == 0 then
		if self.DEBUG_MODE then
			error("Stack is empty!\n")
		else
			io.write("Stack is empty!\n")
		end
		return nil
	end
	
	--/Pop from stack and save for return
	local state = table.remove(self.stack)
	
	--/Call exit function
	if state.onExit then	
		state:onExit(self)
	end
	
	--/Call StackOver function
	if #self.stack > 0 then
		if self.stack[#self.stack].onUnstackOver then
			self.stack[#self.stack]:onUnstackOver(self)
		end 
	end
	
	--/Update blocking positions
	for i = #self.stack, 1, -1 do
		if self.stack[i].blockUpdate then
			self.blockUpdatePos = i
			break
		end
		if i == 1 then self.blockUpdatePos = 1 end
	end
	for i = #self.stack, 1, -1 do
		if self.stack[i].blockDraw then
			self.blockDrawPos = i
			break
		end
		if i == 1 then self.blockDrawPos = 1 end
	end
	for i = #self.stack, 1, -1 do
		if self.stack[i].blockKeys then
			self.blockKeysPos = i
			break
		end
		if i == 1 then self.blockKeysPos = 1 end
	end
	for i = #self.stack, 1, -1 do
		if self.stack[i].blockWindow then
			self.blockWindowPos = i
			break
		end
		if i == 1 then self.blockWindowPos = 1 end
	end
	
	self.canUpdateTop = true
	return state
end

--//Get the top of the stack without popping it//--
function Statement:peek()
	return #self.stack > 0 and self.stack[#self.stack] or nil
end

--//Callback functions//--
function Statement:draw()
	--FIXME Add love.graphics.push("all") for each state?
	if #self.stack > 0 then
		--/Draw states below top
		if #self.stack > 1 then
			for i = self.canUpdateTop and self.blockDrawPos or self.blockDrawPos-1, #self.stack-1 do
				if self.stack[i].draw then
					self.stack[i]:draw()
				end
			end
		end
		
		--/If there is a transition shader and it is still on transition
		if not self.canUpdateTop and self.actualShader then
			love.graphics.setCanvas(self.canvas)
		end
		
		if self.stack[#self.stack].draw then
			self.stack[#self.stack]:draw()
		end
		
		--/If there is a transition shader and it is still on transition
		if not self.canUpdateTop and self.actualShader then
			love.graphics.setCanvas()
			love.graphics.setShader(self.actualShader)
			self.actualShader:send("value", (self.maxTimer-self.timer)/self.maxTimer)
			love.graphics.draw(self.canvas)
			love.graphics.setShader()
		end
	end

	love.graphics.setShader()
end

function Statement:update(dt)
	if self.timer > 0 then
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.timer = 0
			self.canUpdateTop = true
		end
	end
	

	if #self.stack > 0 then
		for i = #self.stack, self.blockUpdatePos, -1 do
			if self.stack[i].update then
				self.stack[i]:update(dt)
			end
		end
	end
end

function Statement:keypressed(key)
	if #self.stack > 0 then
		for i = #self.stack, self.blockKeysPos, -1 do
			if self.stack[i].keypressed then
				self.stack[i]:keypressed(key)
			end
		end
	end
end

function Statement:keyreleased(key)
	if #self.stack > 0 then
		for i = #self.stack, self.blockKeysPos, -1 do
			if self.stack[i].keyreleased then
				self.stack[i]:keyreleased(key)
			end
		end
	end
end

function Statement:joystickpressed(joystick, button)
	if #self.stack > 0 then
		for i = #self.stack, self.blockKeysPos, -1 do
			if self.stack[i].joystickpressed then
				self.stack[i]:joystickpressed(joystick, button)
			end
		end
	end
end

function Statement:joystickreleased(joystick, button)
	if #self.stack > 0 then
		for i = #self.stack, self.blockKeysPos, -1 do
			if self.stack[i].joystickreleased then
				self.stack[i]:joystickreleased(joystick, button)
			end
		end
	end
end

function Statement:joystickaxis(joystick, axis, value)
	if #self.stack > 0 then
		for i = #self.stack, self.blockKeysPos, -1 do
			if self.stack[i].joystickaxis then
				self.stack[i]:joystickaxis(joystick, axis, value)
			end
		end
	end
end

function Statement:mousepressed(x, y, button)
	if #self.stack > 0 then
		for i = #self.stack, self.blockMousePos, -1 do
			if self.stack[i].mousepressed then
				self.stack[i]:mousepressed(x, y, button)
			end
		end
	end
end

function Statement:mousereleased(x, y, button)
	if #self.stack > 0 then
		for i = #self.stack, self.blockMousePos, -1 do
			if self.stack[i].mousereleased then
				self.stack[i]:mousereleased(x, y, button)
			end
		end
	end
end

function Statement:resize(width, height)
	if #self.stack > 0 then
		for i = #self.stack, self.blockWindowPos, -1 do
			if self.stack[i].resize then
				self.stack[i]:resize(width, height)
			end
		end
	end
end

return Statement
