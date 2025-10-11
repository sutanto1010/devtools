import 'package:equatable/equatable.dart';

abstract class JsonFormatterState extends Equatable {
  const JsonFormatterState();

  @override
  List<Object?> get props => [];
}

class JsonFormatterInitial extends JsonFormatterState {
  const JsonFormatterInitial();
}

class JsonFormatterLoaded extends JsonFormatterState {
  final String inputText;
  final String outputText;
  final String errorMessage;
  final bool isFullscreenInput;
  final bool isFullscreenOutput;
  final bool isLoading;

  const JsonFormatterLoaded({
    this.inputText = '',
    this.outputText = '',
    this.errorMessage = '',
    this.isFullscreenInput = false,
    this.isFullscreenOutput = false,
    this.isLoading = false,
  });

  JsonFormatterLoaded copyWith({
    String? inputText,
    String? outputText,
    String? errorMessage,
    bool? isFullscreenInput,
    bool? isFullscreenOutput,
    bool? isLoading,
  }) {
    return JsonFormatterLoaded(
      inputText: inputText ?? this.inputText,
      outputText: outputText ?? this.outputText,
      errorMessage: errorMessage ?? this.errorMessage,
      isFullscreenInput: isFullscreenInput ?? this.isFullscreenInput,
      isFullscreenOutput: isFullscreenOutput ?? this.isFullscreenOutput,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        inputText,
        outputText,
        errorMessage,
        isFullscreenInput,
        isFullscreenOutput,
        isLoading,
      ];
}

class JsonFormatterSuccess extends JsonFormatterState {
  final String inputText;
  final String outputText;
  final bool isFullscreenInput;
  final bool isFullscreenOutput;

  const JsonFormatterSuccess({
    required this.inputText,
    required this.outputText,
    this.isFullscreenInput = false,
    this.isFullscreenOutput = false,
  });

  @override
  List<Object?> get props => [
        inputText,
        outputText,
        isFullscreenInput,
        isFullscreenOutput,
      ];
}

class JsonFormatterError extends JsonFormatterState {
  final String inputText;
  final String errorMessage;
  final bool isFullscreenInput;
  final bool isFullscreenOutput;

  const JsonFormatterError({
    required this.inputText,
    required this.errorMessage,
    this.isFullscreenInput = false,
    this.isFullscreenOutput = false,
  });

  @override
  List<Object?> get props => [
        inputText,
        errorMessage,
        isFullscreenInput,
        isFullscreenOutput,
      ];
}

class JsonFormatterClipboardSuccess extends JsonFormatterState {
  final String inputText;
  final String outputText;
  final String message;
  final bool isFullscreenInput;
  final bool isFullscreenOutput;

  const JsonFormatterClipboardSuccess({
    required this.inputText,
    required this.outputText,
    required this.message,
    this.isFullscreenInput = false,
    this.isFullscreenOutput = false,
  });

  @override
  List<Object?> get props => [
        inputText,
        outputText,
        message,
        isFullscreenInput,
        isFullscreenOutput,
      ];
}