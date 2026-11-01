// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// This file is for testings that require a `LiveTestWidgetsFlutterBinding`
void main() {
  final binding = LiveTestWidgetsFlutterBinding();
  testWidgets('Widgets are built within the current test zone (test 1 of 2)', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/113885
    Zone? buildZone;
    final Zone bodyZone = Zone.current;
    await tester.pumpWidget(
      TestWidgetsApp(
        home: Builder(
          builder: (BuildContext context) {
            buildZone = Zone.current;
            return const Text('Test 1');
          },
        ),
      ),
    );
    expect(buildZone, equals(bodyZone));
  });

  testWidgets('Widgets are built within the current test zone (test 2 of 2)', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/113885
    Zone? buildZone;
    final Zone bodyZone = Zone.current;
    await tester.pumpWidget(
      TestWidgetsApp(
        home: Builder(
          builder: (BuildContext context) {
            buildZone = Zone.current;
            return const Text('Test 2');
          },
        ),
      ),
    );
    expect(buildZone, equals(bodyZone));
  });

  testWidgets('Frame callbacks and pointer events run in current test zone (test 1 of 2)', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/113885
    Zone? frameCallbackZone;
    Zone? postFrameCallbackZone;
    Zone? gestureZone;
    final Zone bodyZone = Zone.current;

    tester.binding.scheduleFrameCallback((Duration timeStamp) {
      frameCallbackZone = Zone.current;
    });
    tester.binding.addPostFrameCallback((Duration timeStamp) {
      postFrameCallbackZone = Zone.current;
    });

    await tester.pumpWidget(
      TestWidgetsApp(
        home: GestureDetector(
          onTap: () {
            gestureZone = Zone.current;
          },
          child: const Text('Tap target 1'),
        ),
      ),
    );

    await tester.tap(find.text('Tap target 1'));
    await tester.pump();

    expect(frameCallbackZone, equals(bodyZone));
    expect(postFrameCallbackZone, equals(bodyZone));
    expect(gestureZone, equals(bodyZone));
  });

  testWidgets('Frame callbacks and pointer events run in current test zone (test 2 of 2)', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/113885
    Zone? frameCallbackZone;
    Zone? postFrameCallbackZone;
    Zone? gestureZone;
    final Zone bodyZone = Zone.current;

    tester.binding.scheduleFrameCallback((Duration timeStamp) {
      frameCallbackZone = Zone.current;
    });
    tester.binding.addPostFrameCallback((Duration timeStamp) {
      postFrameCallbackZone = Zone.current;
    });

    await tester.pumpWidget(
      TestWidgetsApp(
        home: GestureDetector(
          onTap: () {
            gestureZone = Zone.current;
          },
          child: const Text('Tap target 2'),
        ),
      ),
    );

    await tester.tap(find.text('Tap target 2'));
    await tester.pump();

    expect(frameCallbackZone, equals(bodyZone));
    expect(postFrameCallbackZone, equals(bodyZone));
    expect(gestureZone, equals(bodyZone));
  });

  testWidgets(
    'Teardown callbacks and frame callbacks in teardown run in current test zone (test 1 of 2)',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/113885
      final Zone bodyZone = Zone.current;
      addTearDown(() async {
        Zone? teardownBuildZone;
        await tester.pumpWidget(
          TestWidgetsApp(
            home: Builder(
              builder: (BuildContext context) {
                teardownBuildZone = Zone.current;
                return const Text('Teardown 1');
              },
            ),
          ),
        );
        expect(teardownBuildZone, equals(bodyZone));
      });
    },
  );

  testWidgets(
    'Teardown callbacks and frame callbacks in teardown run in current test zone (test 2 of 2)',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/113885
      final Zone bodyZone = Zone.current;
      addTearDown(() async {
        Zone? teardownBuildZone;
        await tester.pumpWidget(
          TestWidgetsApp(
            home: Builder(
              builder: (BuildContext context) {
                teardownBuildZone = Zone.current;
                return const Text('Teardown 2');
              },
            ),
          ),
        );
        expect(teardownBuildZone, equals(bodyZone));
      });
    },
  );

  testWidgets('Input PointerAddedEvent', (WidgetTester tester) async {
    await tester.pumpWidget(const TestWidgetsApp(home: Text('Test')));
    await tester.pump();
    final TestGesture gesture = await tester.createGesture();
    // This mimics the start of a gesture as seen on a device, where inputs
    // starts with a PointerAddedEvent.
    await gesture.addPointer();
    // The expected result of the test is not to trigger any assert.
  });

  testWidgets('Input PointerHoverEvent', (WidgetTester tester) async {
    PointerHoverEvent? hoverEvent;
    await tester.pumpWidget(
      TestWidgetsApp(
        home: MouseRegion(
          child: const Text('Test'),
          onHover: (PointerHoverEvent event) {
            hoverEvent = event;
          },
        ),
      ),
    );
    await tester.pump();
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final Offset location = tester.getCenter(find.text('Test'));
    // for mouse input without a down event, moveTo generates a hover event
    await gesture.moveTo(location);
    expect(hoverEvent, isNotNull);
    expect(hoverEvent!.position, location);
  });

  testWidgets('hitTesting works when using setSurfaceSize', (WidgetTester tester) async {
    var invocations = 0;
    await tester.pumpWidget(
      TestWidgetsApp(
        home: GestureDetector(
          onTap: () {
            invocations++;
          },
          child: const Text('Test'),
        ),
      ),
    );

    await tester.tap(find.byType(Text));
    await tester.pump();
    expect(invocations, 1);

    await tester.binding.setSurfaceSize(const Size(200, 300));
    await tester.pump();
    await tester.tap(find.byType(Text));
    await tester.pump();
    expect(invocations, 2);

    await tester.binding.setSurfaceSize(null);
    await tester.pump();
    await tester.tap(find.byType(Text));
    await tester.pump();
    expect(invocations, 3);
  });

  testWidgets('setSurfaceSize works', (WidgetTester tester) async {
    addTearDown(binding.resetLayers);
    await tester.pumpWidget(const TestWidgetsApp(home: Center(child: Text('Test'))));

    final Size windowCenter = tester.view.physicalSize / tester.view.devicePixelRatio / 2;
    final double windowCenterX = windowCenter.width;
    final double windowCenterY = windowCenter.height;

    Offset widgetCenter = tester.getRect(find.byType(Text)).center;
    expect(widgetCenter.dx, windowCenterX);
    expect(widgetCenter.dy, windowCenterY);

    await tester.binding.setSurfaceSize(const Size(200, 300));
    await tester.pump();
    widgetCenter = tester.getRect(find.byType(Text)).center;
    expect(widgetCenter.dx, 100);
    expect(widgetCenter.dy, 150);

    await tester.binding.setSurfaceSize(null);
    await tester.pump();
    widgetCenter = tester.getRect(find.byType(Text)).center;
    expect(widgetCenter.dx, windowCenterX);
    expect(widgetCenter.dy, windowCenterY);
  });

  testWidgets("reassembleApplication doesn't get stuck", (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/79150

    await expectLater(tester.binding.reassembleApplication(), completes);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets(
    'shouldPropagateDevicePointerEvents can override events from ${TestBindingEventSource.device}',
    (WidgetTester tester) async {
      binding.shouldPropagateDevicePointerEvents = true;

      await tester.pumpWidget(_ShowNumTaps());

      final Offset position = tester.getCenter(find.text('0'));

      // Simulates a real device tap.
      //
      // `handlePointerEventForSource defaults to sending events using
      // TestBindingEventSource.device. This will not be forwarded to the actual
      // gesture handlers, unless `shouldPropagateDevicePointerEvents` is true.
      binding.handlePointerEventForSource(PointerDownEvent(position: position));
      binding.handlePointerEventForSource(PointerUpEvent(position: position));

      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      // Reset the value, otherwise the test will fail when it checks that this
      // has not been changed as an invariant.
      binding.shouldPropagateDevicePointerEvents = false;
    },
  );

  testWidgets('resetLayers resets configuration and replaces root layer', (
    WidgetTester tester,
  ) async {
    // Ensure cleanup. This statement is not part of the test.
    addTearDown(binding.resetLayers);

    final ViewConfiguration currentConfig = binding.renderView.configuration;
    await binding.setSurfaceSize(const Size(400, 400));
    binding.renderView.configuration = const ViewConfiguration(devicePixelRatio: 10.0);
    final Layer? currentRootLayer = binding.renderView.debugLayer;

    await binding.resetLayers(); // This statement is the testee.

    // Verify that all properties have been reset
    expect(
      binding.renderView.configuration.logicalConstraints,
      equals(currentConfig.logicalConstraints),
    );
    expect(
      binding.renderView.configuration.physicalConstraints,
      equals(currentConfig.physicalConstraints),
    );
    expect(
      binding.renderView.configuration.devicePixelRatio,
      equals(currentConfig.devicePixelRatio),
    );
    // Verify that root layer has been replaced
    expect(binding.renderView.debugLayer, isNot(same(currentRootLayer)));
  });

  testWidgets(
    'A pump called between skipped handleBeginFrame and handleDrawFrame draws a frame and does not hang subsequent pumps',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/194352
      var buildCount = 0;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            buildCount++;
            return const Placeholder();
          },
        ),
      );
      expect(buildCount, 1);

      // Schedule a frame without expecting a frame, so that LiveTestWidgetsFlutterBinding
      // skips handleBeginFrame.
      final FrameCallback originalOnBeginFrame = tester.binding.platformDispatcher.onBeginFrame!;
      final resumed = Completer<void>();
      tester.binding.platformDispatcher.onBeginFrame = (Duration timeStamp) {
        originalOnBeginFrame(timeStamp);
        // If the frame was skipped, schedulerPhase remains idle.
        if (tester.binding.schedulerPhase == SchedulerPhase.idle && !resumed.isCompleted) {
          tester.binding.platformDispatcher.onBeginFrame = originalOnBeginFrame;
          scheduleMicrotask(resumed.complete);
        }
      };
      tester.binding.platformDispatcher.scheduleFrame();

      await resumed.future;
      // At this moment, we are in a microtask between handleBeginFrame (which skipped
      // the frame) and handleDrawFrame.
      // Call pump: this pump must not complete until a frame is actually drawn.
      var frameDrawn = false;
      tester.binding.addPostFrameCallback((_) {
        frameDrawn = true;
      });

      await tester.pump();
      expect(frameDrawn, isTrue);

      // Verify that subsequent pumps do not hang.
      var subsequentFrameDrawn = false;
      tester.binding.addPostFrameCallback((_) {
        subsequentFrameDrawn = true;
      });
      await tester.pump().timeout(const Duration(seconds: 2));
      expect(subsequentFrameDrawn, isTrue);
    },
  );
}

/// A widget that shows the number of times it has been tapped.
class _ShowNumTaps extends StatefulWidget {
  @override
  _ShowNumTapsState createState() => _ShowNumTapsState();
}

class _ShowNumTapsState extends State<_ShowNumTaps> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _counter++;
        });
      },
      child: Directionality(textDirection: TextDirection.ltr, child: Text(_counter.toString())),
    );
  }
}
