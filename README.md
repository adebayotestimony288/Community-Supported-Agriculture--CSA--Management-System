# Community Supported Agriculture (CSA) Management System

A comprehensive blockchain-based system for managing Community Supported Agriculture programs using Clarity smart contracts on the Stacks blockchain.

## System Overview

This CSA management system consists of five interconnected smart contracts that handle all aspects of running a community-supported agriculture program:

### Core Contracts

1. **csa-members.clar** - Member registration, subscription management, and payment processing
2. **harvest-distribution.clar** - Harvest allocation, distribution scheduling, and pickup coordination
3. **farm-visits.clar** - Educational program scheduling and farm visit management
4. **seasonal-planning.clar** - Crop planning, seasonal schedules, and harvest forecasting
5. **member-feedback.clar** - Feedback collection, satisfaction tracking, and program improvement

## Key Features

### Member Management
- Member registration and profile management
- Subscription tier selection (Basic, Premium, Family)
- Payment processing and subscription renewals
- Member status tracking (Active, Suspended, Expired)

### Harvest Distribution
- Weekly harvest allocation based on subscription tiers
- Pickup location and time slot management
- Distribution tracking and member notifications
- Surplus handling and redistribution

### Farm Visits & Education
- Educational program scheduling
- Visit capacity management
- Member registration for events
- Seasonal workshop coordination

### Seasonal Planning
- Crop selection and planting schedules
- Harvest forecasting and planning
- Seasonal subscription management
- Weather and growing condition tracking

### Feedback System
- Member satisfaction surveys
- Harvest quality ratings
- Program improvement suggestions
- Farmer-member communication

## Data Structures

### Member Profiles
```clarity
{
  member-id: uint,
  wallet-address: principal,
  subscription-tier: (string-ascii 20),
  status: (string-ascii 20),
  join-date: uint,
  payment-due: uint,
  total-paid: uint
}
