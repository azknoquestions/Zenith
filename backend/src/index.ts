import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";

import { topstepRouter } from "./routes/topstep";
import { newsRouter } from "./routes/news";
import { aiRouter } from "./routes/ai/chat";

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: "*"
  })
);
app.use(express.json());
app.use(morgan("dev"));

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "zenith-backend" });
});

app.use("/topstep", topstepRouter);
app.use("/news", newsRouter);
app.use("/ai", aiRouter);

const port = process.env.PORT || 4000;
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Zenith backend listening on port ${port}`);
});

