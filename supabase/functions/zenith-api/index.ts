// Zenith API: full backend on Supabase Edge Functions (free tier, no separate server).
// Set secrets in Supabase: PROJECTX_BASE_URL, FINNHUB_API_KEY, NEWSDATA_API_KEY, NVIDIA_API_KEY
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const PROJECTX_BASE = Deno.env.get("PROJECTX_BASE_URL") ?? "https://api.topstepx.com";
const FINNHUB_KEY = Deno.env.get("FINNHUB_API_KEY") ?? "";
const NEWSDATA_KEY = Deno.env.get("NEWSDATA_API_KEY") ?? "";
const NVIDIA_KEY = Deno.env.get("NVIDIA_API_KEY") ?? "";

// Fallback when Topstep API returns no contracts. Front-month CME futures (Sept 2025 = U25). Updated from ProjectX docs.
const BUILTIN_CONTRACTS: Array<{ id: string; name: string; description: string; symbolId: string; tickSize: number; tickValue: number }> = [
  { id: "CON.F.US.EP.U25", name: "ESU5", description: "E-Mini S&P 500: September 2025", symbolId: "F.US.EP", tickSize: 0.25, tickValue: 12.5 },
  { id: "CON.F.US.ENQ.U25", name: "NQU5", description: "E-mini NASDAQ-100: September 2025", symbolId: "F.US.ENQ", tickSize: 0.25, tickValue: 5 },
  { id: "CON.F.US.MES.U25", name: "MESU5", description: "Micro E-mini S&P 500: September 2025", symbolId: "F.US.MES", tickSize: 0.25, tickValue: 1.25 },
  { id: "CON.F.US.MNQ.U25", name: "MNQU5", description: "Micro E-mini Nasdaq-100: September 2025", symbolId: "F.US.MNQ", tickSize: 0.25, tickValue: 0.5 },
  { id: "CON.F.US.RTY.U25", name: "RTYU5", description: "E-mini Russell 2000: September 2025", symbolId: "F.US.RTY", tickSize: 0.1, tickValue: 5 },
  { id: "CON.F.US.M2K.U25", name: "M2KU5", description: "Micro E-mini Russell 2000: September 2025", symbolId: "F.US.M2K", tickSize: 0.1, tickValue: 0.5 },
  { id: "CON.F.US.EU6.U25", name: "6EU5", description: "Euro FX (Globex): September 2025", symbolId: "F.US.EU6", tickSize: 0.00005, tickValue: 6.25 },
  { id: "CON.F.US.JY6.U25", name: "6JU5", description: "Japanese Yen (Globex): September 2025", symbolId: "F.US.JY6", tickSize: 0.0000005, tickValue: 6.25 },
  { id: "CON.F.US.BP6.U25", name: "6BU5", description: "British Pound (Globex): September 2025", symbolId: "F.US.BP6", tickSize: 0.0001, tickValue: 6.25 },
  { id: "CON.F.US.CA6.U25", name: "6CU5", description: "Canadian Dollar (Globex): September 2025", symbolId: "F.US.CA6", tickSize: 0.00005, tickValue: 5 },
  { id: "CON.F.US.MX6.U25", name: "6MU5", description: "Mexican Peso (Globex): September 2025", symbolId: "F.US.MX6", tickSize: 0.00001, tickValue: 5 },
  { id: "CON.F.US.EEU.U25", name: "E7U5", description: "E-mini Euro FX: September 2025", symbolId: "F.US.EEU", tickSize: 0.0001, tickValue: 6.25 },
  { id: "CON.F.US.EMD.U25", name: "EMDU5", description: "E-mini MidCap 400: September 2025", symbolId: "F.US.EMD", tickSize: 0.1, tickValue: 10 },
  { id: "CON.F.US.NKD.U25", name: "NKDU5", description: "Nikkei 225 (Globex): September 2025", symbolId: "F.US.NKD", tickSize: 5, tickValue: 25 },
  { id: "CON.F.US.SR3.Z25", name: "SR3Z5", description: "3 Month SOFR: December 2025", symbolId: "F.US.SR3", tickSize: 0.005, tickValue: 12.5 },
  { id: "CON.F.US.CL.U25", name: "CLU5", description: "Crude Oil WTI: September 2025", symbolId: "F.US.CL", tickSize: 0.01, tickValue: 10 },
  { id: "CON.F.US.GC.U25", name: "GCU5", description: "Gold: September 2025", symbolId: "F.US.GC", tickSize: 0.1, tickValue: 10 },
  { id: "CON.F.US.ZN.U25", name: "ZNU5", description: "10-Year T-Note: September 2025", symbolId: "F.US.ZN", tickSize: 0.015625, tickValue: 15.625 },
  { id: "CON.F.US.ZB.U25", name: "ZBU5", description: "30-Year T-Bond: September 2025", symbolId: "F.US.ZB", tickSize: 0.03125, tickValue: 31.25 },
];

// Symbol shortcuts for quote resolution when contracts list is empty. Map common symbols to built-in contract IDs.
const SYMBOL_TO_CONTRACT: Record<string, string> = {
  ES: "CON.F.US.EP.U25", ESU5: "CON.F.US.EP.U25", NQ: "CON.F.US.ENQ.U25", NQU5: "CON.F.US.ENQ.U25",
  MES: "CON.F.US.MES.U25", MESU5: "CON.F.US.MES.U25", MNQ: "CON.F.US.MNQ.U25", MNQU5: "CON.F.US.MNQ.U25",
  RTY: "CON.F.US.RTY.U25", RTYU5: "CON.F.US.RTY.U25", M2K: "CON.F.US.M2K.U25", M2KU5: "CON.F.US.M2K.U25",
  "6E": "CON.F.US.EU6.U25", "6EU5": "CON.F.US.EU6.U25", "6J": "CON.F.US.JY6.U25", "6JU5": "CON.F.US.JY6.U25",
  "6B": "CON.F.US.BP6.U25", "6BU5": "CON.F.US.BP6.U25", "6C": "CON.F.US.CA6.U25", "6CU5": "CON.F.US.CA6.U25",
  "6M": "CON.F.US.MX6.U25", "6MU5": "CON.F.US.MX6.U25", E7: "CON.F.US.EEU.U25", E7U5: "CON.F.US.EEU.U25",
  EMD: "CON.F.US.EMD.U25", EMDU5: "CON.F.US.EMD.U25", NKD: "CON.F.US.NKD.U25", NKDU5: "CON.F.US.NKD.U25",
  SR3: "CON.F.US.SR3.Z25", SR3Z5: "CON.F.US.SR3.Z25",
  CL: "CON.F.US.CL.U25", CLU5: "CON.F.US.CL.U25", GC: "CON.F.US.GC.U25", GCU5: "CON.F.US.GC.U25",
  ZN: "CON.F.US.ZN.U25", ZNU5: "CON.F.US.ZN.U25", ZB: "CON.F.US.ZB.U25", ZBU5: "CON.F.US.ZB.U25",
};

function getContractId(symbol: string): string | null {
  const s = symbol.toUpperCase().trim();
  return SYMBOL_TO_CONTRACT[s] ?? null;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

function getAuth(req: Request): { apiKey: string | undefined; userName: string | undefined } {
  return {
    apiKey: req.headers.get("x-topstep-api-key") ?? undefined,
    userName: req.headers.get("x-topstep-username") ?? undefined,
  };
}

type ProjectXTokenResult =
  | { ok: true; token: string }
  | { ok: false; reason: string; message: string; projectXStatus?: number; projectXBody?: Record<string, unknown> };

async function projectXToken(apiKey: string, userName?: string): Promise<ProjectXTokenResult> {
  const effectiveUser = (userName ?? "").trim() || "trader";
  try {
    const loginUrl = `${PROJECTX_BASE}/api/Auth/loginKey`;
    const res = await fetch(loginUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ userName: effectiveUser, apiKey }),
    });
    const data = await res.json().catch(() => ({})) as Record<string, unknown>;
    const safeBody = data && typeof data === "object" ? { ...data, token: data.token ? "[REDACTED]" : undefined } : {};
    const pxMessage = (data?.errorMessage ?? data?.message ?? "") as string;
    const errCode = typeof data?.errorCode === "number" ? data.errorCode : null;
    // ProjectX LoginErrorCode: 0=Success, 1=UserNotFound, 2=PasswordVerificationFailed, 3=InvalidCredentials, 9=ApiSubscriptionNotFound, 10=ApiKeyAuthenticationDisabled
    const codeHint = errCode === 1 ? " Use the exact username or email you use to log in at topstep.com." : errCode === 3 ? " Key and username don’t match. Use the exact email you use at topstep.com; create a new API key in Settings → API and try again; or contact Topstep support." : errCode === 9 ? " API subscription not found—ensure TopstepX API access is enabled." : errCode === 10 ? " API key auth is disabled for this account—enable in Topstep settings." : "";
    const message = (pxMessage || "Invalid API key or username.") + codeHint;
    if (res.status === 401 || data?.success === false) {
      return { ok: false, reason: "invalid_key", message, projectXStatus: res.status, projectXBody: safeBody };
    }
    if (data?.success && data?.token) return { ok: true, token: data.token as string };
    return { ok: false, reason: "invalid_key", message, projectXStatus: res.status, projectXBody: safeBody };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    return { ok: false, reason: "server_error", message: msg || "Could not reach Topstep." };
  }
}

type ContractEntry = { id: string; name: string; description: string; symbolId: string; tickSize: number; tickValue: number };

function parseContractList(arr: unknown, filterActiveOnly = false): ContractEntry[] {
  if (!Array.isArray(arr)) return [];
  return arr
    .map((c: Record<string, unknown>) => ({
      id: String(c.id ?? ""),
      name: String(c.name ?? ""),
      description: String(c.description ?? ""),
      symbolId: String(c.symbolId ?? ""),
      tickSize: Number(c.tickSize) || 0,
      tickValue: Number(c.tickValue) || 0,
      _active: c.activeContract === true,
      _hasActiveFlag: "activeContract" in c,
    }))
    .filter((x) => x.id && x.name && (!filterActiveOnly || x._active || !x._hasActiveFlag))
    .map(({ _active: _, _hasActiveFlag: __, ...c }) => c);
}

function parseContractResponse(data: Record<string, unknown> | unknown[]): ContractEntry[] {
  const arr = Array.isArray(data) ? data : (Array.isArray((data as Record<string, unknown>).contracts) ? (data as Record<string, unknown>).contracts : Array.isArray((data as Record<string, unknown>).data) ? (data as Record<string, unknown>).data : []);
  return parseContractList(arr, true);
}

async function projectXContractSearch(token: string, searchText: string): Promise<ContractEntry[]> {
  try {
    const res = await fetch(`${PROJECTX_BASE}/api/Contract/search`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${token}`, "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ live: true, searchText: searchText.trim() }),
    });
    const data = await res.json().catch(() => ({})) as Record<string, unknown>;
    if (Array.isArray(data?.contracts)) return parseContractList(data.contracts, false);
  } catch (_) {}
  return [];
}

/** GET /market-data/available-contracts (Topstep-style); filter activeContract: true */
async function projectXContractsMarketData(token: string): Promise<ContractEntry[]> {
  try {
    const res = await fetch(`${PROJECTX_BASE}/market-data/available-contracts`, {
      method: "GET",
      headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json" },
    });
    const data = await res.json().catch(() => ({})) as Record<string, unknown>;
    const list = parseContractResponse(data);
    if (list.length > 0) return list;
    const arr = Array.isArray(data) ? parseContractList(data, true) : [];
    if (arr.length > 0) return arr;
  } catch (_) {}
  return [];
}

async function projectXContracts(token: string): Promise<ContractEntry[]> {
  let list: ContractEntry[] = [];
  try {
    list = await projectXContractsMarketData(token);
    if (list.length > 0) return list;
  } catch (_) {}
  try {
    const res = await fetch(`${PROJECTX_BASE}/api/Contract/available`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${token}`, "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ live: true }),
    });
    const data = await res.json().catch(() => ({})) as Record<string, unknown>;
    list = parseContractResponse(data);
    if (list.length === 0) list = Array.isArray(data?.contracts) ? parseContractList(data.contracts, true) : [];
    if (list.length > 0) return list;
    const fromEmpty = await projectXContractSearch(token, "");
    if (fromEmpty.length > 0) return fromEmpty;
    const fromSearch = await projectXContractSearch(token, "E");
    if (fromSearch.length > 0) return fromSearch;
    const fromSearchN = await projectXContractSearch(token, "N");
    const fromSearchM = await projectXContractSearch(token, "M");
    const byId = new Map<string, ContractEntry>();
    for (const c of [...fromSearch, ...fromSearchN, ...fromSearchM]) byId.set(c.id, c);
    return Array.from(byId.values());
  } catch (_) {}
  return [];
}

function resolveSymbolToContractId(symbol: string, contracts: Array<{ id: string; name: string; symbolId: string }>): string | null {
  const s = symbol.toUpperCase().trim();
  const match = contracts.find((c) => c.name.toUpperCase().startsWith(s) || c.symbolId.toUpperCase().includes(s.replace(/^F\.US\./, "")));
  return match?.id ?? null;
}

async function projectXBars(token: string, contractId: string, opts: { startTime: string; endTime: string; unit: number; unitNumber: number; limit: number; includePartialBar: boolean }): Promise<Array<{ t: string; o: number; h: number; l: number; c: number; v: number }>> {
  try {
    const res = await fetch(`${PROJECTX_BASE}/api/History/retrieveBars`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${token}`, "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ contractId, live: true, ...opts }),
    });
    const data = await res.json().catch(() => ({}));
    if (data?.success && Array.isArray(data.bars)) return data.bars;
  } catch (_) {}
  return [];
}

async function handleTopstepConnection(req: Request): Promise<Response> {
  const { apiKey, userName } = getAuth(req);
  const keyPresent = !!apiKey?.trim();
  const keyLen = apiKey?.trim().length ?? 0;
  const effectiveUser = (userName ?? "").trim() || "trader";
  if (!keyPresent) return jsonResponse({ connected: false, error: "missing_key", message: "API key is required.", debug: { keyReceived: false } }, 400);
  const result = await projectXToken(apiKey!.trim(), userName?.trim());
  if (!result.ok) {
    const status = result.reason === "invalid_key" ? 401 : 502;
    const body = { connected: false, error: result.reason, message: result.message, debug: { keyReceived: true, keyLength: keyLen, effectiveUser, projectXBase: PROJECTX_BASE, projectXStatus: result.projectXStatus, projectXBody: result.projectXBody } };
    return jsonResponse(body, status);
  }
  let accountCount = 0;
  try {
    const r = await fetch(`${PROJECTX_BASE}/api/Account/search`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${result.token}`, "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ onlyActiveAccounts: true }),
    });
    const d = await r.json().catch(() => ({})) as { accounts?: unknown[]; success?: boolean };
    accountCount = (d?.success && Array.isArray(d.accounts)) ? d.accounts.length : 0;
  } catch (_) {}
  return jsonResponse({ connected: true, accountCount, message: accountCount > 0 ? `Connected. ${accountCount} account(s) found.` : "Connected. No accounts in this key." });
}

async function handleTopstepAccounts(req: Request): Promise<Response> {
  const { apiKey, userName } = getAuth(req);
  if (!apiKey) return jsonResponse({ accounts: [{ id: "demo", name: "Topstep Evaluation", type: "Evaluation", currency: "USD", balance: 100000, equity: 100250, drawdownLimit: 2000 }] });
  const result = await projectXToken(apiKey, userName);
  if (!result.ok) return jsonResponse({ error: result.message }, result.reason === "invalid_key" ? 401 : 502);
  try {
    const r = await fetch(`${PROJECTX_BASE}/api/Account/search`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${result.token}`, "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ onlyActiveAccounts: true }),
    });
    const data = await r.json().catch(() => ({})) as { accounts?: Array<{ id?: number; name?: string; balance?: number; canTrade?: boolean; isVisible?: boolean }>; success?: boolean };
    if (data?.success && Array.isArray(data.accounts) && data.accounts.length > 0) {
      const accounts = data.accounts.map((a) => ({
        id: String(a.id ?? ""),
        name: a.name ?? `Account ${a.id ?? ""}`,
        type: "Evaluation",
        currency: "USD",
        balance: a.balance ?? 0,
        equity: a.balance ?? 0,
        drawdownLimit: null,
      }));
      return jsonResponse({ accounts });
    }
    return jsonResponse({ accounts: [] });
  } catch (_) {
    return jsonResponse({ error: "Failed to fetch accounts from Topstep." }, 502);
  }
}

async function handleTopstepContracts(req: Request): Promise<Response> {
  const { apiKey, userName } = getAuth(req);
  if (!apiKey) return jsonResponse({ contracts: BUILTIN_CONTRACTS });
  const result = await projectXToken(apiKey, userName);
  if (!result.ok) return jsonResponse({ contracts: BUILTIN_CONTRACTS });
  let contracts = await projectXContracts(result.token);
  if (contracts.length === 0) contracts = BUILTIN_CONTRACTS;
  return jsonResponse({ contracts });
}

async function handleTopstepQuotes(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const symbols = (url.searchParams.get("symbols") ?? "").split(",").filter(Boolean);
  const contractIds = (url.searchParams.get("contractIds") ?? "").split(",").filter(Boolean);
  if (symbols.length === 0 && contractIds.length === 0) return jsonResponse({ quotes: [] });

  const { apiKey, userName } = getAuth(req);
  if (!apiKey) return jsonResponse({ quotes: [] });
  const result = await projectXToken(apiKey, userName);
  if (!result.ok) return jsonResponse({ quotes: [] });
  const token = result.token;
  let contracts = await projectXContracts(token);
  if (contracts.length === 0) contracts = BUILTIN_CONTRACTS;
  const toFetch: Array<{ contractId: string; contract: { id: string; name: string; description: string; tickSize: number; tickValue: number } }> = [];

  if (contractIds.length > 0) {
    for (const cid of contractIds.slice(0, 20)) {
      const c = contracts.find((x) => x.id === cid);
      if (c) toFetch.push({ contractId: cid, contract: c });
    }
  } else {
    for (const sym of symbols.slice(0, 20)) {
      const s = sym.trim().toUpperCase();
      let cid = resolveSymbolToContractId(s, contracts);
      if (!cid) cid = getContractId(s);
      if (!cid) continue;
      const c = contracts.find((x) => x.id === cid);
      if (!c) {
        const builtin = BUILTIN_CONTRACTS.find((x) => x.id === cid);
        if (builtin) toFetch.push({ contractId: cid, contract: builtin });
      } else {
        toFetch.push({ contractId: cid, contract: c });
      }
    }
  }

  const now = new Date();
  const endTime = now.toISOString();
  const startTime = new Date(now.getTime() - 2 * 60 * 60 * 1000).toISOString();
  const quotes: unknown[] = [];
  for (const { contractId, contract } of toFetch) {
    const bars = await projectXBars(token, contractId, { startTime, endTime, unit: 2, unitNumber: 1, limit: 5, includePartialBar: true });
    const lastBar = bars.length > 0 ? bars[bars.length - 1] : null;
    const prevBar = bars.length >= 2 ? bars[bars.length - 2] : null;
    const c = lastBar?.c ?? 0;
    const pc = prevBar?.c ?? c;
    const net = c && pc ? c - pc : 0;
    const pct = pc ? (net / pc) * 100 : 0;
    quotes.push({
      id: contract.id,
      instrument: { id: contract.id, symbol: contract.name, name: contract.description || contract.name, assetClass: "Futures" },
      lastPrice: c,
      netChange: net,
      percentChange: pct,
      high: lastBar?.h ?? null,
      low: lastBar?.l ?? null,
    });
  }
  return jsonResponse({ quotes });
}

async function handleTopstepPositions(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const accountId = url.searchParams.get("accountId");
  if (!accountId) return jsonResponse({ error: "Missing accountId" }, 400);
  const { apiKey, userName } = getAuth(req);
  if (!apiKey) return jsonResponse({ positions: [] });
  const result = await projectXToken(apiKey, userName);
  if (!result.ok) return jsonResponse({ positions: [] });
  try {
    const r = await fetch(`${PROJECTX_BASE}/api/Position/searchOpen`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${result.token}`, "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify({ accountId: Number(accountId) }),
    });
    const data = await r.json().catch(() => ({}));
    const raw = (data?.positions ?? []) as Array<{ id?: number; accountId?: number; contractId?: string; type?: number; size?: number; averagePrice?: number; creationTimestamp?: string }>;
    let contracts = await projectXContracts(result.token);
    if (contracts.length === 0) contracts = BUILTIN_CONTRACTS;
    const byId = new Map(contracts.map((c) => [c.id, c]));
    const positions = raw.map((p) => {
      const contract = p.contractId ? byId.get(p.contractId) : null;
      return {
        id: String(p.id ?? p.contractId ?? ""),
        accountId: String(p.accountId ?? accountId),
        contractId: p.contractId ?? "",
        contractName: contract?.name ?? p.contractId ?? "",
        symbol: contract?.name ?? p.contractId ?? "",
        type: p.type ?? 0,
        size: p.size ?? 0,
        averagePrice: p.averagePrice ?? 0,
        creationTimestamp: p.creationTimestamp ?? null,
      };
    });
    return jsonResponse({ positions });
  } catch (_) {
    return jsonResponse({ positions: [] });
  }
}

async function handleTopstepOrdersGet(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const accountId = url.searchParams.get("accountId");
  if (!accountId) return jsonResponse({ error: "Missing accountId" }, 400);
  let startTimestamp = url.searchParams.get("startTimestamp");
  const endTimestamp = url.searchParams.get("endTimestamp") ?? undefined;
  if (!startTimestamp) {
    const d = new Date();
    d.setUTCHours(0, 0, 0, 0);
    startTimestamp = d.toISOString();
  }
  const { apiKey, userName } = getAuth(req);
  if (!apiKey) return jsonResponse({ orders: [] });
  const result = await projectXToken(apiKey, userName);
  if (!result.ok) return jsonResponse({ orders: [] });
  try {
    const body: { accountId: number; startTimestamp: string; endTimestamp?: string } = { accountId: Number(accountId), startTimestamp };
    if (endTimestamp) body.endTimestamp = endTimestamp;
    const r = await fetch(`${PROJECTX_BASE}/api/Order/search`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${result.token}`, "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await r.json().catch(() => ({}));
    const raw = (data?.orders ?? []) as Array<{ id?: number; accountId?: number; contractId?: string; status?: number; type?: number; side?: number; size?: number; limitPrice?: number | null; stopPrice?: number | null; fillVolume?: number; filledPrice?: number; creationTimestamp?: string; updateTimestamp?: string }>;
    let contracts = await projectXContracts(result.token);
    if (contracts.length === 0) contracts = BUILTIN_CONTRACTS;
    const byId = new Map(contracts.map((c) => [c.id, c]));
    const orders = raw.map((o) => {
      const contract = o.contractId ? byId.get(o.contractId) : null;
      return {
        id: String(o.id ?? ""),
        accountId: String(o.accountId ?? accountId),
        contractId: o.contractId ?? "",
        contractName: contract?.name ?? o.contractId ?? "",
        symbol: contract?.name ?? o.contractId ?? "",
        status: o.status ?? 0,
        type: o.type ?? 2,
        side: o.side ?? 0,
        size: o.size ?? 0,
        limitPrice: o.limitPrice ?? null,
        stopPrice: o.stopPrice ?? null,
        fillVolume: o.fillVolume ?? 0,
        filledPrice: o.filledPrice ?? null,
        creationTimestamp: o.creationTimestamp ?? null,
        updateTimestamp: o.updateTimestamp ?? null,
      };
    });
    return jsonResponse({ orders });
  } catch (_) {
    return jsonResponse({ orders: [] });
  }
}

async function handleTopstepTrades(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const accountId = url.searchParams.get("accountId");
  if (!accountId) return jsonResponse({ error: "Missing accountId" }, 400);
  let startTimestamp = url.searchParams.get("startTimestamp");
  const endTimestamp = url.searchParams.get("endTimestamp") ?? undefined;
  if (!startTimestamp) {
    const d = new Date();
    d.setDate(d.getDate() - 30);
    d.setUTCHours(0, 0, 0, 0);
    startTimestamp = d.toISOString();
  }
  const { apiKey, userName } = getAuth(req);
  if (!apiKey) return jsonResponse({ trades: [] });
  const result = await projectXToken(apiKey, userName);
  if (!result.ok) return jsonResponse({ trades: [] });
  try {
    const body: { accountId: number; startTimestamp: string; endTimestamp?: string } = { accountId: Number(accountId), startTimestamp };
    if (endTimestamp) body.endTimestamp = endTimestamp;
    const r = await fetch(`${PROJECTX_BASE}/api/Trade/search`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${result.token}`, "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await r.json().catch(() => ({}));
    const raw = (data?.trades ?? []) as Array<{ id?: number; accountId?: number; contractId?: string; orderId?: number; side?: number; size?: number; price?: number; profitLoss?: number; fees?: number; creationTimestamp?: string }>;
    let contracts = await projectXContracts(result.token);
    if (contracts.length === 0) contracts = BUILTIN_CONTRACTS;
    const byId = new Map(contracts.map((c) => [c.id, c]));
    const trades = raw.map((t) => {
      const contract = t.contractId ? byId.get(t.contractId) : null;
      return {
        id: String(t.id ?? ""),
        accountId: String(t.accountId ?? accountId),
        contractId: t.contractId ?? "",
        contractName: contract?.name ?? t.contractId ?? "",
        symbol: contract?.name ?? t.contractId ?? "",
        orderId: t.orderId != null ? String(t.orderId) : null,
        side: t.side ?? 0,
        size: t.size ?? 0,
        price: t.price ?? 0,
        profitLoss: t.profitLoss ?? null,
        fees: t.fees ?? null,
        creationTimestamp: t.creationTimestamp ?? null,
      };
    });
    return jsonResponse({ trades });
  } catch (_) {
    return jsonResponse({ trades: [] });
  }
}

async function handleTopstepBars(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const contractId = url.searchParams.get("contractId");
  if (!contractId) return jsonResponse({ error: "Missing contractId" }, 400);
  const { apiKey, userName } = getAuth(req);
  if (!apiKey) return jsonResponse({ error: "API key required" }, 401);
  const result = await projectXToken(apiKey, userName);
  if (!result.ok) return jsonResponse({ error: result.message }, 401);
  const from = url.searchParams.get("from");
  const to = url.searchParams.get("to");
  const unit = Math.min(6, Math.max(1, Number(url.searchParams.get("unit")) || 2));
  const unitNumber = Number(url.searchParams.get("unitNumber")) || 1;
  const limit = Math.min(20000, Math.max(1, Number(url.searchParams.get("limit")) || 500));
  const endTime = to || new Date().toISOString();
  const start = from ? new Date(from) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const startTime = from || start.toISOString();
  const bars = await projectXBars(result.token, contractId, { startTime, endTime, unit, unitNumber, limit, includePartialBar: false });
  return jsonResponse({ bars });
}

async function handleTopstepOrdersPost(req: Request): Promise<Response> {
  const { apiKey, userName } = getAuth(req);
  if (!apiKey) return jsonResponse({ status: "accepted", orderId: "demo-order-id" });
  let body: { accountId?: string; symbol?: string; contractId?: string; side?: string; type?: string; quantity?: number; limitPrice?: number; stopPrice?: number };
  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }
  if (!body?.accountId || !body?.quantity || body.quantity < 1) return jsonResponse({ error: "Missing accountId or invalid quantity" }, 400);
  const result = await projectXToken(apiKey, userName);
  if (!result.ok) return jsonResponse({ error: result.message }, 401);
  const contractId = body.contractId ?? (body.symbol ? (getContractId(body.symbol) ?? "") : "");
  if (!contractId) return jsonResponse({ error: "Unknown symbol; provide symbol or contractId" }, 400);
  const typeMap: Record<string, number> = { market: 2, limit: 1, stop: 4 };
  const orderType = typeMap[body.type ?? "market"] ?? 2;
  const side = body.side === "sell" ? 1 : 0;
  const size = Math.floor(Number(body.quantity));
  try {
    const payload = {
      accountId: Number(body.accountId),
      contractId,
      type: orderType,
      side,
      size,
      limitPrice: orderType === 1 ? body.limitPrice ?? null : null,
      stopPrice: orderType === 4 ? body.stopPrice ?? null : null,
    };
    const r = await fetch(`${PROJECTX_BASE}/api/Order/place`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${result.token}`, "Content-Type": "application/json", "Accept": "text/plain" },
      body: JSON.stringify(payload),
    });
    const data = await r.json().catch(() => ({}));
    if (data?.success) return jsonResponse({ status: "accepted", orderId: String(data.orderId ?? "") });
    return jsonResponse({ error: data?.errorMessage ?? "Order rejected" }, 400);
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: msg || "Order failed" }, 400);
  }
}

async function handleNewsHeadlines(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const categoriesParam = url.searchParams.get("categories") ?? "general,forex,crypto,merger";
  const categories = categoriesParam.split(",").map((c) => c.trim()).filter(Boolean);
  const toFetch = categories.length > 0 ? categories : ["general", "forex", "crypto", "merger"];
  const all: Array<{ id: string; headline: string; source: string; publishedAt: string; summary: string; symbols: string[] }> = [];

  if (FINNHUB_KEY) {
    for (const category of toFetch.slice(0, 6)) {
      try {
        const r = await fetch(`https://finnhub.io/api/v1/news?category=${encodeURIComponent(category)}&token=${FINNHUB_KEY}`);
        const data = await r.json().catch(() => []);
        const items = Array.isArray(data) ? data : [];
        for (const item of items as Array<{ id?: number; datetime?: number; headline?: string; source?: string; summary?: string; related?: string }>) {
          const id = item.id?.toString() ?? item.datetime?.toString() ?? "";
          if (id) all.push({
            id,
            headline: item.headline ?? "",
            source: item.source ?? "",
            publishedAt: new Date((item.datetime || 0) * 1000).toISOString(),
            summary: item.summary ?? "",
            symbols: item.related ? (item.related as string).split(",").filter(Boolean) : [],
          });
        }
      } catch (_) {}
    }
  }
  if (NEWSDATA_KEY) {
    try {
      const r = await fetch(`https://newsdata.io/api/1/latest?apikey=${encodeURIComponent(NEWSDATA_KEY)}&language=en`);
      const data = await r.json().catch(() => ({}));
      const raw = data?.results ?? data?.data ?? (Array.isArray(data) ? data : []);
      if (Array.isArray(raw)) {
        for (const item of raw as Array<{ article_id?: string; link?: string; pubDate?: string; title?: string; source_name?: string; source_id?: string; description?: string; keywords?: string[] }>) {
          const id = item.article_id ?? item.link ?? item.pubDate ?? "";
          if (id) all.push({
            id: String(id),
            headline: item.title ?? "",
            source: item.source_name ?? item.source_id ?? "",
            publishedAt: item.pubDate ? new Date(item.pubDate).toISOString() : new Date().toISOString(),
            summary: item.description ?? "",
            symbols: Array.isArray(item.keywords) ? item.keywords.slice(0, 10) : [],
          });
        }
      }
    } catch (_) {}
  }

  const seen = new Set<string>();
  const deduped = all.filter((item) => {
    const key = item.id || item.headline?.slice(0, 80) || "";
    if (key && !seen.has(key)) { seen.add(key); return true; }
    return false;
  });
  deduped.sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime());
  return jsonResponse({ news: deduped.slice(0, 80) });
}

async function handleNewsEvents(req: Request): Promise<Response> {
  if (!FINNHUB_KEY) return jsonResponse({ events: [] });
  const url = new URL(req.url);
  let from = url.searchParams.get("from") ?? "";
  let to = url.searchParams.get("to") ?? "";
  const now = new Date();
  if (!from) from = now.toISOString().slice(0, 10);
  if (!to) {
    const weekOut = new Date(now);
    weekOut.setDate(weekOut.getDate() + 7);
    to = weekOut.toISOString().slice(0, 10);
  }
  try {
    const r = await fetch(`https://finnhub.io/api/v1/calendar/economic?from=${from}&to=${to}&token=${FINNHUB_KEY}`);
    const data = await r.json().catch(() => ({}));
    const raw = (data?.economicCalendar ?? []) as Array<{ eventId?: number; country?: string; time?: string; date?: string; event?: string; importance?: string; previous?: unknown; estimate?: unknown; actual?: unknown }>;
    const mapped = raw.slice(0, 200).map((ev) => ({
      id: ev.eventId?.toString() ?? `${ev.country}-${ev.time}-${ev.event}`,
      time: new Date(ev.time || ev.date || 0).toISOString(),
      country: ev.country,
      name: ev.event,
      importance: ev.importance || "Medium",
      previous: ev.previous?.toString(),
      forecast: ev.estimate?.toString(),
      actual: ev.actual?.toString(),
    }));
    return jsonResponse({ events: mapped });
  } catch (_) {
    return jsonResponse({ events: [] });
  }
}

async function handleAiChat(req: Request): Promise<Response> {
  if (!NVIDIA_KEY) return jsonResponse({ error: "NVIDIA_API_KEY not configured" }, 500);
  let body: { messages?: Array<{ role?: string; content?: string }> };
  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }
  const messages = body?.messages ?? [];
  const systemPrompt = {
    role: "system",
    content: "You are Zenith, a macro-focused trading assistant for Topstep traders. You explain macroeconomic drivers, risk, and context in calm, clear language. You avoid hype, gamification, and short-term dopamine. You never give investment advice, only educational explanations of what is happening and what risks exist.",
  };
  const finalMessages = [systemPrompt, ...messages];
  try {
    const r = await fetch("https://integrate.api.nvidia.com/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${NVIDIA_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "gpt-4.1-mini", messages: finalMessages, temperature: 0.4 }),
    });
    const data = await r.json().catch(() => ({}));
    if (!r.ok) return jsonResponse(data?.error ?? { error: "AI request failed" }, r.status);
    return jsonResponse(data);
  } catch (e: unknown) {
    return jsonResponse({ error: e instanceof Error ? e.message : "AI request failed" }, 500);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET, POST, OPTIONS", "Access-Control-Allow-Headers": "*" } });
  }
  const url = new URL(req.url);
  const path = url.searchParams.get("path") ?? "/health";
  // #region agent log
  try {
    await fetch("http://127.0.0.1:7707/ingest/cf743728-3c3a-4ee3-8424-80e8f4efc712", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Debug-Session-Id": "ed0068" },
      body: JSON.stringify({
        sessionId: "ed0068",
        location: "zenith-api/index.ts:serve",
        message: "Edge Function received request",
        data: { path, method: req.method, pathParamRaw: url.searchParams.get("path") },
        timestamp: Date.now(),
        hypothesisId: "H3,H5",
      }),
    }).catch(() => {});
  } catch (_) {}
  // #endregion

  try {
    if (path === "/health") return jsonResponse({ status: "ok", service: "zenith-api" });
    if (path === "/topstep/connection" && req.method === "GET") return await handleTopstepConnection(req);
    if (path === "/topstep/accounts" && req.method === "GET") return await handleTopstepAccounts(req);
    if (path === "/topstep/contracts" && req.method === "GET") return await handleTopstepContracts(req);
    if (path === "/topstep/quotes" && req.method === "GET") return await handleTopstepQuotes(req);
    if (path === "/topstep/positions" && req.method === "GET") return await handleTopstepPositions(req);
    if (path === "/topstep/orders" && req.method === "GET") return await handleTopstepOrdersGet(req);
    if (path === "/topstep/orders" && req.method === "POST") return await handleTopstepOrdersPost(req);
    if (path === "/topstep/trades" && req.method === "GET") return await handleTopstepTrades(req);
    if (path === "/topstep/bars" && req.method === "GET") return await handleTopstepBars(req);
    if (path === "/news/headlines" && req.method === "GET") return await handleNewsHeadlines(req);
    if (path === "/news/events" && req.method === "GET") return await handleNewsEvents(req);
    if (path === "/ai/chat" && req.method === "POST") return await handleAiChat(req);
    return jsonResponse({ error: "Not found" }, 404);
  } catch (e: unknown) {
    return jsonResponse({ error: e instanceof Error ? e.message : "Server error" }, 500);
  }
});
