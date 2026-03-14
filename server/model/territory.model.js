import mongoose from 'mongoose';

const TerritorySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  mode: {
    type: String,
    enum: ["walking", "jogging", "running", "cycling"]
  },
  timeTaken: {
    type: Number,
    required: true,
  },
  capturedAt: {
    type: Date,
    default: Date.now,
  },
  area: {
    type: Number,
    required: true,
  },
  Polygon: {
    type: {
      type: String,
      enum: ['Polygon'],
      required: true,
    },
    coordinates: {
      type: [[[Number]]], // Array of arrays of coordinates (longitude, latitude)
      required: true,
    },
  },        
}, { timestamps: true });

TerritorySchema.index({ Polygon: "2dsphere" });
const Territory = mongoose.model('Territory', TerritorySchema);

export default Territory;