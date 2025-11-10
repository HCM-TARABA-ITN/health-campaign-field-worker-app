import 'package:attendance_management/router/attendance_router.dart';
import 'package:attendance_management/router/attendance_router.gm.dart';
import 'package:auto_route/auto_route.dart';
import 'package:complaints/blocs/localization/app_localization.dart';
import 'package:complaints/router/complaints_router.dart';
import 'package:complaints/router/complaints_router.gm.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_forms_engine/blocs/app_localization.dart';
import 'package:digit_forms_engine/router/forms_router.dart';
import 'package:digit_scanner/blocs/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/blocs/app_localization.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:inventory_management/models/entities/stock.dart';
import 'package:inventory_management/router/inventory_router.dart';
import 'package:inventory_management/router/inventory_router.gm.dart';
import 'package:referral_reconciliation/router/referral_reconciliation_router.dart';
import 'package:referral_reconciliation/router/referral_reconciliation_router.gm.dart';
import 'package:registration_delivery/blocs/app_localization.dart';
import 'package:registration_delivery/router/registration_delivery_router.dart';
import 'package:registration_delivery/router/registration_delivery_router.gm.dart';
import 'package:survey_form/blocs/app_localization.dart';
import 'package:survey_form/router/survey_form_router.dart';

import '../blocs/inventory_management/custom_inventory_report.dart';
import '../blocs/localization/app_localization.dart';
import '../pages/acknowledgement.dart';
import '../pages/authenticated.dart';
import '../pages/boundary_selection.dart';
import '../pages/checklist/custom_survey_form.dart';
import '../pages/checklist/custom_survey_form_acknowledgement.dart';
import '../pages/checklist/custom_survey_form_boundary_view.dart';
import '../pages/checklist/custom_survey_form_preview.dart';
import '../pages/checklist/custom_survey_form_view.dart';
import '../pages/checklist/custom_survey_form_wrapper.dart';
import '../pages/complaints/custom_complaints_details.dart';
import '../pages/complaints/custom_complaints_inbox.dart';
import '../pages/home.dart';
import '../pages/inventory_management/custom_acknowledgement.dart';
import '../pages/inventory_management/custom_inventory_facility_selection.dart';
import '../pages/inventory_management/custom_inventory_report_details.dart';
import '../pages/inventory_management/custom_inventory_report_selection.dart';
import '../pages/inventory_management/custom_manage_stock.dart';
import '../pages/inventory_management/custom_min_number.dart';
import '../pages/inventory_management/custom_stock_details.dart';
import '../pages/inventory_management/custom_stock_reconciliation.dart';
import '../pages/inventory_management/custom_transactional_details.dart';
import '../pages/inventory_management/custom_warehouse_details.dart';
import '../pages/inventory_management/qr_scanner.dart';
import '../pages/inventory_management/qrscanner.dart';
import '../pages/inventory_management/view_all_transactions_page.dart';
import '../pages/inventory_management/view_record_cdd.dart';
import '../pages/inventory_management/view_record_lga.dart';
import '../pages/inventory_management/view_stock_records.dart';
import '../pages/inventory_management/view_transactions_page.dart';
import '../pages/language_selection.dart';
import '../pages/login.dart';
import '../pages/profile.dart';
import '../pages/project_facility_selection.dart';
import '../pages/project_selection.dart';
import '../pages/qr_details_page.dart';
import '../pages/registration_delivery/custom_forms_render.dart';
import '../pages/registration_delivery/custom_household_acknowledgement.dart';
import '../pages/registration_delivery/custom_household_overview.dart';
import '../pages/registration_delivery/custom_search_beneficiary.dart';
import '../pages/reports/beneficiary/beneficaries_report.dart';
import '../pages/summary_report/custom_distribution_summary_report.dart';
import '../pages/summary_report/custom_summary_report.dart';
import '../pages/unauthenticated.dart';

export 'package:auto_route/auto_route.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(
  // INFO : Need to add the router modules here
  modules: [
    InventoryRoute,
    RegistrationDeliveryRoute,
    ReferralReconciliationRoute,
    AttendanceRoute,
    ComplaintsRoute,
    SurveyFormRoute,
    FormsRoute
  ],
)
class AppRouter extends _$AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> routes = [
    AutoRoute(
      page: UnauthenticatedRouteWrapper.page,
      path: '/',
      children: [
        AutoRoute(
          page: LoginRoute.page,
          path: 'login',
          initial: true,
        ),
      ],
    ),
    AutoRoute(
      page: AuthenticatedRouteWrapper.page,
      path: '/',
      children: [
        AutoRoute(page: HomeRoute.page, path: 'home'),
        AutoRoute(page: BeneficiaryIdDownSyncRoute.page),
        AutoRoute(page: ProfileRoute.page, path: 'profile'),
        AutoRoute(page: UserQRDetailsRoute.page, path: 'user-qr-code'),
        AutoRoute(
          page: CustomDistributionSummaryReportDetailsRoute.page,
          path: 'custom-distribution-summary-report',
        ),
        AutoRoute(
          page: CustomManageStocksRoute.page,
          path: 'custom-manage-stocks',
        ),
        AutoRoute(
          page: QRScannerRoute.page,
          path: 'qr-scanner',
        ),
        AutoRoute(
          page: ViewStockRecordsLGARoute.page,
          path: 'custom-stock-view-lga',
        ),
        AutoRoute(
          page: ViewStockRecordsCDDRoute.page,
          path: 'custom-stock-view-lga',
        ),

        AutoRoute(
          page: CustomMinNumberRoute.page,
          path: 'custom-min-number',
        ),
        AutoRoute(
          page: BeneficiariesReportRoute.page,
          path: 'beneficiary-downsync-report',
        ),
        AutoRoute(
          page: ViewTransactionsRoute.page,
          path: 'beneficiary-downsync-report',
        ),

        // Attendance Route
        AutoRoute(
          page: ManageAttendanceRoute.page,
          path: 'manage-attendance',
        ),
        AutoRoute(
          page: AttendanceDateSessionSelectionRoute.page,
          path: 'attendance-date-session-selection',
        ),
        AutoRoute(
          page: MarkAttendanceRoute.page,
          path: 'mark-attendance',
        ),
        AutoRoute(
          page: AttendanceAcknowledgementRoute.page,
          path: 'attendance-acknowledgement',
        ),

        AutoRoute(
          page: CustomMinNumberRoute.page,
          path: 'custom-min-number',
        ),

        // Referral Reconciliation Route
        // Admin Console changed custom
        AutoRoute(
            page: HFCreateReferralWrapperRoute.page, // here
            path: 'hf-referral',
            children: [
              AutoRoute(
                  page: ReferralFacilityRoute.page, path: 'facility-details'),
              AutoRoute(
                  page: ReferralFacilityRoute.page, // here
                  path: 'custom-facility-details',
                  initial: true),
              RedirectRoute(
                  path: 'facility-details',
                  redirectTo: 'custom-facility-details'),
              AutoRoute(
                  page: RecordReferralDetailsRoute.page,
                  path: 'referral-details'),
              AutoRoute(
                  page: RecordReferralDetailsRoute.page, //here
                  path: 'custom-referral-details'),
              RedirectRoute(
                  path: 'referral-details',
                  redirectTo: 'custom-referral-details'),
              AutoRoute(
                page: ReferralReasonChecklistRoute.page,
                path: 'referral-checklist-create',
              ),
              AutoRoute(
                page: ReferralReasonChecklistRoute.page, //here
                path: 'custom-referral-checklist-create',
              ),
              RedirectRoute(
                  path: 'referral-checklist-create',
                  redirectTo: 'custom-referral-checklist-create'),
              AutoRoute(
                page: ReferralReasonChecklistPreviewRoute.page,
                path: 'referral-checklist-view',
              ),
              AutoRoute(
                page: ReferralReasonChecklistPreviewRoute.page, // here
                path: 'custom-referral-checklist-view',
              ),
              RedirectRoute(
                  path: 'referral-checklist-view',
                  redirectTo: 'custom-referral-checklist-view'),
            ]),
        AutoRoute(
          page: ReferralReconAcknowledgementRoute.page,
          path: 'referral-acknowledgement',
        ),
        AutoRoute(
          page: ReferralReconProjectFacilitySelectionRoute.page,
          path: 'referral-project-facility',
        ),
        AutoRoute(
          page: SearchReferralReconciliationsRoute.page,
          path: 'search-referrals',
        ),

        // ...RegistrationDeliveryRoute().routes,
        // from registration delivery
        AutoRoute(
            page: RegistrationDeliveryWrapperRoute.page,
            path: 'custom-registration-delivery-wrapper',
            children: [
              AutoRoute(
                page: SearchBeneficiaryRoute.page,
                path: 'search-beneficiary',
              ),
              AutoRoute(
                initial: true,
                page: CustomSearchBeneficiaryRoute.page,
                path: 'custom-search-beneficiary',
              ),
              RedirectRoute(
                path: 'search-beneficiary',
                redirectTo: 'custom-search-beneficiary',
              ),
              AutoRoute(
                page: BeneficiaryErrorRoute.page,
                path: 'beneficiary-error',
              ),
              AutoRoute(
                page: BeneficiaryAcknowledgementRoute.page,
                path: 'beneficiary-acknowledgement',
              ),
              AutoRoute(
                page: HouseholdOverviewRoute.page,
                path: 'household-overview',
              ),
              AutoRoute(
                page: CustomHouseholdOverviewRoute.page,
                path: 'custom-household-overview',
              ),
              RedirectRoute(
                path: 'household-overview',
                redirectTo: 'custom-household-overview',
              ),
              AutoRoute(
                page: BeneficiaryDetailsRoute.page,
                path: 'beneficiary-details',
              ),
              AutoRoute(
                page: HouseholdAcknowledgementRoute.page,
                path: 'household-acknowledgement',
              ),
              AutoRoute(
                page: CustomHouseholdAcknowledgementRoute.page,
                path: 'custom-household-acknowledgement',
              ),
              RedirectRoute(
                  path: 'household-acknowledgement',
                  redirectTo: 'custom-household-acknowledgement'),
              AutoRoute(
                page: CustomFormsRenderRoute.page,
                path: 'custom-forms-render/:pageName',
              ),

              // ...FormsRoute().routes,
            ]),
        AutoRoute(page: BeneficiaryIdDownSyncRoute.page),

        // Custom Summary Report Route
        AutoRoute(
          page: CustomSummaryReportRoute.page,
          path: 'custom-report-summary',
        ),

        // Inventory Route
        AutoRoute(
          page: CustomStockReconciliationRoute.page,
          path: 'custom-stock-reconciliation',
        ),
        AutoRoute(
          page: CustomInventoryReportSelectionRoute.page,
          path: 'custom-inventory-report-selection',
        ),
        AutoRoute(
          page: CustomInventoryReportDetailsRoute.page,
          path: 'custom-inventory-report-details',
        ),
        AutoRoute(
          page: InventoryAcknowledgementRoute.page,
          path: 'inventory-acknowledgement',
        ),

        AutoRoute(
            page: CustomAcknowledgementRoute.page,
            path: 'custom-acknowledgement-stock'),
        AutoRoute(
          page: ViewStockRecordsRoute.page,
          path: 'custom-stock-record-view',
        ),

        AutoRoute(
          page: RecordStockWrapperRoute.page,
          path: 'record-stock',
          children: [
            AutoRoute(
              page: CustomWarehouseDetailsRoute.page,
              path: 'custom-warehouse-details',
              initial: true,
            ),
            AutoRoute(
              page: StockDetailsRoute.page,
              path: 'details',
            ),
            AutoRoute(
              page: CustomStockDetailsRoute.page,
              path: 'custom-details',
            ),
            RedirectRoute(
              path: 'details',
              redirectTo: 'custom-details',
            ),
            AutoRoute(
              page: CustomTransactionalDetailsRoute.page,
              path: 'custom-transaction-details',
            ),
            AutoRoute(
              page: ViewAllTransactionsRoute.page,
              path: 'custom-all-transactions',
            ),
          ],
        ),

        AutoRoute(
          page: InventoryFacilitySelectionRoute.page,
          path: 'inventory-select-facilities',
        ),

        AutoRoute(
          page: CustomInventoryFacilitySelectionRoute.page,
          path: 'custom-inventory-select-facilities',
        ),

        AutoRoute(
          page: AcknowledgementRoute.page,
          path: 'acknowledgement',
        ),

        AutoRoute(
          page: ProjectFacilitySelectionRoute.page,
          path: 'select-project-facilities',
        ),

        /// Project Selection
        AutoRoute(
          page: ProjectSelectionRoute.page,
          path: 'select-project',
          initial: true,
        ),

        /// Boundary Selection
        AutoRoute(
          page: BoundarySelectionRoute.page,
          path: 'select-boundary',
        ),

        // SurveyForm Route
        AutoRoute(
            page: CustomSurveyFormWrapperRoute.page,
            path: 'custom-surveyForm',
            children: [
              AutoRoute(
                page: CustomSurveyformRoute.page,
                path: '',
              ),
              AutoRoute(
                  page: CustomSurveyFormBoundaryViewRoute.page,
                  path: 'custom-view-boundary'),
              AutoRoute(
                  page: CustomSurveyFormViewRoute.page, path: 'custom-view'),
              AutoRoute(
                  page: CustomSurveyFormPreviewRoute.page,
                  path: 'custom-preview'),
              AutoRoute(
                  page: CustomSurveyFormAcknowledgementRoute.page,
                  path: 'custom-surveyForm-acknowledgement'),
            ]),

        AutoRoute(
          page: ComplaintsInboxWrapperRoute.page,
          path: 'complaints-inbox',
          children: [
            AutoRoute(
              page: CustomComplaintsInboxRoute.page,
              path: 'complaints-inbox-items',
              initial: true,
            ),
            AutoRoute(
              page: ComplaintsInboxFilterRoute.page,
              path: 'complaints-inbox-filter',
            ),
            AutoRoute(
              page: ComplaintsInboxSearchRoute.page,
              path: 'complaints-inbox-search',
            ),
            AutoRoute(
              page: ComplaintsInboxSortRoute.page,
              path: 'complaints-inbox-sort',
            ),
            AutoRoute(
              page: ComplaintsDetailsViewRoute.page,
              path: 'complaints-inbox-view-details',
            ),
          ],
        ),

        /// Complaints registration
        AutoRoute(
          page: ComplaintsRegistrationWrapperRoute.page,
          path: 'complaints-registration',
          children: [
            AutoRoute(
              page: ComplaintTypeRoute.page,
              path: 'complaints-type',
              initial: true,
            ),
            AutoRoute(
              page: ComplaintsLocationRoute.page,
              path: 'complaints-location',
            ),
            AutoRoute(
              page: ComplaintsDetailsRoute.page,
              path: 'complaints-details',
            ),
            // Admin Console
            AutoRoute(
              page: CustomComplaintsDetailsRoute.page,
              path: 'custom-complaints-details',
            ),
            RedirectRoute(
              path: 'complaints-details',
              redirectTo: 'custom-complaints-details',
            ),
          ],
        ),

        /// Complaints Acknowledgemnet
        AutoRoute(
          page: ComplaintsAcknowledgementRoute.page,
          path: 'complaints-acknowledgement',
        ),
      ],
    ),
  ];
}
