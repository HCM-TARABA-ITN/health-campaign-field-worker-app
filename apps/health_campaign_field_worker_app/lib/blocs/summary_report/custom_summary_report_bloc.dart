import 'dart:async';

import 'package:collection/collection.dart';
import 'package:digit_ui_components/utils/date_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:registration_delivery/models/entities/household.dart';
import 'package:registration_delivery/models/entities/task.dart';
import 'package:registration_delivery/utils/typedefs.dart';
import 'package:registration_delivery/utils/utils.dart';

import '../../models/entities/status.dart';
import '../../utils/constants.dart';

part 'custom_summary_report_bloc.freezed.dart';

typedef SummaryReportEmitter = Emitter<SummaryReportState>;

class SummaryReportBloc extends Bloc<SummaryReportEvent, SummaryReportState> {
  final HouseholdDataRepository householdRepository;
  final TaskDataRepository taskDataRepository;

  SummaryReportBloc({
    required this.householdRepository,
    required this.taskDataRepository,
  }) : super(const SummaryReportEmptyState()) {
    on<SummaryReportLoadDataEvent>(_handleLoadDataEvent);
    on<SummaryReportLoadingEvent>(_handleLoadingEvent);
  }

  Future<void> _handleLoadDataEvent(
    SummaryReportLoadDataEvent event,
    SummaryReportEmitter emit,
  ) async {
    emit(const SummaryReportLoadingState());

    List<HouseholdModel> householdListData = [];
    List<TaskModel> taskListData = [];
    List<TaskModel> administeredSuccessTaskList = [];
    final currentCycle =
        RegistrationDeliverySingleton().projectType?.cycles?.firstWhere(
              (e) =>
                  (e.startDate) < DateTime.now().millisecondsSinceEpoch &&
                  (e.endDate) > DateTime.now().millisecondsSinceEpoch,
            );
    final currentUserUuId =
        RegistrationDeliverySingleton().loggedInUserUuid ?? '';
    householdListData =
        await (householdRepository).search(HouseholdSearchModel());
    taskListData = await (taskDataRepository).search(TaskSearchModel());
    final householdList = currentCycle == null
        ? householdListData
        : householdListData.where((household) {
            final createdTime = household.auditDetails?.createdTime ?? 0;
            final createdBy = household.auditDetails?.createdBy;
            if (createdBy == null) return false;
            if (createdBy.isEmpty) return false;
            return createdTime >= currentCycle.startDate &&
                createdTime <= currentCycle.endDate &&
                createdBy == currentUserUuId;
          }).toList();
    final taskList = currentCycle == null
        ? taskListData
        : taskListData.where((task) {
            final createdTime = task.auditDetails?.createdTime ?? 0;
            final createdBy = task.auditDetails?.createdBy;
            if (createdBy == null) return false;
            if (createdBy.isEmpty) return false;
            return createdTime >= currentCycle.startDate &&
                createdTime <= currentCycle.endDate &&
                createdBy == currentUserUuId;
          }).toList();
    for (var element in taskList) {
      if (element.status == null) continue;
      final status = StatusMapper.fromValue(element.status);

      if (status == Status.administrationSuccess ||
          status == Status.administeredSuccess) {
        administeredSuccessTaskList.add(element);
      }
    }

    final groupedEntries = administeredSuccessTaskList.groupListsBy(
      (element) => element.projectBeneficiaryClientReferenceId,
    );
    // Keep only the latest task (by createdTime) from each group
    administeredSuccessTaskList = groupedEntries.values.map((tasks) {
      tasks.sort(
        (a, b) => (b.auditDetails?.createdTime ?? 0)
            .compareTo(a.auditDetails?.createdTime ?? 0),
      );
      return tasks.first; // most recent one
    }).toList();

    Map<String, List<HouseholdModel>> dateVsHouseholdsList = {};
    Map<String, List<TaskModel>> dateVsAdministeredSuccessTaskList = {};
    Set<String> uniqueDates = {};
    Map<String, int> dateVsHouseholdsCount = {};
    Map<String, int> dateVsHouseholdMembersCount = {};
    Map<String, int> dateVsAdministeredSuccessTaskCount = {};
    Map<String, int> dateVsBednetDistributedCount = {};
    Map<String, Map<String, int>> dateVsEntityVsCountMap = {};

    for (var element in householdList) {
      var dateKey = DigitDateUtils.getDateFromTimestamp(
          element.clientAuditDetails!.createdTime);
      if (element.clientAuditDetails!.createdTime >= currentCycle!.startDate &&
          element.clientAuditDetails!.createdTime <= currentCycle.endDate &&
          element.clientAuditDetails!.createdBy == currentUserUuId) {
        dateVsHouseholdsList.putIfAbsent(dateKey, () => []).add(element);
      }
    }

    for (var element in administeredSuccessTaskList) {
      var dateKey = DigitDateUtils.getDateFromTimestamp(
          element.clientAuditDetails!.createdTime);
      if (element.clientAuditDetails!.createdTime >= currentCycle!.startDate &&
          element.clientAuditDetails!.createdTime <= currentCycle.endDate &&
          element.clientAuditDetails!.createdBy == currentUserUuId) {
        dateVsAdministeredSuccessTaskList
            .putIfAbsent(dateKey, () => [])
            .add(element);
      }
    }

    // get a set of unique dates
    getUniqueSetOfDates(
      dateVsHouseholdsList,
      dateVsAdministeredSuccessTaskList,
      uniqueDates,
    );

    // populate the day vs count for that day map
    populateDateVsCountMap(dateVsHouseholdsList, dateVsHouseholdsCount);
    populateDateVsCountMapForMembers(
        dateVsHouseholdsList, dateVsHouseholdMembersCount);
    populateDateVsCountMap(
        dateVsAdministeredSuccessTaskList, dateVsAdministeredSuccessTaskCount);
    populateDateVsCountMapForBednets(
        dateVsAdministeredSuccessTaskList, dateVsBednetDistributedCount);

    popoulateDateVsEntityCountMap(
      dateVsEntityVsCountMap,
      dateVsHouseholdsCount,
      dateVsHouseholdMembersCount,
      dateVsAdministeredSuccessTaskCount,
      dateVsBednetDistributedCount,
      uniqueDates,
    );
    dateVsEntityVsCountMap =
        sortMapByDateKeyAndRenameDate(dateVsEntityVsCountMap);
    dateVsEntityVsCountMap = addTotalEntryToMap(dateVsEntityVsCountMap);

    emit(SummaryReportDataState(data: dateVsEntityVsCountMap));
  }

  void getUniqueSetOfDates(
    Map<String, List<HouseholdModel>> dateVsHouseholdsList,
    Map<String, List<TaskModel>> dateVsAdministeredSuccessTaskList,
    Set<String> uniqueDates,
  ) {
    uniqueDates.addAll(dateVsHouseholdsList.keys.toSet());
    uniqueDates.addAll(dateVsAdministeredSuccessTaskList.keys.toSet());
  }

  void populateDateVsCountMap(
      Map<String, List> map, Map<String, int> dateVsCount) {
    map.forEach((key, value) {
      dateVsCount[key] = value.length;
    });
  }

  void populateDateVsCountMapForMembers(
      Map<String, List<HouseholdModel>> map, Map<String, int> dateVsCount) {
    map.forEach((key, value) {
      int totalMemberCount = 0;
      for (var household in value) {
        totalMemberCount += household.memberCount ?? 0;
      }
      dateVsCount[key] = totalMemberCount;
    });
  }

  void populateDateVsCountMapForBednets(
      Map<String, List<TaskModel>> map, Map<String, int> dateVsCount) {
    map.forEach((key, value) {
      int totalBednetsDistributed = 0;
      for (var task in value) {
        final qtyStr = task.resources?.first.quantity?.toString() ?? '0';
        final qty = double.tryParse(qtyStr)?.toInt() ?? 0;
        totalBednetsDistributed += qty;
      }
      dateVsCount[key] = totalBednetsDistributed;
    });
  }

  void popoulateDateVsEntityCountMap(
    Map<String, Map<String, int>> dateVsEntityVsCountMap,
    Map<String, int> dateVsHouseholdsCount,
    Map<String, int> dateVsHouseholdMembersCount,
    Map<String, int> dateVsAdministeredSuccessTaskCount,
    Map<String, int> dateVsBednetDistributedCount,
    Set<String> uniqueDates,
  ) {
    for (var date in uniqueDates) {
      Map<String, int> elementVsCount = {};
      if (dateVsHouseholdsCount.containsKey(date) &&
          dateVsHouseholdsCount[date] != null) {
        var count = dateVsHouseholdsCount[date];
        elementVsCount[Constants.registeredHouseholds] = count ?? 0;
      }
      if (dateVsHouseholdMembersCount.containsKey(date) &&
          dateVsHouseholdMembersCount[date] != null) {
        var count = dateVsHouseholdMembersCount[date];
        elementVsCount[Constants.householdMembers] = count ?? 0;
      }
      if (dateVsAdministeredSuccessTaskCount.containsKey(date) &&
          dateVsAdministeredSuccessTaskCount[date] != null) {
        var count = dateVsAdministeredSuccessTaskCount[date];
        elementVsCount[Constants.tokensRedeemed] = count ?? 0;
      }
      if (dateVsBednetDistributedCount.containsKey(date) &&
          dateVsBednetDistributedCount[date] != null) {
        var count = dateVsBednetDistributedCount[date];
        elementVsCount[Constants.bednetsDistributed] = count ?? 0;
      }

      dateVsEntityVsCountMap[date] = elementVsCount;
    }
  }

  Map<String, Map<String, int>> sortMapByDateKeyAndRenameDate(
    Map<String, Map<String, int>> dateVsEntityVsCountMap,
  ) {
    final sortedEntries = dateVsEntityVsCountMap.entries.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(_toIsoFormat(a.key));
        final dateB = DateTime.parse(_toIsoFormat(b.key));
        return dateA.compareTo(dateB);
      });

    final Map<String, Map<String, int>> renamedMap = {};

    for (int i = sortedEntries.length - 1; i >= 0; i--) {
      final originalDate = sortedEntries[i].key;

      final parsedDate = DateFormat('dd/MM/yyyy').parse(originalDate);
      final formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);

      final newKey = formattedDate; // '$originalDate Day${i + 1}'
      renamedMap[newKey] = sortedEntries[i].value;
    }

    return renamedMap;
  }

  Map<String, Map<String, int>> addTotalEntryToMap(
      Map<String, Map<String, int>> originalMap) {
    final Map<String, int> totalMap = {};

    for (final dayEntry in originalMap.entries) {
      final dayData = dayEntry.value;
      for (final entry in dayData.entries) {
        totalMap.update(entry.key, (value) => value + entry.value,
            ifAbsent: () => entry.value);
      }
    }

    // Create new map with 'Total' at the end
    final Map<String, Map<String, int>> newMap = {
      ...originalMap,
      'Total': totalMap,
    };

    return newMap;
  }

  /// Converts 'dd/MM/yyyy' to 'yyyy-MM-dd' for proper DateTime parsing
  String _toIsoFormat(String dateStr) {
    final parts = dateStr.split('/');
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Future<void> _handleLoadingEvent(
    SummaryReportLoadingEvent event,
    SummaryReportEmitter emit,
  ) async {
    emit(const SummaryReportLoadingState());
  }
}

@freezed
class SummaryReportEvent with _$SummaryReportEvent {
  const factory SummaryReportEvent.loadSummaryData({
    required String userId,
  }) = SummaryReportLoadDataEvent;

  const factory SummaryReportEvent.loading() = SummaryReportLoadingEvent;
}

@freezed
class SummaryReportState with _$SummaryReportState {
  const factory SummaryReportState.loading() = SummaryReportLoadingState;
  const factory SummaryReportState.empty() = SummaryReportEmptyState;

  const factory SummaryReportState.data({
    @Default({}) Map<String, Map<String, int>> data,
  }) = SummaryReportDataState;
}
