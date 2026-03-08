import express from "express";
import { authenticate } from "../middleware/auth.middleware.js";
import { validateStats } from "../middleware/validate.middleware.js";
import {
  createStats,
  getStatsByTerritory,
  getUserStats,
  getUserSummary,
  getLeaderboard,
  getRecentActivity,
  deleteStats
} from "../controller/stats.controller.js";

const statsRouter = express.Router();

// All stats routes require authentication
statsRouter.use(authenticate);

// Create stats for a territory
statsRouter.post("/", validateStats, createStats);

// Get user's stats summary (totals, averages, etc.)
statsRouter.get("/summary", getUserSummary);

// Get user's recent activity
statsRouter.get("/recent", getRecentActivity);

// Get leaderboard
statsRouter.get("/leaderboard", getLeaderboard);

// Get all user's stats with pagination
statsRouter.get("/", getUserStats);

// Get stats for a specific territory
statsRouter.get("/territory/:territoryId", getStatsByTerritory);

// Delete stats
statsRouter.delete("/:statsId", deleteStats);

export default statsRouter;
