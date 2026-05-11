import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// FIXED IMPORT BELOW
import { GoogleGenerativeAI } from "npm:@google/generative-ai@0.11.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { imageBase64 } = await req.json()
    const keysString = Deno.env.get('GEMINI_KEYS') || ""
    const apiKeys = keysString.split(',').map(k => k.trim())

    if (apiKeys.length === 0) throw new Error("No API keys configured.")

    const prompt = `Analyze this image for safety hazards. 
    Return ONLY this format:
    OBJECT: [Name]
    STATUS: [NOT_APPLICABLE/LOCKED/UNLOCKED/HAZARD]
    REASON: [Specific visual evidence]`

    for (const key of apiKeys) {
      try {
        const genAI = new GoogleGenerativeAI(key)
        const model = genAI.getGenerativeModel({ model: "gemini-3-flash-preview" })

        const result = await model.generateContent([
          prompt,
          { inlineData: { data: imageBase64, mimeType: "image/jpeg" } }
        ])

        const textResponse = result.response.text()

        return new Response(JSON.stringify({ result: textResponse }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })

      } catch (err: any) {
        if (err.message?.includes('429') || err.message?.includes('quota')) {
          console.log("Key exhausted, trying next one...")
          continue 
        }
        throw err 
      }
    }

    throw new Error("All API keys are exhausted.")

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})