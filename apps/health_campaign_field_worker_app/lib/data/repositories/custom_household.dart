import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:drift/drift.dart';
import 'package:registration_delivery/registration_delivery.dart';
import '../../models/entities/household.dart' as local;

class CustomHouseholdLocalRepository extends HouseholdLocalRepository {
  CustomHouseholdLocalRepository(
    super.sql,
    super.opLogManager,
  );

  void listenToChanges({
    required local.HouseholdSearchModel query,
    required void Function(List<HouseholdModel> data) listener,
  }) async {
    return retryLocalCallOperation(() async {
      final select = sql.select(sql.household)
        ..where(
          (tbl) => buildAnd([
            if (query.tenantId != null)
              sql.household.tenantId.equals(
                query.tenantId!,
              ),
            if (query.clientCreatedBy != null)
              sql.household.clientCreatedBy.equals(
                query.clientCreatedBy!,
              ),
            if (query.plannedEndDate != null && query.plannedStartDate != null)
              sql.household.clientCreatedTime.isBetweenValues(
                query.plannedStartDate!,
                query.plannedEndDate!,
              ),
          ]),
        );

      select.watch().listen((results) {
        final data = results
            .map((e) {
              final household = e;
              return HouseholdModel(
                id: household.id,
                clientReferenceId: household.clientReferenceId,
                rowVersion: household.rowVersion,
                tenantId: household.tenantId,
                isDeleted: household.isDeleted,
                memberCount: household.memberCount,
                latitude: household.latitude,
                longitude: household.longitude,
                clientAuditDetails: household.clientCreatedBy != null &&
                        household.clientCreatedTime != null
                    ? ClientAuditDetails(
                        createdBy: household.clientCreatedBy!,
                        createdTime: household.clientCreatedTime!,
                        lastModifiedBy: household.clientModifiedBy,
                        lastModifiedTime: household.clientModifiedTime,
                      )
                    : null,
              );
            })
            .whereNotNull()
            .where((element) => element.isDeleted != true)
            .toList();

        listener(data);
      });
    });
  }

  FutureOr<List<HouseholdModel>> progressBarSearch(
    local.HouseholdSearchModel query, [
    String? userId,
  ]) async {
    return retryLocalCallOperation<List<HouseholdModel>>(() async {
      final selectQuery = sql.select(sql.household).join([
        leftOuterJoin(
          sql.address,
          sql.address.relatedClientReferenceId.equalsExp(
            sql.household.clientReferenceId,
          ),
        ),
        leftOuterJoin(
          sql.taskResource,
          sql.taskResource.taskclientReferenceId.equalsExp(
            sql.household.clientReferenceId,
          ),
        ),
      ]);

      final results = await (selectQuery
            ..where(buildAnd([
              if (query.clientReferenceId != null)
                sql.household.clientReferenceId.isIn(
                  query.clientReferenceId!,
                ),
              if (userId != null)
                sql.household.auditCreatedBy.equals(
                  userId,
                ),
              if (query.tenantId != null)
                sql.household.tenantId.equals(
                  query.tenantId!,
                ),
              if (query.clientCreatedBy != null)
                sql.household.clientCreatedBy.equals(
                  query.clientCreatedBy!,
                ),
              if (query.plannedEndDate != null &&
                  query.plannedStartDate != null)
                sql.household.clientCreatedTime.isBetweenValues(
                  query.plannedStartDate!,
                  query.plannedEndDate!,
                ),
            ]))
            ..orderBy([
              OrderingTerm(
                expression: sql.household.clientModifiedTime,
                mode: OrderingMode.asc,
              ),
            ]))
          .get();

      final householdsMap = <String, HouseholdModel>{};

      for (final e in results) {
        final household = e.readTableOrNull(sql.household);
        final address = e.readTableOrNull(sql.address);

        if (household == null) continue;

        // Check if the household is already in the map
        if (!householdsMap.containsKey(household.clientReferenceId)) {
          // If it's not, create a new household and add it to the map
          householdsMap[household.clientReferenceId] = HouseholdModel(
            id: household.id,
            memberCount: household.memberCount,
            latitude: household.latitude,
            longitude: household.longitude,
            clientReferenceId: household.clientReferenceId,
            rowVersion: household.rowVersion,
            tenantId: household.tenantId,
            isDeleted: household.isDeleted,
            householdType: household.householdType,
            additionalFields: household.additionalFields == null
                ? null
                : HouseholdAdditionalFieldsMapper.fromJson(
                    household.additionalFields!,
                  ),
            address: address == null
                ? null
                : AddressModel(
                    id: address.id,
                    relatedClientReferenceId: household.clientReferenceId,
                    tenantId: address.tenantId,
                    doorNo: address.doorNo,
                    latitude: address.latitude,
                    longitude: address.longitude,
                    landmark: address.landmark,
                    locationAccuracy: address.locationAccuracy,
                    addressLine1: address.addressLine1,
                    addressLine2: address.addressLine2,
                    city: address.city,
                    pincode: address.pincode,
                    type: address.type,
                    locality: address.localityBoundaryCode != null
                        ? LocalityModel(
                            code: address.localityBoundaryCode!,
                            name: address.localityBoundaryName,
                          )
                        : null,
                    rowVersion: address.rowVersion,
                    auditDetails: (household.auditCreatedBy != null &&
                            household.auditCreatedTime != null)
                        ? AuditDetails(
                            createdBy: household.auditCreatedBy!,
                            createdTime: household.auditCreatedTime!,
                            lastModifiedBy: household.auditModifiedBy,
                            lastModifiedTime: household.auditModifiedTime,
                          )
                        : null,
                    clientAuditDetails: (household.clientCreatedBy != null &&
                            household.clientCreatedTime != null)
                        ? ClientAuditDetails(
                            createdBy: household.clientCreatedBy!,
                            createdTime: household.clientCreatedTime!,
                            lastModifiedBy: household.clientModifiedBy,
                            lastModifiedTime: household.clientModifiedTime,
                          )
                        : null,
                  ),
            auditDetails: (household.auditCreatedBy != null &&
                    household.auditCreatedTime != null)
                ? AuditDetails(
                    createdBy: household.auditCreatedBy!,
                    createdTime: household.auditCreatedTime!,
                    lastModifiedBy: household.auditModifiedBy,
                    lastModifiedTime: household.auditModifiedTime,
                  )
                : null,
            clientAuditDetails: (household.clientCreatedBy != null &&
                    household.clientCreatedTime != null)
                ? ClientAuditDetails(
                    createdBy: household.clientCreatedBy!,
                    createdTime: household.clientCreatedTime!,
                    lastModifiedBy: household.clientModifiedBy,
                    lastModifiedTime: household.clientModifiedTime,
                  )
                : null,
          );
        }
      }

      // Convert the map values to a list of households
      final uniqueHouseholds = householdsMap.values.toList();

      return uniqueHouseholds
          .where((element) => element.isDeleted != true)
          .toList();
    });
  }

  @override
  FutureOr<List<HouseholdModel>> search(
    HouseholdSearchModel query, [
    String? userId,
  ]) async {
    final customQuery = query as local.HouseholdSearchModel;
    return retryLocalCallOperation<List<HouseholdModel>>(() async {
      final selectQuery = sql.select(sql.household).join(
        [
          leftOuterJoin(
            sql.address,
            sql.address.relatedClientReferenceId.equalsExp(
              sql.household.clientReferenceId,
            ),
          ),
        ],
      );

      (selectQuery
        ..where(
          buildAnd(
            [
              if (customQuery.clientReferenceId != null)
                sql.household.clientReferenceId
                    .isIn(customQuery.clientReferenceId!),
              if (customQuery.id != null)
                sql.household.id.isIn(
                  customQuery.id!,
                ),
              if (customQuery.tenantId != null)
                sql.household.tenantId.equals(
                  customQuery.tenantId!,
                ),
              if (userId != null)
                sql.household.auditCreatedBy.equals(
                  userId,
                ),
              if (customQuery.clientCreatedBy != null)
                sql.household.clientCreatedBy.equals(
                  customQuery.clientCreatedBy!,
                ),
              if (customQuery.plannedEndDate != null &&
                  customQuery.plannedStartDate != null)
                sql.household.clientCreatedTime.isBetweenValues(
                  customQuery.plannedStartDate!,
                  customQuery.plannedEndDate!,
                ),
              if (customQuery.latitude != null &&
                  customQuery.longitude != null &&
                  customQuery.maxRadius != null &&
                  customQuery.isProximityEnabled == true)
                CustomExpression<bool>('''
        (6371393 * acos(
            cos(${customQuery.latitude! * math.pi / 180.0}) * cos((address.latitude * ${math.pi / 180.0}))
            * cos((address.longitude * ${math.pi / 180.0}) - ${customQuery.longitude! * math.pi / 180.0})
            + sin(${customQuery.latitude! * math.pi / 180.0}) * sin((address.latitude * ${math.pi / 180.0}))
        )) <= ${customQuery.maxRadius!}
    '''),
            ],
          ),
        ));

      final results = await selectQuery.get();

      return results
          .map((e) {
            final household = e.readTable(sql.household);
            final address = e.readTableOrNull(sql.address);

            return HouseholdModel(
              id: household.id,
              householdType: household.householdType,
              tenantId: household.tenantId,
              clientReferenceId: household.clientReferenceId,
              memberCount: household.memberCount,
              rowVersion: household.rowVersion,
              isDeleted: household.isDeleted,
              additionalFields: household.additionalFields != null &&
                      household.additionalFields.toString().isNotEmpty
                  ? HouseholdAdditionalFieldsMapper.fromJson(
                      household.additionalFields.toString())
                  : null,
              auditDetails: (household.auditCreatedBy != null &&
                      household.auditCreatedTime != null)
                  ? AuditDetails(
                      createdBy: household.auditCreatedBy!,
                      createdTime: household.auditCreatedTime!,
                      lastModifiedBy: household.auditModifiedBy,
                      lastModifiedTime: household.auditModifiedTime,
                    )
                  : null,
              clientAuditDetails: (household.clientCreatedBy != null &&
                      household.clientCreatedTime != null)
                  ? ClientAuditDetails(
                      createdBy: household.clientCreatedBy!,
                      createdTime: household.clientCreatedTime!,
                      lastModifiedBy: household.clientModifiedBy,
                      lastModifiedTime: household.clientModifiedTime,
                    )
                  : null,
              address: address == null
                  ? null
                  : AddressModel(
                      id: address.id,
                      buildingName: address.buildingName,
                      relatedClientReferenceId: household.clientReferenceId,
                      tenantId: address.tenantId,
                      doorNo: address.doorNo,
                      latitude: address.latitude,
                      longitude: address.longitude,
                      landmark: address.landmark,
                      locationAccuracy: address.locationAccuracy,
                      addressLine1: address.addressLine1,
                      addressLine2: address.addressLine2,
                      city: address.city,
                      pincode: address.pincode,
                      locality: address.localityBoundaryCode != null
                          ? LocalityModel(
                              code: address.localityBoundaryCode!,
                              name: address.localityBoundaryName,
                            )
                          : null,
                      type: address.type,
                      rowVersion: address.rowVersion,
                      auditDetails: (household.auditCreatedBy != null &&
                              household.auditCreatedBy != null)
                          ? AuditDetails(
                              createdBy: household.auditCreatedBy!,
                              createdTime: household.auditCreatedTime!,
                              lastModifiedBy: household.auditModifiedBy,
                              lastModifiedTime: household.auditModifiedTime,
                            )
                          : null,
                      clientAuditDetails: (household.clientCreatedBy != null &&
                              household.clientCreatedTime != null)
                          ? ClientAuditDetails(
                              createdBy: household.clientCreatedBy!,
                              createdTime: household.clientCreatedTime!,
                              lastModifiedBy: household.clientModifiedBy,
                              lastModifiedTime: household.clientModifiedTime,
                            )
                          : null,
                    ),
            );
          })
          .where((element) => element.isDeleted != true)
          .toList();
    });
  }

  @override
  DataModelType get type => DataModelType.household;
}
