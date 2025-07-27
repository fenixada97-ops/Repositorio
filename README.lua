-- 📡 Script avançado de Monitoramento para Blox Fruits (Otimizado)
-- Mostra: Level, Beli, Fragmentos, Frutas guardadas, Mastery, Status
-- Envia uma mensagem inicial de teste + atualizações a cada 1 minuto

local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer
local Data = player:WaitForChild("Data")
local startTime = tick()

-- ✅ SEU WEBHOOK DO DISCORD - COLOQUE O URL CORRETO AQUI
local WEBHOOK_URL = "https://discord.com/api/webhooks/1398816628417888388/dk_dfon8Z5ZU1CEMpzVmX0satTLAoktXqFYh_5Hel7AZ9kIpshyvI2V6YyiHeLYeStLd" -- Substitua pelo seu webhook válido!

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

--- Coleta as frutas guardadas no inventário
local function getFruitInventory()
    local fruitList = {}
    local success, fruits = pcall(function()
        return game:GetService("ReplicatedStorage"):WaitForChild("Remotes").CommF_:InvokeServer("getInventoryFruits")
    end)

    if success and fruits then
        for _, fruit in pairs(fruits) do
            if fruit and fruit.Name then
                table.insert(fruitList, fruit.Name)
            end
        end
    else
        warn("Erro ao obter inventário de frutas:", fruits)
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

--- Coleta os status (melee, defense, etc.) do jogador
local function getStats()
    local stats = {}
    if player and player.Stats then
        for _, stat in pairs(player.Stats:GetChildren()) do
            if stat and stat.Name and stat.Value then
                stats[stat.Name] = stat.Value
            end
        end
    end
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
    local requestFunc = syn and syn.request or http_request or request or fluxus and fluxus.request

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
        warn("Seu executor não suporta requisições HTTP. O monitoramento via Discord não funcionará.")
    end
end

--- Inicia o monitoramento
wait(5) -- Pequena pausa para garantir que os dados iniciais carreguem

local initialCurrent = {
    Level = Data.Level.Value,
    Beli = Data.Beli.Value,
    Fragments = Data.Fragments.Value,
    Fruits = getFruitInventory(),
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
