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

const prompt = `You are an expert industrial safety inspector enforcing a hospital's strict Safe Work Procedures (SWP). Analyze this image and evaluate it against the specific Non-Compliance (NC) list below, as well as general safety hazards.

HOSPITAL SWP CONSTRAINTS TO ENFORCE:
1. LADDERS & HEIGHT: Check for damaged parts, unlocked spreaders, standing on the top rung, carrying items (lack of 3-point contact) and unstable placement. 
2. BUDDY SYSTEM & PERSONNEL: Check for lack of a buddy system on ladders, missing attendants/watchmen for confined spaces or lifters, and unauthorized entry into cordoned zones.
3. PPE (Personal Protective Equipment): Look for missing safety helmets, safety shoes and gloves. 
4. AREA & SURFACE HAZARDS: Check for uncordoned work/refilling areas, slippery or wet surfaces, obstructed transport routes/exits, debris on platforms, and lack of ventilation.

OUTPUT FORMAT:
Evaluate the following four categories. For each, assign a Label from this exact list: [DANGEROUS, PARTIALLY COMPLIANT, COMPLIANT, SAFE, N/A]. Then assign an overall compliance status based on the most severe category detected. For example, if any category is "DANGEROUS", the overall status is "DANGEROUS". If all categories are "COMPLIANT" or "SAFE", the overall status is "COMPLIANT". If a category cannot be evaluated due to lack of information, label it as "N/A" and do not let it affect the overall compliance status.
* Note: "COMPLIANT" means inherent risks exist (e.g., working at heights) but proper safety measures are taken. "N/A" means the category is not present in the image.

If a critical feature is cut out of frame or covered, state that it "cannot be confirmed" and default to PARTIALLY COMPLIANT or N/A. Do not invent details.

Return EXACTLY this format and nothing else:

DETECTION: [Overall Compliance Status: DANGEROUS, PARTIALLY COMPLIANT, COMPLIANT, SAFE, N/A]

ANALYSIS:
- [Ladder/Height] Compliance: [Insert Label]
  Description: [Detail what is observed. e.g., "Worker is standing on the top rung."]
  Reasoning: [Explain why the observed condition led to the assigned label. e.g., "Standing on the top rung is a violation of safe ladder use because it eliminates stability and increases fall risk."]
  Advice: [Provide specific corrective action, e.g., "Step down to the second rung."]

- [PPE] Compliance: [Insert Label]
  Description: [Detail what is observed. e.g., "One worker has a helmet, the other cannot be confirmed."]
  Reasoning: [Explain why the observed condition led to the assigned label. e.g., "Missing safety helmet is a violation of PPE requirements."]
  Advice: [Provide specific corrective action.]

- [Buddy System] Compliance: [Insert Label]
  Description: [Detail what is observed. e.g., "Two people are detected."]
  Reasoning: [Explain why the observed condition led to the assigned label. e.g., "Lack of a buddy system is a violation of safety protocols."]
  Advice: [Provide specific corrective action.]

- [Area/Surface Hazards] Compliance: [Insert Label]
  Description: [Detail what is observed. e.g., "Debris is scattered around the base."]
  Reasoning: [Explain why the observed condition led to the assigned label. e.g., "Scattered debris creates a tripping hazard."]
  Advice: [Provide specific corrective action.]
`;

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