# Local AI Agent Architecture for ERP (On-Device SLM)

## 1. The Model: Small Language Models (SLMs)
To run smoothly on a user's laptop, tablet, or phone, we cannot use massive 70B+ parameter models. We need a highly optimized SLM (Small Language Model) between **2B to 8B parameters**.

**Recommended Models (2026 Benchmarks):**
*   **Microsoft Phi-3 Mini (3.8B) / Phi-4 Silica:** Purpose-built for edge devices. Exceptional at logic, instruction following, and function calling.
*   **Llama-3-8B-Instruct (Quantized):** Powerful, but requires a device with decent RAM (8GB+).
*   **Google Gemma-2 (2B):** Extremely lightweight, runs on almost any mobile device or old laptop.

*Crucial Step:* The model must be fine-tuned or heavily prompted specifically for **JSON Function Calling**, as its primary job is not just chatting, but triggering system actions.

---

## 2. Deployment Mechanism (How it runs)
Depending on your platform (Web vs. Desktop/Mobile apps), the execution environment changes:

*   **For the React Web App (Browser):** Use **WebLLM** (powered by Apache TVM) or **Transformers.js**. These utilize **WebGPU** to run the LLM directly in the user's browser using their local graphics card. The model weights are downloaded once and cached in the browser's IndexedDB.
*   **For Windows/Android Apps:** Bundle **ONNX Runtime** or **Llama.cpp**. These run highly compressed (quantized) GGUF models directly on the native OS, utilizing local NPUs (Neural Processing Units) or CPUs.

---

## 3. Context Awareness (Knowing the System & Data)
An ERP is too vast to put everything in the prompt. We use **Local RAG** (Retrieval-Augmented Generation) combined with **UI State Injection**.

### A. State Injection (The "What are you looking at" context)
The AI must always know the user's current context. We inject the React/Zustand state directly into the system prompt invisibly.
*   *Example Hidden Context:* "User is currently on Page: Invoice Details. Invoice ID: INV-2024-099. Status: Overdue. Customer: Acme Corp."

### B. Local RAG (The "How does accounting work" context)
We don't need a cloud vector database. We can use local browser-based vector search (e.g., **Orama** or local **SQLite + pgvector**).
*   **SOP Embedding:** We pre-embed documentation, accounting principles (e.g., GAAP rules for depreciation), and ERP navigation workflows.
*   *Workflow:* When a user asks "How do I write off this invoice?", the system searches the local RAG, pulls the exact workflow instructions, and feeds it to the local SLM to answer.

---

## 4. Execution Workflow (Human-in-the-Loop)
Because financial data is critical, the AI **never writes directly to the database**. It uses a pattern called the **"Ghost UI" (Draft & Approve)**.

1. **User Request:** "Pay 50% of this overdue invoice."
2. **AI Reasoning:** The model recognizes the intent and decides to call the `create_payment_allocation` tool.
3. **JSON Output:** The model outputs an invisible payload:
   ```json
   {
     "tool": "open_payment_modal",
     "arguments": {
       "invoice_id": "INV-2024-099",
       "amount": 2500.00,
       "account": "cash"
     }
   }
   ```
4. **App Interception:** The React app intercepts this JSON (it does not show it in the chat).
5. **Ghost UI / Confirmation:** The app opens the standard Payment Modal in the UI, **pre-filled** with the AI's suggestions. The chat says: *"I've prepared the payment for $2,500. Please review and confirm below."*
6. **User Execution:** The user reviews the modal and clicks the standard "Save & Post" button.

### Why this is perfect:
*   The AI doesn't need database access keys.
*   The user is strictly responsible for the final ledger entry.
*   You leverage your existing React forms and Zod validation logic. If the AI makes a mistake, your standard form validation catches it before it hits the database.

---

## 5. Phased Integration Plan

**Phase 1: The Navigational Copilot**
*   Implement WebLLM with a 2B model.
*   Give it tools to navigate the app (`navigate_to(route)`, `open_modal(name)`).
*   *User:* "I need to add a new supplier."
*   *AI:* Routes the app to `/vendors/new` and says "Here is the form."

**Phase 2: The Data Reader & RAG Expert**
*   Inject page context and local vector search.
*   *User:* "What is our standard depreciation method for laptops?"
*   *AI:* Reads the local RAG rules, sees the current fixed asset screen, and explains the rule.

**Phase 3: The Workflow Executor (Ghost UI)**
*   Give the AI access to pre-fill forms (Invoices, Journal Entries).
*   *User:* "Create a journal entry for $100 for office supplies paid from petty cash."
*   *AI:* Opens the `/transactions/journal` modal, pre-fills Debit: Office Supplies ($100), Credit: Petty Cash ($100), and waits for the user to hit Save.

---

## 6. Extreme Edge Optimization (Mobile & Embedded Systems)
Running a 2B+ model on a mobile device or POS terminal will cause thermal throttling and RAM exhaustion (OS OOM kills). To run AI safely on low-end hardware, we must apply extreme compression and architectural shifts:

### A. Sub-500M Parameter Models (TinyLLMs)
Instead of 2B-8B models, we use ultra-small models designed specifically for edge devices:
*   **SmolLM (135M or 360M):** A 135M parameter model, when quantized to 4-bit, takes **less than 100MB of RAM**.
*   **Qwen2.5-0.5B (500M):** Highly capable in multiple languages (including Arabic) while keeping a tiny footprint.

### B. 1.58-bit Quantization (The BitNet Era)
Standard models use 16-bit or 8-bit floating-point numbers. We apply **1.58-bit quantization (Ternary Weights)** where neural network weights are restricted to just three values: `-1, 0, or 1`.
*   **Why it prevents device burnout:** It eliminates heavy floating-point matrix multiplications. The CPU/GPU only has to perform simple integer addition. This drops energy consumption and RAM usage by 70-90%, keeping the phone cool and fast.

### C. Task-Specific Distillation (Don't memorize, just parse)
A 135M parameter model does not have enough parameters to "memorize" accounting rules. Instead, we use it **strictly as an intent parser**.
1.  **Fine-Tuning:** We fine-tune a TinyLLM specifically on the Mizan ERP JSON schemas.
2.  **The Shift:** We do not ask the model to reason about accounting. We use deterministic code for the accounting logic, and only use the AI to translate the user's natural language ("I want to return 2 items from the last order") into JSON (`{"action": "pos_return", "qty": 2}`).

### D. Fallback: Semantic Routing (Non-Generative AI)
For ultra-low-end embedded systems, skip generative LLMs entirely. Use a **Semantic Router** (e.g., FastText or MobileBERT). These take up only **5MB to 25MB** of storage. They simply classify the user's text into one of 50 pre-defined intents (e.g., `INTENT_NAVIGATE_INVOICE`) and use standard regex to extract numbers, completely bypassing heavy generation.
