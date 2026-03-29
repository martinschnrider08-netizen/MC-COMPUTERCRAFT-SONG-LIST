local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local playlistUrl = "https://raw.githubusercontent.com/martinschnrider08-netizen/MC-COMPUTERCRAFT-SONG-LIST/main/Playlist.txt"

if not speaker then error("Kein Speaker gefunden!") end

-- Globale Variablen
local w, h = term.getSize()
local songs = {}
local currentPage = 1
local songsPerPage = 10

-- Farbschema
local colorscheme = {
    bg = colors.black,
    header_bg = colors.gray,
    header_text = colors.yellow,
    text = colors.white,
    number = colors.lightBlue,
    play_bg = colors.blue,
    play_title = colors.lime,
    ui_line = colors.gray,
    ui_text = colors.lightGray,
    highlight = colors.orange,
    vinyl = colors.gray,
    base = colors.brown,
    tonearm = colors.lightGray,
    notes = colors.yellow,
    bar_bg = colors.gray,
    bar_fill = colors.lime,
}

local function printCentered(y, text, textColor, bgColor)
    term.setBackgroundColor(bgColor or colorscheme.bg)
    term.setTextColor(textColor or colorscheme.text)
    local x = math.max(1, math.floor((w - #text) / 2) + 1)
    term.setCursorPos(x, y)
    term.write(text)
end

local function clearScreen(color)
    term.setBackgroundColor(color)
    term.clear()
end

local function drawHeader(title)
    term.setBackgroundColor(colorscheme.header_bg)
    term.setCursorPos(1, 1)
    term.clearLine()
    printCentered(1, title, colorscheme.header_text, colorscheme.header_bg)
    term.setBackgroundColor(colorscheme.bg)
end

local function getPlaylist()
    clearScreen(colorscheme.bg)
    drawHeader("CLOUD PLAYER v4.1")
    printCentered(5, "Verbinde mit Cloud...", colorscheme.ui_text)
    
    local finalUrl = playlistUrl .. "?t=" .. os.epoch("utc")
    local response = http.get(finalUrl)
    if not response then return songs end
    
    local newSongs = {}
    local line = response.readLine()
    while line do
        line = line:gsub("%s+", "")
        if line:find("http") then table.insert(newSongs, line) end
        line = response.readLine()
    end
    response.close()
    return newSongs
end

local function drawTurntable(tick)
    local centerX = w - 8
    local centerY = h / 2 + 1
    term.setTextColor(colorscheme.notes)
    local noteChars = {"?", "?", "?"}
    for i=1, 3 do
        local offY = math.sin((tick + i*10) * 0.2) * 1
        term.setCursorPos(centerX - 3 + i*2, centerY - 5 + offY)
        term.write(noteChars[i])
    end
    term.setTextColor(colorscheme.base)
    term.setCursorPos(centerX - 5, centerY + 3) term.write("***********")
    term.setCursorPos(centerX - 5, centerY + 4) term.write("***********")
    term.setTextColor(colorscheme.vinyl)
    term.setCursorPos(centerX - 3, centerY - 2) term.write("#######")
    term.setCursorPos(centerX - 4, centerY - 1) term.write("##     ##")
    term.setCursorPos(centerX - 5, centerY    ) term.write("##   O   ##")
    term.setCursorPos(centerX - 4, centerY + 1) term.write("##     ##")
    term.setCursorPos(centerX - 3, centerY + 2) term.write("#######")
    term.setTextColor(colorscheme.tonearm)
    term.setCursorPos(centerX + 3, centerY - 2) term.write("\\")
    term.setCursorPos(centerX + 4, centerY - 1) term.write(" |")
    term.setCursorPos(centerX + 4, centerY    ) term.write(" O")
end

local function playSong(url)
    local response = http.get(url, nil, true)
    if not response then return end
    
    local decoder = dfpwm.make_decoder()
    local name = url:match("([^/]+)%.dfpwm$") or "Song"
    name = name:gsub("%%20", " ")
    
    local tick = 0
    local lastDraw = 0
    
    -- Wir lesen den Song in Häppchen
    while true do
        local chunk = response.read(16 * 1024)
        if not chunk then break end
        local buffer = decoder(chunk)
        
        while not speaker.playAudio(buffer) do
            if os.clock() - lastDraw > 0.1 then
                clearScreen(colorscheme.play_bg)
                drawHeader("NUN SPIELT")
                term.setCursorPos(2, 4)
                term.setTextColor(colorscheme.text)
                term.write("Titel:")
                term.setCursorPos(2, 5)
                term.setTextColor(colorscheme.play_title)
                term.write(name:sub(1, w-18))
                
                drawTurntable(tick)
                tick = tick + 1
                
                term.setCursorPos(2, h)
                term.setTextColor(colorscheme.ui_text)
                term.write("[q] Stoppen & Zurueck")
                lastDraw = os.clock()
            end
            
            local ev, p = os.pullEvent()
            if ev == "char" and p == "q" then 
                response.close() 
                return 
            end
        end
    end
    response.close()
end

-- Start
songs = getPlaylist()

while true do
    term.setBackgroundColor(colorscheme.bg)
    term.clear()
    drawHeader("CLOUD PLAYER v4.1")
    
    local totalPages = math.max(1, math.ceil(#songs / songsPerPage))
    if currentPage > totalPages then currentPage = totalPages end
    
    local startIdx = (currentPage - 1) * songsPerPage + 1
    local endIdx = math.min(startIdx + songsPerPage - 1, #songs)
    
    for i = startIdx, endIdx do
        local sName = songs[i]:match("([^/]+)%.dfpwm$") or "Song "..i
        sName = sName:gsub("%%20", " ")
        term.setCursorPos(2, 2 + (i - startIdx))
        term.setTextColor(colorscheme.number)
        term.write(string.format("%2d", i) .. ": ")
        term.setTextColor(colorscheme.text)
        term.write(sName:sub(1, w-6))
    end
    
    term.setCursorPos(1, h-3)
    term.setTextColor(colorscheme.ui_line)
    term.write(string.rep("-", w))
    term.setCursorPos(2, h-2)
    term.setTextColor(colorscheme.ui_text)
    term.write("Seite " .. currentPage .. "/" .. totalPages)
    term.setTextColor(colorscheme.highlight)
    term.write("  [n/p] Blaettern  [u] Update")
    term.setCursorPos(2, h)
    term.setTextColor(colorscheme.play_title)
    term.write("Nr tippen & Enter: ")
    
    local input = read()
    if input == "n" and currentPage < totalPages then
        currentPage = currentPage + 1
    elseif input == "p" and currentPage > 1 then
        currentPage = currentPage - 1
    elseif input == "u" then
        songs = getPlaylist()
        currentPage = 1
    elseif tonumber(input) and songs[tonumber(input)] then
        playSong(songs[tonumber(input)])
    end
end
