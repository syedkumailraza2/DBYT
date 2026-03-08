import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  territories: {
    
    type: [mongoose.Schema.Types.ObjectId],
    ref: 'Territory',
  },
  streak: {
    current: Number,
    longest: Number,
    lastActive: Date,
  },
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

export default User;
