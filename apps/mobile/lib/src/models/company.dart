import 'package:flutter/material.dart';

class Company {
  const Company({
    required this.name,
    required this.ticker,
    required this.symbol,
    required this.description,
    required this.products,
    required this.color,
    required this.price,
    required this.change,
  });

  final String name;
  final String ticker;
  final String symbol;
  final String description;
  final List<String> products;
  final Color color;
  final double price;
  final double change;
}

abstract final class DemoCompanies {
  static const apple = Company(
    name: 'Apple',
    ticker: 'AAPL',
    symbol: 'tAAPLc',
    description: 'The company behind iPhone, Mac, iPad, AirPods and more.',
    products: ['iPhone', 'Mac', 'AirPods'],
    color: Colors.white,
    price: 214.32,
    change: 1.81,
  );

  static const meta = Company(
    name: 'Meta Platforms',
    ticker: 'META',
    symbol: 'tMETAc',
    description:
        'The parent company of Instagram, WhatsApp, Facebook and Threads.',
    products: ['Instagram', 'WhatsApp', 'Threads'],
    color: Color(0xFF38A5FF),
    price: 500,
    change: 1.2,
  );

  static const nvidia = Company(
    name: 'NVIDIA',
    ticker: 'NVDA',
    symbol: 'tNVDAc',
    description:
        'The computing company behind GeForce, RTX, CUDA and accelerated AI.',
    products: ['GeForce', 'RTX', 'CUDA'],
    color: Color(0xFF9BFF00),
    price: 180,
    change: 2.4,
  );

  static const alphabet = Company(
    name: 'Alphabet',
    ticker: 'GOOGL',
    symbol: 'tGOOGLc',
    description:
        'The company behind Google Search, YouTube, Android, Gemini and more.',
    products: ['Google', 'YouTube', 'Gemini'],
    color: Color(0xFF4285F4),
    price: 150,
    change: 1.09,
  );
}
