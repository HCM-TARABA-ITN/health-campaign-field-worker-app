import 'package:collection/collection.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_data_model/models/templates/template_config.dart';
import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:digit_ui_components/widgets/molecules/panel_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registration_delivery/registration_delivery.dart';
import 'package:registration_delivery/router/registration_delivery_router.gm.dart';
import 'package:registration_delivery/utils/registration_component_keys.dart'
    as registration_keys;

import '../../../utils/i18_key_constants.dart' as i18;
import '../../../widgets/localized.dart';
import '../../blocs/auth/auth.dart';
import '../../router/app_router.dart';

@RoutePage()
class CustomHouseholdAcknowledgementPage extends LocalizedStatefulWidget {
  final bool? enableViewHousehold;

  const CustomHouseholdAcknowledgementPage({
    super.key,
    super.appLocalizations,
    this.enableViewHousehold,
  });

  @override
  State<CustomHouseholdAcknowledgementPage> createState() =>
      CustomHouseholdAcknowledgementPageState();
}

class CustomHouseholdAcknowledgementPageState
    extends LocalizedState<CustomHouseholdAcknowledgementPage> {
  late RegistrationWrapperState wrapper;

  // Safely update stock using the first household's first task's clientReferenceId
  Future<void> updateStock(List<HouseholdWrapper>? householdMembers) async {
    if (householdMembers == null || householdMembers.isEmpty) return;
    final tasks = householdMembers.first.tasks;
    final clientReferenceId = (tasks != null && tasks.isNotEmpty)
        ? tasks.first.clientReferenceId
        : null;
    if (clientReferenceId != null && clientReferenceId.isNotEmpty) {
      context.read<AuthBloc>().add(
            AuthDeliveryProductCountsEvent(
                clientReferenceId: clientReferenceId),
          );
    }
  }

  @override
  void initState() {
    super.initState();
    wrapper = context.read<RegistrationWrapperBloc>().state;
    updateStock(wrapper.householdMembers);
  }

  @override
  Widget build(BuildContext context) {
    final pageKey = HouseholdAcknowledgementRoute.name.replaceAll('Route', '');
    final householdAcknowledgementTemplate =
        RegistrationDeliverySingleton().templateConfigs?[pageKey];
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);
    final wrapper = context.read<RegistrationWrapperBloc>().state;
    final isDeliveryFlow = householdAcknowledgementTemplate?.label
            .toLowerCase()
            .contains('delivery') ==
        true;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: BlocBuilder<RegistrationWrapperBloc, RegistrationWrapperState>(
          builder: (context, householdState) {
            return Padding(
              padding: const EdgeInsets.all(spacer2),
              child: PanelCard(
                type: PanelType.success,
                additionalDetails: [
                  if (wrapper.householdMembers != null &&
                      wrapper.householdMembers.isNotEmpty &&
                      wrapper.householdMembers?.first?.individuals?.lastOrNull!
                              .identifiers!
                              .lastWhereOrNull(
                                (e) =>
                                    e.identifierType ==
                                    IdentifierTypes.uniqueBeneficiaryID
                                        .toValue(),
                              )
                              ?.identifierId !=
                          null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${localizations.translate(i18.beneficiaryDetails.eToken)}\n',
                            style: textTheme.headingM.copyWith(
                              color: const DigitColors().light.paperPrimary,
                            ),
                          ),
                          TextSpan(
                            text:
                                '${getSubTextId(wrapper.householdMembers.first)}\n',
                            style: textTheme.headingM.copyWith(
                              fontSize:
                                  textTheme.headingM.fontSize! + 4, // bigger
                              fontWeight: FontWeight.bold, // bold
                              color: const DigitColors().light.paperPrimary,
                            ),
                          ),
                          TextSpan(
                            text:
                                '\n${localizations.translate(isDeliveryFlow ? i18.beneficiaryDetails.shortGuidingMessageForDelivery : i18.beneficiaryDetails.shortGuidingMessage)}',
                            style: textTheme.headingM.copyWith(
                              fontWeight: FontWeight.normal,
                              color: const DigitColors().light.paperPrimary,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    )
                ],
                description: householdAcknowledgementTemplate
                            ?.properties?[registration_keys.acknowledgementKeys
                                .acknowledgmentDescriptionKey]
                            ?.hidden ==
                        true
                    ? ""
                    : localizations.translate(
                        householdAcknowledgementTemplate
                                ?.properties?[registration_keys
                                    .acknowledgementKeys
                                    .acknowledgmentDescriptionKey]
                                ?.label ??
                            i18.acknowledgementSuccess
                                .acknowledgementDescriptionText,
                      ),
                title: householdAcknowledgementTemplate
                            ?.properties?[registration_keys
                                .acknowledgementKeys.acknowledgmentTitleKey]
                            ?.hidden ==
                        true
                    ? ""
                    : householdAcknowledgementTemplate
                                ?.properties?[registration_keys
                                    .acknowledgementKeys.acknowledgmentTitleKey]
                                ?.label !=
                            null
                        ? localizations.translate(
                            householdAcknowledgementTemplate
                                    ?.properties?[registration_keys
                                        .acknowledgementKeys
                                        .acknowledgmentTitleKey]
                                    ?.label ??
                                "")
                        : "",
                actions: _buildActionButtons(
                    context, householdAcknowledgementTemplate),
                sortButtons: false,
              ),
            );
          },
        ),
      ),
    );
  }

  List<DigitButton>? _buildActionButtons(
    BuildContext context,
    TemplateConfig? template,
  ) {
    final primaryProp =
        template?.properties?[registration_keys.commonKeys.primaryButtonKey];
    final secondaryProp =
        template?.properties?[registration_keys.commonKeys.secondaryButtonKey];

    final entries = <MapEntry<int, DigitButton>>[];

    if (primaryProp?.hidden != true) {
      final order = primaryProp?.order ?? 0;
      entries.add(MapEntry(
        order,
        DigitButton(
          label: localizations.translate(primaryProp?.label ??
              i18.householdDetails.viewHouseHoldDetailsAction),
          onPressed: () {
            context.router.popAndPush(HouseholdOverviewRoute());
          },
          type: DigitButtonType.primary,
          size: DigitButtonSize.large,
        ),
      ));
    }

    if (secondaryProp?.hidden != true) {
      final order = secondaryProp?.order ?? 1;
      entries.add(MapEntry(
        order,
        DigitButton(
          label: localizations.translate(secondaryProp?.label ??
              i18.acknowledgementSuccess.actionLabelText),
          onPressed: () {
            context.router
                .popUntilRouteWithName(CustomSearchBeneficiaryRoute.name);
          },
          type: DigitButtonType.secondary,
          size: DigitButtonSize.large,
        ),
      ));
    }

    if (entries.isEmpty) return null;

    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => e.value).toList(growable: false);
  }

  getSubText(HouseholdWrapper? wrapper) {
    return wrapper != null
        ? '${localizations.translate(i18.beneficiaryDetails.eToken)}\n'
            '${wrapper.individuals?.lastOrNull!.identifiers!.lastWhereOrNull(
                  (e) =>
                      e.identifierType ==
                      IdentifierTypes.uniqueBeneficiaryID.toValue(),
                )?.identifierId ?? localizations.translate(i18.common.noResultsFound)}'
        : '';
  }

  getSubTextId(HouseholdWrapper? wrapper) {
    String? rawId = wrapper?.individuals?.lastOrNull?.identifiers
        ?.lastWhereOrNull((e) =>
            e.identifierType == IdentifierTypes.uniqueBeneficiaryID.toValue())
        ?.identifierId;

    // Format ID as xxx-xxx-xxx
    String formattedId = '';
    if (rawId != null && rawId.isNotEmpty) {
      formattedId = rawId.replaceAllMapped(
        RegExp(r".{1,3}"), // groups of 3 chars
        (match) => "${match.group(0)}-",
      );
      if (formattedId.endsWith('-')) {
        formattedId = formattedId.substring(0, formattedId.length - 1);
      }
    } else {
      formattedId = localizations.translate(i18.common.noResultsFound);
    }
    return formattedId.isNotEmpty ? formattedId : '';
  }
}
