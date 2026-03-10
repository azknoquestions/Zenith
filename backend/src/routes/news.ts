import express from "express";
import axios from "axios";
import { env } from "../config/env";

export const newsRouter = express.Router();

const NEWS_CATEGORIES = ["general", "forex", "crypto", "merger"] as const;

/** Normalized news item shape for the API response */
interface NewsItemNormalized {
  id: string;
  headline: string;
  source: string;
  publishedAt: string;
  summary: string;
  symbols: string[];
}

async function fetchFinnhubNews(categories: string[]): Promise<NewsItemNormalized[]> {
  if (!env.FINNHUB_API_KEY) return [];
  const out: NewsItemNormalized[] = [];
  for (const category of categories.slice(0, 6)) {
    try {
      const url = `https://finnhub.io/api/v1/news?category=${encodeURIComponent(category)}&token=${env.FINNHUB_API_KEY}`;
      const { data } = await axios.get(url, { timeout: 5000 });
      const items = Array.isArray(data) ? data : [];
      for (const item of items) {
        const id = item.id?.toString() ?? item.datetime?.toString() ?? "";
        if (id) {
          out.push({
            id,
            headline: item.headline,
            source: item.source ?? "",
            publishedAt: new Date((item.datetime || 0) * 1000).toISOString(),
            summary: item.summary ?? "",
            symbols: item.related ? (item.related as string).split(",").filter(Boolean) : []
          });
        }
      }
    } catch (_) {
      // skip failed category
    }
  }
  return out;
}

async function fetchNewsdataNews(): Promise<NewsItemNormalized[]> {
  if (!env.NEWSDATA_API_KEY) return [];
  try {
    const url = `https://newsdata.io/api/1/latest?apikey=${encodeURIComponent(env.NEWSDATA_API_KEY)}&language=en`;
    const { data } = await axios.get(url, { timeout: 8000 });
    const raw = data?.results ?? data?.data ?? (Array.isArray(data) ? data : []);
    if (!Array.isArray(raw)) return [];
    const out: NewsItemNormalized[] = [];
    for (const item of raw) {
      const id = item.article_id ?? item.link ?? item.pubDate ?? "";
      if (!id) continue;
      const pubDate = item.pubDate ? new Date(item.pubDate).toISOString() : new Date().toISOString();
      out.push({
        id: String(id),
        headline: item.title ?? "",
        source: item.source_name ?? item.source_id ?? "",
        publishedAt: pubDate,
        summary: item.description ?? "",
        symbols: Array.isArray(item.keywords) ? item.keywords.slice(0, 10) : []
      });
    }
    return out;
  } catch (_) {
    return [];
  }
}

newsRouter.get("/headlines", async (req, res) => {
  try {
    const categoriesParam = (req.query.categories as string) || NEWS_CATEGORIES.join(",");
    const categories = categoriesParam.split(",").map((c) => c.trim()).filter(Boolean);
    const toFetch = categories.length > 0 ? categories : [...NEWS_CATEGORIES];

    const [finnhubItems, newsdataItems] = await Promise.all([
      fetchFinnhubNews(toFetch),
      fetchNewsdataNews()
    ]);

    const seen = new Set<string>();
    const all: NewsItemNormalized[] = [];
    for (const item of [...finnhubItems, ...newsdataItems]) {
      const dedupeKey = item.id || item.headline?.slice(0, 80) || "";
      if (dedupeKey && !seen.has(dedupeKey)) {
        seen.add(dedupeKey);
        all.push(item);
      }
    }

    all.sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime());
    return res.json({ news: all.slice(0, 80) });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch news" });
  }
});

newsRouter.get("/events", async (req, res) => {
  try {
    if (!env.FINNHUB_API_KEY) {
      return res.json({ events: [] });
    }

    let from = (req.query.from as string) || "";
    let to = (req.query.to as string) || "";
    const now = new Date();
    if (!from) {
      from = now.toISOString().slice(0, 10);
    }
    if (!to) {
      const weekOut = new Date(now);
      weekOut.setDate(weekOut.getDate() + 7);
      to = weekOut.toISOString().slice(0, 10);
    }

    const url = `https://finnhub.io/api/v1/calendar/economic?from=${from}&to=${to}&token=${env.FINNHUB_API_KEY}`;
    const { data } = await axios.get(url, { timeout: 5000 });

    const eventsRaw = (data && (data as any).economicCalendar) || [];
    const mapped = (eventsRaw as any[]).slice(0, 200).map((ev) => ({
      id: ev.eventId?.toString() ?? `${ev.country}-${ev.time}-${ev.event}`,
      time: new Date(ev.time || ev.date).toISOString(),
      country: ev.country,
      name: ev.event,
      importance: ev.importance || "Medium",
      previous: ev.previous?.toString(),
      forecast: ev.estimate?.toString(),
      actual: ev.actual?.toString()
    }));

    return res.json({ events: mapped });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch events" });
  }
});

