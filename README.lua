-- Script de Notificação Simples para Discord (TESTE FINAL)

local HttpService = game:GetService("HttpService")

-- ✅ SEU WEBHOOK DO DISCORD - COLOQUE O URL CORRETO AQUI
-- Use o MESMO URL que funcionou perfeitamente no seu teste Python!
local WEBHOOK_URL = "https://discord.com/api/webhooks/1398816628417888388/dk_dfon8Z5ZU1CEMpzVmX0satTLAoktXqFYh_5Hel7AZ9kIpshyvI2V6YyiHeLYeStLd" -- **MANTENHA ESTE URL SE ELE FUNCIONOU NO PYTHON**

-- Conteúdo da mensagem de teste
local testMessage = "🚀 Alerta: Teste de notificação direta do Roblox bem-sucedido! Horário: " .. os.date("!%Y-%m-%d %H:%M:%S")

-- Payload para o Discord
local payload = HttpService:JSONEncode({
    content = testMessage,
    username = "Roblox Notificador Simples",
    avatar_url = "https://i.imgur.com/your_avatar_image.png" -- Opcional: URL de uma imagem para o avatar do webhook
})

-- Detecta a função de requisição HTTP do executor
local requestFunc = rawget(getfenv(0), "http_request") or rawget(getfenv(0), "request") or (syn and syn.request) or (fluxus and fluxus.request)

if requestFunc then
    print("[Notificador] Tentando enviar mensagem para o Discord...")
    local success, result = pcall(function()
        return requestFunc({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = payload
        })
    end)

    if success then
        print("[Notificador] Requisição HTTP enviada com sucesso para o Discord.")
        if result and result.StatusCode then
            print("[Notificador] Status Code do Discord:", result.StatusCode)
            if result.StatusCode >= 200 and result.StatusCode < 300 then
                print("[Notificador] Mensagem de teste enviada com sucesso! Verifique o Discord.")
            else
                print("[Notificador] Erro do Discord (Status " .. result.StatusCode .. ", Corpo: " .. (result.Body or "N/A") .. ")")
            end
        else
            print("[Notificador] Resposta do Discord sem StatusCode. Verifique o Discord manualmente.")
        end
    else
        warn("🚨 [Notificador] FALHA CRÍTICA ao enviar requisição HTTP: " .. tostring(result))
        warn("[Notificador] ISSO INDICA QUE SEU EXECUTOR NÃO ESTÁ ATIVANDO REQUISIÇÕES HTTP POST OU HÁ UM BLOQUEIO.")
    end
else
    warn("🚨 [Notificador] Seu executor NÃO SUPORTA requisições HTTP (função requestFunc não encontrada).")
end

print("[Notificador] Script de notificação concluído.")
