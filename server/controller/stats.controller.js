import mongoose from "mongoose";
import Stats from "../model/stats.model.js";
import Territory from "../model/territory.model.js";

export const createStats = async (req, res) => {
  try {
    const userId = req.userId;
    const { territoryId, distanceCovered, caloriesBurned, averageSpeed, timeTaken } = req.body;

    const territory = await Territory.findById(territoryId);
    if (!territory) {
      return res.status(404).json({ message: "Territory not found" });
    }

    if (territory.userId.toString() !== userId) {
      return res.status(403).json({ message: "Not authorized to add stats for this territory" });
    }

    const existingStats = await Stats.findOne({ territory: territoryId });
    if (existingStats) {
      return res.status(400).json({ message: "Stats already exist for this territory" });
    }

    const stats = await Stats.create({
      user: userId,
      territory: territoryId,
      distanceCovered,
      caloriesBurned,
      averageSpeed,
      timeTaken
    });

    res.status(201).json({
      message: "Stats recorded successfully",
      stats
    });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid ID format" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getStatsByTerritory = async (req, res) => {
  try {
    const { territoryId } = req.params;

    const stats = await Stats.findOne({ territory: territoryId })
      .populate("territory")
      .populate("user", "username");

    if (!stats) {
      return res.status(404).json({ message: "Stats not found for this territory" });
    }

    res.status(200).json({ stats });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid territory ID format" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getUserStats = async (req, res) => {
  try {
    const userId = req.userId;
    const { page = 1, limit = 20 } = req.query;

    const stats = await Stats.find({ user: userId })
      .populate("territory")
      .sort({ capturedAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit));

    const total = await Stats.countDocuments({ user: userId });

    res.status(200).json({
      stats,
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

export const getUserSummary = async (req, res) => {
  try {
    const userId = req.userId;

    const summary = await Stats.aggregate([
      { $match: { user: new mongoose.Types.ObjectId(userId) } },
      {
        $group: {
          _id: null,
          totalDistance: { $sum: "$distanceCovered" },
          totalCalories: { $sum: "$caloriesBurned" },
          totalTime: { $sum: "$timeTaken" },
          averageSpeed: { $avg: "$averageSpeed" },
          totalActivities: { $sum: 1 }
        }
      }
    ]);

    const territoriesCount = await Territory.countDocuments({ userId });

    const modeBreakdown = await Stats.aggregate([
      { $match: { user: new mongoose.Types.ObjectId(userId) } },
      {
        $lookup: {
          from: "territories",
          localField: "territory",
          foreignField: "_id",
          as: "territoryData"
        }
      },
      { $unwind: "$territoryData" },
      {
        $group: {
          _id: "$territoryData.mode",
          count: { $sum: 1 },
          distance: { $sum: "$distanceCovered" },
          calories: { $sum: "$caloriesBurned" },
          time: { $sum: "$timeTaken" }
        }
      }
    ]);

    res.status(200).json({
      summary: summary[0] || {
        totalDistance: 0,
        totalCalories: 0,
        totalTime: 0,
        averageSpeed: 0,
        totalActivities: 0
      },
      territoriesCount,
      modeBreakdown
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getLeaderboard = async (req, res) => {
  try {
    const { metric = "totalDistance", limit = 10 } = req.query;

    const validMetrics = ["totalDistance", "totalCalories", "totalActivities", "totalArea"];

    if (!validMetrics.includes(metric)) {
      return res.status(400).json({
        message: `Invalid metric. Valid options: ${validMetrics.join(", ")}`
      });
    }

    let leaderboard;

    if (metric === "totalArea") {
      leaderboard = await Territory.aggregate([
        {
          $group: {
            _id: "$userId",
            totalArea: { $sum: "$area" },
            count: { $sum: 1 }
          }
        },
        { $sort: { totalArea: -1 } },
        { $limit: parseInt(limit) },
        {
          $lookup: {
            from: "users",
            localField: "_id",
            foreignField: "_id",
            as: "user"
          }
        },
        { $unwind: "$user" },
        {
          $project: {
            _id: 0,
            userId: "$_id",
            username: "$user.username",
            totalArea: 1,
            territoriesCount: "$count"
          }
        }
      ]);
    } else {
      const groupField = {
        totalDistance: "$distanceCovered",
        totalCalories: "$caloriesBurned",
        totalActivities: 1
      };

      leaderboard = await Stats.aggregate([
        {
          $group: {
            _id: "$user",
            value: metric === "totalActivities" ? { $sum: 1 } : { $sum: groupField[metric] }
          }
        },
        { $sort: { value: -1 } },
        { $limit: parseInt(limit) },
        {
          $lookup: {
            from: "users",
            localField: "_id",
            foreignField: "_id",
            as: "user"
          }
        },
        { $unwind: "$user" },
        {
          $project: {
            _id: 0,
            userId: "$_id",
            username: "$user.username",
            [metric]: "$value"
          }
        }
      ]);
    }

    res.status(200).json({
      metric,
      leaderboard
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getRecentActivity = async (req, res) => {
  try {
    const userId = req.userId;
    const { days = 7 } = req.query;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(days));

    const recentStats = await Stats.find({
      user: userId,
      capturedAt: { $gte: startDate }
    })
      .populate("territory")
      .sort({ capturedAt: -1 });

    const dailyBreakdown = await Stats.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(userId),
          capturedAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            $dateToString: { format: "%Y-%m-%d", date: "$capturedAt" }
          },
          distance: { $sum: "$distanceCovered" },
          calories: { $sum: "$caloriesBurned" },
          activities: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    res.status(200).json({
      period: `Last ${days} days`,
      activities: recentStats,
      dailyBreakdown
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const deleteStats = async (req, res) => {
  try {
    const { statsId } = req.params;
    const userId = req.userId;

    const stats = await Stats.findById(statsId);

    if (!stats) {
      return res.status(404).json({ message: "Stats not found" });
    }

    if (stats.user.toString() !== userId) {
      return res.status(403).json({ message: "Not authorized to delete these stats" });
    }

    await Stats.findByIdAndDelete(statsId);

    res.status(200).json({ message: "Stats deleted successfully" });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid stats ID format" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};
