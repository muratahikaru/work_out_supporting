import 'dart:math';

import 'package:vector_math/vector_math.dart';

enum KeyPointPart {
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

const _poseNetIndices = {
  5: KeyPointPart.leftShoulder,
  6: KeyPointPart.rightShoulder,
  7: KeyPointPart.leftElbow,
  8: KeyPointPart.rightElbow,
  9: KeyPointPart.leftWrist,
  10: KeyPointPart.rightWrist,
  11: KeyPointPart.leftHip,
  12: KeyPointPart.rightHip,
  13: KeyPointPart.leftKnee,
  14: KeyPointPart.rightKnee,
  15: KeyPointPart.leftAnkle,
  16: KeyPointPart.rightAnkle,
};

class KeyPoint {
  final KeyPointPart part;
  final Vector2 vec;
  final double score;
  const KeyPoint(this.part, this.vec, this.score);
}

class KeyPoints {
  final Map<KeyPointPart, KeyPoint> _points;

  KeyPoints.fromPoseNet(dynamic cognition) : _points = {} {
    _poseNetIndices.forEach((key, part) {
      var v = cognition["keypoints"]?[key];
      if (v != null) {
        _points[part] = KeyPoint(part, Vector2(v["x"], v["y"]), v["score"]);
      }
    });
  }

  @override
  String toString() {
    return _points.toString();
  }

  List<KeyPoint> get points => _points.values.toList();

  double get score {
    if (_points.isEmpty) {
      return 0;
    }
    var sum = _points.entries
        .map((e) => e.value.score)
        .reduce((value, element) => value + element);
    return sum / _points.length;
  }

  Vector2? get leftHip => _points[KeyPointPart.leftHip]?.vec;

  // ダンベルフライ部位
  Vector2? get rightShoulder => _points[KeyPointPart.rightShoulder]?.vec;
  Vector2? get leftShoulder => _points[KeyPointPart.leftShoulder]?.vec;
  Vector2? get rightElbow => _points[KeyPointPart.rightElbow]?.vec;
  Vector2? get leftElbow => _points[KeyPointPart.leftElbow]?.vec;
  Vector2? get rightWrist => _points[KeyPointPart.rightWrist]?.vec;
  Vector2? get leftWrist => _points[KeyPointPart.leftWrist]?.vec;

  double? get leftKneeAngle {
    final hip = _points[KeyPointPart.leftHip]?.vec;
    final knee = _points[KeyPointPart.leftKnee]?.vec;
    final ankle = _points[KeyPointPart.leftAnkle]?.vec;
    if (hip == null || knee == null || ankle == null) {
      return null;
    }
    return (hip - knee).angleTo(ankle - knee);
  }

  double? get rightKneeAngle {
    final hip = _points[KeyPointPart.rightHip]?.vec;
    final knee = _points[KeyPointPart.rightKnee]?.vec;
    final ankle = _points[KeyPointPart.rightAnkle]?.vec;
    if (hip == null || knee == null || ankle == null) {
      return null;
    }
    return (hip - knee).angleTo(ankle - knee);
  }

  // ダンベルフライ部位角度
  double? get leftElbowAngle {
    final shoulder = _points[KeyPointPart.leftShoulder]?.vec;
    final elbow = _points[KeyPointPart.leftElbow]?.vec;
    final wrist = _points[KeyPointPart.leftWrist]?.vec;

    if(shoulder == null || elbow == null || wrist == null) {
      return null;
    }
    return (shoulder - elbow).angleTo(wrist - elbow);
  }

  double? get rightElbowAngle {
    final shoulder = _points[KeyPointPart.rightShoulder]?.vec;
    final elbow = _points[KeyPointPart.rightElbow]?.vec;
    final wrist = _points[KeyPointPart.rightWrist]?.vec;

    if(shoulder == null || elbow == null || wrist == null) {
      return null;
    }
    return (shoulder - elbow).angleTo(wrist - elbow);
  }

  double? get leftShoulderToWristAngle {
    final wrist = _points[KeyPointPart.leftWrist]?.vec;
    final leftShoulder = _points[KeyPointPart.leftShoulder]?.vec;
    final rightShoulder = _points[KeyPointPart.rightShoulder]?.vec;

    if (wrist == null || leftShoulder == null || rightShoulder == null) {
      return null;
    }

    return (wrist - leftShoulder).angleTo(rightShoulder - leftShoulder);
  }

  double? get rightShoulderToWristAngle {
    final wrist = _points[KeyPointPart.rightWrist]?.vec;
    final rightShoulder = _points[KeyPointPart.rightShoulder]?.vec;
    final leftShoulder = _points[KeyPointPart.leftShoulder]?.vec;

    if (wrist == null || rightShoulder == null || leftShoulder == null) {
      return null;
    }

    return (wrist - rightShoulder).angleTo(leftShoulder - rightShoulder);
  }

}

const _bufferSize = 30;

class SquatKeyPointsSeries {
  final List<DateTime> timestamps;
  final List<KeyPoints> keyPoints;
  final List<double> kneeAngles;

  const SquatKeyPointsSeries(this.timestamps, this.keyPoints, this.kneeAngles);

  const SquatKeyPointsSeries.init()
      : timestamps = const [],
        keyPoints = const [],
        kneeAngles = const [];

  SquatKeyPointsSeries push(DateTime timestamp, KeyPoints kp) {
    if (kp.leftHip == null || kp.leftKneeAngle == null) {
      return this;
    }

    final timestamps = [timestamp, ...this.timestamps];
    final keyPoints = [kp, ...this.keyPoints];
    if (keyPoints.length == 1) {
      return SquatKeyPointsSeries(timestamps, keyPoints, [kp.leftKneeAngle!]);
    }

    const k = 0.7;
    final kneeAngles = [
      this.kneeAngles.first * (1 - k) + kp.leftKneeAngle! * k,
      ...this.kneeAngles,
    ];
    return SquatKeyPointsSeries(
      timestamps.length > _bufferSize
          ? timestamps.sublist(0, _bufferSize - 1)
          : timestamps,
      keyPoints.length > _bufferSize
          ? keyPoints.sublist(0, _bufferSize - 1)
          : keyPoints,
      kneeAngles.length > _bufferSize
          ? kneeAngles.sublist(0, _bufferSize - 1)
          : kneeAngles,
    );
  }

  double get kneeAngleSpeed {
    // kneeとankle,kneeとhipの角度の変化
    // radian / sec
    if (kneeAngles.length < 2) {
      return 0;
    }
    final dt = timestamps[0].difference(timestamps[1]);
    return (kneeAngles[0] - kneeAngles[1]) /
        (dt.inMicroseconds.toDouble() / 1000000);
  }

  List<double> get kneeAngleSpeeds {
    // radian / sec
    if (kneeAngles.length < 2) {
      return [];
    }
    return List<double>.generate(kneeAngles.length - 1, (i) {
      final dt = timestamps[i].difference(timestamps[i + 1]);
      return (kneeAngles[i] - kneeAngles[i + 1]) /
          (dt.inMicroseconds.toDouble() / 1000000);
    });
  }

  bool get isStanding {
    return kneeAngleSpeed > 2.0;
  }

  bool get isUnderParallel {
    // radian
    // 1.74444 → 約100度
    return kneeAngles.first < (pi * 10 / 18);
  }
}

class DumbbellFlyKeyPointsSeries {
  final List<DateTime> timestamps;
  final List<KeyPoints> keyPoints;
  final List<double> rightElbowAngles;
  final List<double> leftElbowAngles;
  final List<double> rightShoulderToWristAngles;
  final List<double> leftShoulderToWristAngles;

  const DumbbellFlyKeyPointsSeries(this.timestamps, this.keyPoints, this.rightElbowAngles, this.leftElbowAngles, this.rightShoulderToWristAngles, this.leftShoulderToWristAngles);

  const DumbbellFlyKeyPointsSeries.init()
    : timestamps = const [],
      keyPoints = const [],
      rightElbowAngles = const [],
      leftElbowAngles = const [],
      rightShoulderToWristAngles = const [],
      leftShoulderToWristAngles = const [];

  DumbbellFlyKeyPointsSeries push(DateTime timestamp, KeyPoints kp) {
    if (kp.rightShoulder == null ||
        kp.leftShoulder == null ||
        kp.rightElbow == null ||
        kp.leftElbow == null ||
        kp.rightWrist == null ||
        kp.leftWrist == null
    ) {
      return this;
    }

    final timestamps = [timestamp, ...this.timestamps];
    final keyPoints = [kp, ...this.keyPoints];

    if (keyPoints.length == 1) {
      return DumbbellFlyKeyPointsSeries(timestamps, keyPoints, [kp.rightElbowAngle!], [kp.leftElbowAngle!], [kp.rightShoulderToWristAngle!], [kp.leftShoulderToWristAngle!]);
    }

    // 移動平均
    const k = 0.7;
    final rightElbowAngles = [
      this.rightElbowAngles.first * (1 - k) + kp.rightElbowAngle! * k,
      ...this.rightElbowAngles,
    ];
    final leftElbowAngles = [
      this.leftElbowAngles.first * (1 - k) + kp.leftElbowAngle! * k,
      ...this.leftElbowAngles,
    ];
    final rightShoulderToWristAngles = [
      this.rightShoulderToWristAngles.first * (1 - k) + kp.rightShoulderToWristAngle! * k,
      ...this.rightShoulderToWristAngles,
    ];
    final leftShoulderToWristAngles = [
      this.leftShoulderToWristAngles.first * (1 - k) + kp.leftShoulderToWristAngle! * k,
      ...this.leftShoulderToWristAngles,
    ];

    return DumbbellFlyKeyPointsSeries(
      timestamps.length > _bufferSize
          ? timestamps.sublist(0, _bufferSize - 1)
          : timestamps,
      keyPoints.length > _bufferSize
          ? keyPoints.sublist(0, _bufferSize - 1)
          : keyPoints,
      rightElbowAngles.length > _bufferSize
          ? rightElbowAngles.sublist(0, _bufferSize - 1)
          : rightElbowAngles,
      leftElbowAngles.length > _bufferSize
          ? leftElbowAngles.sublist(0, _bufferSize - 1)
          : leftElbowAngles,
      rightShoulderToWristAngles.length > _bufferSize
          ? rightShoulderToWristAngles.sublist(0, _bufferSize - 1)
          :rightShoulderToWristAngles,
      leftShoulderToWristAngles.length > _bufferSize
          ? leftShoulderToWristAngles.sublist(0, _bufferSize - 1)
          : leftShoulderToWristAngles
    );
  }

  double get rightShoulderToWristAngleSpeed {
    if (rightShoulderToWristAngles.length < 2) {
      return 0;
    }
    final dt = timestamps[0].difference(timestamps[1]);
    return (rightShoulderToWristAngles[0] - rightShoulderToWristAngles[1]) /
        (dt.inMicroseconds.toDouble() / 1000000);
  }

  double get leftShoulderToWristAngleSpeed {
    if (leftShoulderToWristAngles.length < 2) {
      return 0;
    }
    final dt = timestamps[0].difference(timestamps[1]);
    return (leftShoulderToWristAngles[0] - leftShoulderToWristAngles[1]) /
        (dt.inMicroseconds.toDouble() / 1000000);
  }

  bool get isStartPosition {
    //125度より小さい
    return (rightShoulderToWristAngles.first < 2.182) && (leftShoulderToWristAngles.first < 2.186);
  }

  bool get isObtuseAngle {
    // 100度以上120度以下
    return (rightElbowAngles.first >= 1.745 ) && (rightShoulderToWristAngles.first <= 2.094) && (leftShoulderToWristAngles.first >= 1.745) &&  (leftShoulderToWristAngles.first <= 2.094);
  }

  bool get isUnderParallel {
    // 175度より大きい
    return (rightShoulderToWristAngles.first > 3.054) && (leftShoulderToWristAngles.first > 3.054);
  }

}