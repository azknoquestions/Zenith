/**
 * ProjectX Gateway API helpers (Topstep).
 * @see https://gateway.docs.projectx.com/docs/getting-started/authenticate/authenticate-api-key
 */

import axios from "axios";
import { env } from "../config/env";

const cache = new Map<string, { token: string; expiresAt: number }>();
const TTL_MS = 50 * 60 * 1000; // 50 min

export async function getProjectXToken(apiKey: string, userName?: string): Promise<string | null> {
  const key = `${userName ?? ""}:${apiKey}`;
  const cached = cache.get(key);
  if (cached && cached.expiresAt > Date.now()) return cached.token;

  const base = env.PROJECTX_BASE_URL;
  try {
    const { data } = await axios.post<{ token?: string; success?: boolean; errorCode?: number }>(
      `${base}/api/Auth/loginKey`,
      { userName: userName ?? "trader", apiKey },
      { headers: { "Content-Type": "application/json", accept: "text/plain" }, timeout: 10000 }
    );
    if (data.success && data.token) {
      cache.set(key, { token: data.token, expiresAt: Date.now() + TTL_MS });
      return data.token;
    }
  } catch (_) {}
  return null;
}

/** Map symbol to ProjectX contractId (fallback when Contract/available not used). */
export const SYMBOL_TO_CONTRACT: Record<string, string> = {
  ES: "CON.F.US.EP.M25",
  NQ: "CON.F.US.ENQ.M25",
  CL: "CON.F.US.CL.M25",
  GC: "CON.F.US.GC.M25",
  ZN: "CON.F.US.ZN.M25",
  ZB: "CON.F.US.ZB.M25",
  MES: "CON.F.US.MES.M25",
  MNQ: "CON.F.US.MNQ.M25"
};

export function getContractId(symbol: string): string | null {
  const s = symbol.toUpperCase().trim();
  return SYMBOL_TO_CONTRACT[s] ?? null;
}

export interface ProjectXContract {
  id: string;
  name: string;
  description: string;
  symbolId: string;
  tickSize: number;
  tickValue: number;
  activeContract?: boolean;
}

const contractsCache = new Map<string, { contracts: ProjectXContract[]; expiresAt: number }>();
const CONTRACTS_TTL_MS = 5 * 60 * 1000; // 5 min

export async function getProjectXContracts(token: string): Promise<ProjectXContract[]> {
  const cached = contractsCache.get("all");
  if (cached && cached.expiresAt > Date.now()) return cached.contracts;

  const base = env.PROJECTX_BASE_URL;
  try {
    const { data } = await axios.post<{
      contracts?: Array<{
        id?: string;
        name?: string;
        description?: string;
        symbolId?: string;
        tickSize?: number;
        tickValue?: number;
        activeContract?: boolean;
      }>;
      success?: boolean;
    }>(`${base}/api/Contract/available`, { live: true }, {
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", accept: "application/json" },
      timeout: 10000
    });
    if (data.success && Array.isArray(data.contracts)) {
      const list = data.contracts.map((c) => ({
        id: c.id ?? "",
        name: c.name ?? "",
        description: c.description ?? "",
        symbolId: c.symbolId ?? "",
        tickSize: Number(c.tickSize) || 0,
        tickValue: Number(c.tickValue) || 0,
        activeContract: c.activeContract
      })).filter((c) => c.id && c.name);
      contractsCache.set("all", { contracts: list, expiresAt: Date.now() + CONTRACTS_TTL_MS });
      return list;
    }
  } catch (_) {}
  return [];
}

/** Resolve base symbol (e.g. ES, NQ) to first matching contract id from list (front-month style). */
export function resolveSymbolToContractId(symbol: string, contracts: ProjectXContract[]): string | null {
  const s = symbol.toUpperCase().trim();
  const match = contracts.find(
    (c) => c.name.toUpperCase().startsWith(s) || c.symbolId.toUpperCase().includes(s.replace(/^F\.US\./, ""))
  );
  return match?.id ?? null;
}

export interface ProjectXBar {
  t: string;
  o: number;
  h: number;
  l: number;
  c: number;
  v: number;
}

export async function getProjectXBars(
  token: string,
  contractId: string,
  opts: { startTime: string; endTime: string; unit: number; unitNumber: number; limit: number; includePartialBar: boolean }
): Promise<ProjectXBar[]> {
  const base = env.PROJECTX_BASE_URL;
  try {
    const { data } = await axios.post<{ bars?: ProjectXBar[]; success?: boolean }>(
      `${base}/api/History/retrieveBars`,
      {
        contractId,
        live: true,
        startTime: opts.startTime,
        endTime: opts.endTime,
        unit: opts.unit,
        unitNumber: opts.unitNumber,
        limit: opts.limit,
        includePartialBar: opts.includePartialBar
      },
      {
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", accept: "application/json" },
        timeout: 15000
      }
    );
    if (data.success && Array.isArray(data.bars)) return data.bars;
  } catch (_) {}
  return [];
}
