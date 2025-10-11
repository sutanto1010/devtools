import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'json_formatter_event.dart';
import 'json_formatter_state.dart';

class JsonFormatterBloc extends Bloc<JsonFormatterEvent, JsonFormatterState> {
  JsonFormatterBloc() : super(const JsonFormatterInitial()) {
    on<FormatJsonEvent>(_onFormatJson);
    on<MinifyJsonEvent>(_onMinifyJson);
    on<ClearAllEvent>(_onClearAll);
    on<PasteFromClipboardEvent>(_onPasteFromClipboard);
    on<CopyToClipboardEvent>(_onCopyToClipboard);
    on<LoadSampleJsonEvent>(_onLoadSampleJson);
    on<ToggleFullscreenEvent>(_onToggleFullscreen);
    on<UpdateInputEvent>(_onUpdateInput);
  }

  void _onFormatJson(FormatJsonEvent event, Emitter<JsonFormatterState> emit) {
    try {
      final input = event.input.trim();
      if (input.isEmpty) {
        emit(JsonFormatterError(
          inputText: event.input,
          errorMessage: 'Please enter JSON to format',
        ));
        return;
      }

      final jsonObject = jsonDecode(input);
      const encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(jsonObject);

      emit(_getCurrentState().copyWith(
        inputText: input,
        outputText: formattedJson,
        errorMessage: '',
      ));
    } catch (e) {
      emit(JsonFormatterError(
        inputText: event.input,
        errorMessage: 'Invalid JSON: ${e.toString()}',
      ));
    }
  }

  void _onMinifyJson(MinifyJsonEvent event, Emitter<JsonFormatterState> emit) {
    try {
      final input = event.input.trim();
      if (input.isEmpty) {
        emit(JsonFormatterError(
          inputText: event.input,
          errorMessage: 'Please enter JSON to minify',
        ));
        return;
      }

      final jsonObject = jsonDecode(input);
      final minifiedJson = jsonEncode(jsonObject);

      emit(_getCurrentState().copyWith(
        inputText: input,
        outputText: minifiedJson,
        errorMessage: '',
      ));
    } catch (e) {
      emit(JsonFormatterError(
        inputText: event.input,
        errorMessage: 'Invalid JSON: ${e.toString()}',
      ));
    }
  }

  void _onClearAll(ClearAllEvent event, Emitter<JsonFormatterState> emit) {
    emit(_getCurrentState().copyWith(
      inputText: '',
      outputText: '',
      errorMessage: '',
    ));
  }

  void _onPasteFromClipboard(PasteFromClipboardEvent event, Emitter<JsonFormatterState> emit) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        emit(_getCurrentState().copyWith(
          inputText: clipboardData.text!,
          errorMessage: '',
        ));
      } else {
        emit(JsonFormatterError(
          inputText: _getCurrentState().inputText,
          errorMessage: 'Clipboard is empty',
        ));
      }
    } catch (e) {
      emit(JsonFormatterError(
        inputText: _getCurrentState().inputText,
        errorMessage: 'Failed to paste from clipboard',
      ));
    }
  }

  void _onCopyToClipboard(CopyToClipboardEvent event, Emitter<JsonFormatterState> emit) async {
    if (event.output.isEmpty) {
      emit(JsonFormatterError(
        inputText: _getCurrentState().inputText,
        errorMessage: 'No formatted JSON to copy',
      ));
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: event.output));
      emit(JsonFormatterClipboardSuccess(
        inputText: _getCurrentState().inputText,
        outputText: _getCurrentState().outputText,
        message: 'Copied to clipboard successfully',
      ));
    } catch (e) {
      emit(JsonFormatterError(
        inputText: _getCurrentState().inputText,
        errorMessage: 'Failed to copy to clipboard',
      ));
    }
  }

  void _onLoadSampleJson(LoadSampleJsonEvent event, Emitter<JsonFormatterState> emit) {
    const sampleJson = '{"name":"John Doe","age":30,"email":"john.doe@example.com","address":{"street":"123 Main St","city":"New York","state":"NY","zipCode":"10001"},"phoneNumbers":[{"type":"home","number":"212-555-1234"},{"type":"work","number":"646-555-5678"}],"isActive":true,"balance":2543.75,"tags":["developer","team-lead","remote"],"metadata":{"lastLogin":"2024-01-15T08:30:00Z","preferences":{"theme":"dark","notifications":true}}}';
    
    emit(_getCurrentState().copyWith(
      inputText: sampleJson,
      outputText: '',
      errorMessage: '',
    ));
  }

  void _onToggleFullscreen(ToggleFullscreenEvent event, Emitter<JsonFormatterState> emit) {
    if (event.isInput) {
      emit(_getCurrentState().copyWith(
        isFullscreenInput: !_getCurrentState().isFullscreenInput,
      ));
    } else {
      emit(_getCurrentState().copyWith(
        isFullscreenOutput: !_getCurrentState().isFullscreenOutput,
      ));
    }
  }

  void _onUpdateInput(UpdateInputEvent event, Emitter<JsonFormatterState> emit) {
    emit(_getCurrentState().copyWith(
      inputText: event.input,
      errorMessage: '',
    ));
  }

  JsonFormatterLoaded _getCurrentState() {
    if (state is JsonFormatterLoaded) {
      return state as JsonFormatterLoaded;
    }
    return const JsonFormatterLoaded();
  }
}