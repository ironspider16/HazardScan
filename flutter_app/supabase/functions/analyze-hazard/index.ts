// index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "npm:@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const buildDiagnosticJson = (title: string, details: string) => {
    return JSON.stringify({
      overallStatus: "N/A",
      ladderHeight: { 
        compliance: "N/A", 
        description: `Diagnostic: ${title}`, 
        reasoning: details, 
        advice: "Check this text payload to see exactly what Google returned to your edge function." 
      },
      ppe: { compliance: "N/A", description: "N/A", reasoning: "N/A", advice: "N/A" },
      buddySystem: { compliance: "N/A", description: "N/A", reasoning: "N/A", advice: "N/A" },
      areaHazards: { compliance: "N/A", description: "N/A", reasoning: "N/A", advice: "N/A" }
    });
  };

  try {
    const { imageBase64 } = await req.json()
    const keysString = Deno.env.get('GEMINI_API_KEY') || ""
    const apiKeys = keysString.split(',').map(k => k.trim())

    if (apiKeys.length === 0) {
      return new Response(buildDiagnosticJson("Setup Error", "No API keys configured in Supabase environment variables."), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const cleanBase64 = imageBase64.replace(/^data:image\/[a-z]+;base64,/, "");

    const prompt = `You are an expert industrial safety inspector enforcing a hospital's strict Safe Work Procedures (SWP). 
Analyze this image and evaluate it against the specific Non-Compliance (NC) list below, as well as general safety hazards.

HOSPITAL SWP CONSTRAINTS TO ENFORCE:
1. LADDERS & HEIGHT: You must check for locked spreader bars (the hinged bar), standing on the top rung, carrying items (lack of 3-point contact) and unstable placement. You MUST CHECK if the ladder's spreader bars are locked, if unable to confirm, mark as "N/A" or "PARTIALLY COMPLIANT".
2. BUDDY SYSTEM & PERSONNEL: Check for lack of a buddy system on ladders, missing attendants/watchmen for confined spaces or lifters, and unauthorized entry into cordoned zones.
3. PPE (Personal Protective Equipment): Look for missing safety helmets, safety shoes and gloves. Boots must be rubber if the surface is wet. 
4. AREA & SURFACE HAZARDS: Check for uncordoned work/refilling areas, slippery or wet surfaces, obstructed transport routes/exits, debris on platforms, confined spaces such as vents and lack of ventilation. Confined spaces are to be marked as either "PARTIALLY COMPLIANT" or "SAFE". You may include here any other general hazards you see as well. This category is a catch-all for any safety issues not covered by the first three categories.

OUTPUT INSTRUCTIONS:
- Evaluate the 4 target safety categories and map your assessment data into the requested JSON schema fields (compliance, description, reasoning, and advice).
- For compliance fields, choose exactly one value from this list: [DANGEROUS, PARTIALLY COMPLIANT, COMPLIANT, SAFE, N/A].
- If the image is too ambiguous to make a clear judgment on a category, mark it as "N/A" or "PARTIALLY COMPLIANT" and explain in the reasoning field what information is missing or unclear. Do not invent details that are not visible in the image, but you can make logical inferences based on what is visible (e.g., if you see a ladder but cannot confirm if the spreader bars are locked, you can infer potential risk and mark as "PARTIALLY COMPLIANT" with reasoning).
`;

    for (const key of apiKeys) {
      try {
        const genAI = new GoogleGenerativeAI(key)
        
        const model = genAI.getGenerativeModel({ 
          model: "gemini-3.5-flash", 
          safetySettings: [ //Note: These safety settings are set to BLOCK_NONE to allow the model to provide feedback on all categories, even if it identifies harmful content. Adjust as needed based on application requirements.
            { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" },
            { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
            { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
            { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" }
          ],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: {
              type: "OBJECT",
              properties: {
                overallStatus: { type: "STRING" },
                ladderHeight: { 
                  type: "OBJECT", 
                  properties: { compliance: { type: "STRING" }, description: { type: "STRING" }, reasoning: { type: "STRING" }, advice: { type: "STRING" } },
                  required: ["compliance", "description", "reasoning", "advice"]
                },
                ppe: { 
                  type: "OBJECT", 
                  properties: { compliance: { type: "STRING" }, description: { type: "STRING" }, reasoning: { type: "STRING" }, advice: { type: "STRING" } },
                  required: ["compliance", "description", "reasoning", "advice"]
                },
                buddySystem: { 
                  type: "OBJECT", 
                  properties: { compliance: { type: "STRING" }, description: { type: "STRING" }, reasoning: { type: "STRING" }, advice: { type: "STRING" } },
                  required: ["compliance", "description", "reasoning", "advice"]
                },
                areaHazards: { 
                  type: "OBJECT", 
                  properties: { compliance: { type: "STRING" }, description: { type: "STRING" }, reasoning: { type: "STRING" }, advice: { type: "STRING" } },
                  required: ["compliance", "description", "reasoning", "advice"]
                }
              },
              required: ["overallStatus", "ladderHeight", "ppe", "buddySystem", "areaHazards"]
            }
          }
        } as any)

        const result = await model.generateContent([
          prompt,
          { inlineData: { data: cleanBase64, mimeType: 'image/jpeg' } }
        ]);

        if (!result.response || !result.response.candidates || result.response.candidates.length === 0) {
          const rawResponseText = JSON.stringify(result);
          return new Response(buildDiagnosticJson("Empty Candidates Object", `API responded but candidates array is empty. Full response: ${rawResponseText}`), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200
          });
        }

        let textResponse = result.response.text();

        // Guard against empty text response from SDK
        if (!textResponse || textResponse.trim() === "") {
          return new Response(buildDiagnosticJson("Empty Text Response", "result.response.text() returned empty. Candidates existed but text extraction failed. SDK may not support responseMimeType on this model version."), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200
          });
        }

        textResponse = textResponse.replace(/```json/g, "").replace(/```/g, "").trim();

        console.log(`Response length: ${textResponse.length}`)
        console.log(`Response preview: ${textResponse.substring(0, 200)}`)

        return new Response(textResponse, {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        })

      } catch (err: any) {
        if (err.message?.includes('429') || err.message?.includes('quota')) {
          continue 
        }
        return new Response(buildDiagnosticJson("SDK Execution Error", err.message || "Unknown internal SDK error."), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        });
      }
    }

    return new Response(buildDiagnosticJson("Exhaustion Error", "All configured API keys returned quota failures."), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    });

  } catch (error: any) {
    return new Response(buildDiagnosticJson("Global Runtime Crash", error.message || "Request parsing failed."), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  }
})