import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:digit_components/utils/date_utils.dart';
import 'package:digit_data_model/utils/typedefs.dart'
    hide ProductVariantDataRepository;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:inventory_management/models/entities/stock.dart';
import 'package:inventory_management/models/entities/transaction_type.dart';
import 'package:inventory_management/utils/typedefs.dart'
    hide ProductVariantDataRepository;
import 'package:registration_delivery/models/entities/status.dart';
import 'package:registration_delivery/registration_delivery.dart';

import '../../data/repositories/custom_task.dart';
import '../../models/distribution_summary_data_model.dart';
import '../../utils/constants.dart';
import '../../utils/environment_config.dart';

part 'custom_distribution_summary_report.freezed.dart';

typedef CustomDistributionSummaryReportEmitter
    = Emitter<CustomDistributionSummaryReportState>;

class CustomDistributionSummaryReportBloc extends Bloc<
    CustomDistributionSummaryReportEvent,
    CustomDistributionSummaryReportState> {
  final IndividualDataRepository individualRepository;

  final HouseholdDataRepository householdRepository;

  final TaskDataRepository taskRepository;

  final ProductVariantDataRepository productVariantRepository;

  final StockDataRepository stockDataRepository;

  final ProjectBeneficiaryDataRepository projectBeneficiaryRepository;

  CustomDistributionSummaryReportBloc({
    required this.individualRepository,
    required this.householdRepository,
    required this.taskRepository,
    required this.productVariantRepository,
    required this.stockDataRepository,
    required this.projectBeneficiaryRepository,
  }) : super(const CustomDistributionSummaryReportEmptyState()) {
    on(_handleLoadDataEvent);
    on(_handleLoadingEvent);
  }

  Future<void> _handleLoadDataEvent(
    CustomDistributionSummaryReportLoadDataEvent event,
    CustomDistributionSummaryReportEmitter emit,
  ) async {
    var userId = event.userId;

    Map<String, List<HouseholdModel>> dayVsHouseholdListMap = {};
    Map<String, List<TaskModel>> dayVsTaskListMap = {};
    Map<String, List<ProjectBeneficiaryModel>> dayVsProjectBeneficiaryListMap1 =
        {};
    Map<String, List<ProjectBeneficiaryModel>> dayVsProjectBeneficiaryListMap2 =
        {};

    Map<String, int> dateVsHouseholdCount = {};
    Map<String, int> dateVsChildrenTreatedCount1 = {};
    Map<String, int> dateVsChildrenTreatedCount2 = {};
    // Assuming each element has 'date' (String or DateTime) and 'quantity' (int or double)

    Map<String, double> dateVsDrugsReceivedCount = {};
    // Assuming each element has 'date' (String or DateTime) and 'quantity' (int or double)

    Map<String, double> dateVsDrugsUsedCount = {};
    // Assuming each element has 'date' (String or DateTime) and 'quantity' (int or double)

    Map<String, double> dateVsDrugsBalanceCount = {};

    Set<String> uniqueDates = {};

    Map<String, DistributionSummaryData> dateVsDistributionSummaryData = {};

    // get all the households consent yes or no both
    final householdList =
        await (householdRepository as HouseholdLocalRepository).search(
      HouseholdSearchModel(tenantId: envConfig.variables.tenantId),
      userId,
    );

    // filter yes consent households
    final consentYesHouseholds = getConsentYesHouseholds(householdList);

    // download all the successful task
    final successfulTaskList =
        await (taskRepository as CustomTaskLocalRepository).progressBarSearch(
      TaskSearchModel(
          tenantId: envConfig.variables.tenantId,
          status: Status.administeredSuccess.toValue()),
      userId,
    );

    // download all the redose task
    final redoseTaskList =
        await (taskRepository as CustomTaskLocalRepository).progressBarSearch(
      TaskSearchModel(
          tenantId: envConfig.variables.tenantId,
          status: Status.visited.toValue()),
      userId,
    );

    Set<String> projectBeneficiaryClientReferenceIds = successfulTaskList
        .map((e) => e.projectBeneficiaryClientReferenceId ?? "")
        .toSet()
        .where((element) => element.isNotEmpty)
        .toSet();

    // get all the successful pb based on the task created till now
    final successfulProjectBeneficiaryList = await (projectBeneficiaryRepository
            as ProjectBeneficiaryLocalRepository)
        .search(
      ProjectBeneficiarySearchModel(
          tenantId: envConfig.variables.tenantId,
          clientReferenceId: projectBeneficiaryClientReferenceIds.toList()),
    );

// Fetching the stock received transactions details
    final receivedStocks = (await stockDataRepository.search(
      StockSearchModel(
        receiverId: [userId],
        transactionType: [TransactionType.received.toValue()],
      ),
    ))
        .where(
          (element) =>
              element.clientAuditDetails != null &&
              element.clientAuditDetails?.createdBy == userId,
        )
        .toList();

    for (var stock in receivedStocks) {
      var dateKey = DigitDateUtils.getDateFromTimestamp(
        stock.dateOfEntry ?? stock.clientAuditDetails!.createdTime,
      ); // Replace 'date' with the actual field name in your data model.
      final quantity = double.parse(stock.quantity ??
          '0'); // Replace 'quantity' with the actual field name.

      // Accumulate the quantity for the same date
      dateVsDrugsReceivedCount[dateKey] =
          (dateVsDrugsReceivedCount[dateKey] ?? 0) + quantity;
    }

    for (var element in consentYesHouseholds) {
      var dateKey = DigitDateUtils.getDateFromTimestamp(
        element.clientAuditDetails!.createdTime,
      );
      dayVsHouseholdListMap.putIfAbsent(dateKey, () => []).add(element);
    }

    for (var element in successfulTaskList) {
      var dateKey = DigitDateUtils.getDateFromTimestamp(
        element.clientAuditDetails!.createdTime,
      );
      dayVsTaskListMap.putIfAbsent(dateKey, () => []).add(element);
    }

    for (var element in successfulProjectBeneficiaryList) {
      var dateKey = DigitDateUtils.getDateFromTimestamp(
        element.clientAuditDetails!.createdTime,
      );
      var productVariantId =
          productVariantKeyFromBeneficiaryModel(element, successfulTaskList);
      if (productVariantId == Constants.productVariantId1) {
        dayVsProjectBeneficiaryListMap1
            .putIfAbsent(dateKey, () => [])
            .add(element);
      } else {
        dayVsProjectBeneficiaryListMap2
            .putIfAbsent(dateKey, () => [])
            .add(element);
      }
    }

    uniqueDates.addAll(dayVsProjectBeneficiaryListMap1.keys.toSet());
    uniqueDates.addAll(dayVsProjectBeneficiaryListMap2.keys.toSet());
    uniqueDates.addAll(dayVsHouseholdListMap.keys.toSet());
    uniqueDates.addAll(dayVsTaskListMap.keys.toSet());
    uniqueDates.addAll(dateVsDrugsReceivedCount.keys.toSet());

    // populate the day vs count for that day map
    populateDateVsCountMap(dayVsHouseholdListMap, dateVsHouseholdCount);
    // populate the day vs count for that day map
    populateDateVsCountMap(
        dayVsProjectBeneficiaryListMap1, dateVsChildrenTreatedCount1);

    populateDateVsCountMap(
        dayVsProjectBeneficiaryListMap2, dateVsChildrenTreatedCount2);

    // calculate stock used by date
    calculateStockUsedByDate(
        dateVsDrugsUsedCount, successfulTaskList, redoseTaskList);

    // calculate stock balance by date
    //Assumption received dates are before or same as used and balance dates
    calculateStockBalanceByDate(dateVsDrugsUsedCount, dateVsDrugsReceivedCount,
        dateVsDrugsBalanceCount, uniqueDates);

    // populate the final distribution summary data
    popoulateDateVsEntityCountMap(
      dateVsHouseholdCount,
      dateVsChildrenTreatedCount1,
      dateVsChildrenTreatedCount2,
      dateVsDrugsReceivedCount,
      dateVsDrugsUsedCount,
      dateVsDrugsBalanceCount,
      uniqueDates,
      dateVsDistributionSummaryData,
    );

    emit(CustomDistributionSummaryReportSummaryDataState(
      summaryData: SplayTreeMap<String, DistributionSummaryData>.from(
        dateVsDistributionSummaryData,
        (a, b) => b.compareTo(a),
      ),
    ));
  }

  String? productVariantKeyFromBeneficiaryModel(
      ProjectBeneficiaryModel element, List<TaskModel> successfulTaskList) {
    var clientReferenceId = element.clientReferenceId;
    TaskModel? tasks = successfulTaskList
        .where(
            (e) => e.projectBeneficiaryClientReferenceId == clientReferenceId)
        .firstOrNull;
    if (tasks == null) return null;
    var productVariantId = tasks.resources
        ?.firstWhereOrNull((e) => e.productVariantId != null)
        ?.productVariantId;
    return productVariantId;
  }

  void calculateStockUsedByDate(Map<String, double> dateVsDrugsUsedCount,
      List<TaskModel> successfulTaskList, List<TaskModel> redoseTaskList) {
    // successfulTaskList.addAll(redoseTaskList);
    List<TaskModel> totalTasks = [];
    if (successfulTaskList.isEmpty) {
      totalTasks.addAll(redoseTaskList);
    } else if (redoseTaskList.isEmpty) {
      totalTasks.addAll(successfulTaskList);
    } else {
      totalTasks.addAll(successfulTaskList);
      totalTasks.addAll(redoseTaskList);
    }
    for (var task in totalTasks) {
      double stockUsed = getQuantityFromTask(task);

      var dateKey = DigitDateUtils.getDateFromTimestamp(
        task.clientAuditDetails!.createdTime,
      );
      if (dateVsDrugsUsedCount.containsKey(dateKey) &&
          dateVsDrugsUsedCount[dateKey] != null) {
        double stockUsedTillNow = dateVsDrugsUsedCount[dateKey]!;
        stockUsedTillNow = stockUsedTillNow + stockUsed;
        dateVsDrugsUsedCount[dateKey] = stockUsedTillNow;
      } else {
        dateVsDrugsUsedCount[dateKey] = stockUsed;
      }
    }
  }

  void calculateStockBalanceByDate(
    Map<String, double> dateVsDrugsUsedCount,
    Map<String, double> dateVsDrugsReceivedCount,
    Map<String, double> dateVsDrugsBalanceCount,
    Set<String> uniqueDates,
  ) {
    // Sort dates in ascending order
    final sortedDates = uniqueDates.toList()..sort();

    double previousBalance = 0.0;

    for (var date in sortedDates) {
      double received = dateVsDrugsReceivedCount[date] ?? 0.0;
      double used = dateVsDrugsUsedCount[date] ?? 0.0;

      double currentBalance = previousBalance + received - used;

      dateVsDrugsBalanceCount[date] = currentBalance;
      previousBalance = currentBalance;
    }
  }

  double getQuantityFromTask(TaskModel task) {
    final quantity = resourceDistributed(task.resources);
    return quantity;
  }

  double resourceDistributed(List<TaskResourceModel>? taskResources) {
    double resourceDistributed = 0;
    RegExp intPattern = RegExp(r'^\d+$');
    RegExp doublePattern = RegExp(r'^\d+\.\d+$');
    if (taskResources != null) {
      for (var resource in taskResources) {
        // Info quantity is string type as per model
        String quantity = resource.quantity ?? "0";
        try {
          if (intPattern.hasMatch(quantity)) {
            resourceDistributed = resourceDistributed + int.parse(quantity);
          } else if (doublePattern.hasMatch(quantity)) {
            //info will round the decimal and convert to int
            double parsedQuantity = double.parse(quantity);
            if (parsedQuantity.isNaN ||
                parsedQuantity.isInfinite ||
                parsedQuantity.isNegative) {
              continue;
            } else {
              int correctedQuantity = parsedQuantity.ceil();
              resourceDistributed = resourceDistributed + correctedQuantity;
            }
          } else {
            continue;
          }
        } catch (e) {
          continue;
        }
      }
    }
    return resourceDistributed;
  }

  dynamic getTheCorrespondingTask(
      HouseholdModel household,
      List<TaskModel> taskList,
      List<ProjectBeneficiaryModel> projectBeneficiaries) {
    final projectBeneficiary = projectBeneficiaries
        .where((element) =>
            element.beneficiaryClientReferenceId == household.clientReferenceId)
        .firstOrNull;
    if (projectBeneficiary == null) {
      return null;
    }
    final task = taskList
        .where((element) =>
            element.projectBeneficiaryClientReferenceId ==
            projectBeneficiary.clientReferenceId)
        .firstOrNull;
    if (task == null) {
      return null;
    }
    return task;
  }

  void populateDateVsCountMap(
      Map<String, List> map, Map<String, int> dateVsCount) {
    map.forEach((key, value) {
      dateVsCount[key] = value.length;
    });
  }

  List<HouseholdModel> getConsentYesHouseholds(
      List<HouseholdModel> households) {
    final consentYesHouseholds = households.where((household) {
      final isConsentGiven = household.additionalFields?.fields
          .firstWhereOrNull((h) => h.key == Constants.headConsent)
          ?.value;

      return isConsentGiven == null
          ? false
          : isConsentGiven == "true"
              ? true
              : false;
    }).toList();

    return consentYesHouseholds;
  }

  void getDrugsVsQuantityMap(
    List<TaskModel> taskList,
    String date,
    Map<String, Map<String?, dynamic>> dayVsDrugsQuantityMap,
  ) {
    Map<String?, double> resourceVsQuantity = {};
    List<TaskResourceModel> taskResourceList = [];

    for (var task in taskList) {
      if (task.resources == null) {
        continue;
      }
      taskResourceList.addAll(task.resources!.toList());
    }
    for (var resource in taskResourceList) {
      double quantityDistributed = 0;
      double quantityRedosed = 0;

      var resourceId = resource.productVariantId;
      quantityDistributed = quantityDistributed +
          (resource.quantity!.toString().contains(".")
              ? double.parse((resource.quantity ?? "0.0").toString()).toInt()
              : int.parse((resource.quantity ?? "0").toString()));
      if (resource.additionalFields != null) {
        var value = resource.additionalFields!.fields
            .firstWhereOrNull(
              (element) => element.key == Constants.reDoseQuantityKey,
            )
            ?.value;
        quantityRedosed = quantityRedosed +
            (value == null || value == "null"
                ? 0
                : (value.toString().contains(".")
                    ? double.parse(value.toString()).toInt()
                    : int.parse(value.toString())));
      }
      final quantityUsed = quantityDistributed + quantityRedosed;

      resourceVsQuantity.update(
        resourceId,
        (existingValue) => existingValue + quantityUsed,
        ifAbsent: () => quantityUsed,
      );
    }
    dayVsDrugsQuantityMap[date] = resourceVsQuantity;
  }

  void popoulateDateVsEntityCountMap(
    Map<String, int> dateVsHouseholdCount,
    Map<String, int> dateVsChildrenTreatedCount1,
    Map<String, int> dateVsChildrenTreatedCount2,
    Map<String, double> dateVsDrugsReceivedCount,
    Map<String, double> dateVsDrugsUsedCount,
    Map<String, double> dateVsDrugsBalanceCount,
    Set<String> uniqueDates,
    Map<String, DistributionSummaryData> dateVsDistributionSummaryData,
  ) {
    for (var date in uniqueDates) {
      var householdCount = 0;
      var childrenTreatedCount1 = 0;
      var childrenTreatedCount2 = 0;
      var drugsReceivedCount = 0.0;
      var drugsUsedCount = 0.0;
      var drugsBalanceCount = 0.0;

      if (dateVsHouseholdCount.containsKey(date) &&
          dateVsHouseholdCount[date] != null) {
        householdCount = dateVsHouseholdCount[date]!;
      }
      if (dateVsChildrenTreatedCount1.containsKey(date) &&
          dateVsChildrenTreatedCount1[date] != null) {
        childrenTreatedCount1 = dateVsChildrenTreatedCount1[date]!;
      }
      if (dateVsChildrenTreatedCount2.containsKey(date) &&
          dateVsChildrenTreatedCount2[date] != null) {
        childrenTreatedCount2 = dateVsChildrenTreatedCount2[date]!;
      }
      if (dateVsDrugsUsedCount.containsKey(date) &&
          dateVsDrugsUsedCount[date] != null) {
        drugsUsedCount = dateVsDrugsUsedCount[date]!;
      }
      if (dateVsDrugsReceivedCount.containsKey(date) &&
          dateVsDrugsReceivedCount[date] != null) {
        drugsReceivedCount = dateVsDrugsReceivedCount[date]!;
      }
      if (dateVsDrugsBalanceCount.containsKey(date) &&
          dateVsDrugsBalanceCount[date] != null) {
        drugsBalanceCount = dateVsDrugsBalanceCount[date]!;
      }

      final childrenTreatedPercentage =
          ((childrenTreatedCount1 + childrenTreatedCount2) /
                  Constants.dailyTarget) *
              100;

      DistributionSummaryData distributionSummaryData = DistributionSummaryData(
        householdRegisteredCount: householdCount,
        childrenTreatedCount1: childrenTreatedCount1,
        childrenTreatedCount2: childrenTreatedCount2,
        childrenTreatedPercentageCount:
            double.tryParse(childrenTreatedPercentage.toStringAsFixed(2)) ?? 0,
        drugsUsed: drugsUsedCount,
        drugsReceived: drugsReceivedCount,
        drugsBalance: drugsBalanceCount,
      );

      dateVsDistributionSummaryData[date] = distributionSummaryData;
    }
  }

  Future<void> _handleLoadingEvent(
    CustomDistributionSummaryReportLoadingEvent event,
    CustomDistributionSummaryReportEmitter emit,
  ) async {
    emit(const CustomDistributionSummaryReportLoadingState());
  }
}

@freezed
class CustomDistributionSummaryReportEvent
    with _$CustomDistributionSummaryReportEvent {
  const factory CustomDistributionSummaryReportEvent.loadData({
    required String userId,
  }) = CustomDistributionSummaryReportLoadDataEvent;

  const factory CustomDistributionSummaryReportEvent.loading() =
      CustomDistributionSummaryReportLoadingEvent;
}

@freezed
class CustomDistributionSummaryReportState
    with _$CustomDistributionSummaryReportState {
  const factory CustomDistributionSummaryReportState.loading() =
      CustomDistributionSummaryReportLoadingState;
  const factory CustomDistributionSummaryReportState.empty() =
      CustomDistributionSummaryReportEmptyState;

  const factory CustomDistributionSummaryReportState.summaryData({
    @Default({}) Map<String, DistributionSummaryData> summaryData,
  }) = CustomDistributionSummaryReportSummaryDataState;
}
