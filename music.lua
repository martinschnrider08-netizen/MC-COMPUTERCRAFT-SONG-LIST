local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
-- ERSETZE DEN LINK UNTEN MIT DEINEM RAW-PLAYLIST-LINK
local playlistUrl = "https://github.com/martinschnrider08-netizen/MC-COMPUTERCRAFT-SONG-LIST/raw/refs/heads/main/Playlist.txt"


if not speaker then
    error("Kein Speaker gefunden! Bitte einen anschließen.")
end

local function getPlaylist()
    term.clear()
    term.setCursorPos(1,1)
    print("Verbinde mit GitHub...")
    
    -- Cache-Buster: Erzwingt das Laden der neuesten Version
    local finalUrl = playlistUrl .. "?t=" .. os.epoch("utc")
    local response = http.get(finalUrl)
    
    if not response then 
        print("FEHLER: Playlist nicht erreichbar!")
        return nil 
    end
    
    local songs = {}
    local line = response.readLine()
    while line do
        -- Entfernt Leerzeichen und prüft auf http
        line = line:gsub("%s+", "")
        if line:find("http") then
            table.insert(songs, line)
        end
        line = response.readLine()
    end
    response.close()
    return songs
end

local function playSong(url)
    local response = http.get(url, nil, true)
    if not response then
        print("Fehler beim Streamen des Songs.")
        sleep(2)
        return
    end

    local decoder = dfpwm.make_decoder()
    local name = url:match("([^/]+)%.dfpwm$") or "Unbekannter Titel"
    name = name:gsub("%%20", " ") -- Fix für Leerzeichen in URLs
    
    term.clear()
    term.setCursorPos(1,1)
    print("--- SPIELE JETZT ---")
    print(name)
    print("\nDruecke 'q' zum Beenden")

    while true do
        local chunk = response.read(16 * 1024)
        if not chunk then break end
        local buffer = decoder(chunk)
        
        while not speaker.playAudio(buffer) do
            local event, key = os.pullEvent()
            if event == "char" and key == "q" then
                print("Song gestoppt.")
                response.close()
                return
            end
        end
    end
    response.close()
end

-- Hauptmenü
while true do
    local songs = getPlaylist()
    
    if songs and #songs > 0 then
        term.clear()
        term.setCursorPos(1,1)
        print("--- DEIN CLOUD PLAYER ---")
        print("Gefundene Songs: " .. #songs)
        print("-------------------------")
        
        for i, url in ipairs(songs) do
            local name = url:match("([^/]+)%.dfpwm$") or "Song " .. i
            name = name:gsub("%%20", " ")
            print(i .. ": " .. name)
        end
        
        print("\nWaehle Nr oder 'u' fuer Update:")
        local input = read()
        
        if input == "u" then
            print("Aktualisiere...")
            sleep(0.5)
        elseif tonumber(input) and songs[tonumber(input)] then
            playSong(songs[tonumber(input)])
        end
    else
        print("\nKeine Songs gefunden oder offline.")
        print("Druecke Enter zum Neuversuch...")
        read()
    end
end
