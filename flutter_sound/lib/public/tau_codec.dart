/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0), as published by
 * the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

/// Flutter Sound Input nodes
/// {@category Main}
library node;

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_player_platform_interface.dart';
import 'package:logger/logger.dart' show Level, Logger;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import '../../flutter_sound.dart';



enum AudioFormat
{
  ogg,
  caf,
  webm,
  adts,
  mp4,
  wav,
  aiff,
  raw,
  mp3,
  flac,
  nb,
  wb,
}

enum Endianness
{
  littleEndian,
  bigEndian,
}

enum Depth
{
  int16,
  int8,
  flt32,
}

enum NbChannels
{
  mono,
  stereo,
}

/// A TauCodec is an object specifying the codec itself and the file format
abstract class TauCodec {

  AudioFormat? audioFormat;
  @deprecated Codec deprecatedCodec = Codec.defaultCodec;
  TauCodec()
  {
  }
}


class DefaultCodec  extends TauCodec {
  /* ctor */ DefaultCodec() {
    deprecatedCodec = Codec.defaultCodec;
  }
}

class Opus extends TauCodec {
  /* ctor */ Opus(AudioFormat audioFormat,) {
    this.audioFormat = audioFormat;
    switch (audioFormat)
    {
      case AudioFormat.ogg: deprecatedCodec = Codec.opusOGG; break;
      case AudioFormat.caf: deprecatedCodec = Codec.opusCAF; break;
      case AudioFormat.webm: deprecatedCodec = Codec.opusWebM; break;
      default: throw Exception ('Bad Audio Format');
    }
  }
}

class Vorbis extends TauCodec {
  /* ctor */ Vorbis(AudioFormat audioFormat,) {
    this.audioFormat = audioFormat;
    switch (audioFormat)
    {
      case AudioFormat.ogg: deprecatedCodec = Codec.vorbisOGG; break;
      case AudioFormat.webm: deprecatedCodec = Codec.vorbisWebM; break;
      default: throw Exception ('Bad Audio Format');
    }
  }
}

class Mp3  extends TauCodec {
  /* ctor */ Mp3() {
    deprecatedCodec = Codec.mp3;
    audioFormat = AudioFormat.mp3;
  }
}


class Aac extends TauCodec {
  /* ctor */ Aac(AudioFormat audioFormat,) {
    this.audioFormat = audioFormat;
    switch (audioFormat)
    {
      case AudioFormat.adts: deprecatedCodec = Codec.aacADTS; break;
      case AudioFormat.mp4: deprecatedCodec = Codec.aacMP4; break;
      default: throw Exception ('Bad Audio Format');
    }
  }
}


class Flac  extends TauCodec {
  /* ctor */ Mp3() {
    deprecatedCodec = Codec.flac;
    audioFormat = AudioFormat.flac;
  }
}

class Pcm extends TauCodec {
  Endianness endianness;
  Depth depth;
  NbChannels nbChannels;
  int sampleRate;

  /* ctor */ Pcm(AudioFormat audioFormat,{
    required this.depth,
    required this.endianness,
    required this.nbChannels,
    required this.sampleRate,
  })
  {
    this.audioFormat = audioFormat;
    switch (audioFormat)
    {
      case AudioFormat.wav: deprecatedCodec = Codec.pcm16WAV; break;
      case AudioFormat.aiff: deprecatedCodec = Codec.pcm16AIFF; break;
      case AudioFormat.webm:  deprecatedCodec = Codec.pcmWebM; break;
      case AudioFormat.caf:  deprecatedCodec = Codec.pcm16CAF; break;
      case AudioFormat.raw: deprecatedCodec = Codec.pcm16; break;
      default: throw Exception ('Bad Audio Format');
    }
  }
  int nbrChannels() => (nbChannels == NbChannels.mono) ? 1 : 2;
  int nDepth() {
    switch (depth)
    {
      case Depth.int16: return 16;
      case Depth.int8: return 8;
      case Depth.flt32: return 32;
    }
  }

}


class Amr extends TauCodec
{
  /* ctor */ Amr(AudioFormat audioFormat) {
    this.audioFormat = audioFormat;
    switch (audioFormat)
    {
      case AudioFormat.nb: deprecatedCodec = Codec.amrNB; break;
      case AudioFormat.wb: deprecatedCodec = Codec.amrWB; break;
    }
  }

}

/// Get the new API9 TauCodec from the old API6 Codec
@deprecated
TauCodec getCodecFromDeprecated(Codec codec)
{
  TauCodec r = DefaultCodec();
  switch (codec)
  {
    case Codec.defaultCodec: r = DefaultCodec(); break;
    case Codec.aacADTS: r = Aac(AudioFormat.adts); break;
    case Codec.opusOGG: r = Opus(AudioFormat.ogg); break;
    case Codec.opusCAF: r = Opus(AudioFormat.caf); break;
    case Codec.mp3: r = Mp3(); break;
    case Codec.vorbisOGG: r = Vorbis(AudioFormat.ogg); break;
    case Codec.pcm16: r = Pcm(AudioFormat.raw, depth: Depth.int16, endianness: Endianness.littleEndian, nbChannels: NbChannels.mono, sampleRate: 44100,); break;
    case Codec.pcm16WAV: r = Pcm(AudioFormat.wav, depth: Depth.int16, endianness: Endianness.littleEndian, nbChannels: NbChannels.mono, sampleRate: 44100,); break;
    case Codec.pcm16AIFF: r = Pcm(AudioFormat.aiff, depth: Depth.int16, endianness: Endianness.littleEndian, nbChannels: NbChannels.mono, sampleRate: 44100,); break;
    case Codec.pcm16CAF: r = Pcm(AudioFormat.caf, depth: Depth.int16, endianness: Endianness.littleEndian, nbChannels: NbChannels.mono, sampleRate: 44100,); break;
    case Codec.flac: r = Flac(); break;
    case Codec.aacMP4: r = Aac(AudioFormat.mp4); break;
    case Codec.amrNB: Amr(AudioFormat.nb); break;
    case Codec.amrWB: Amr(AudioFormat.wb); break;
    case Codec.pcm8: r = Pcm(AudioFormat.raw, depth: Depth.int8, endianness: Endianness.littleEndian, nbChannels: NbChannels.mono, sampleRate: 44100,); break;
    case Codec.pcmFloat32: r = Pcm(AudioFormat.raw, depth: Depth.flt32, endianness: Endianness.littleEndian, nbChannels: NbChannels.mono, sampleRate: 44100,); break;
    case Codec.pcmWebM: r = Pcm(AudioFormat.webm, depth: Depth.int16, endianness: Endianness.littleEndian, nbChannels: NbChannels.mono, sampleRate: 44100,); break;
    case Codec.opusWebM: r = Opus(AudioFormat.webm); break;
    case Codec.vorbisWebM: r = Vorbis(AudioFormat.webm); break;
  }
  return r;
}
