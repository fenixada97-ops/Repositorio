-- 📡 Script avançado de Monitoramento para Blox Fruits (Otimizado para KRNL e Novas Estruturas de Dados)
-- Mostra: Level, Beli, Fragmentos, Frutas guardadas, Mastery, Status
-- Envia uma mensagem inicial de teste + atualizações a cada 1 minuto

local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer
local Data = player:WaitForChild("Data") -- Isso geralmente ainda funciona para Level, Beli, Fragments
local startTime = tick()

-- ✅ SEU WEBHOOK DO DISCORD - COLOQUE O URL CORRETO AQUI
-- Use o MESMO URL que funcionou no seu teste Python!
local WEBHOOK_URL = "https://discord.com/api/webhooks/1398816628417888388/dk_dfon8Z5ZU1CEMpzVmX0satTLAoktXqFYh_5Hel7AZ9kIpshyvI2V6YyiHeLYeStLd" -- **MANTENHA ESTE URL SE ELE FUNCIONOU NO PYTHON**

-- Dados anteriores para comparação
local lastData = {
    Level = Data.Level.Value,
    Beli = Data.Beli.Value,
    Fragments = Data.Fragments.Value,
    Fruits = {}, -- Será preenchido na primeira execução
}

--- Função auxiliar para formatar números grandes (ex: 1.2M, 1.5K)
local function formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

--- Coleta as frutas guardadas no inventário (Tentativa de correção)
local function getFruitInventory()
    local fruitList = {}
    local success, fruits = pcall(function()
        -- Tenta encontrar o RemoteFunction de forma mais genérica ou por nome conhecido
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remotes then
            local commF = remotes:FindFirstChild("CommF_") or remotes:FindFirstChild("CommF") -- Tenta CommF_ ou CommF
            if commF and commF:IsA("RemoteFunction") then
                return commF:InvokeServer("getInventoryFruits")
            end
        end
        return nil -- Retorna nil se não encontrar o RemoteFunction
    end)

    if success and fruits and type(fruits) == "table" then
        for _, fruit in pairs(fruits) do
            if fruit and fruit.Name then
                table.insert(fruitList, fruit.Name)
            end
        end
    else
        warn("Erro ao obter inventário de frutas ou retorno inesperado:", tostring(fruits))
    end
    return fruitList
end

--- Compara frutas antigas e novas para identificar as ganhas
local function compareFruits(old, new)
    local gained = {}
    local oldFruitMap = {}
    for _, fruitName in pairs(old) do
        oldFruitMap[fruitName] = (oldFruitMap[fruitName] or 0) + 1
    end

    for _, fruitName in pairs(new) do
        if oldFruitMap[fruitName] and oldFruitMap[fruitName] > 0 then
            oldFruitMap[fruitName] = oldFruitMap[fruitName] - 1
        else
            table.insert(gained, fruitName)
        end
    end
    return gained
end

--- Coleta os status (melee, defense, etc.) do jogador (Tentativa de correção)
local function getStats()
    local stats = {}
    -- Tenta encontrar os stats dentro de "player.leaderstats" ou outro local comum
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in pairs(leaderstats:GetChildren()) do
            if stat and stat.Name and stat.Value then
                stats[stat.Name] = stat.Value
            end
        end
    end
    -- Se não encontrar em leaderstats, tenta outros locais conhecidos do Blox Fruits
    -- (Ajuste conforme a estrutura atual do jogo, se souber onde estão)
    -- Ex: player.PlayerStats, player.Character.Stats, etc.
    -- Por enquanto, vamos focar em leaderstats que é mais comum para stats visíveis.

    -- Adiciona os stats que o script espera, mesmo que não os encontre, para evitar erro de nil
    stats["Melee"] = stats["Melee"] or "N/A"
    stats["Defense"] = stats["Defense"] or "N/A"
    stats["Sword"] = stats["Sword"] or "N/A"
    stats["Gun"] = stats["Gun"] or "N/A"
    stats["Blox Fruit"] = stats["Blox Fruit"] or "N/A"

    return stats
end

--- Pega a Mastery da fruta equipada
local function getEquippedFruitMastery()
    local tool = player.Character:FindFirstChildOfClass("Tool")
    if tool and string.find(tool.Name, "Fruit") then -- Verifica se é uma fruta equipada
        local mastery = tool:FindFirstChild("Level")
        if mastery and mastery.Value then
            return tool.Name .. " - Mastery " .. mastery.Value
        else
            return tool.Name .. " - Mastery desconhecido"
        end
    end
    return "Nenhuma fruta equipada"
end

--- Envia a mensagem embed para o Discord
local function sendToDiscord(diff, current, isFirst)
    local now = tick()
    local elapsed = math.floor(now - startTime)
    local stats = getStats()
    local mastery = getEquippedFruitMastery()

    local description = "Detalhes do progresso do seu farm no Blox Fruits!"
    if isFirst then
        description = "Seu monitor de farm foi iniciado com sucesso!"
    end

    local fields = {
        {["name"] = "⏱ Tempo Online", ["value"] = tostring(elapsed // 60) .. " min", ["inline"] = true},
        {["name"] = "📊 Level", ["value"] = tostring(current.Level) .. (isFirst and "" or " (+" .. formatNumber(diff.Level) .. ")"), ["inline"] = true},
        {["name"] = "💰 Beli", ["value"] = formatNumber(current.Beli) .. (isFirst and "" or " (+" .. formatNumber(diff.Beli) .. ")"), ["inline"] = true},
        {["name"] = "🔷 Fragmentos", ["value"] = formatNumber(current.Fragments) .. (isFirst and "" or " (+" .. formatNumber(diff.Fragments) .. ")"), ["inline"] = true},
        {["name"] = "🍈 Fruta Equipada", ["value"] = mastery, ["inline"] = false},
        {["name"] = "💪 Status", ["value"] =
            "Melee: " .. tostring(stats["Melee"] or "N/A") ..
            "\nDefense: " .. tostring(stats["Defense"] or "N/A") ..
            "\nSword: " .. tostring(stats["Sword"] or "N/A") ..
            "\nGun: " .. tostring(stats["Gun"] or "N/A") ..
            "\nBlox Fruit: " .. tostring(stats["Blox Fruit"] or "N/A"), ["inline"] = false},
        {["name"] = "📦 Frutas Guardadas", ["value"] = (#current.Fruits > 0 and table.concat(current.Fruits, ", ") or "Nenhuma fruta guardada"), ["inline"] = false},
    }

    if not isFirst and #diff.NewFruits > 0 then
        table.insert(fields, {
            ["name"] = "🆕 Novas Frutas Obtidas",
            ["value"] = table.concat(diff.NewFruits, ", "),
            ["inline"] = false
        })
    end

    local embed = {
        ["title"] = isFirst and "✅ Monitor de Farm Iniciado!" or "🍥 Monitoramento de Farm - Blox Fruits",
        ["description"] = description,
        ["fields"] = fields,
        ["color"] = isFirst and 3066993 or 15844367, -- Verde para início, Laranja para atualizações
        ["footer"] = {["text"] = "Monitor de Farm | Feito com ☕"},
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    local payload = HttpService:JSONEncode({embeds = {embed}})

    local requestFunc = rawget(getfenv(0), "http_request") or rawget(getfenv(0), "request") or (syn and syn.request) or (fluxus and fluxus.request)

    if requestFunc then
        local success, result = pcall(function()
            return requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = payload
            })
        end)

        if not success or (result and result.StatusCode and (result.StatusCode < 200 or result.StatusCode >= 300)) then
            local errorMsg = "Erro desconhecido ao enviar webhook."
            if result and result.StatusCode then
                errorMsg = "Erro no Discord (Status: " .. result.StatusCode .. ", Corpo: " .. (result.Body or "N/A") .. ")"
            elseif not success then
                errorMsg = "Falha na requisição HTTP (Lua Error): " .. tostring(result)
            end
            warn("🚨 Alerta: Falha ao enviar atualização para o Discord! " .. errorMsg)
            warn("Verifique se o URL do webhook está correto e se ele ainda é válido no Discord.")
        end
    else
        warn("Seu executor (KRNL ou outro) não suporta requisições HTTP. O monitoramento via Discord não funcionará.")
    end
end

--- Inicia o monitoramento
wait(5) -- Pequena pausa para garantir que os dados iniciais carreguem

-- Tenta obter os dados iniciais de forma segura, se falhar, usa valores padrão
local initialLevel = Data.Level.Value
local initialBeli = Data.Beli.Value
local initialFragments = Data.Fragments.Value
local initialFruits = getFruitInventory()

local initialCurrent = {
    Level = initialLevel,
    Beli = initialBeli,
    Fragments = initialFragments,
    Fruits = initialFruits,
}
lastData = initialCurrent -- Define os dados iniciais para futuras comparações
sendToDiscord({}, initialCurrent, true) -- Envia a mensagem de início

-- 🔁 Loop principal: Executa a cada 1 minuto
while wait(60) do
    local current = {
        Level = Data.Level.Value,
        Beli = Data.Beli.Value,
        Fragments = Data.Fragments.Value,
        Fruits = getFruitInventory(),
    }

    local diff = {
        Level = current.Level - lastData.Level,
        Beli = current.Beli - lastData.Beli,
        Fragments = current.Fragments - lastData.Fragments,
        NewFruits = compareFruits(lastData.Fruits, current.Fruits)
    }

    sendToDiscord(diff, current, false)
    lastData = current
end
