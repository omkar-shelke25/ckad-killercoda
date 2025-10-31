# 🔒 CKAD: Fix Pod Communication with NetworkPolicies

## Scenario

You're working in a **production** namespace where strict NetworkPolicies control pod-to-pod communication. A pod named **api-check** needs to communicate with **web-server** and **redis-server** pods, but currently cannot.

## The Challenge

- ⚠️ You are **NOT allowed** to modify or create any NetworkPolicy
- 🎯 You must enable bi-directional communication between:
  - `api-check` ↔️ `web-server`
  - `api-check` ↔️ `redis-server`

## Your Task

Find a way to make the **api-check** pod work with the existing NetworkPolicies by understanding how they use pod labels for traffic control.

Click **Start** to begin!
