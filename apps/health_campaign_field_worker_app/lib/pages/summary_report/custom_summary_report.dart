import 'package:digit_ui_components/enum/app_enums.dart';
import 'package:digit_ui_components/theme/spacers.dart';
import 'package:digit_ui_components/widgets/atoms/digit_button.dart';
import 'package:digit_ui_components/widgets/molecules/digit_card.dart';
import 'package:digit_ui_components/widgets/scrollable_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:registration_delivery/widgets/back_navigation_help_header.dart';
import 'package:registration_delivery/widgets/showcase/showcase_wrappers.dart';

import '../../../router/app_router.dart';
import '../../../utils/i18_key_constants.dart' as i18_local;
import '../../../utils/utils.dart';
import '../../blocs/summary_report/custom_summary_report_bloc.dart';
import '../../models/entities/roles_type.dart';
import '../../widgets/localized.dart';
import '../../widgets/reports/readonly_pluto_grid.dart';

@RoutePage()
class CustomSummaryReportPage extends LocalizedStatefulWidget {
  const CustomSummaryReportPage({
    super.key,
    super.appLocalizations,
  });

  @override
  State<CustomSummaryReportPage> createState() => _CustomSummaryReportState();
}

class _CustomSummaryReportState
    extends LocalizedState<CustomSummaryReportPage> {
  @override
  void initState() {
    super.initState();
    // Load data when the page is initialized
    _loadData();
  }

  void _loadData() {
    final bloc = BlocProvider.of<SummaryReportBloc>(context);
    bloc.add(const SummaryReportLoadingEvent());
    Future.delayed(const Duration(milliseconds: 500), () {
      bloc.add(SummaryReportLoadDataEvent(
        userId: context.loggedInUserUuid,
      ));
    });
  }

  bool get isRegistrar => context.loggedInUserRoles
      .where(
        (role) => role.code == RolesType.registrar.toValue(),
      )
      .toList()
      .isNotEmpty;
  bool get isDistributor => context.loggedInUserRoles
      .where(
        (role) => role.code == RolesType.distributor.toValue(),
      )
      .toList()
      .isNotEmpty;

  static const _dateKey = 'dateKey';
  static const _registeredHouseholdsKey = 'registeredHouseholdsKey';
  static const _householdMembersKey = 'householdMembersKey';
  static const _tokensRedeemedKey = 'tokensRedeemedKey';
  static const _bednetsDistributedKey = 'bednetsDistributedKey';

  FormGroup _form() {
    return fb.group({});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SummaryReportBloc, SummaryReportState>(
        builder: (context, sumamryReportState) {
          if (sumamryReportState is SummaryReportLoadingState) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ScrollableContent(
            footer: DigitCard(
              margin: const EdgeInsets.only(top: spacer2),
              children: [
                DigitButton(
                  mainAxisSize: MainAxisSize.max,
                  type: DigitButtonType.primary,
                  size: DigitButtonSize.large,
                  label: localizations
                      .translate(i18_local.acknowledgementSuccess.goToHome),
                  onPressed: () {
                    context.router.popUntilRouteWithName(HomeRoute.name);
                  },
                ),
              ],
            ),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackNavigationHelpHeaderWidget(),
              Container(
                padding: const EdgeInsets.all(kPadding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localizations
                        .translate(i18_local.homeShowcase.summaryReport),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
              if (sumamryReportState is SummaryReportDataState)
                ReactiveFormBuilder(
                  form: _form,
                  builder: (ctx, form, child) {
                    return SizedBox(
                      height: 400,
                      child: _ReportDetailsContent(
                        title: localizations
                            .translate(i18_local.homeShowcase.summaryReport),
                        data: DigitGridData(
                          columns: [
                            DigitGridColumn(
                              label: localizations.translate(
                                  i18_local.homeShowcase.summaryReportDate),
                              key: _dateKey,
                              width: 120,
                            ),
                            if (isRegistrar) ...[
                              DigitGridColumn(
                                label: localizations.translate(i18_local
                                    .homeShowcase
                                    .summaryReportRegistredHouseholds),
                                key: _registeredHouseholdsKey,
                                width: 180,
                              ),
                              DigitGridColumn(
                                label: localizations.translate(i18_local
                                    .homeShowcase
                                    .summaryReportHouseholdMembers),
                                key: _householdMembersKey,
                                width: 180,
                              ),
                            ],
                            if (isDistributor) ...[
                              DigitGridColumn(
                                label: localizations.translate(i18_local
                                    .homeShowcase.summaryReportTokensRedeemed),
                                key: _tokensRedeemedKey,
                                width: 180,
                              ),
                              DigitGridColumn(
                                label: localizations.translate(i18_local
                                    .homeShowcase
                                    .summaryReportBednetsDistributed),
                                key: _bednetsDistributedKey,
                                width: 180,
                              ),
                            ],
                          ],
                          rows: [
                            for (final entry
                                in sumamryReportState.data.entries) ...[
                              DigitGridRow(
                                [
                                  DigitGridCell(
                                    key: _dateKey,
                                    value: entry.key,
                                  ),
                                  if (isRegistrar) ...[
                                    DigitGridCell(
                                      key: _registeredHouseholdsKey,
                                      value: (entry.value[Constants
                                                  .registeredHouseholds] ??
                                              0)
                                          .toString(),
                                    ),
                                    DigitGridCell(
                                      key: _householdMembersKey,
                                      value: (entry.value[
                                                  Constants.householdMembers] ??
                                              0)
                                          .toString(),
                                    ),
                                  ],
                                  if (isDistributor) ...[
                                    DigitGridCell(
                                      key: _tokensRedeemedKey,
                                      value: (entry.value[
                                                  Constants.tokensRedeemed] ??
                                              0)
                                          .toString(),
                                    ),
                                    DigitGridCell(
                                      key: _bednetsDistributedKey,
                                      value: (entry.value[Constants
                                                  .bednetsDistributed] ??
                                              0)
                                          .toString(),
                                    ),
                                  ],
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
    required this.title,
    required this.data,
  });

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

// ignore: unused_element
class _NoReportContent extends StatelessWidget {
  final String title;
  final String message;

  const _NoReportContent({
    required this.title,
    required this.message,
  });

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
