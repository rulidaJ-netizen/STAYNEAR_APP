import { createClient } from "npm:@supabase/supabase-js@2";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@6";

const firebaseProjectId = "staynear-58ae7";
const bucketName = "staynear-images";
const allowedFolders = new Set(["profiles", "listings"]);
const allowedMimeTypes = new Set(["image/jpeg", "image/png", "image/webp"]);
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const firebaseKeys = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {...corsHeaders, "Content-Type": "application/json"},
  });
}

async function firebaseUid(request: Request): Promise<string> {
  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) throw new Error("Missing token");
  const token = authorization.slice("Bearer ".length).trim();
  const { payload } = await jwtVerify(token, firebaseKeys, {
    issuer: `https://securetoken.google.com/${firebaseProjectId}`,
    audience: firebaseProjectId,
  });
  if (typeof payload.sub !== "string" || payload.sub.length === 0) {
    throw new Error("Missing Firebase user ID");
  }
  return payload.sub;
}

function authorizedPath(path: unknown, uid: string): string | null {
  if (typeof path !== "string" || path.startsWith("/") || path.includes("..")) {
    return null;
  }
  const parts = path.split("/");
  if (parts.length !== 3 || !allowedFolders.has(parts[0]) || parts[1] !== uid) {
    return null;
  }
  if (!/^[0-9]+_image\.(jpg|jpeg|png|webp)$/.test(parts[2])) return null;
  return path;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", {headers: corsHeaders});
  if (request.method !== "POST") return json({error: "Method not allowed"}, 405);

  let uid: string;
  try {
    uid = await firebaseUid(request);
  } catch (_) {
    return json({error: "Invalid or expired Firebase token"}, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch (_) {
    return json({error: "Invalid JSON body"}, 400);
  }

  const path = authorizedPath(body.path, uid);
  if (path === null) return json({error: "Invalid storage path"}, 403);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({error: "Storage service is not configured"}, 500);
  }
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {persistSession: false, autoRefreshToken: false},
  });

  if (body.action === "create-upload") {
    if (typeof body.mimeType !== "string" || !allowedMimeTypes.has(body.mimeType)) {
      return json({error: "Unsupported image type"}, 400);
    }
    const {data, error} = await admin.storage
      .from(bucketName)
      .createSignedUploadUrl(path, {upsert: false});
    if (error || !data?.token) {
      console.error("Could not create signed upload URL", error);
      return json({error: "Could not authorize upload"}, 500);
    }
    return json({path: data.path, token: data.token});
  }

  if (body.action === "delete") {
    const {error} = await admin.storage.from(bucketName).remove([path]);
    if (error) {
      console.error("Could not delete storage object", error);
      return json({error: "Could not delete image"}, 500);
    }
    return json({deleted: true});
  }

  return json({error: "Unsupported action"}, 400);
});
