const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const validateSignup = (req, res, next) => {
  const { username, email, password } = req.body;

  if (!username || username.trim().length < 3) {
    return res.status(400).json({ message: "Username must be at least 3 characters" });
  }

  if (!email || !emailRegex.test(email)) {
    return res.status(400).json({ message: "Invalid email format" });
  }

  if (!password || password.length < 6) {
    return res.status(400).json({ message: "Password must be at least 6 characters" });
  }

  next();
};

export const validateLogin = (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !emailRegex.test(email)) {
    return res.status(400).json({ message: "Invalid email format" });
  }

  if (!password) {
    return res.status(400).json({ message: "Password is required" });
  }

  next();
};

export const validateTerritory = (req, res, next) => {
  const { coordinates, mode, timeTaken } = req.body;

  if (!coordinates || !Array.isArray(coordinates)) {
    return res.status(400).json({ message: "Coordinates array is required" });
  }

  if (!mode || !["walking", "jogging", "running", "cycling"].includes(mode)) {
    return res.status(400).json({ message: "Mode must be walking, jogging, running, or cycling" });
  }

  if (!timeTaken || typeof timeTaken !== "number" || timeTaken <= 0) {
    return res.status(400).json({ message: "Valid timeTaken is required" });
  }

  next();
};

export const validateStats = (req, res, next) => {
  const { territoryId, distanceCovered, caloriesBurned, averageSpeed, timeTaken } = req.body;

  if (!territoryId) {
    return res.status(400).json({ message: "Territory ID is required" });
  }

  if (typeof distanceCovered !== "number" || distanceCovered < 0) {
    return res.status(400).json({ message: "Valid distanceCovered is required" });
  }

  if (typeof caloriesBurned !== "number" || caloriesBurned < 0) {
    return res.status(400).json({ message: "Valid caloriesBurned is required" });
  }

  if (typeof averageSpeed !== "number" || averageSpeed < 0) {
    return res.status(400).json({ message: "Valid averageSpeed is required" });
  }

  if (typeof timeTaken !== "number" || timeTaken <= 0) {
    return res.status(400).json({ message: "Valid timeTaken is required" });
  }

  next();
};
