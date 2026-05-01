// Setup type definitions for built-in Supabase Runtime APIs
import { serve } from "https://deno.land/std@0.123.0/http/server.ts";
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenAI } from 'npm:@google/genai';
import { createClient } from 'jsr:@supabase/supabase-js@2'

// CORS Hlavičky - Absolutní nutnost pro komunikaci s Flutterem
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

console.info('Edge Function "scan-receipt" started.');

Deno.serve(async (req: Request) => {
    // 1. Zpracování CORS Preflight requestu z Flutteru
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {

         const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? '',
            { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
        )

        const authHeader = req.headers.get('Authorization')!
        const token = authHeader.replace('Bearer ', '')
        const { data } = await supabaseClient.auth.getUser(token)


        //Request z flutteru
        const { imageBase64, imageType, mimeType } = await req.json();

        const apiKey = Deno.env.get("GEMINI_API_KEY");
        if (!apiKey) {
            throw new Error("Missing GEMINI_API_KEY environment variable.");
        }
        const ai = new GoogleGenAI({ apiKey: apiKey });

        let finalPrompt = "";

        // 4. Rozhodovací logika podle typu obrázku
        switch (imageType) {
            case "groceries":
            case "receipt":
                finalPrompt = `Jsi expertní AI systém pro vytěžování dat z českých nákupních účtenek. 
Tvým úkolem je analyzovat fotografii účtenky a extrahovat z ní data.

PRAVIDLA EXTRAKCE:
1. ABSOLUTNÍ PRIORITA: Extrahuj PŘÍSNĚ POUZE základní suroviny a ingredience určené k vaření (maso, zelenina, mléčné výrobky atd.).
2. CO NESMÍŠ EXTRAHOVAT: Ignoruj hotová jídla (bagety), nápoje (pivo, voda), pochutiny (brambůrky, žvýkačky), nepotravinářské zboží (tašky) a ceny/DPH.
3. Očištění názvů: Zkrácené názvy (např. "ML.POLOTUC. 1L") převeď na čistý, spisovný název v základním tvaru ("Mléko polotučné"). Odstraň značky.
4. Množství a jednotky: Vytáhni množství (např. 0.5) a jednotku (kg, ks, g, ml). Pokud chybí, odhadni výchozí hodnotu (např. 1) a logickou jednotku (ks).

POŽADOVANÝ VÝSTUP (STRIKTNÍ JSON):
{
  "items": [
    {
      "raw_name": "přesný text z účtenky",
      "clean_name": "znormalizovaný název suroviny",
      "quantity": 1.0,
      "unit": "ks/g/kg/ml/l"
    }
  ]
}`;
                break;
            default:
                throw new Error(`Nepodporovaný imageType: ${imageType}`);
        }

        // 5. Odeslání do Gemini 2.5 Flash
        const geminiJsonResponse = await ai.models.generateContent({
            model: "gemini-2.5-flash",
            contents: [
                finalPrompt,
                {
                    inlineData: {
                        data: imageBase64,
                        mimeType: mimeType,
                    }
                }
            ],
            config: {
                // Toto donutí model vrátit perfektní JSON bez Markdown obalu
                responseMimeType: "application/json",
            }
        });

        console.log(geminiJsonResponse)

        const extracted = JSON.parse(geminiJsonResponse) as {
            ingredients: { clean_name: string }[]
        }

        const returnJson = [];

        for (const ingredient of extracted.ingredients) {
            const q = ingredient.clean_name

            const { data, error } = await supabaseClient
                .from('ingredients')
                .select('id, name, category, default_unit, search_aliases, emoji, is_staple, measurement_type, est_value, est_unit, est_price')
                .textSearch('fts', q)

            returnJson.push(data);

        }

        // 6. Vrácení odpovědi zpět do aplikace
        return new Response(
            JSON.stringify({ ingredients: returnJson }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
        );



    } catch (error) {
        console.error("Error processing request:", error);
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 500,
        });
    }
});