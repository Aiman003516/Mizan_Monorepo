import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const ACTIONS = new Set([
  "invoice_draft",
  "bill_draft",
  "customer_draft",
  "vendor_draft",
  "journal_entry_draft",
  "staff_invitation_batch_draft",
]);

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function stringValue(value: unknown, maxLength: number): string | undefined {
  if (typeof value !== "string") return undefined;
  const result = value.trim();
  return result && result.length <= maxLength ? result : undefined;
}

function uuid(value: unknown): string | undefined {
  const result = stringValue(value, 64);
  return result && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(result) ? result : undefined;
}

function date(value: unknown): string | undefined {
  const result = stringValue(value, 10);
  return result && /^\d{4}-\d{2}-\d{2}$/.test(result) ? result : undefined;
}

function integer(value: unknown, min: number, max: number): number | undefined {
  const result = typeof value === "number" ? value : typeof value === "string" && value.trim() ? Number(value) : NaN;
  return Number.isSafeInteger(result) && result >= min && result <= max ? result : undefined;
}

function numberValue(value: unknown, min: number, max: number): number | undefined {
  const result = typeof value === "number" ? value : typeof value === "string" && value.trim() ? Number(value) : NaN;
  return Number.isFinite(result) && result >= min && result <= max ? result : undefined;
}

function email(value: unknown): string | undefined {
  const result = stringValue(value, 320)?.toLowerCase();
  return result && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(result) ? result : undefined;
}

async function permission(client: SupabaseClient, tenantId: string, values: string[]) {
  const { data, error } = await client.rpc("has_tenant_permission", {
    p_tenant_id: tenantId,
    p_permissions: values,
  });
  if (error || data !== true) throw new Error("Permission denied");
}

async function tenantForUser(client: SupabaseClient, user: User, requestedTenantId?: string) {
  const { data, error } = await client.from("staff_members").select("tenant_id").eq("user_id", user.id).eq("status", "active").order("created_at").limit(20);
  if (error) throw new Error("Tenant membership unavailable");
  const ids = (data || []).map((row) => row.tenant_id as string).filter(Boolean);
  if (requestedTenantId && ids.includes(requestedTenantId)) return requestedTenantId;
  if (ids.length === 1) return ids[0];
  throw new Error(ids.length > 1 ? "Tenant selection is required" : "Active tenant membership required");
}

async function normalizePayload(
  actionType: string,
  rawPayload: unknown,
  client: SupabaseClient,
  tenantId: string,
) {
  if (!ACTIONS.has(actionType) || !rawPayload || typeof rawPayload !== "object" || Array.isArray(rawPayload)) throw new Error("Unsupported action draft");
  const input = rawPayload as Record<string, unknown>;
  if (actionType === "invoice_draft" || actionType === "bill_draft") {
    await permission(
      client,
      tenantId,
      actionType === "invoice_draft"
        ? ["manageCrm", "createInvoices", "manageInvoices", "manageSettings"]
        : ["manageCrm", "createBills", "manageBills", "manageSettings"],
    );
    const partyId = uuid(input[actionType === "invoice_draft" ? "customer_id" : "vendor_id"]);
    const start = date(input.invoice_date ?? input.bill_date);
    const due = date(input.due_date);
    const currency = stringValue(input.currency_code, 5)?.toUpperCase();
    const items = Array.isArray(input.items) ? input.items : [];
    if (!partyId || !start || !due || !currency || !/^[A-Z]{3,5}$/.test(currency) || due < start || items.length === 0 || items.length > 100) throw new Error("Document draft data is invalid");
    const table = actionType === "invoice_draft" ? "customers" : "vendors";
    const { data: party } = await client.from(table).select("id").eq("id", partyId).eq("tenant_id", tenantId).eq("is_deleted", false).maybeSingle();
    if (!party) throw new Error("Referenced party does not belong to the current tenant");
    const normalizedItems = items.map((item) => {
      if (!item || typeof item !== "object" || Array.isArray(item)) throw new Error("Document item data is invalid");
      const row = item as Record<string, unknown>;
      const description = stringValue(row.description, 500);
      const quantity = numberValue(row.quantity, 0.000001, 1_000_000_000);
      const unitPrice = integer(row.unit_price, 0, 9_000_000_000_000_000);
      if (!description || quantity === undefined || unitPrice === undefined) throw new Error("Document item data is invalid");
      return { description, quantity, unit_price: unitPrice };
    });
    return actionType === "invoice_draft"
      ? { customer_id: partyId, invoice_date: start, due_date: due, currency_code: currency, notes: stringValue(input.notes, 2000) || null, items: normalizedItems }
      : { vendor_id: partyId, bill_date: start, due_date: due, currency_code: currency, vendor_bill_number: stringValue(input.vendor_bill_number, 120) || null, notes: stringValue(input.notes, 2000) || null, items: normalizedItems };
  }
  if (actionType === "customer_draft" || actionType === "vendor_draft") {
    await permission(
      client,
      tenantId,
      actionType === "customer_draft"
        ? ["manageCrm", "manageCustomers", "manageSettings"]
        : ["manageCrm", "manageVendors", "manageSettings"],
    );
    const name = stringValue(input.name, 200);
    if (!name) throw new Error("Party name is required");
    const normalizedEmail = input.email == null || input.email === "" ? null : email(input.email);
    if (input.email && !normalizedEmail) throw new Error("Email is invalid");
    return { name, email: normalizedEmail, phone: stringValue(input.phone, 80) || null, address: stringValue(input.address, 500) || null, tax_id: stringValue(input.tax_id, 120) || null, notes: stringValue(input.notes, 2000) || null };
  }
  if (actionType === "staff_invitation_batch_draft") {
    await permission(client, tenantId, ["manageStaff", "manageSettings"]);
    const roleId = uuid(input.role_id);
    const recipients = Array.isArray(input.recipient_emails) ? input.recipient_emails.map(email).filter((value): value is string => !!value) : [];
    const uniqueRecipients = [...new Set(recipients)];
    if (!roleId || uniqueRecipients.length === 0 || uniqueRecipients.length > 100 || uniqueRecipients.length !== recipients.length) throw new Error("Invitation batch data is invalid");
    const { data: role } = await client.from("roles").select("id,name,is_system_admin").eq("id", roleId).eq("tenant_id", tenantId).maybeSingle();
    if (!role || role.is_system_admin) throw new Error("Role does not belong to the current tenant");
    return { role_id: roleId, role_name: role.name, recipient_emails: uniqueRecipients };
  }
  if (actionType === "journal_entry_draft") {
    await permission(client, tenantId, ["manageSettings"]);
    throw new Error("Journal-entry drafts are not enabled in this release");
  }
  throw new Error("Unsupported action draft");
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return response({ error: "Method not allowed" }, 405);
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) return response({ error: "AI action service is not configured" }, 503);
  const token = request.headers.get("Authorization")?.replace(/^Bearer\s+/i, "").trim();
  if (!token) return response({ error: "Authentication required" }, 401);
  const userClient = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: `Bearer ${token}` } } });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);
  const { data: auth, error: authError } = await userClient.auth.getUser(token);
  if (authError || !auth.user) return response({ error: "Authentication required" }, 401);
  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return response({ error: "Invalid request body" }, 400);
  }
  let tenantId: string;
  try {
    tenantId = await tenantForUser(userClient, auth.user, uuid(body.tenant_id));
  } catch (error) {
    const message = error instanceof Error ? error.message : "Tenant access unavailable";
    return response({ error: message === "Tenant selection is required" ? message : "Active tenant membership required" }, 403);
  }
  const action = stringValue(body.action, 32) || "create_draft";
  const idempotencyKey = uuid(body.idempotency_key) || crypto.randomUUID();
  if (action === "cancel") {
    const requestId = uuid(body.action_request_id);
    if (!requestId) return response({ error: "Action request id is required" }, 400);
    const { data, error } = await adminClient.from("ai_action_requests").update({ status: "cancelled" }).eq("id", requestId).eq("tenant_id", tenantId).eq("user_id", auth.user.id).eq("status", "pending").gt("expires_at", new Date().toISOString()).select("id,action_type,payload,preview,status,expires_at,created_at,confirmation_token,confirmed_at,executed_at,execution_result,execution_error").maybeSingle();
    if (error || !data) return response({ error: "Action request could not be cancelled" }, 404);
    return response({ action_request: data });
  }
  if (action === "confirm") {
    const requestId = uuid(body.action_request_id);
    const confirmationToken = uuid(body.confirmation_token);
    if (!requestId || !confirmationToken) return response({ error: "Confirmation is required" }, 400);

    const { data: execution, error: executionError } = await userClient.rpc("execute_ai_action", {
      p_action_request_id: requestId,
      p_confirmation_token: confirmationToken,
    });
    if (executionError) {
      const message = executionError.message || "Action execution failed";
      const status = /expired|no longer pending|invalid|unavailable/i.test(message) ? 409 : 422;
      return response({ error: "Action execution could not be completed" }, status);
    }

    const { data: request, error: requestError } = await adminClient
      .from("ai_action_requests")
      .select("id,action_type,payload,preview,status,expires_at,created_at,confirmation_token,confirmed_at,executed_at,execution_result,execution_error")
      .eq("id", requestId)
      .eq("tenant_id", tenantId)
      .eq("user_id", auth.user.id)
      .maybeSingle();
    if (requestError || !request) return response({ error: "Action execution result is unavailable" }, 500);
    return response({ action_request: request, execution });
  }
  if (action !== "create_draft") return response({ error: "Unsupported action" }, 400);
  const actionType = stringValue(body.action_type, 64);
  if (!actionType || !ACTIONS.has(actionType)) return response({ error: "Unsupported action draft" }, 400);
  try {
    const payload = await normalizePayload(actionType, body.payload, userClient, tenantId);
    const existing = await adminClient.from("ai_action_requests").select("id,action_type,payload,preview,status,expires_at,created_at,confirmation_token,confirmed_at,executed_at,execution_result,execution_error").eq("tenant_id", tenantId).eq("user_id", auth.user.id).eq("idempotency_key", idempotencyKey).maybeSingle();
    if (existing.data) return response({ action_request: existing.data });
    const conversationId = uuid(body.conversation_id);
    const insert = await adminClient.from("ai_action_requests").insert({ tenant_id: tenantId, user_id: auth.user.id, conversation_id: conversationId, action_type: actionType, payload, preview: { action_type: actionType, payload }, idempotency_key: idempotencyKey }).select("id,action_type,payload,preview,status,expires_at,created_at,confirmation_token,confirmed_at,executed_at,execution_result,execution_error").single();
    if (insert.error || !insert.data) return response({ error: "Action draft could not be saved" }, 500);
    await adminClient.from("ai_audit_events").insert({ request_id: idempotencyKey, tenant_id: tenantId, user_id: auth.user.id, conversation_id: conversationId, event_type: "tool_call", tool_name: "create_action_draft", success: true, metadata: { action_type: actionType } });
    return response({ action_request: insert.data });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Action draft is invalid";
    return response({ error: message === "Permission denied" ? "Permission denied" : "Action draft is invalid" }, 422);
  }
});
