import 'dart:convert';

/// Deserialize the preferences file and return a map of key-value pairs.
///
/// The [file] parameter represents the preferences file to be deserialized.
/// It should be a [File] object.
///
/// The function reads the bytes from the file and iterates through them to
/// extract the key-value pairs. It uses a state machine to keep track of the
/// current state while parsing the bytes.
///
/// Returns a [Map] containing the deserialized key-value pairs, where the keys
/// are of type [String] and the values are of type [String].
Map<String, String> deserializePreferencesFile(file) {
  var bytes = file.readAsBytesSync();

  var values = <String, String>{};

  var index = 0;
  var state = State.none;
  var sizeHex = <int>[];
  var lastKey = '';
  while (index < bytes.length) {
    var byte = bytes[index++];
    var hex = byte.toRadixString(16).toUpperCase().padLeft(2, '0');

    if (state == State.none) {
      if (hex == '0A') {
        state = State.readKeyStart0A;
      }
      continue;
    }

    if (state == State.readKeyFinish) {
      if (hex == '12') {
        state = State.readValueStart12;
      }
      continue;
    }

    if (state == State.readKeyStart0A) {
      if (hex == '0A') {
        state = State.readKeySize0A;
        byte = bytes[index];
        hex = byte.toRadixString(16).toUpperCase().padLeft(2, '0');
        sizeHex.add(byte);
      }
      continue;
    }

    if (state == State.readValueStart12) {
      if (hex == '2A') {
        state = State.readValueSize2A;
      } else if (hex == '08') {
        state = State.readValuesSize08;
        // quick read of the boolean value
        var isTrue = bytes[index++] > 0;
        values[lastKey] = isTrue.toString();
        state = State.none;
        sizeHex = [];
      } else {
        sizeHex.add(byte);
      }
      continue;
    }

    if (state == State.readKeySize0A) {
      var size = _decodeLEB128(sizeHex);

      var contentBytes = <int>[];
      while (index < bytes.length && size > 0) {
        contentBytes.add(bytes[index++]);
        size--;
      }
      var content = utf8.decode(contentBytes);
      lastKey = content;

      sizeHex = [];
      state = State.readKeyFinish;
      continue;
    }

    if (state == State.readValueSize2A) {
      var isSizeOneByte = sizeHex.length == 1;
      var size = _decodeLEB128(sizeHex) - (isSizeOneByte ? 2 : 3);

      if (!isSizeOneByte) {
        index++;
      }

      var contentBytes = <int>[];
      while (index < bytes.length && size > 0) {
        contentBytes.add(bytes[index++]);
        size--;
      }
      var content = utf8.decode(contentBytes);
      values[lastKey] = content;
      _printValues(values);

      sizeHex = [];
      state = State.none;
      continue;
    }
  }

  return values;
}

/// Decodes a list of integers in Little-Endian Base 128 (LEB128) format.
/// Returns the decoded integer value.
int _decodeLEB128(List<int> sizeHex) {
  var index = 0;
  var result = 0;
  var shift = 0;
  while (index < sizeHex.length) {
    var byte = sizeHex[index++];
    result |= (byte & 0x7f) << shift;
    shift += 7;
    if ((0x80 & byte) == 0) {
      if (shift < 32 && (byte & 0x40) != 0) {
        return result | (~0 << shift);
      }
      return result;
    }
  }
  return result;
}

/// Prints the key-value pairs in the given map.
void _printValues(Map<String, String> values) {
  var strings = [];
  for (var entry in values.entries) {
    strings.add('"${entry.key}": "${entry.value}"');
  }
}

/// Represents the different states for parsing preferences.
enum State {
  none,
  readKeyStart0A, // key start
  readKeySize0A, // key size
  readKeyFinish,
  readValueStart12, // value start
  readValueSize2A, // value size for strings
  readValuesSize08, // value size for booleans
}
