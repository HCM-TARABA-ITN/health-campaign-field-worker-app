import 'package:digit_components/digit_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:registration_delivery/widgets/back_navigation_help_header.dart';

import '../../../router/app_router.dart';
import '../../../utils/i18_key_constants.dart' as i18Local;
import '../../../utils/utils.dart';
import '../../blocs/summary_report/custom_distribution_summary_report.dart';
import '../../widgets/localized.dart';
import '../../widgets/reports/readonly_pluto_grid.dart';

@RoutePage()
class CustomDistributionSummaryReportDetailsPage
    extends LocalizedStatefulWidget {
  const CustomDistributionSummaryReportDetailsPage({
    super.key,
    super.appLocalizations,
  });

  @override
  State<CustomDistributionSummaryReportDetailsPage> createState() =>
      _CustomDistributionSummaryReportDetailsState();
}

class _CustomDistributionSummaryReportDetailsState
    extends LocalizedState<CustomDistributionSummaryReportDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Load data when the page is initialized
    _loadData();
  }

  void _loadData() {
    final bloc = BlocProvider.of<CustomDistributionSummaryReportBloc>(context);
    bloc.add(const CustomDistributionSummaryReportLoadingEvent());
    Future.delayed(const Duration(milliseconds: 500), () {
      bloc.add(CustomDistributionSummaryReportLoadDataEvent(
        userId: context.loggedInUserUuid,
      ));
    });
  }

  static const _householdRegisteredKey = 'householdRegisteredKey';
  static const _drugsUsedKey = 'drugsUsedKey';
  static const _drugsReceivedKey = 'drugsReceivedKey';
  static const _drugsBalanceKey = 'drugsBalanceKey';
  static const _childrenTreatedCountKey1 = 'childrenTreatedCountKey1';
  static const _childrenTreatedCountKey2 = 'childrenTreatedCountKey2';
  static const __childrenTreatedPercentageKey = 'childrenTreatedPercentageKey';
  static const _dateKey = 'dateKey';

  FormGroup _form() {
    return fb.group({});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CustomDistributionSummaryReportBloc,
          CustomDistributionSummaryReportState>(
        builder: (context, customDistributionSumamryReportState) {
          if (customDistributionSumamryReportState
              is CustomDistributionSummaryReportLoadingState) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ScrollableContent(
            footer: Padding(
              padding: const EdgeInsets.fromLTRB(kPadding, 0, kPadding, 0),
              child: DigitElevatedButton(
                child: Text(localizations
                    .translate(i18Local.acknowledgementSuccess.goToHome)),
                onPressed: () {
                  context.router.popUntilRouteWithName(HomeRoute.name);
                },
              ),
            ),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackNavigationHelpHeaderWidget(),
              Container(
                padding: const EdgeInsets.all(kPadding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localizations.translate(
                      i18Local.inventoryReportDetails.summaryReport,
                    ),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
              if (customDistributionSumamryReportState
                  is CustomDistributionSummaryReportSummaryDataState)
                ReactiveFormBuilder(
                  form: _form,
                  builder: (ctx, form, child) {
                    return SizedBox(
                      height: 400,
                      child: _ReportDetailsContent(
                        title: localizations.translate(
                          i18Local.inventoryReportDetails.summaryReport,
                        ),
                        data: DigitGridData(
                          columns: [
                            DigitGridColumn(
                              label: localizations.translate(
                                i18Local.inventoryReportDetails.dateLabel,
                              ),
                              key: _dateKey,
                              width: 90,
                            ),
                            DigitGridColumn(
                              label: localizations.translate(
                                i18Local
                                    .inventoryReportDetails.houseHoldRegistered,
                              ),
                              key: _householdRegisteredKey,
                              width: localizations
                                      .translate(
                                        i18Local.inventoryReportDetails
                                            .houseHoldRegistered,
                                      )
                                      .length *
                                  8,
                            ),
                            DigitGridColumn(
                              label:
                                  "${localizations.translate(i18Local.inventoryReportDetails.childrenTreated)} (3-11 months)",
                              key: _childrenTreatedCountKey1,
                              width:
                                  "${localizations.translate(i18Local.inventoryReportDetails.childrenTreated)} (3-11 months)"
                                          .length *
                                      7.5,
                            ),
                            DigitGridColumn(
                              label:
                                  "${localizations.translate(i18Local.inventoryReportDetails.childrenTreated)} (12-59 months)",
                              key: _childrenTreatedCountKey2,
                              width:
                                  "${localizations.translate(i18Local.inventoryReportDetails.childrenTreated)} (12-59 months)"
                                          .length *
                                      7.5,
                            ),
                            DigitGridColumn(
                              label: localizations.translate(i18Local
                                  .inventoryReportDetails
                                  .childrenTreatedPercentage),
                              key: __childrenTreatedPercentageKey,
                              width: localizations
                                      .translate(
                                        i18Local.inventoryReportDetails
                                            .childrenTreatedPercentage,
                                      )
                                      .length *
                                  8,
                            ),
                            DigitGridColumn(
                              label: localizations.translate(i18Local
                                  .inventoryReportDetails.drugsReceived),
                              key: _drugsReceivedKey,
                              width: localizations
                                      .translate(
                                        i18Local.inventoryReportDetails
                                            .drugsReceived,
                                      )
                                      .length *
                                  10,
                            ),
                            DigitGridColumn(
                              label: localizations.translate(
                                  i18Local.inventoryReportDetails.drugsUsed),
                              key: _drugsUsedKey,
                              width: localizations
                                      .translate(
                                        i18Local
                                            .inventoryReportDetails.drugsUsed,
                                      )
                                      .length *
                                  10,
                            ),
                            DigitGridColumn(
                              label: localizations.translate(
                                  i18Local.inventoryReportDetails.drugsBalance),
                              key: _drugsBalanceKey,
                              width: localizations
                                      .translate(
                                        i18Local.inventoryReportDetails
                                            .drugsBalance,
                                      )
                                      .length *
                                  10,
                            ),
                          ],
                          rows: [
                            for (final entry
                                in customDistributionSumamryReportState
                                    .summaryData.entries) ...[
                              DigitGridRow(
                                [
                                  DigitGridCell(
                                    key: _dateKey,
                                    value: entry.key,
                                  ),
                                  DigitGridCell(
                                    key: _householdRegisteredKey,
                                    value:
                                        (entry.value.householdRegisteredCount ??
                                                0)
                                            .toString(),
                                  ),
                                  DigitGridCell(
                                    key: _childrenTreatedCountKey1,
                                    value:
                                        (entry.value.childrenTreatedCount1 ?? 0)
                                            .toString(),
                                  ),
                                  DigitGridCell(
                                    key: _childrenTreatedCountKey2,
                                    value:
                                        (entry.value.childrenTreatedCount2 ?? 0)
                                            .toString(),
                                  ),
                                  DigitGridCell(
                                    key: __childrenTreatedPercentageKey,
                                    value: (entry.value
                                                .childrenTreatedPercentageCount ??
                                            0)
                                        .toString(),
                                  ),
                                  DigitGridCell(
                                    key: _drugsReceivedKey,
                                    value: (entry.value.drugsReceived ?? 0)
                                        .toString(),
                                  ),
                                  DigitGridCell(
                                    key: _drugsUsedKey,
                                    value:
                                        (entry.value.drugsUsed ?? 0).toString(),
                                  ),
                                  DigitGridCell(
                                    key: _drugsBalanceKey,
                                    value: (entry.value.drugsBalance ?? 0)
                                        .toString(),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportDetailsContent extends StatelessWidget {
  final String title;
  final DigitGridData data;

  const _ReportDetailsContent({
    Key? key,
    required this.title,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: kPadding * 2),
          Flexible(
            child: ReadonlyDigitGrid(
              data: data,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoReportContent extends StatelessWidget {
  final String title;
  final String message;

  const _NoReportContent({
    Key? key,
    required this.title,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: kPadding * 2,
          width: double.maxFinite,
        ),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      ],
    );
  }
}
