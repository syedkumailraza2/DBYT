import mongoose from "mongoose";

const StatsSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  territory: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Territory",
    required: true,
  },
  distanceCovered: {
    type: Number,
    required: true,
  },
  caloriesBurned: {
    type: Number,
    required: true,
  },
  averageSpeed: {
    type: Number,
    required: true,
  },
  timeTaken: {
    type: Number,
    required: true,
  },
  capturedAt: {
    type: Date,
    default: Date.now,
  },
});

StatsSchema.index({ user: 1, capturedAt: -1 });

const Stats = mongoose.model("Stats", StatsSchema);

export default Stats;
