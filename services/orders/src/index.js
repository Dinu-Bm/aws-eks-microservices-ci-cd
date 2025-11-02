const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/health", (_, res) => res.json({ status: "ok" }));
app.get("/orders", (_, res) => res.json([{ id: 101, total: 250 }]));

app.listen(PORT, () => console.log(`orders service on :${PORT}`));
