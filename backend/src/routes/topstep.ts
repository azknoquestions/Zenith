import express from "express";
import axios from "axios";
import { env } from "../config/env";

export const topstepRouter = express.Router();

topstepRouter.get("/accounts", async (req, res) => {
  try {
    const apiKey = req.header("x-topstep-api-key");

    // TODO: When wiring the real Topstep API, use apiKey to authenticate
    // requests on behalf of this user instead of the demo response.

    const demoAccount = {
      id: "demo",
      name: "Topstep Evaluation",
      type: "Evaluation",
      currency: "USD",
      balance: 100000,
      equity: 100250,
      drawdownLimit: 2000
    };
    return res.json({ accounts: [demoAccount] });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch accounts" });
  }
});

topstepRouter.get("/quotes", async (_req, res) => {
  try {
    // This will later proxy to Topstep / Finnhub for real-time market data.
    return res.json({
      quotes: []
    });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch quotes" });
  }
});

topstepRouter.post("/orders", async (req, res) => {
  try {
    const order = req.body;
    if (!order || !order.instrument || !order.side || !order.quantity) {
      return res.status(400).json({ error: "Invalid order payload" });
    }

    // TODO: Validate risk locally, then send to Topstep.
    // await axios.post(`${env.TOPSTEP_BASE_URL}/orders`, order, { headers: { Authorization: `Bearer ${token}` } });

    return res.json({ status: "accepted", orderId: "demo-order-id" });
  } catch (error) {
    return res.status(500).json({ error: "Failed to submit order" });
  }
});

