codeunit 136607 "ERM RS Setup External Files"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ValueIsNotFoundErr: Label 'Value is not found in exported Worksheet Line.';
        Text003: Label 'Package Data imported incorrectly.';
        Text004: Label 'Record must be exported for value %1.';
        Text005: Label 'No records must be exported for value %1.';
        Text006: Label 'Field %1 must be exported.';
        Text007: Label 'Field %1 must not be exported.';
        ValueIsIncorrectErr: Label 'Value is incorrect for table ID %1.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWrkShtLineExportToExcel()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        Location: Record Location;
    begin
        Initialize;
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreateConfigLine(
          ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Location, '', '', false);
        ConfigLine.SetRange("Line No.", ConfigLine."Line No.");
        ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);
        ExportPackageToExcel(ConfigPackage.Code, 0);
        Location.FindFirst;
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(Location.Code), ValueIsNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageExportToExcel_OneTable()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        Initialize;
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Customer Posting Group");
        ExportPackageToExcel(ConfigPackage.Code, 0);
        CustomerPostingGroup.FindSet;
        repeat
            Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(CustomerPostingGroup.Code), ValueIsNotFoundErr);
        until CustomerPostingGroup.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageExportToExcel_TwoTables()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        Initialize;
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Location);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Customer Posting Group");
        ExportPackageToExcel(ConfigPackage.Code, DATABASE::"Customer Posting Group");
        CustomerPostingGroup.FindSet;
        repeat
            Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(CustomerPostingGroup.Code), ValueIsNotFoundErr);
        until CustomerPostingGroup.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageExportToExcel_EmulateUserSelection_SelectedTablesExported()
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        ConfigPackageTable: Record "Config. Package Table";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        ConfigPackageCode: Code[20];
    begin
        Initialize;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimension(Dimension);
        CreatePackageWithCustomerAndDimension(ConfigPackageCode, ConfigPackageTable);

        MarkPackageTables(ConfigPackageCode, ConfigPackageTable);
        ExportSelectedTablesToExcel(ConfigPackageCode, ConfigPackageTable);

        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(Customer."No.") and
          LibraryReportValidation.CheckIfValueExists(Dimension.Code), ValueIsNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageExportToExcel_EmulateUserSelection_NonSelectesTablesSkipped()
    var
        Dimension: Record Dimension;
        DimVal: Record "Dimension Value";
        ConfigPackageTable: Record "Config. Package Table";
        LibraryDimension: Codeunit "Library - Dimension";
        ConfigPackageCode: Code[20];
    begin
        Initialize;
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimVal, Dimension.Code);
        CreatePackageWithCustomerAndDimension(ConfigPackageCode, ConfigPackageTable);

        MarkPackageTables(ConfigPackageCode, ConfigPackageTable);
        ExportSelectedTablesToExcel(ConfigPackageCode, ConfigPackageTable);

        Assert.IsFalse(LibraryReportValidation.CheckIfValueExists(DimVal.Code), StrSubstNo(Text005, DimVal.Code));
    end;

    [Test]
    [HandlerFunctions('ImportPreviewModalHandler')]
    [Scope('OnPrem')]
    procedure VerifyPackageImportFromExcel_OneTable()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageRecord: Record "Config. Package Record";
        Location: Record Location;
    begin
        Initialize;
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Location);
        ExportPackageToExcel(ConfigPackage.Code, 0);
        ImportPackageFromExcel;

        ConfigPackageRecord.SetRange("Package Code", ConfigPackage.Code);
        Assert.AreEqual(Location.Count, ConfigPackageRecord.Count, Text003);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageExportToExcel_FilteredTable_InFilter()
    var
        Location: Record Location;
    begin
        // Verify record in filter exported
        Initialize;

        Location.FindFirst;
        AddPackageFilterAndExport(DATABASE::Location, Location.FieldNo(Code), Location.Code);

        // Verify that record exported with Location Code in defined filter
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(Location.Code), StrSubstNo(Text004, Location.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageExportToExcel_FilteredTable_OutOfFilter()
    var
        Location: Record Location;
    begin
        // Verify no records out of filters exported
        Initialize;

        Location.FindFirst;
        AddPackageFilterAndExport(DATABASE::Location, Location.FieldNo(Code), Location.Code);

        // Verify no records exported with Location Code that not exists in defined filter
        Location.SetFilter(Code, '<>%1', Location.Code);
        Location.FindFirst;
        Assert.IsFalse(LibraryReportValidation.CheckIfValueExists(Location.Code), StrSubstNo(Text005, Location.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageExportToExcel_IncludeFields_Yes()
    var
        Location: Record Location;
    begin
        // Verify records exported with fields marked as Include = TRUE
        Initialize;

        SetIncludeFieldAndExport(true, DATABASE::Location, Location.FieldNo("Default Bin Code"));

        // Verify that field with Include = TRUE was exported
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(Location.FieldName("Default Bin Code")),
          StrSubstNo(Text006, Location."Default Bin Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPackageExportToExcel_IncludeFields_No()
    var
        Location: Record Location;
    begin
        // Verify records not exported with fields marked as Include = FALSE
        Initialize;

        SetIncludeFieldAndExport(false, DATABASE::Location, Location.FieldNo("Default Bin Code"));

        // Verify that field with Include = FALSE was not exported
        Assert.IsFalse(
          LibraryReportValidation.CheckIfValueExists(Location.FieldName("Default Bin Code")),
          StrSubstNo(Text007, Location."Default Bin Code"));
    end;

    [Test]
    [HandlerFunctions('ImportPreviewModalHandler')]
    [Scope('OnPrem')]
    procedure ImportFromExcel_ImportDataWitnWrongCaseForOption_NoErrors()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageError: Record "Config. Package Error";
        InventorySetup: Record "Inventory Setup";
        [RunOnClient]
        XlWrkBkWriter: DotNet WorkbookWriter;
        [RunOnClient]
        XlWrkShtWriter: DotNet WorksheetWriter;
    begin
        Initialize;
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Inventory Setup");
        ExportPackageToExcel(ConfigPackage.Code, 0);

        XlWrkBkWriter := XlWrkBkWriter.Open(LibraryReportValidation.GetFileName);
        ConfigPackageTable.CalcFields("Table Name");
        XlWrkShtWriter := XlWrkBkWriter.GetWorksheetByName(ConfigPackageTable."Table Name");
        XlWrkShtWriter.SetCellValueText(
          4, 'E', LowerCase(Format(InventorySetup."Automatic Cost Adjustment"::Never)), XlWrkShtWriter.DefaultCellDecorator);
        XlWrkBkWriter.Close;

        ImportPackageFromExcel;

        Assert.IsTrue(ConfigPackageError.IsEmpty, Text003);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportToExcel_ExportDataConsideringFieldProcessingOrder_FieldIsInOrder()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        PaymentMethod: Record "Payment Method";
        PaymentMethodAccountType: Text;
        FoundValue: Boolean;
    begin
        Initialize;
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Payment Method");

        LibraryRapidStart.SetProcessingOrderForField(
          ConfigPackage.Code, ConfigPackageTable."Table ID", PaymentMethod.FieldNo("Bal. Account Type"), 1);

        ExportPackageToExcel(ConfigPackage.Code, 0);

        PaymentMethodAccountType := LibraryReportValidation.GetValueAt(FoundValue, 4, 2);

        Assert.IsTrue(
          (PaymentMethodAccountType = Format(PaymentMethod."Bal. Account Type"::"G/L Account")) or
          (PaymentMethodAccountType = Format(PaymentMethod."Bal. Account Type"::"Bank Account")),
          ValueIsNotFoundErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ImportPreviewModalHandler')]
    [Scope('OnPrem')]
    procedure VerifyCorrectRecordCountImportedOver()
    begin
        // Verify correct record count of table and dimensions after excel import over existent package data
        // Verify package record count = database records for each table
        Initialize;

        VerifyCorrectRecordCountImportOver_Helper(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ImportPreviewModalHandler')]
    [Scope('OnPrem')]
    procedure VerifyRecordCountNotChangedOnCancelImport()
    begin
        // Verify records and dimensions not imported if import canceled
        // Verify package record count = 1 for each table
        Initialize;

        VerifyCorrectRecordCountImportOver_Helper(false);
    end;

    [Test]
    [HandlerFunctions('ImportPreviewModalHandler')]
    [Scope('OnPrem')]
    procedure PackageImportTableFilterField()
    var
        ConfigPackageData: Record "Config. Package Data";
        Permission: Record Permission;
        ConfigPackageCode: Code[20];
        SecurityFilter: Text;
    begin
        // [SCENARIO 363000] RapidStart Package imports field of TableFilter type correctly
        Initialize;

        // [GIVEN] Permission with Security Filter = X (of Field Type TableFilter)
        CreatePermissionWithSecurityFilter(Permission, SecurityFilter);

        // [GIVEN] Exported RapidStart Package Data for Permission Record with Security Filter = X (TableFilter field type).
        ConfigPackageCode := AddPackageFilterAndExport(DATABASE::Permission, Permission.FieldNo("Role ID"), Permission."Role ID");

        // [WHEN] RapidStart Package is imported
        ImportPackageFromExcel;

        // [THEN] Config Package Data created with Security Filter = X.
        with ConfigPackageData do begin
            SetRange("Package Code", ConfigPackageCode);
            SetRange("Table ID", DATABASE::Permission);
            SetRange("Field ID", Permission.FieldNo("Security Filter"));
            FindFirst;
            Assert.AreEqual(
              SecurityFilter, Value,
              StrSubstNo(ValueIsIncorrectErr, DATABASE::Permission));
        end;
    end;

    [Test]
    [HandlerFunctions('ImportPreviewModalHandler')]
    [Scope('OnPrem')]
    procedure ExportPackageWithTable5650()
    var
        TotalValueInsured: Record "Total Value Insured";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageError: Record "Config. Package Error";
    begin
        // [SCENARIO 381067] Export table having field with name the same to table's name
        Initialize;

        // [GIVEN] Table "A" with Field "A" having 1 entry.
        Assert.AreEqual(
          TotalValueInsured.TableName,
          TotalValueInsured.FieldName("Total Value Insured"),
          'Field name must be equal to table name');

        TotalValueInsured.DeleteAll();
        TotalValueInsured.Init();
        TotalValueInsured.Insert();
        Commit();

        // [GIVEN] Configuration package with table "A" exported to excel
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Total Value Insured");
        ExportPackageToExcel(ConfigPackage.Code, 0);

        // [WHEN] Import excel
        ImportPackageFromExcel;

        // [THEN] 1 record imported into package without any error
        ConfigPackageRecord.SetRange("Package Code", ConfigPackage.Code);
        Assert.AreEqual(TotalValueInsured.Count, ConfigPackageRecord.Count, Text003);
        ConfigPackageError.Init();
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        Assert.RecordIsEmpty(ConfigPackageError);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
        LibraryRapidStart.CleanUp('');
    end;

    local procedure ExportPackageToExcel(ConfigPackageCode: Code[20]; TableID: Integer)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        ConfigPackageTable.SetRange("Package Code", ConfigPackageCode);
        if TableID <> 0 then
            ConfigPackageTable.SetRange("Table ID", TableID);
        ConfigExcelExchange.SetHideDialog(true);
        ConfigExcelExchange.ExportExcel(FileName, ConfigPackageTable, false, false);
        FileName := FileManagement.UploadFileSilent(FileName);
        LibraryReportValidation.SetFullFileName(FileName);
    end;

    local procedure ExportSelectedTablesToExcel(ConfigPackageCode: Code[20]; var ConfigPackageTable: Record "Config. Package Table")
    var
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        ConfigPackageTable.SetRange("Package Code", ConfigPackageCode);
        ConfigExcelExchange.SetHideDialog(true);
        ConfigExcelExchange.ExportExcel(FileName, ConfigPackageTable, false, false);
        FileName := FileManagement.UploadFileSilent(FileName);
        LibraryReportValidation.SetFullFileName(FileName);
    end;

    local procedure ImportPackageFromExcel()
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, FileManagement.UploadFileSilent(LibraryReportValidation.GetFileName));
        ConfigExcelExchange.ImportExcel(TempBlob);
    end;

    local procedure AddPackageFilterAndExport(TableID: Integer; FieldID: Integer; FieldFilter: Text[250]): Code[20]
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, TableID, 0, FieldID, FieldFilter);

        ExportPackageToExcel(ConfigPackage.Code, TableID);

        exit(ConfigPackage.Code);
    end;

    local procedure SetIncludeFieldAndExport(Include: Boolean; TableID: Integer; FieldID: Integer): Code[20]
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, TableID, FieldID, Include);

        ExportPackageToExcel(ConfigPackage.Code, TableID);

        exit(ConfigPackage.Code);
    end;

    local procedure CreatePackageWithCustomerAndDimension(var ConfigPackageCode: Code[20]; var ConfigPackageTable: Record "Config. Package Table")
    var
        ConfigPackage: Record "Config. Package";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Customer);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Dimension);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Dimension Value");

        ConfigPackageCode := ConfigPackage.Code;
    end;

    local procedure CreatePermissionWithSecurityFilter(var Permission: Record Permission; var SecurityFilter: Text)
    var
        PermissionSet: Record "Permission Set";
        GLAccount: Record "G/L Account";
    begin
        with PermissionSet do begin
            Init;
            Validate(
              "Role ID",
              LibraryUtility.GenerateRandomCode(FieldNo("Role ID"), DATABASE::"Permission Set"));
            Insert(true);
        end;

        SecurityFilter := GLAccount.TableCaption + ': ' + GLAccount.FieldCaption("Account Type") + '=' +
          Format(GLAccount."Account Type"::Heading);

        with Permission do begin
            Init;
            Validate("Role ID", PermissionSet."Role ID");
            Validate("Object Type", "Object Type"::"Table Data");
            Validate("Object ID", DATABASE::"G/L Account");
            Insert(true);
            Evaluate("Security Filter", SecurityFilter);
            Modify(true);
        end;
    end;

    local procedure MarkPackageTables(ConfigPackageCode: Code[20]; var ConfigPackageTable: Record "Config. Package Table")
    begin
        ConfigPackageTable.Get(ConfigPackageCode, DATABASE::Customer);
        ConfigPackageTable.Mark(true);
        ConfigPackageTable.Get(ConfigPackageCode, DATABASE::Dimension);
        ConfigPackageTable.Mark(true);
        ConfigPackageTable.MarkedOnly(true);
    end;

    local procedure FillPackageWithData(ConfigPackage: Record "Config. Package"; RecCount: Integer; ConfirmValue: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
        "Field": Record "Field";
        i: Integer;
    begin
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        if ConfigPackageTable.FindSet then
            repeat
                for i := 1 to RecCount do begin
                    Field.SetRange(TableNo, ConfigPackageTable."Table ID");
                    Field.FindFirst;
                    LibraryRapidStart.CreatePackageDataForField(
                      ConfigPackage, ConfigPackageTable, Field.TableNo, Field."No.",
                      LibraryUtility.GenerateRandomCode(Field."No.", Field.TableNo), i);
                end;
                LibraryVariableStorage.Enqueue(ConfirmValue);
            until ConfigPackageTable.Next = 0;
    end;

    local procedure VerifyPackageRecordCount(PackageCode: Code[20]; ConfirmImport: Boolean; RecCount: Integer)
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        with ConfigPackageTable do begin
            SetRange("Package Code", PackageCode);
            SetRange("Company Filter (Source Table)", CompanyName);
            if FindSet then
                repeat
                    CalcFields("No. of Package Records");
                    if ConfirmImport then
                        Assert.AreEqual(GetNoOfDatabaseRecords, "No. of Package Records", StrSubstNo(ValueIsIncorrectErr, "Table ID"))
                    else
                        Assert.AreEqual(RecCount, "No. of Package Records", StrSubstNo(ValueIsIncorrectErr, "Table ID"));
                until Next = 0;
        end;
    end;

    local procedure VerifyCorrectRecordCountImportOver_Helper(ConfirmImport: Boolean): Code[20]
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        PackageCode: Code[20];
    begin
        LibraryVariableStorage.Enqueue(true);
        LibraryRapidStart.CreatePackage(ConfigPackage);
        PackageCode := ConfigPackage.Code;
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Customer, '', PackageCode, true);

        // EXECUTE
        ExportPackageToExcel(PackageCode, 0);
        FillPackageWithData(ConfigPackage, 1, ConfirmImport);

        ImportPackageFromExcel;

        // VERIFY package record count
        VerifyPackageRecordCount(PackageCode, ConfirmImport, 1);

        exit(PackageCode);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ConfirmValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ConfirmValue);
        Reply := ConfirmValue;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ImportPreviewModalHandler(var ConfigPackageImportPreview: TestPage "Config. Package Import Preview")
    begin
        ConfigPackageImportPreview.Import.Invoke;
    end;
}

