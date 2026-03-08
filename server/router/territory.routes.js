import express from "express";
import { authenticate } from "../middleware/auth.middleware.js";
import { validateTerritory } from "../middleware/validate.middleware.js";
import {
  createTerritory,
  getTerritory,
  getUserTerritories,
  getAllTerritories,
  getNearbyTerritories,
  deleteTerritory
} from "../controller/territory.controller.js";

const territoryRouter = express.Router();

// Protected routes (must come before wildcard routes)
territoryRouter.post("/", authenticate, validateTerritory, createTerritory);
territoryRouter.get("/", authenticate, getUserTerritories);
territoryRouter.delete("/:territoryId", authenticate, deleteTerritory);

// Public routes
territoryRouter.get("/all", getAllTerritories);
territoryRouter.get("/nearby", getNearbyTerritories);
territoryRouter.get("/:territoryId", getTerritory);

export default territoryRouter;
