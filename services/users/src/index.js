const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/health", (_, res) => res.json({ status: "ok" }));
app.get("/users", (_, res) => res.json([{ id: 1, name: "Alice" }]));

app.listen(PORT, () => console.log(`users service on :${PORT}`));
