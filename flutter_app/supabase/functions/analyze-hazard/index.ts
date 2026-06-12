// index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Added errorType, keySlot, and modelUsed to every diagnostic response.
  // Flutter reads errorType to distinguish real results from failures without
  // string-matching the description text.
  const buildDiagnosticJson = (
    title: string,
    details: string,
    errorType: string = "DIAGNOSTIC",
    keySlot: number = -1,
    modelUsed: string = "none",
  ) => {
    return JSON.stringify({
      errorType,
      keySlot,
      modelUsed,
      systemNotice: null,
      overallStatus: "N/A",
      ladderHeight: {
        compliance: "N/A",
        description: `Diagnostic: ${title}`,
        reasoning: details,
        advice: "Check this payload to see what was returned.",
      },
      ppe: {
        compliance: "N/A",
        description: "N/A",
        reasoning: "N/A",
        advice: "N/A",
      },
      buddySystem: {
        compliance: "N/A",
        description: "N/A",
        reasoning: "N/A",
        advice: "N/A",
      },
      areaHazards: {
        compliance: "N/A",
        description: "N/A",
        reasoning: "N/A",
        advice: "N/A",
      },
    });
  };

  try {
    const { imagesBase64, userContext } = await req.json();
    const keysString = Deno.env.get("GEMINI_API_KEY") || "";
    const apiKeys = keysString.split(",").map((k: string) => k.trim()).filter((
      k: string,
    ) => k.length > 0);

    const modelArray = [
      "gemini-3.5-flash",
      "gemini-3-flash-preview",
      "gemini-3.1-flash-lite",
      "gemini-2.5-flash",
    ];

    // SETUP_ERROR now includes errorType so Flutter can show the right dialog.
    if (apiKeys.length === 0) {
      return new Response(
        buildDiagnosticJson(
          "Setup Error",
          "No API keys configured in Supabase environment variables.",
          "SETUP_ERROR",
        ),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const imageParts = (imagesBase64 || []).map((base64Str: string) => {
      const cleanBase64 = base64Str.replace(/^data:image\/[a-z]+;base64,/, "");
      return {
        inlineData: {
          data: cleanBase64,
          mimeType: "image/jpeg",
        },
      };
    });

    const prompt =
      `You are an expert industrial safety inspector enforcing a hospital's strict Safe Work Procedures (SWP). 
Analyze these workspace images collectively (which may present different perspective angles or close-ups of the same environment) and evaluate them against the specific Non-Compliance (NC) list below, as well as general safety hazards.
 
ADDITIONAL SITE CONTEXT PROVIDED BY THE TECHNICIAN ON-SITE:
"${userContext || "No additional context provided."}"
 
HOSPITAL SWP CONSTRAINTS TO ENFORCE:
1. LADDERS & HEIGHT: You must check for locked spreader bars (the hinged bar), standing on the top rung, carrying items (lack of 3-point contact) and unstable placement. You MUST CHECK if the ladder's spreader bars are locked, if unable to confirm, mark as "N/A" or "PARTIALLY COMPLIANT".
2. BUDDY SYSTEM & PERSONNEL: Check for lack of a buddy system on ladders, missing attendants/watchmen for confined spaces or lifters, and unauthorized entry into cordoned zones. It is assumed that one of the buddy system participants is the photographer, so if you see one person on a ladder but cannot confirm if a buddy is present, you can infer potential non-compliance and mark as "PARTIALLY COMPLIANT" only with reasoning.
3. PPE (Personal Protective Equipment): Look for missing safety helmets, safety shoes and gloves. Boots must be rubber if the surface is wet. 
4. AREA & SURFACE HAZARDS: Check for uncordoned work/refilling areas, slippery or wet surfaces, obstructed transport routes/exits, debris on platforms, confined spaces such as vents and lack of ventilation. Confined spaces are to be marked as either "PARTIALLY COMPLIANT" or "SAFE". You may include here any other general hazards you see as well. This category is a catch-all for any safety issues not covered by the first three categories.
 
OUTPUT INSTRUCTIONS:
- Evaluate the 4 target safety categories and map your assessment data into the requested JSON schema fields (compliance, description, reasoning, and advice).
- For compliance fields, choose exactly one value from this list: [DANGEROUS, PARTIALLY COMPLIANT, COMPLIANT, SAFE, N/A].
- If the images are too ambiguous to make a clear judgment on a category, mark it as "N/A" or "PARTIALLY COMPLIANT" and explain in the reasoning field what information is missing or unclear. Do not invent details that are not visible across the images, but you can make logical inferences based on what is visible (e.g., if you see a ladder but cannot confirm if the spreader bars are locked, you can infer potential risk and mark as "PARTIALLY COMPLIANT" with reasoning).
`;

    for (let keyIdx = 0; keyIdx < apiKeys.length; keyIdx++) {
      const activeKey = apiKeys[keyIdx];

      for (const currentModelName of modelArray) {
        try {
          console.log(
            `[AI-MONITORING] [ATTEMPT] Key Slot: ${keyIdx} | Model Target: ${currentModelName} | Images: ${imageParts.length}`,
          );

          const genAI = new GoogleGenerativeAI(activeKey);
          const model = genAI.getGenerativeModel({
            model: currentModelName,
            safetySettings: [
              {
                category: "HARM_CATEGORY_DANGEROUS_CONTENT",
                threshold: "BLOCK_NONE",
              },
              { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
              {
                category: "HARM_CATEGORY_HATE_SPEECH",
                threshold: "BLOCK_NONE",
              },
              {
                category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                threshold: "BLOCK_NONE",
              },
            ],
            generationConfig: {
              responseMimeType: "application/json",
              responseSchema: {
                type: "OBJECT",
                properties: {
                  overallStatus: {
                    type: "STRING",
                    enum: [
                      "DANGEROUS",
                      "PARTIALLY COMPLIANT",
                      "COMPLIANT",
                      "SAFE",
                      "N/A",
                    ],
                  },
                  ladderHeight: {
                    type: "OBJECT",
                    properties: {
                      compliance: {
                        type: "STRING",
                        enum: [
                          "DANGEROUS",
                          "PARTIALLY COMPLIANT",
                          "COMPLIANT",
                          "SAFE",
                          "N/A",
                        ],
                      },
                      description: { type: "STRING" },
                      reasoning: { type: "STRING" },
                      advice: { type: "STRING" },
                    },
                    required: [
                      "compliance",
                      "description",
                      "reasoning",
                      "advice",
                    ],
                  },
                  ppe: {
                    type: "OBJECT",
                    properties: {
                      compliance: {
                        type: "STRING",
                        enum: [
                          "DANGEROUS",
                          "PARTIALLY COMPLIANT",
                          "COMPLIANT",
                          "SAFE",
                          "N/A",
                        ],
                      },
                      description: { type: "STRING" },
                      reasoning: { type: "STRING" },
                      advice: { type: "STRING" },
                    },
                    required: [
                      "compliance",
                      "description",
                      "reasoning",
                      "advice",
                    ],
                  },
                  buddySystem: {
                    type: "OBJECT",
                    properties: {
                      compliance: {
                        type: "STRING",
                        enum: [
                          "DANGEROUS",
                          "PARTIALLY COMPLIANT",
                          "COMPLIANT",
                          "SAFE",
                          "N/A",
                        ],
                      },
                      description: { type: "STRING" },
                      reasoning: { type: "STRING" },
                      advice: { type: "STRING" },
                    },
                    required: [
                      "compliance",
                      "description",
                      "reasoning",
                      "advice",
                    ],
                  },
                  areaHazards: {
                    type: "OBJECT",
                    properties: {
                      compliance: {
                        type: "STRING",
                        enum: [
                          "DANGEROUS",
                          "PARTIALLY COMPLIANT",
                          "COMPLIANT",
                          "SAFE",
                          "N/A",
                        ],
                      },
                      description: { type: "STRING" },
                      reasoning: { type: "STRING" },
                      advice: { type: "STRING" },
                    },
                    required: [
                      "compliance",
                      "description",
                      "reasoning",
                      "advice",
                    ],
                  },
                },
                required: [
                  "overallStatus",
                  "ladderHeight",
                  "ppe",
                  "buddySystem",
                  "areaHazards",
                ],
              },
            },
          } as any);

          const result = await model.generateContent([prompt, ...imageParts]);

          if (
            !result.response || !result.response.candidates ||
            result.response.candidates.length === 0
          ) {
            console.warn(
              `[AI-MONITORING] [WARN] Empty candidates from ${currentModelName} Key Slot ${keyIdx}`,
            );
            continue;
          }

          let textResponse = result.response.text();
          if (!textResponse || textResponse.trim() === "") {
            console.warn(
              `[AI-MONITORING] [WARN] Blank text from ${currentModelName} Key Slot ${keyIdx}`,
            );
            continue;
          }

          textResponse = textResponse.replace(/```json/g, "").replace(
            /```/g,
            "",
          ).trim();

          // Every success response now includes errorType: null, keySlot, and
          // modelUsed. Flutter reads these to log routing and show the backup
          // model snackbar. systemNotice is non-null only when a fallback model
          // was used.
          let responsePayloadObject = JSON.parse(textResponse);

          responsePayloadObject.errorType = null;
          responsePayloadObject.keySlot = keyIdx;
          responsePayloadObject.modelUsed = currentModelName;

          const isPrimaryModel = currentModelName === modelArray[0];
          responsePayloadObject.systemNotice = isPrimaryModel
            ? null
            : `Primary model unavailable. Analysis routed to backup model (${currentModelName}) on key slot ${keyIdx}.`;

          console.log(
            `[AI-MONITORING] [SUCCESS] Key Slot: ${keyIdx} | Model: ${currentModelName}`,
          );

          return new Response(JSON.stringify(responsePayloadObject), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200,
          });
        } catch (err: any) {
          const rawErrorMessage = err.message || "";
          console.error(
            `[AI-MONITORING] [FAILURE-TRACE] Key Slot: ${keyIdx} | Model: ${currentModelName} | Message: ${rawErrorMessage}`,
          );

          if (
            rawErrorMessage.includes("429") ||
            rawErrorMessage.toLowerCase().includes("quota") ||
            rawErrorMessage.toLowerCase().includes("rate limit")
          ) {
            console.warn(
              `[AI-MONITORING] [ROTATION] 429 on Key Slot ${keyIdx}. Advancing to next key...`,
            );
            break;
          }

          if (
            rawErrorMessage.includes("503") ||
            rawErrorMessage.toLowerCase().includes("overloaded") ||
            rawErrorMessage.toLowerCase().includes("service unavailable")
          ) {
            console.warn(
              `[AI-MONITORING] [ROTATION] 503 on ${currentModelName}. Trying next model on Key Slot ${keyIdx}...`,
            );
            continue;
          }

          // SDK_ERROR now passes keyIdx and currentModelName so you can see
          // exactly where it crashed in the Flutter error dialog.
          return new Response(
            buildDiagnosticJson(
              "SDK Execution Error",
              rawErrorMessage,
              "SDK_ERROR",
              keyIdx,
              currentModelName,
            ),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
              status: 200,
            },
          );
        }
      }
    }

    // EXHAUSTION_ERROR is now a named errorType Flutter checks for specifically
    // to show the quota warning dialog.
    console.error(
      `[AI-MONITORING] [CRITICAL-FATAL] Full key and model exhaustion.`,
    );
    return new Response(
      buildDiagnosticJson(
        "Exhaustion Error",
        "All available keys and fallback models returned cloud platform infrastructure faults.",
        "EXHAUSTION_ERROR",
      ),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error: any) {
    console.error(
      `[AI-MONITORING] [CRASH] Edge Function Core Exception: ${error.message}`,
    );
    return new Response(
      buildDiagnosticJson(
        "Global Runtime Crash",
        error.message || "Request parsing failed.",
        "GLOBAL_CRASH",
      ),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  }
});
