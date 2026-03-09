import express from "express";
import axios from "axios";
import { env } from "../config/env";
import {
  getProjectXToken,
  getContractId,
  getProjectXContracts,
  getProjectXBars,
  resolveSymbolToContractId,
  type ProjectXContract
} from "../lib/projectx";

export const topstepRouter = express.Router();

const DEMO_ACCOUNT = {
  id: "demo",
  name: "Topstep Evaluation",
  type: "Evaluation",
  currency: "USD",
  balance: 100000,
  equity: 100250,
  drawdownLimit: 2000
};

function getAuth(req: express.Request): { apiKey: string | undefined; userName: string | undefined } {
  return {
    apiKey: req.header("x-topstep-api-key") ?? undefined,
    userName: req.header("x-topstep-username") ?? undefined
  };
}

topstepRouter.get("/accounts", async (req, res) => {
  try {
    const { apiKey, userName } = getAuth(req);

    if (apiKey) {
      const token = await getProjectXToken(apiKey, userName);
      if (token) {
        try {
          const base = env.PROJECTX_BASE_URL;
          const { data } = await axios.get(`${base}/api/Account/list`, {
            headers: { Authorization: `Bearer ${token}`, accept: "application/json" },
            timeout: 10000
          });
          if (Array.isArray(data) && data.length > 0) {
            const accounts = data.map((a: { accountId?: number; name?: string; type?: string }) => ({
              id: String(a.accountId ?? a),
              name: a.name ?? `Account ${a.accountId ?? a}`,
              type: a.type ?? "Evaluation",
              currency: "USD",
              balance: 0,
              equity: 0,
              drawdownLimit: null
            }));
            return res.json({ accounts });
          }
          return res.json({ accounts: [] });
        } catch (_) {
          return res.status(502).json({ error: "Failed to fetch accounts from Topstep" });
        }
      }
      return res.status(401).json({ error: "Invalid API key" });
    }

    return res.json({ accounts: [DEMO_ACCOUNT] });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch accounts" });
  }
});

topstepRouter.get("/contracts", async (req, res) => {
  try {
    const { apiKey, userName } = getAuth(req);
    if (apiKey) {
      const token = await getProjectXToken(apiKey, userName);
      if (token) {
        const contracts = await getProjectXContracts(token);
        return res.json({ contracts });
      }
    }
    return res.json({ contracts: [] });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch contracts" });
  }
});

topstepRouter.get("/quotes", async (req, res) => {
  try {
    const symbols = (req.query.symbols as string)?.split(",").filter(Boolean) ?? [];
    const contractIds = (req.query.contractIds as string)?.split(",").filter(Boolean) ?? [];
    if (symbols.length === 0 && contractIds.length === 0) {
      return res.json({ quotes: [] });
    }

    const { apiKey, userName } = getAuth(req);
    if (apiKey) {
      const token = await getProjectXToken(apiKey, userName);
      if (token) {
        const contracts = await getProjectXContracts(token);
        const toFetch: { contractId: string; contract: ProjectXContract }[] = [];

        if (contractIds.length > 0) {
          for (const cid of contractIds.slice(0, 20)) {
            const contract = contracts.find((c) => c.id === cid);
            if (contract) toFetch.push({ contractId: cid, contract });
          }
        } else {
          for (const sym of symbols.slice(0, 20)) {
            const s = sym.trim().toUpperCase();
            const cid = resolveSymbolToContractId(s, contracts) ?? getContractId(s);
            if (!cid) continue;
            const contract = contracts.find((c) => c.id === cid) ?? {
              id: cid,
              name: s,
              description: s,
              symbolId: s,
              tickSize: 0,
              tickValue: 0
            };
            toFetch.push({ contractId: cid, contract });
          }
        }

        const quotes: any[] = [];
        const now = new Date();
        const endTime = now.toISOString();
        const startTime = new Date(now.getTime() - 60 * 60 * 1000).toISOString();

        for (const { contractId, contract } of toFetch) {
          const bars = await getProjectXBars(token, contractId, {
            startTime,
            endTime,
            unit: 2,
            unitNumber: 1,
            limit: 2,
            includePartialBar: true
          });
          const lastBar = bars.length > 0 ? bars[bars.length - 1] : null;
          const prevBar = bars.length >= 2 ? bars[bars.length - 2] : null;
          const c = lastBar?.c ?? 0;
          const pc = prevBar?.c ?? c;
          const net = c && pc ? c - pc : 0;
          const pct = pc ? (net / pc) * 100 : 0;
          quotes.push({
            id: contract.id,
            instrument: {
              id: contract.id,
              symbol: contract.name,
              name: contract.description || contract.name,
              assetClass: "Futures"
            },
            lastPrice: c,
            netChange: net,
            percentChange: pct,
            high: lastBar?.h ?? null,
            low: lastBar?.l ?? null
          });
        }
        return res.json({ quotes });
      }
    }

    return res.json({ quotes: [] });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch quotes" });
  }
});

topstepRouter.get("/positions", async (req, res) => {
  try {
    const accountId = req.query.accountId as string;
    if (!accountId) return res.status(400).json({ error: "Missing accountId" });

    const { apiKey, userName } = getAuth(req);
    if (!apiKey) return res.json({ positions: [] });

    const token = await getProjectXToken(apiKey, userName);
    if (!token) return res.json({ positions: [] });

    const base = env.PROJECTX_BASE_URL;
    const { data } = await axios.post(
      `${base}/api/Position/searchOpen`,
      { accountId: Number(accountId) },
      {
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", accept: "application/json" },
        timeout: 10000
      }
    );
    const rawPositions = (data?.positions ?? []) as Array<{
      id?: number;
      accountId?: number;
      contractId?: string;
      type?: number;
      size?: number;
      averagePrice?: number;
      creationTimestamp?: string;
    }>;
    const contracts = await getProjectXContracts(token);
    const byId = new Map(contracts.map((c) => [c.id, c]));

    const positions = rawPositions.map((p) => {
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
        creationTimestamp: p.creationTimestamp ?? null
      };
    });
    return res.json({ positions });
  } catch (_) {
    return res.json({ positions: [] });
  }
});

topstepRouter.get("/orders", async (req, res) => {
  try {
    const accountId = req.query.accountId as string;
    let startTimestamp = req.query.startTimestamp as string;
    const endTimestamp = (req.query.endTimestamp as string) || undefined;
    if (!accountId) return res.status(400).json({ error: "Missing accountId" });

    if (!startTimestamp) {
      const d = new Date();
      d.setUTCHours(0, 0, 0, 0);
      startTimestamp = d.toISOString();
    }

    const { apiKey, userName } = getAuth(req);
    if (!apiKey) return res.json({ orders: [] });

    const token = await getProjectXToken(apiKey, userName);
    if (!token) return res.json({ orders: [] });

    const base = env.PROJECTX_BASE_URL;
    const body: { accountId: number; startTimestamp: string; endTimestamp?: string } = {
      accountId: Number(accountId),
      startTimestamp
    };
    if (endTimestamp) body.endTimestamp = endTimestamp;

    const { data } = await axios.post(`${base}/api/Order/search`, body, {
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", accept: "application/json" },
      timeout: 10000
    });
    const rawOrders = (data?.orders ?? []) as Array<{
      id?: number;
      accountId?: number;
      contractId?: string;
      status?: number;
      type?: number;
      side?: number;
      size?: number;
      limitPrice?: number | null;
      stopPrice?: number | null;
      fillVolume?: number;
      filledPrice?: number;
      creationTimestamp?: string;
      updateTimestamp?: string;
    }>;
    const contracts = await getProjectXContracts(token);
    const byId = new Map(contracts.map((c) => [c.id, c]));

    const orders = rawOrders.map((o) => {
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
        updateTimestamp: o.updateTimestamp ?? null
      };
    });
    return res.json({ orders });
  } catch (_) {
    return res.json({ orders: [] });
  }
});

topstepRouter.get("/bars", async (req, res) => {
  try {
    const contractId = req.query.contractId as string;
    const from = req.query.from as string;
    const to = req.query.to as string;
    const unit = Math.min(6, Math.max(1, Number(req.query.unit) || 2));
    const unitNumber = Number(req.query.unitNumber) || 1;
    const limit = Math.min(20000, Math.max(1, Number(req.query.limit) || 500));

    if (!contractId) return res.status(400).json({ error: "Missing contractId" });

    const { apiKey, userName } = getAuth(req);
    if (!apiKey) return res.status(401).json({ error: "API key required" });

    const token = await getProjectXToken(apiKey, userName);
    if (!token) return res.status(401).json({ error: "Invalid API key" });

    const endTime = to || new Date().toISOString();
    const start = from ? new Date(from) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const startTime = from || start.toISOString();

    const bars = await getProjectXBars(token, contractId, {
      startTime,
      endTime,
      unit,
      unitNumber,
      limit,
      includePartialBar: false
    });
    return res.json({ bars });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch bars" });
  }
});

topstepRouter.post("/orders", async (req, res) => {
  try {
    const apiKey = req.header("x-topstep-api-key");
    const userName = req.header("x-topstep-username");
    const body = req.body as {
      accountId: string;
      symbol?: string;
      contractId?: string;
      side: "buy" | "sell";
      type: "market" | "limit" | "stop";
      quantity: number;
      limitPrice?: number;
      stopPrice?: number;
    };

    if (!body?.accountId || !body?.quantity || body.quantity < 1) {
      return res.status(400).json({ error: "Missing accountId or invalid quantity" });
    }
    const contractId = body.contractId ?? (body.symbol ? getContractId(body.symbol) : null);
    if (!contractId) {
      return res.status(400).json({ error: "Unknown symbol; provide symbol or contractId" });
    }

    const typeMap = { market: 2, limit: 1, stop: 4 } as const;
    const orderType = typeMap[body.type ?? "market"] ?? 2;
    const side = body.side === "sell" ? 1 : 0;
    const size = Math.floor(Number(body.quantity));

    if (apiKey) {
      const token = await getProjectXToken(apiKey, userName ?? undefined);
      if (!token) return res.status(401).json({ error: "Invalid API key" });
      try {
        const base = env.PROJECTX_BASE_URL;
        const payload: any = {
          accountId: Number(body.accountId),
          contractId,
          type: orderType,
          side,
          size,
          limitPrice: orderType === 1 ? body.limitPrice ?? null : null,
          stopPrice: orderType === 4 ? body.stopPrice ?? null : null
        };
        const { data } = await axios.post(`${base}/api/Order/place`, payload, {
          headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", accept: "text/plain" },
          timeout: 10000
        });
        if (data?.success) {
          return res.json({ status: "accepted", orderId: String(data.orderId ?? "") });
        }
        return res.status(400).json({ error: data?.errorMessage ?? "Order rejected" });
      } catch (err: any) {
        const msg = err.response?.data?.errorMessage ?? err.message ?? "Order failed";
        return res.status(400).json({ error: msg });
      }
    }

    return res.json({ status: "accepted", orderId: "demo-order-id" });
  } catch (error) {
    return res.status(500).json({ error: "Failed to submit order" });
  }
});

