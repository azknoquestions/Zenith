export interface Env {
  TOPSTEP_BASE_URL: string;
  PROJECTX_BASE_URL: string;
  TOPSTEP_CLIENT_ID?: string;
  TOPSTEP_CLIENT_SECRET?: string;

  FINNHUB_API_KEY?: string;
  TRADING_ECONOMICS_KEY?: string;

  NVIDIA_API_KEY?: string;
}

export const env: Env = {
  TOPSTEP_BASE_URL: process.env.TOPSTEP_BASE_URL || "https://api.topstep.com",
  PROJECTX_BASE_URL: process.env.PROJECTX_BASE_URL || "https://api.thefuturesdesk.projectx.com",
  TOPSTEP_CLIENT_ID: process.env.TOPSTEP_CLIENT_ID,
  TOPSTEP_CLIENT_SECRET: process.env.TOPSTEP_CLIENT_SECRET,
  FINNHUB_API_KEY: process.env.FINNHUB_API_KEY,
  TRADING_ECONOMICS_KEY: process.env.TRADING_ECONOMICS_KEY,
  NVIDIA_API_KEY: process.env.NVIDIA_API_KEY
};

