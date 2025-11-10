import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:inventory_management/models/entities/stock.dart';
import 'package:inventory_management/utils/utils.dart';
import 'package:inventory_management/widgets/localized.dart';
import 'package:logger/logger.dart';

import '../../data/repositories/local/inventory_management/custom_stock.dart';
import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/action_card/min_number_card.dart';
import '../../widgets/custom_back_navigation.dart';

@RoutePage()
class CustomMinNumberPage extends LocalizedStatefulWidget {
  final dynamic type;
  const CustomMinNumberPage({
    super.key,
    super.appLocalizations,
    required this.type,
  });

  @override
  State<CustomMinNumberPage> createState() => CustomMinNumberPageState();
}

class CustomMinNumberPageState extends LocalizedState<CustomMinNumberPage> {
  List<StockModel> stockList = [];

  @override
  void initState() {
    super.initState();
    loadLocalStockData();
    Logger().i(
        "Stock Type: ${widget.type == StockRecordEntryType.returned ? "RETURNED" : widget.type == StockRecordEntryType.receipt ? "RECEIVED" : "DISPATCHED"}");
  }

  Future<void> loadLocalStockData() async {
    final repository =
        context.read<LocalRepository<StockModel, StockSearchModel>>()
            as CustomStockLocalRepository;

    final result =
        await repository.search(StockSearchModel(), context.loggedInUserUuid);

    // Define correct values
    String? transactionType;
    String? transactionReason;

    if (widget.type == StockRecordEntryType.returned) {
      transactionType = 'RECEIVED';
      transactionReason = 'RETURNED';
    } else if (widget.type == StockRecordEntryType.receipt) {
      transactionType = 'RECEIVED';
      transactionReason = 'RECEIVED';
    } else if (widget.type == StockRecordEntryType.dispatch) {
      transactionType = 'DISPATCHED';
    } else if (widget.type == StockRecordEntryType.loss) {
      transactionType = 'DISPATCHED';
      transactionReason = 'LOST_IN_TRANSIT';
    } else if (widget.type == StockRecordEntryType.damaged) {
      transactionType = 'DISPATCHED';
      transactionReason = 'DAMAGED_IN_TRANSIT';
    }

    final filteredResult = result.where((stock) {
      return stock.transactionType == transactionType &&
          stock.transactionReason == transactionReason;
    }).toList();

    Logger().i("Filtered Stock Count: ${filteredResult.length}");
    Logger().i(
        "First filtered stock: ${filteredResult.isNotEmpty ? filteredResult.first.toJson() : 'None'}");

    setState(() {
      stockList = filteredResult.sorted((a, b) {
        return b.auditDetails?.lastModifiedTime
                .compareTo(a.auditDetails?.lastModifiedTime ?? 0) ??
            0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);

    // Group stockList by materialNoteNumber
    final Map<String, List<StockModel>> groupedStock = {};
    for (final stock in stockList) {
      final mrn = stock.additionalFields?.fields
          .firstWhere((f) => f.key == 'materialNoteNumber',
              orElse: () => const AdditionalField('', ''))
          .value;

      Logger().i('MRN: $mrn');

      if (mrn == null || mrn.isEmpty) continue;

      groupedStock.putIfAbsent(mrn, () => []);
      groupedStock[mrn]!.add(stock);
    }

    final groupedEntries = groupedStock.entries.toList();
    List<StockModel> finalStocks = [];

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ScrollableContent(
          header: const Column(
            children: [
              CustomBackNavigationHelpHeaderWidget(showHelp: false),
            ],
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(spacer2),
              ),
              margin: const EdgeInsets.all(spacer2),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: groupedEntries.isEmpty
                    ? const Center(child: Text("No transactions found."))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16.0),
                          Text("Select the MRN number",
                              style: textTheme.headingL),
                          const SizedBox(height: 16.0),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.78,
                            child: ListView.builder(
                              itemCount: groupedEntries.length,
                              itemBuilder: (context, index) {
                                final mrn = groupedEntries[index].key;
                                finalStocks = [];
                                for (StockModel stockModel
                                    in groupedEntries[index].value) {
                                  finalStocks
                                      .add(condenseStockObject(stockModel));
                                }
                                final stocks = groupedEntries[index].value;
                                final jsonStr = jsonEncode(finalStocks);

                                final compressed =
                                    zlib.encode(utf8.encode(jsonStr));
                                final encoded = base64Url.encode(compressed);

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      context.router.push(
                                        ViewStockRecordsRoute(
                                          mrnNumber: mrn,
                                          stockRecords: stocks,
                                        ),
                                      );
                                    },
                                    child: MinNumberCard(
                                      localizations: localizations,
                                      data: encoded,
                                      entryType: widget.type,
                                      minNumber: mrn,
                                      cddCode: stocks
                                              .first.additionalFields?.fields
                                              .firstWhereOrNull((e) =>
                                                  e.key == 'distributorName')
                                              ?.value ??
                                          "",
                                      date: formatDateFromMillis(stocks.first
                                              .auditDetails?.createdTime ??
                                          0),
                                      items: stocks.map((s) {
                                        final name = (s.additionalFields?.fields
                                                    .firstWhere(
                                                        (f) =>
                                                            f.key ==
                                                            'productName',
                                                        orElse: () =>
                                                            const AdditionalField(
                                                                '', ''))
                                                    .value ??
                                                'N/A')
                                            .toString();

                                        final quantity =
                                            (s.quantity ?? 0).toString();

                                        return {
                                          'name': name,
                                          'quantity': quantity,
                                        };
                                      }).toList(),
                                      waybillNumber: InventorySingleton()
                                              .isDistributor
                                          ? null
                                          : stocks.first.wayBillNumber ?? "",
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  StockModel condenseStockObject(StockModel stockModel) {
    return stockModel.copyWith(
      auditDetails: null,
      clientAuditDetails: null,
      additionalFields: stockModel.additionalFields?.copyWith(
        fields: [
          ...(stockModel.additionalFields?.fields ?? []),
        ],
      ),
    );
  }
}
