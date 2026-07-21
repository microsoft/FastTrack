---
title: Agent Brainstorming Template
type: strategy
category: PowerPoint
summary: >-
  Map an agent’s type, user flow, knowledge sources, tools, and target problem before
  implementation.
author: Microsoft FastTrack
version: 1.0.0
published: "2025-06-18"
updated: "2025-10-28"
tags:
  - template
  - planning
  - powerpoint
format: pptx
whatItIs: >-
  A one-slide PowerPoint planning template for visualizing the user-to-agent flow, selected agent
  type, knowledge sources, tools, and target problem.
whyUseIt:
  - Align stakeholders on a simple agent design before building.
  - Identify the minimum knowledge and tools required for the primary scenario.
  - Keep implementation focused on a clearly mapped user flow.
howToUse: |-
  1. Download `Copilot Agent Brainstorming.pptx` from this folder.
  2. Select the intended agent type.
  3. Fill in the user input, agent process, knowledge source, tool, and problem statement.
  4. Review the slide with stakeholders and keep it as a build reference.
prerequisites:
  - Microsoft PowerPoint or a compatible presentation editor
---

# Copilot Agent Brainstorming

A simple visual template to help you map out your Copilot agent specifications before building.

![alt text](./Images/Copilot%20Agent%20Brainstorm%20Slide.png)

## 🎯 What This Is

This slide template helps you visualize and plan your agent by mapping out:
- **Agent Type** - Which type fits your needs
- **Knowledge Sources** - What information your agent accesses
- **Tools** - What actions your agent can perform  
- **User Flow** - How users will interact with your agent

## 📋 How To Use This Template

1. **Choose Your Agent Type** (top section)
   - SPO Agent: SharePoint content only
   - Declarative Agent: Built-in M365 tools + web search
   - Custom Agent: Full customization with specialized tools

2. **Map the Flow** (center diagram)
   - Start with what the **User** provides
   - Show how the **Agent** processes the request
   - Identify what **Knowledge** sources are needed
   - Define what **Tools** will be used

3. **Define Your Problem** (bottom section)
   - Write your specific use case scenario

## 🖼️ Template Structure

```
┌─────────────┬─────────────────┬─────────────────┐
│  SPO Agent  │ Declarative     │  Custom Agent   │
│             │ Agent           │                 │
└─────────────┴─────────────────┴─────────────────┘

    User ──► Agent ──► Knowledge ──► Tool
     │         │          │          │
     │         │          │          │
    [Input]  [Process]  [Source]   [Action]
```

## 📝 Example: Acronyms Agent

**Agent Type:** Declarative Agent  
**User Input:** Provides acronym for explanation  
**Agent Process:** Reviews text and searches knowledge base  
**Knowledge Source:** Word document or SPO list with acronym definitions  
**Tool Output:** Returns definition or asks for clarification  

## 📥 Download Template

**[Download PowerPoint Template: Copilot Agent Brainstorming.pptx](./Copilot%20Agent%20Brainstorming.pptx)**

## 🚀 Getting Started

1. Download the slide template above
2. Fill in your specific:
   - Agent type selection
   - User input scenarios  
   - Knowledge sources needed
   - Tool requirements
   - Expected outputs
3. Use this visual to align with stakeholders before building
4. Reference during development to stay on track

## 💡 Tips

- Keep it simple - focus on the main user scenario
- Be specific about knowledge sources (which SharePoint site, which documents, etc.)
- Identify the minimum viable tools needed
- Test your flow logic before building

---

**Purpose:** Turn complex agent requirements into a simple visual that everyone can understand.