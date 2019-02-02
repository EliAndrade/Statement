local Statement = {}

Statement.stack = {}
Statement.blockUpdatePos = 0
Statement.blockMousePos = 0
Statement.blockKeysPos = 0
Statement.blockDrawPos = 0


function Statement:push(state, ...)
	--Check if it is already at stack
	for i, v in ipairs(self.stack) do
		if v == state then
			io.write("State is already at stack!\n")
			--Return false as state was already at stack
			return false
		end
	end
	
	--Call StackOver function
	if #self.stack > 0 then
		if self.stack[#self.stack].onStackOver then
			self.stack[#self.stack]:onStackOver(self)
		end 
	end
	
	--Push onto stack
	table.insert(self.stack, state)
	
	--Update blocking positions
	if state.blockUpdate then
		self.blockUpdatePos = #self.stack
	end
	if state.blockKeys then
		self.blockKeysPos = #self.stack
	end
	if state.blockDraw then
		self.blockDrawPos = #self.stack
	end
	
	--Call start function
	if state.onStart then
		state:onStart(self, unpack({...}))
	end
	
	--Return true as state was not at stack
	return true
end

function Statement:pop()
	--Check if stack is empty
	if #self.stack == 0 then
		io.write("Stack is empty!\n")
		return nil
	end
	
	--Pop from stack and save for return
	local state = table.remove(self.stack)
	
	--Call exit function
	if state.onExit then	
		state:onExit(self)
	end
	
	--Call StackOver function
	if #self.stack > 0 then
		if self.stack[#self.stack].onUnstackOver then
			self.stack[#self.stack]:onUnstackOver(self)
		end 
	end
	
	--Update blocking positions
	for i = #self.stack, 1, -1 do
		if self.stack[i].blockUpdate then
			self.blockUpdatePos = i
			break
		end
		if i == 1 then 
			self.blockUpdatePos = 0
		end
	end
	for i = #self.stack, 1, -1 do
		if self.stack[i].blockDraw then
			self.blockDrawPos = i
			break
		end
		if i == 1 then 
			self.blockDrawPos = 0
		end
	end
	for i = #self.stack, 1, -1 do
		if self.stack[i].blockKeys then
			self.blockKeysPos = i
			break
		end
		if i == 1 then 
			self.blockKeysPos = 0
		end
	end
	return state
end

function Statement:peek()
	return #self.stack > 0 and self.stack[#self.stack] or nil
end

function Statement:draw()
	if #self.stack > 0 then
		for i = self.blockDrawPos == 0 and 1 or self.blockDrawPos, #self.stack do
			if self.stack[i].draw then
				self.stack[i]:draw()
			end
		end
	end
end

function Statement:update(dt)
	if #self.stack > 0 then
		for i = #self.stack, self.blockUpdatePos == 0 and 1 or self.blockUpdatePos, -1 do
			if self.stack[i].update then
				self.stack[i]:update(dt)
			end
		end
	end
end

function Statement:keypressed(key)
	if #self.stack > 0 then
		for i = #self.stack, self.blockKeysPos == 0 and 1 or self.blockKeysPos, -1 do
			if self.stack[i].keypressed then
				self.stack[i]:keypressed(key)
			end
		end
	end
end

function Statement:keyreleased(key)
	if #self.stack > 0 then
		for i = #self.stack, self.blockKeysPos == 0 and 1 or self.blockKeysPos, -1 do
			if self.stack[i].keyreleased then
				self.stack[i]:keyreleased(key)
			end
		end
	end
end

function Statement:mousepressed(x, y, button)
	if #self.stack > 0 then
		for i = #self.stack, self.blockMousePos == 0 and 1 or self.blockMousePos, -1 do
			if self.stack[i].mousepressed then
				self.stack[i]:mousepressed(x, y, button)
			end
		end
	end
end

function Statement:mousereleased(x, y, button)
	if #self.stack > 0 then
		for i = #self.stack, self.blockMousePos == 0 and 1 or self.blockMousePos, -1 do
			if self.stack[i].mousereleased then
				self.stack[i]:mousereleased(x, y, button)
			end
		end
	end
end
return Statement