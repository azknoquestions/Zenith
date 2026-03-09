import express from "express";
import axios from "axios";
import { env } from "../../config/env";

export const aiRouter = express.Router();

aiRouter.post("/chat", async (req, res) => {
  try {
    const { messages, context } = req.body as {
      messages: { role: "system" | "user" | "assistant"; content: string }[];
      context?: {
        symbol?: string;
        timeFrame?: string;
        newsIds?: string[];
        eventIds?: string[];
      };
    };

    if (!env.NVIDIA_API_KEY) {
      return res.status(500).json({ error: "NVIDIA_API_KEY not configured" });
    }

    const systemPrompt = [
      {
        role: "system",
        content:
          "You are Zenith, a macro-focused trading assistant for Topstep traders. " +
          "You explain macroeconomic drivers, risk, and context in calm, clear language. " +
          "You avoid hype, gamification, and short-term dopamine. You never give investment advice, " +
          "only educational explanations of what is happening and what risks exist."
      }
    ];

    const finalMessages = [...systemPrompt, ...(messages || [])];

    const response = await axios.post(
      "https://integrate.api.nvidia.com/v1/chat/completions",
      {
        model: "gpt-4.1-mini",
        messages: finalMessages,
        temperature: 0.4
      },
      {
        headers: {
          Authorization: `Bearer ${env.NVIDIA_API_KEY}`,
          "Content-Type": "application/json"
        },
        timeout: 30_000
      }
    );

    return res.json(response.data);
  } catch (error: any) {
    const status = error.response?.status ?? 500;
    const data = error.response?.data ?? { error: "AI request failed" };
    return res.status(status).json(data);
  }
});

