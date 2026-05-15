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
172
  try {
    const { imageBase64 } = await req.json()
    const keysString = Deno.env.get('GEMINI_API_KEY') || ""
    const apiKeys = keysString.split(',').map(k => k.trim())

    if (apiKeys.length === 0) throw new Error("No API keys configured.")

const prompt = `Analyze this image for industrial safety hazards based on these specific hospital standards:

1. LADDERS: Check for damage (broken legs/steps), unspread/unlocked spreaders, missing/unstable steps and broken rungs.
2. LIFTERS/SCAFFOLDS: Check if outriggers are fully inserted/locked, if the area is cordoned, and if warning signage is displayed.
3. CONFINED SPACES: Detect unauthorized entry, lack of ventilation, or obstructed access.
4. PPE: Ensure personnel are wearing safety helmets, safety shoes, and appropriate gear like cryogenic gloves or safety harnesses where required.
5. CHEMICAL/LN2: Check for obstructed transportation routes or uncordoned refilling areas.
6. ELECTRICAL: Check for exposed wiring, damaged equipment, or improper grounding.

Return EXACTLY this format:
OBJECT: [Detected object]
STATUS: [HAZARD or NOT HAZARD]
REASON: [Specific NC from the list, e.g., "Ladder spreaders not locked" or "No proper PPE: missing helmet"]

If no hazard is found, return OBJECT: [Object name] and STATUS: No Hazards Detected.`;

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