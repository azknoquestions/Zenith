import express from "express";
import axios from "axios";
import { env } from "../config/env";

export const newsRouter = express.Router();

newsRouter.get("/headlines", async (_req, res) => {
  try {
    if (!env.FINNHUB_API_KEY) {
      return res.json({ news: [] });
    }

    const url = `https://finnhub.io/api/v1/news?category=general&token=${env.FINNHUB_API_KEY}`;
    const { data } = await axios.get(url, { timeout: 5000 });

    const mapped = (data as any[]).slice(0, 50).map((item) => ({
      id: item.id?.toString() ?? item.datetime?.toString() ?? "",
      headline: item.headline,
      source: item.source,
      publishedAt: new Date(item.datetime * 1000).toISOString(),
      summary: item.summary,
      symbols: item.related ? (item.related as string).split(",").filter(Boolean) : []
    }));

    return res.json({ news: mapped });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch news" });
  }
});

newsRouter.get("/events", async (_req, res) => {
  try {
    if (!env.FINNHUB_API_KEY) {
      return res.json({ events: [] });
    }

    const today = new Date().toISOString().slice(0, 10);
    const url = `https://finnhub.io/api/v1/calendar/economic?from=${today}&to=${today}&token=${env.FINNHUB_API_KEY}`;
    const { data } = await axios.get(url, { timeout: 5000 });

    const eventsRaw = (data && (data as any).economicCalendar) || [];
    const mapped = (eventsRaw as any[]).slice(0, 100).map((ev) => ({
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

