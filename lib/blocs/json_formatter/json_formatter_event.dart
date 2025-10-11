import 'package:equatable/equatable.dart';

abstract class JsonFormatterEvent extends Equatable {
  const JsonFormatterEvent();

  @override
  List<Object?> get props => [];
}

class FormatJsonEvent extends JsonFormatterEvent {
  final String input;

  const FormatJsonEvent(this.input);

  @override
  List<Object?> get props => [input];
}

class MinifyJsonEvent extends JsonFormatterEvent {
  final String input;

  const MinifyJsonEvent(this.input);

  @override
  List<Object?> get props => [input];
}

class ClearAllEvent extends JsonFormatterEvent {
  const ClearAllEvent();
}

class PasteFromClipboardEvent extends JsonFormatterEvent {
  const PasteFromClipboardEvent();
}

class CopyToClipboardEvent extends JsonFormatterEvent {
  final String output;

  const CopyToClipboardEvent(this.output);

  @override
  List<Object?> get props => [output];
}

class LoadSampleJsonEvent extends JsonFormatterEvent {
  const LoadSampleJsonEvent();
}

class ToggleFullscreenEvent extends JsonFormatterEvent {
  final bool isInput;

  const ToggleFullscreenEvent(this.isInput);

  @override
  List<Object?> get props => [isInput];
}

class UpdateInputEvent extends JsonFormatterEvent {
  final String input;

  const UpdateInputEvent(this.input);

  @override
  List<Object?> get props => [input];
}