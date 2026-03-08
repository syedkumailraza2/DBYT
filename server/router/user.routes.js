import express from "express";
import { authenticate } from "../middleware/auth.middleware.js";
import { validateSignup, validateLogin } from "../middleware/validate.middleware.js";
import { Signup, Login, getUser, getMe, updateStreak, updateUser, updateStats } from "../controller/user.controller.js";

const userRouter = express.Router();

// Public routes
userRouter.post("/register", validateSignup, Signup);
userRouter.post("/login", validateLogin, Login);

// Protected routes
userRouter.get("/me", authenticate, getMe);
userRouter.put("/me", authenticate, updateUser);
userRouter.put("/stats", authenticate, updateStats);
userRouter.put("/streak", authenticate, updateStreak);
userRouter.get("/:userId", authenticate, getUser);

export default userRouter;
