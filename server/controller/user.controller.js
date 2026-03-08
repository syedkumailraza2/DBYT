import User from "../model/user.model.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

export const Signup = async (req, res) => {
  console.log("[SIGNUP] Request received");
  console.log("[SIGNUP] Body:", JSON.stringify(req.body, null, 2));

  try {
    const { username, email, password } = req.body;
    console.log("[SIGNUP] Attempting to register:", { username, email });

    const existingUser = await User.findOne({
      $or: [{ email }, { username }]
    });

    if (existingUser) {
      if (existingUser.email === email) {
        console.log("[SIGNUP] Failed: Email already exists");
        return res.status(400).json({ message: "Email already exists" });
      }
      console.log("[SIGNUP] Failed: Username already exists");
      return res.status(400).json({ message: "Username already exists" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({
      username,
      email,
      password: hashedPassword
    });

    await newUser.save();
    console.log("[SIGNUP] Success: User created with ID:", newUser._id);

    res.status(201).json({
      message: "User created successfully",
      userId: newUser._id
    });
  } catch (error) {
    console.error("[SIGNUP] Error:", error.message);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const Login = async (req, res) => {
  console.log("[LOGIN] Request received");
  console.log("[LOGIN] Body:", JSON.stringify({ email: req.body.email, password: "***" }, null, 2));

  try {
    const { email, password } = req.body;
    console.log("[LOGIN] Attempting login for:", email);

    const user = await User.findOne({ email });
    if (!user) {
      console.log("[LOGIN] Failed: User not found");
      return res.status(400).json({ message: "Invalid credentials" });
    }
    console.log("[LOGIN] User found:", user.username);

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      console.log("[LOGIN] Failed: Password mismatch");
      return res.status(400).json({ message: "Invalid credentials" });
    }
    console.log("[LOGIN] Password verified");

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });
    console.log("[LOGIN] Token generated for user:", user._id);

    res.status(200).json({
      message: "Login successful",
      userId: user._id,
      username: user.username,
      token
    });
    console.log("[LOGIN] Success: Response sent");
  } catch (error) {
    console.error("[LOGIN] Error:", error.message);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId)
      .select("-password")
      .populate("territories");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({ user });
  } catch (error) {
    if (error.name === "CastError") {
      return res.status(400).json({ message: "Invalid user ID format" });
    }
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const getMe = async (req, res) => {
  console.log("[GET_ME] Request received for userId:", req.userId);

  try {
    const user = await User.findById(req.userId)
      .select("-password")
      .populate("territories");

    if (!user) {
      console.log("[GET_ME] Failed: User not found");
      return res.status(404).json({ message: "User not found" });
    }

    console.log("[GET_ME] Success: Returning user:", user.username);
    res.status(200).json({ user });
  } catch (error) {
    console.error("[GET_ME] Error:", error.message);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const updateStreak = async (req, res) => {
  try {
    const user = await User.findById(req.userId);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const now = new Date();
    const lastActive = user.streak?.lastActive;
    const currentStreak = user.streak?.current || 0;
    const longestStreak = user.streak?.longest || 0;

    let newStreak = 1;

    if (lastActive) {
      const diffHours = (now - new Date(lastActive)) / (1000 * 60 * 60);

      if (diffHours < 24) {
        newStreak = currentStreak;
      } else if (diffHours < 48) {
        newStreak = currentStreak + 1;
      }
    }

    user.streak = {
      current: newStreak,
      longest: Math.max(longestStreak, newStreak),
      lastActive: now
    };

    await user.save();

    res.status(200).json({
      message: "Streak updated",
      streak: user.streak
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const updateUser = async (req, res) => {
  console.log("[UPDATE_USER] Request received for userId:", req.userId);
  console.log("[UPDATE_USER] Body:", JSON.stringify(req.body, null, 2));

  try {
    const { username, email, password } = req.body;
    const user = await User.findById(req.userId);

    if (!user) {
      console.log("[UPDATE_USER] Failed: User not found");
      return res.status(404).json({ message: "User not found" });
    }

    // Check if new username is already taken by another user
    if (username && username !== user.username) {
      const existingUsername = await User.findOne({ username, _id: { $ne: req.userId } });
      if (existingUsername) {
        console.log("[UPDATE_USER] Failed: Username already taken");
        return res.status(400).json({ message: "Username already taken" });
      }
      user.username = username;
    }

    // Check if new email is already taken by another user
    if (email && email !== user.email) {
      const existingEmail = await User.findOne({ email, _id: { $ne: req.userId } });
      if (existingEmail) {
        console.log("[UPDATE_USER] Failed: Email already taken");
        return res.status(400).json({ message: "Email already taken" });
      }
      user.email = email;
    }

    // Update password if provided
    if (password) {
      const salt = await bcrypt.genSalt(10);
      user.password = await bcrypt.hash(password, salt);
      console.log("[UPDATE_USER] Password updated");
    }

    await user.save();
    console.log("[UPDATE_USER] Success: User updated");

    res.status(200).json({
      message: "User updated successfully",
      user: {
        _id: user._id,
        username: user.username,
        email: user.email,
        territories: user.territories,
        streak: user.streak
      }
    });
  } catch (error) {
    console.error("[UPDATE_USER] Error:", error.message);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const updateStats = async (req, res) => {
  console.log("[UPDATE_STATS] Request received for userId:", req.userId);
  console.log("[UPDATE_STATS] Body:", JSON.stringify(req.body, null, 2));

  try {
    const { streak } = req.body;
    const user = await User.findById(req.userId);

    if (!user) {
      console.log("[UPDATE_STATS] Failed: User not found");
      return res.status(404).json({ message: "User not found" });
    }

    // Update streak if provided
    if (streak) {
      user.streak = {
        current: streak.current ?? user.streak?.current ?? 0,
        longest: streak.longest ?? user.streak?.longest ?? 0,
        lastActive: streak.lastActive ? new Date(streak.lastActive) : user.streak?.lastActive ?? new Date()
      };
      console.log("[UPDATE_STATS] Streak updated:", user.streak);
    }

    await user.save();
    console.log("[UPDATE_STATS] Success: Stats updated");

    res.status(200).json({
      message: "Stats updated successfully",
      streak: user.streak
    });
  } catch (error) {
    console.error("[UPDATE_STATS] Error:", error.message);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};
