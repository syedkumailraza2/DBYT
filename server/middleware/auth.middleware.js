import jwt from "jsonwebtoken";

export const authenticate = async (req, res, next) => {
  console.log("[AUTH] Authenticating request to:", req.method, req.path);

  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      console.log("[AUTH] Failed: No token provided");
      return res.status(401).json({ message: "No token provided" });
    }

    const token = authHeader.split(" ")[1];
    console.log("[AUTH] Token received:", token.substring(0, 20) + "...");

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log("[AUTH] Token decoded, userId:", decoded.id);

    req.userId = decoded.id;
    next();
  } catch (error) {
    console.error("[AUTH] Error:", error.name, error.message);
    if (error.name === "TokenExpiredError") {
      return res.status(401).json({ message: "Token expired" });
    }
    return res.status(401).json({ message: "Invalid token" });
  }
};
