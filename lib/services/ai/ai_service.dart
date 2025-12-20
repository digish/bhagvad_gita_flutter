import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'bert_tokenizer.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  Interpreter? _interpreter;
  BertTokenizer? _tokenizer;

  // Model Config
  static const String _modelPath = 'assets/mobile_assets/model.tflite';
  static const String _vocabPath = 'assets/mobile_assets/vocab.txt';
  static const int _maxLen = 128;
  static const int _outputSize = 384; // MiniLM-L12-v2 embedding dimension

  bool get isInitialized => _interpreter != null && _tokenizer != null;

  /// Initialize the Service (load model & vocab)
  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      // Load Vocab
      final vocabContent = await rootBundle.loadString(_vocabPath);
      _tokenizer = BertTokenizer.fromString(vocabContent, maxLen: _maxLen);
      print('AI Service: Tokenizer loaded.');

      // Load TFLite Model
      final options = InterpreterOptions()..threads = 2; // Tune based on device
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
      print('AI Service: Model loaded.');

      // DEBUG: Inspect Tensors
      print('--- TFLite Model Info ---');
      print('Input Tensors: ${_interpreter!.getInputTensors()}');
      print('Output Tensors: ${_interpreter!.getOutputTensors()}');

      // Warmup (Optional)
    } catch (e) {
      print('AI Service Error: Failed to initialize - $e');
    }
  }

  /// Generates the embedding vector for a given query string
  Future<List<double>> getQueryVector(String query) async {
    if (!isInitialized) {
      await initialize();
    }

    if (_tokenizer == null || _interpreter == null) {
      throw Exception('AI Service is not initialized');
    }

    // Tokenize
    final inputs = _tokenizer!.tokenize(query);
    var inputIds = inputs['inputIds']!;
    var attentionMask = inputs['attentionMask']!;

    // TFLite input ordering is tricky.
    // We will use named inputs if available, usually mapped by signature logic.
    // However, optimum-cli often exports with signatures like:
    // serving_default_input_ids:0, serving_default_attention_mask:0
    // Check debugging logs to confirm, but usually:
    // Index 0: input_ids
    // Index 1: attention_mask
    // Index 2: token_type_ids (sometimes missing)

    // Ensure all lists are of exact maxLen
    if (inputIds.length != _maxLen) {
      inputIds = List<int>.from(inputIds)
        ..addAll(List.filled(_maxLen - inputIds.length, 0));
    }
    if (attentionMask.length != _maxLen) {
      attentionMask = List<int>.from(attentionMask)
        ..addAll(List.filled(_maxLen - attentionMask.length, 0));
    }

    // IMPORTANT: Reshape to [1, maxLen]
    // And ensure types. Int32 or Int64?
    // Usually Int64 for PyTorch exports, but TFLite optimizes to Int32 often.
    // Let's rely on standard list but logging revealed "RangeError (length): Invalid value: Not in inclusive range 0..1: 2"
    // This typically means we are passing 3 inputs but model expects 2 (or vice versa),
    // OR we are accessing output index 2 when only 0 and 1 exist.

    // Let's try passing purely positional inputs based on common TFLite exports:
    // [1, 128], [1, 128], [1, 128]

    var input0 = [inputIds]; // [1, 128]
    var input1 = [attentionMask]; // [1, 128]
    var input2 = [List<int>.filled(_maxLen, 0)]; // [1, 128] token_type_ids

    // We must check input count from logs. Assuming 3 inputs for now.
    // But error "RangeError ... 2" suggests we accessed index 2 and it failed?
    // Maybe model only has 2 inputs (no token_type_ids)?

    // Safest bet: inspect _interpreter.getInputTensors().length dynamically
    final inputCount = _interpreter!.getInputTensors().length;
    List<Object> inputTensors = [];

    if (inputCount >= 1) inputTensors.add(input0);
    if (inputCount >= 2) inputTensors.add(input1);
    if (inputCount >= 3)
      inputTensors.add(input2); // Some XLM-R models don't use token_type_ids

    // OUTPUTS
    // We dynamically allocate buffers based on what the model claims it outputs.
    // This handles both [1, 384] (pooled) and [1, 128, 384] (sequence) models.
    final outputTensorsData = _interpreter!
        .getOutputTensors(); // Get tensor metadata
    final Map<int, Object> outputBuffers = {};

    for (int i = 0; i < outputTensorsData.length; i++) {
      final tensor = outputTensorsData[i];
      final shape = tensor.shape; // e.g. [1, 384] or [1, 128, 384]
      final int totalElements = shape.reduce((a, b) => a * b);

      // Allocate buffer
      // Reshape is an extension from tflite_flutter
      outputBuffers[i] = List.filled(totalElements, 0.0).reshape(shape);
    }

    // Run
    _interpreter!.runForMultipleInputs(inputTensors, outputBuffers);

    // Mean Pooling / Result Extraction Logic
    // We assume Output 0 is the one we want.
    final rawOutput = outputBuffers[0] as List;

    // Check dimensionality
    // If output is [1, 384] (already pooled), return it.
    // If output is [1, 128, 384], perform mean pooling.

    var outputVector = List<double>.filled(_outputSize, 0.0);

    // Case 1: [1, 384] -> list[0] is List<double> of length 384
    if (rawOutput.length == 1 &&
        rawOutput[0] is List &&
        (rawOutput[0] as List).length == _outputSize &&
        (rawOutput[0][0] is! List)) {
      final pooled = rawOutput[0] as List;
      for (int i = 0; i < _outputSize; i++) {
        outputVector[i] = (pooled[i] as num).toDouble();
      }
      return outputVector;
    }

    // Case 2: [1, 128, 384] -> rawOutput[0] is List (length 128), which contains List (length 384)
    if (rawOutput.length == 1 &&
        rawOutput[0] is List &&
        (rawOutput[0] as List).length == _maxLen) {
      final sequenceOutput = rawOutput[0] as List; // List of 128 lists

      // Sum using attention mask
      for (int i = 0; i < inputIds.length; i++) {
        if (attentionMask[i] == 1) {
          // Only valid tokens
          if (i < sequenceOutput.length) {
            final tokenVector = sequenceOutput[i] as List;
            for (int j = 0; j < _outputSize; j++) {
              outputVector[j] += (tokenVector[j] as num).toDouble();
            }
          }
        }
      }

      // Average
      int tokenCount = attentionMask.where((t) => t == 1).length;
      if (tokenCount > 0) {
        for (int j = 0; j < _outputSize; j++) {
          outputVector[j] /= tokenCount;
        }
      }
      return outputVector;
    }

    return outputVector;
  }

  void dispose() {
    _interpreter?.close();
  }
}
