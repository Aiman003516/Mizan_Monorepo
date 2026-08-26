# Local AI/TinyML Research Notes

Date: 2026-08-26

Google’s official LiteRT documentation describes LiteRT as an on-device framework for ML and GenAI deployment, with a workflow of obtaining/converting a model, optimizing it, and running it on an edge accelerator or CPU. Source: https://developers.google.com/edge/litert

Google’s official model-optimization guidance states that post-training float16 quantization requires no data and can reduce model size by up to 50%; dynamic-range quantization requires no data and can reduce size by up to 75%; full integer quantization needs an unlabelled representative sample; and quantization-aware training needs labelled data. It also notes that quantization can reduce size and latency but may introduce accuracy loss, especially for aggressive int8-style compression. Source: https://developers.google.com/edge/litert/conversion/tensorflow/quantization/model_optimization

Implication for Mizan: start with a small classifier/extractor and post-training dynamic-range or int8 evaluation using synthetic/anonymized accounting examples. Do not use quantization or a local model as an accounting authority. Validate the actual Samsung Note9 device for memory, latency, heat, battery, Arabic/English structured-output accuracy, and zero-network behavior in local-only mode. Full local language-model deployment remains the final phase.
