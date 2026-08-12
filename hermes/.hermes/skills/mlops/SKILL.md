---
name: mlops
description: "Use when selecting, evaluating, downloading, serving, or inspecting machine-learning models and related ML infrastructure."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# MLOps Workflow

## Overview

Use this skill when the task is about the model lifecycle: finding a model, downloading it, evaluating it, serving it, or managing experiment metadata. This umbrella replaces a pile of tool-specific model helpers with one end-to-end ML operations guide.

## When to Use

- The user wants to compare models or benchmark a workflow
- You need to download or inspect model artifacts from a hub
- You need to serve, quantize, or run local inference
- You need to measure experiments or track model runs
- The task is about a specialized ML model component rather than a general codebase change

## Core MLOps Families

### Model discovery and artifact management
Use these when you need to find, download, inspect, or publish model artifacts.

### Inference and serving
Use these when you need to run models locally or behind an API, or when you need a serving stack tuned for throughput or latency.

- **llama.cpp / GGUF**: choose this for CPU/edge/single-user local inference, GGUF quantization, Hugging Face Hub GGUF discovery, and OpenAI-compatible lightweight local servers. Detailed archived recipe: `references/llama-cpp.md`.
- **vLLM**: choose this for high-throughput GPU serving, OpenAI-compatible production APIs, tensor parallelism, continuous batching, prefix caching, and AWQ/GPTQ/FP8 deployment. Detailed archived recipe: `references/serving-llms-vllm.md`.

### Evaluation and benchmarking
Use these when you need objective comparisons, benchmark runs, or experiment tracking.

- **lm-evaluation-harness**: choose this for standardized LLM benchmarks such as MMLU, GSM8K, HellaSwag, TruthfulQA, HumanEval, and checkpoint tracking. Detailed archived recipe: `references/evaluating-llms-harness.md`.
- **Weights & Biases**: choose this for experiment tracking, sweeps, artifacts, model registries, and run dashboards. Detailed archived recipe: `references/weights-and-biases.md`.

For vector database / embedding-search comparisons, use the reproducible benchmark pattern in `references/vector-db-benchmarking.md`: real application embeddings, exact-vs-indexed search, index build time, storage size, query-plan verification, and recall overlap against exact top-k.

For cloud/off-prem vector DB selection with fixed high-dimensional embeddings, use `references/vector-db-cloud-provider-selection.md`. It captures the OghmaNotes decision shape: Neon/Postgres as source of truth, Cloudflare Vectorize excluded when dimensions exceed its documented limit, and Qdrant Cloud/Pinecone/Weaviate/Zilliz tradeoffs.

For OghmaNotes specifically, also check `references/oghma-cloud-vector-db-4096.md`: Semyon is moving off-prem toward Cloudflare + Neon, wants to keep 4096-dim embeddings, and prefers a concise verdict/ranked shortlist rather than a long architecture essay. For OghmaNotes specifically, `references/oghma-qdrant-vector-benchmark.md` records the real 4096-dim Qdrant benchmark and the resulting architecture recommendation: keep Postgres canonical and make Qdrant/MariaDB a replaceable vector sidecar behind a `VectorStore` abstraction.

### Specialized model components
Use these when the task is about a particular model family or ML primitive rather than a full application.

- **AudioCraft / MusicGen / AudioGen**: choose this for text-to-music, text-to-sound, melody-conditioned generation, stereo generation, EnCodec, and AudioCraft-specific memory/performance pitfalls. Detailed archived recipe: `references/audiocraft-audio-generation.md`.
- **Segment Anything (SAM)**: choose this for zero-shot image segmentation, point/box prompts, automatic mask generation, ONNX export, and mask post-processing. Detailed archived recipe: `references/segment-anything-model.md`.

## Practical Workflow

1. Identify the lifecycle stage: discover, download, evaluate, serve, or track.
2. Choose the smallest tool that covers that stage.
3. Verify the artifact or server state before declaring success.
4. Keep model, dataset, and experiment metadata explicit so the result can be reproduced.

## Tool Choice Hints

- Use hub tooling for discovery and downloads.
- Use inference/serving tooling when the goal is live predictions or local endpoints.
- Use evaluation tooling when the goal is a comparative answer, not just a demo.
- Use experiment-tracking tooling when the goal is to compare runs over time.

## Reporting style for benchmark/architecture decisions

- Lead with the decision and a compact ranking before explaining tradeoffs.
- If Semyon signals the answer is too long (for example “not reading that wall of text”), switch to a terse summary: verdict, ranked options, and only the key numbers.
- Separate vector-backend performance from full app architecture. Say explicitly whether the recommendation is about the canonical relational DB, the derived vector index, or the full RAG path.

## Pitfalls

- Mixing model discovery with serving configuration and not verifying the final runtime
- Comparing models on anecdote instead of a measured benchmark
- For vector DB decisions, confusing relational database performance with vector-index compatibility; benchmark exact scan, indexed search, recall, and migration cost separately
- Forgetting to record the exact model, revision, or checkpoint used
- Treating a successful download as proof that the model actually runs in the intended stack

## Verification Checklist

- [ ] Lifecycle stage identified
- [ ] Correct MLOps tool chosen
- [ ] Model or experiment artifact verified
- [ ] Runtime or benchmark outcome confirmed
- [ ] Reproducibility details captured
