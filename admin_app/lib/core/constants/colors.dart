import 'package:flutter/material.dart';

// ── Brand colors ───────────────────────────────────────────────────────────
const Color kBg          = Color(0xFF0F172A); // page background
const Color kSurface     = Color(0xFF1E293B); // sidebar / card surface
const Color kSurfaceHigh = Color(0xFF334155); // elevated cards
const Color kBorder      = Color(0xFF334155); // border
const Color kPrimary     = Color(0xFF4F46E5); // indigo accent
const Color kSuccess     = Color(0xFF10B981); // green
const Color kWarning     = Color(0xFFF59E0B); // amber
const Color kError       = Color(0xFFEF4444); // red
const Color kTextPrimary = Color(0xFFF1F5F9); // near-white
const Color kTextMuted   = Color(0xFF94A3B8); // slate-400

// ── Gradient ───────────────────────────────────────────────────────────────
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
