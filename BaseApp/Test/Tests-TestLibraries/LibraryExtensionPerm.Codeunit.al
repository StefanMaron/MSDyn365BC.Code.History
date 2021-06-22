codeunit 130800 "Library - Extension Perm."
{

    trigger OnRun()
    begin
        InsertExtensionPermissions;
    end;

    var
        XD365FULLTxt: Label 'D365 Full Access';
        XD365BUSFULLTxt: Label 'D365 Bus Full Access';
        XTEAMMEMBERTxt: Label 'D365 TEAM MEMBER';
        XBASICTxt: Label 'D365 Basic';
        XREADTxt: Label 'D365 READ';

    procedure InsertExtensionPermissions()
    begin
        InsertPayPalPermissions;
        InsertWorldPayPermissions;
        InsertMicrosoftWalletPermissions;
        InsertYodleePermissions;
        InsertAzureEventEmitterPermissions;
        InsertSalesInventoryForecastPermissions;
        InsertCeridianPayrollPermissions;
        InsertDynamicsGPDataMigrationPermissions;
        InsertQuickBooksSynchronizationPermissions;
        InsertUKPostcodeGetAddressIOPermissions;
        InsertXeroPermissions;
        InsertImageAnalysisPermissions;
        InsertCompanyHubPermissions;
        InsertC52012MigrationPermissions;
        InsertAnonymousDataSharingPermissions;
        InsertQuickBooksOnlineDataMigrationPermissions;
        InsertLatePaymentPredictorPermissions;
        InsertQuickBooksDataMigrationPermissions;
        InsertOIOUBLPermissions;
        InsertSyncBasePermissions;
        InsertXeroSyncPermissions;
        InsertIntelligentCloudPermissions;
        InsertNAV2018IntelligentCloudPermissions;

        Commit();
    end;

    local procedure InsertCompanyHubPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1151, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1152, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1153, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1154, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1155, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1156, 1, 1, 1, 1);
    end;

    local procedure InsertMicrosoftWalletPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1080, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1081, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1085, 1, 1, 1, 1);
    end;

    local procedure InsertWorldPayPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1360, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1361, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1367, 1, 1, 1, 1);
    end;

    local procedure InsertPayPalPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1070, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1071, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1077, 1, 1, 1, 1);
    end;

    local procedure InsertYodleePermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1450, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1451, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1452, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1453, 1, 1, 1, 1);
    end;

    local procedure InsertAzureEventEmitterPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1460, 1, 1, 1, 1);
    end;

    local procedure InsertSalesInventoryForecastPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1850, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1851, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1853, 1, 1, 1, 1);
    end;

    local procedure InsertCeridianPayrollPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1665, 1, 1, 1, 1);
    end;

    local procedure InsertDynamicsGPDataMigrationPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1931, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1932, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1933, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1934, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1935, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1936, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1937, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1938, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1939, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1940, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1941, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1943, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1944, 1, 1, 1, 1);

        InsertExtensionObjectDefaultPermissions(4100, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4101, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4102, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4103, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4104, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4105, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4106, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4107, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4108, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4109, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4110, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4111, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4112, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4113, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4114, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4115, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4116, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4117, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4118, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4119, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4120, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4121, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4122, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4123, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4124, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4125, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4126, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4127, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4128, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4129, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4130, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4131, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4132, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4133, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4134, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4135, 1, 1, 1, 1);
    end;

    local procedure InsertQuickBooksSynchronizationPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(5375, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(5376, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(5378, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(5380, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(5381, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(5382, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(5383, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(5384, 1, 1, 1, 1);
    end;

    local procedure InsertUKPostcodeGetAddressIOPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(9092, 1, 1, 1, 1);
    end;

    local procedure InsertImageAnalysisPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(2028, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(2029, 1, 1, 1, 1);
    end;

    local procedure InsertXeroPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(9681, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(9682, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(9683, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(9684, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(9685, 1, 1, 1, 1);
    end;

    local procedure InsertC52012MigrationPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1860, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1861, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1862, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1863, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1864, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1865, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1866, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1867, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1868, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1869, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1870, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1871, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1872, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1873, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1874, 1, 1, 1, 1);
        // gap because objects exist in BaseApp
        InsertExtensionObjectDefaultPermissions(1880, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1881, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1882, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1883, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1884, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1885, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1886, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1887, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1888, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1889, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1890, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1891, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1892, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1893, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1894, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1895, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1896, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1897, 1, 1, 1, 1);
    end;

    local procedure InsertAnonymousDataSharingPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(2050, 1, 2, 2, 2);
    end;

    local procedure InsertQuickBooksOnlineDataMigrationPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1830, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1831, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1834, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1835, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1836, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1837, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1838, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1839, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1840, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1841, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1842, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1843, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1844, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1846, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1847, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1848, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1849, 1, 1, 1, 1);
    end;

    local procedure InsertLatePaymentPredictorPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1950, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1951, 1, 1, 1, 1);
    end;

    local procedure InsertQuickBooksDataMigrationPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(1911, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1912, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1913, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1914, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1915, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1916, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1917, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(1918, 1, 1, 1, 1);
    end;

    local procedure InsertOIOUBLPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(13630, 1, 1, 1, 1);
    end;

    local procedure InsertSyncBasePermissions()
    begin
        InsertExtensionObjectDefaultPermissions(2400, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(2401, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(2402, 1, 1, 1, 1);
    end;

    local procedure InsertXeroSyncPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(2406, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(2407, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(2408, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(2409, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(2410, 1, 1, 1, 1);
    end;

    local procedure InsertExtensionObjectDefaultPermissions(ObjectId: Integer; ReadPermission: Integer; InsertPermission: Integer; ModifyPermission: Integer; DeletePermission: Integer)
    var
        TableMetadata: Record "Table Metadata";
    begin
        if not TableMetadata.Get(ObjectId) then
            exit;

        InsertData(D365Full, false, ObjectId,
          ReadPermission, InsertPermission, ModifyPermission, DeletePermission);
        InsertData(D365BusFull, false, ObjectId,
          ReadPermission, InsertPermission, ModifyPermission, DeletePermission);
        InsertData(D365Basic, false, ObjectId,
          ReadPermission, InsertPermission, ModifyPermission, DeletePermission);
        InsertData(D365TeamMember, false, ObjectId,
          ReadPermission, InsertPermission, ModifyPermission, DeletePermission);
        InsertData(D365Read, false, ObjectId,
          ReadPermission, 0, 0, 0);
    end;

    local procedure InsertIntelligentCloudPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(4001, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4002, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4003, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4005, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4006, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4007, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4015, 1, 1, 1, 1);
    end;

    local procedure InsertNAV2018IntelligentCloudPermissions()
    begin
        InsertExtensionObjectDefaultPermissions(4018, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4020, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4021, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4023, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4024, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4025, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4026, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4027, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4028, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4032, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4033, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4037, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4038, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4039, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4041, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4042, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4043, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4044, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4045, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4046, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4047, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4048, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4049, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4050, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4051, 1, 1, 1, 1);
        InsertExtensionObjectDefaultPermissions(4052, 1, 1, 1, 1);
    end;

    procedure InsertData(RoleID: Code[20]; ReadOnly: Boolean; ObjectID: Integer; ReadPermission: Integer; InsertPermission: Integer; ModifyPermission: Integer; DeletePermission: Integer)
    var
        Permission: Record Permission;
    begin
        if Permission.Get(RoleID, Permission."Object Type"::"Table Data", ObjectID) then
            exit;

        Permission.Init();
        Permission.Validate("Role ID", RoleID);
        Permission.Validate("Object Type", Permission."Object Type"::"Table Data");
        Permission.Validate("Object ID", ObjectID);
        if ReadOnly = false then begin
            Permission."Read Permission" := ReadPermission;
            Permission."Insert Permission" := InsertPermission;
            Permission."Modify Permission" := ModifyPermission;
            Permission."Delete Permission" := DeletePermission;
        end else begin
            Permission."Read Permission" := ReadPermission;
            Permission."Insert Permission" := Permission."Insert Permission"::" ";
            Permission."Modify Permission" := ModifyPermission;
            Permission."Delete Permission" := Permission."Delete Permission"::" ";
        end;
        Permission."Execute Permission" := Permission."Execute Permission"::" ";
        if Permission.Insert() then; // In case of duplicates when combining permission sets
    end;

    procedure D365BusFull(): Code[20]
    begin
        exit(XD365BUSFULLTxt);
    end;

    procedure D365Full(): Code[20]
    begin
        exit(XD365FULLTxt);
    end;

    procedure D365TeamMember(): Code[20]
    begin
        exit(XTEAMMEMBERTxt);
    end;

    procedure D365Basic(): Code[20]
    begin
        exit(XBASICTxt);
    end;

    procedure D365Read(): Code[20]
    begin
        exit(XREADTxt);
    end;
}

