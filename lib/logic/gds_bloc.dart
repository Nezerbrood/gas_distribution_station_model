import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';
import 'package:gas_distribution_station_model/models/gds_element_type.dart';
import 'package:meta/meta.dart';

part 'gds_event.dart';

part 'gds_state.dart';

class GdsPageBloc extends Bloc<GdsEvent, GdsState> {
  GraphPipeline? graph;
  GraphEdge? _selectedElement;
  Map<Offset, List<GraphPoint>> magneticGrid = {};

  GraphPoint? _mag(GraphPoint point) {
    double MAGNETIC_RANGE = 1;
    for (GraphPoint otherPoint in graph!.points.values.toList()) {
      if (point != otherPoint &&
          (point.position.dx - otherPoint.position.dx).abs() <=
              MAGNETIC_RANGE &&
          (point.position.dy - otherPoint.position.dy).abs() <=
              MAGNETIC_RANGE) {
        point.position = otherPoint.position;
        graph!.mergePoints(point, otherPoint);
        return otherPoint;
      }
    }
  }

  GdsPageBloc() : super(GdsInitial()) {
    on<AddEdgeButtonPressGdsEvent>((event, emit) {
      _addNewEdge(event.throughputFlow);
      emit(GdsMainState(graph!, _selectedElement));
    });
    on<CalculateFlowButtonPressGdsEvent>((event, emit) {
      graph!.distributeFlow();
      emit(GdsMainState(graph!, _selectedElement));
    });
    on<GdsSelectElementEvent>((event, emit) {
      if (_selectedElement == event.element)
        _selectedElement = null;
      else {
        _selectedElement = event.element;
      }
      emit(GdsMainState(graph!, _selectedElement));
    });
    on<GdsDeselectElementEvent>((event, emit) {
      _selectedElement = null;
      emit(GdsMainState(graph!, _selectedElement));
    });
    on<GdsElementMoveEvent>((event, emit) {
      _selectedElement!.p1.position += event
          .p1; //Offset(_selectedElement!.p1.dx+event.p1.dx,_selectedElement!.p1.dy+event.p1.dy);
      _selectedElement!.p2.position += event
          .p2; // Offset(_selectedElement!.p2.dx+event.p2.dx,_selectedElement!.p2.dy+event.p2.dy);
      emit(GdsMainState(graph!, _selectedElement));
    });
    on<GdsPointMoveEvent>((event, emit) {
      GraphPoint p = graph!.points[event.pointId]!;
      p.position += event.delta;
      GraphPoint? otherPoint = _mag(p);
      otherPoint != null ? graph!.mergePoints(p, otherPoint) : 0;
      emit(GdsMainState(graph!, _selectedElement));
    });

    graph = GraphPipeline();
    graph!.addPoint(
        isSource: true, sourceFlow: 100, position: const Offset(100, 0));
    graph!.addPoint(position: Offset(100, 100));
    graph!.addPoint(position: Offset(100, 200));
    //_graph!.addPoint();
    graph!.addPoint(isSink: true, position: Offset(100, 300));

    graph!.link(graph!.points[1]!, graph!.points[2]!, 100);
    graph!.link(graph!.points[2]!, graph!.points[3]!, 100);
    graph!.link(graph!.points[3]!, graph!.points[4]!, 100);

    emit(GdsMainState(graph!, _selectedElement));
  }

  void _addNewEdge(double throughputFlow) {
    var p1 = graph!.addPoint(position: Offset(300, 300));
    var p2 = graph!.addPoint(position: Offset(300, 400));
    graph!.link(p1, p2, throughputFlow);
  }
}
