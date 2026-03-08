import Territory from "../model/territory.model.js";
import User from "../model/user.model.js";
import * as turf from "@turf/turf";

export const createTerritory = async (req, res) => {
  try {
    console.log("[CREATE_TERRITORY] Starting...");
    const userId = req.userId;
    const { coordinates, mode, timeTaken } = req.body;

    console.log("[CREATE_TERRITORY] UserId:", userId);
    console.log("[CREATE_TERRITORY] Mode:", mode, "TimeTaken:", timeTaken);
    console.log("[CREATE_TERRITORY] Coordinates count:", coordinates?.length);

    if (!coordinates || coordinates.length < 4) {
      return res.status(400).json({ message: "Invalid polygon: minimum 4 coordinates required" });
    }

    const first = coordinates[0];
    const last = coordinates[coordinates.length - 1];

    if (first[0] !== last[0] || first[1] !== last[1]) {
      return res.status(400).json({ message: "Path not closed: first and last points must match" });
    }

    console.log("[CREATE_TERRITORY] Calculating area with turf...");
    const polygon = turf.polygon([coordinates]);
    const area = turf.area(polygon);
    console.log("[CREATE_TERRITORY] Area calculated:", area);

    if (area < 50) {
      return res.status(400).json({ message: "Territory too small: minimum 50 square meters" });
    }

    console.log("[CREATE_TERRITORY] Creating territory in DB...");
    const territory = await Territory.create({
      userId,
      mode,
      timeTaken,
      area,
      Polygon: {
        type: "Polygon",
        coordinates: [coordinates]
      }
    });
    console.log("[CREATE_TERRITORY] Territory created:", territory._id);

    await User.findByIdAndUpdate(
      userId,
      { $push: { territories: territory._id } }
    );
    console.log("[CREATE_TERRITORY] User updated");

    res.status(201).json({
      message: "Territory captured",
      territory
    });
  } catch (error) {
    console.error("[CREATE_TERRITORY] Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getTerritory = async (req, res) => {
  try {
    const { territoryId } = req.params;

    const territory = await Territory.findById(territoryId).populate("userId", "username");

    if (!territory) {
      return res.status(404).json({ message: "Territory not found" });
    }

    res.status(200).json({ territory });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid territory ID format" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getUserTerritories = async (req, res) => {
  try {
    const userId = req.userId;

    const territories = await Territory.find({ userId }).sort({ capturedAt: -1 });

    res.status(200).json({
      count: territories.length,
      territories
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getAllTerritories = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const territories = await Territory.find()
      .populate("userId", "username")
      .sort({ capturedAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit));

    const total = await Territory.countDocuments();

    res.status(200).json({
      territories,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getNearbyTerritories = async (req, res) => {
  try {
    const { longitude, latitude, maxDistance = 5000 } = req.query;

    if (!longitude || !latitude) {
      return res.status(400).json({ message: "Longitude and latitude are required" });
    }

    const territories = await Territory.find({
      Polygon: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [parseFloat(longitude), parseFloat(latitude)]
          },
          $maxDistance: parseInt(maxDistance)
        }
      }
    }).populate("userId", "username");

    res.status(200).json({
      count: territories.length,
      territories
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const deleteTerritory = async (req, res) => {
  try {
    const { territoryId } = req.params;
    const userId = req.userId;

    const territory = await Territory.findById(territoryId);

    if (!territory) {
      return res.status(404).json({ message: "Territory not found" });
    }

    if (territory.userId.toString() !== userId) {
      return res.status(403).json({ message: "Not authorized to delete this territory" });
    }

    await Territory.findByIdAndDelete(territoryId);

    await User.findByIdAndUpdate(
      userId,
      { $pull: { territories: territoryId } }
    );

    res.status(200).json({ message: "Territory deleted successfully" });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid territory ID format" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};
