codeunit 136611 "ERM RS Dimensions as Columns"
{
    Permissions = TableData "G/L Entry" = m,
                  TableData "Dimension Set Entry" = m;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start] [Dimension]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IncorrectNumberOfTablesErr: Label 'Incorrect number of tables in package.';
        CannotUseDimensionsAsColumnsErr: Label 'You cannot use the Dimensions as Columns function for table %1.';
        IncorrectDimensionsAsColumnsErr: Label 'Incorrect Dimensions as Columns export.';
        IncorrectDefaultDimensionsErr: Label 'Incorrect Default Dimensions export.';
        IncorrectDefaultDimensionsImportErr: Label 'Default Dimensions imported incorrectly from Excel.';
        DimensionSetIsNotCreatedErr: Label 'Dimension Set is not created.';
        DimensionValueCodeIsNotFoundErr: Label 'Dimension Value Code %1 for Dimension Set is not found.';
        DimensionValueIsCreatedForDimSetErr: Label 'Dimension Value with Code %1 and Value Code %2 for Dimension Set is created.';
        IncorrectDimensionSetIDErr: Label 'Dimension Set ID is incorrect.';
        DimensionExpectedErr: Label 'The setup of Dimensions as Columns was canceled.';
        IncorrectDimPackageDataErr: Label 'Package Data were not updated when validate Dimension As Columns field.';
        NewDimensionNotCreatedErr: Label 'Dimension was not created after applying package with new dimension. ';
        ExportedDimensionCap: Label '%1 (%2)';
        DimensionValueIdNotExistsErr: Label 'Errors for package with Dimension Value Id field not generated.';
        NonExistingDimValueExistsErr: Label 'Errors for package with non-existing dimension value is not generated.';
        AutoincrementMsg: Label 'AutoIncrement field.';
        DimensionNotAppliedErr: Label 'Default dimension was not applied.';
        ConfigPackageMgt: Codeunit "Config. Package Management";
        IsInitialized: Boolean;
        DimValueDoesNotExistsInDimSetErr: Label 'Dimension value %1 %2 does not exist in Dimension Set ID %3.', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';
        DimValueDoesNotExistsErr: Label 'Dimension Value %1 %2 does not exist.', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifyDimAsColumnsDimTablesAdded_ConfirmHandlerYes()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [SCENARIO] Two dimension package tables added to the package if "Dimensions As Columns" set to 'Yes'
        Initialize();
        // [GIVEN] Package with table Customer
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        // [WHEN] Set "Dimensions As Columns" to 'Yes' on Customer table and answer 'Yes' to confirmation
        SetDimensionAsColumns(ConfigPackageTable);
        // [THEN] Three tables in the package: Customer, Dimension Value, Default Dimension.
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetFilter("Table ID", '%1|%2|%3', DATABASE::Customer, DATABASE::"Dimension Value", DATABASE::"Default Dimension");
        Assert.RecordCount(ConfigPackageTable, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerNo')]
    [Scope('OnPrem')]
    procedure VerifyDimAsColumnsDimTablesNotAdded_ConfirmHandlerNo()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [SCENARIO] Addition of dimension tables on "Dimensions As Columns" set to 'Yes' can be cancelled
        Initialize();
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        asserterror SetDimensionAsColumns(ConfigPackageTable);
        Assert.ExpectedError(DimensionExpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimAsColumnsIsNotAllowed()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        Initialize();
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Location);
        asserterror SetDimensionAsColumns(ConfigPackageTable);
        Assert.ExpectedError(StrSubstNo(CannotUseDimensionsAsColumnsErr, ConfigPackageTable."Table ID"));
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifyDimExportToExcelAsColumns()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Dimension: Record Dimension;
        Customer: Record Customer;
        FileName: Text[1024];
    begin
        Initialize();
        CreateAndExportBasicPackage(ConfigPackage, ConfigPackageTable, Customer, FileName);
        LibraryReportValidation.OpenExcelFile;

        Dimension.FindSet;
        repeat
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExists(
                StrSubstNo(ExportedDimensionCap, Dimension."Code Caption", Dimension.TableCaption)), IncorrectDimensionsAsColumnsErr);
        until Dimension.Next = 0;
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifyDefaultDimExportToExcel()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DefaultDimension: Record "Default Dimension";
        Customer: Record Customer;
        FileName: Text[1024];
    begin
        Initialize();
        CreateAndExportBasicPackage(ConfigPackage, ConfigPackageTable, Customer, FileName);

        SetDefaultDimFilter(DefaultDimension, DATABASE::Customer, Customer."No.");
        repeat
            Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(DefaultDimension."Dimension Value Code"),
              IncorrectDefaultDimensionsErr);
        until DefaultDimension.Next = 0;
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes,ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDefaultDimImportFromExcel()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Customer: Record Customer;
        ConfigPackageData: Record "Config. Package Data";
        DefaultDimension: Record "Default Dimension";
        FileName: Text[1024];
    begin
        Initialize();
        // [GIVEN] Customer 'X' with Default Dimensions
        // [GIVEN] Export the package 'A', where Table is 'Customer', "Dimensions as Columns" is 'Yes'
        CreateAndExportBasicPackage(ConfigPackage, ConfigPackageTable, Customer, FileName);
        // [WHEN] Import from Excel
        ImportPackageFromExcel(FileName);

        // [THEN] Package 'A', where data contains Defaul Dimensions for Customer
        SetDefaultDimFilter(DefaultDimension, DATABASE::Customer, Customer."No.");
        SetPackageDataFieldFilterByDefaultDimValueCode(ConfigPackageData, ConfigPackage.Code);
        repeat
            ConfigPackageData.SetRange(Value, DefaultDimension."Dimension Value Code");
            Assert.IsTrue(ConfigPackageData.FindSet, IncorrectDefaultDimensionsImportErr);
        until DefaultDimension.Next = 0;
    end;

    [Test]
    [HandlerFunctions('ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimImportFromExcelAsNewPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ConfigPackageData: Record "Config. Package Data";
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetTreeNode: Record "Dimension Set Tree Node";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        FileName: Text[1024];
        ExpectedDimSetID: Integer;
    begin
        Initialize();
        // [GIVEN] Gen. Journal Line, where Dimenson 'PROJECT' is 'TOYOTA'
        ExpectedDimSetID := CreateDimSet(DimensionValue);
        GenJournalLine.DeleteAll;
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo, 1.23);
        GenJournalLine.Validate("Dimension Set ID", ExpectedDimSetID);
        GenJournalLine.Modify(true);
        // [GIVEN] Package 'A', where Table is 'Gen. Journal Line', "Dimensions as Columns" is 'Yes'
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::"Gen. Journal Line");
        SetDimensionAsColumns(ConfigPackageTable);
        // [GIVEN] Field "Dimension Set ID" is excluded
        ConfigPackageField.Get(
          ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", GenJournalLine.FieldNo("Dimension Set ID"));
        ConfigPackageField.Validate("Include Field", false);
        ConfigPackageField.Modify(true);

        // [GIVEN] Export the package 'A'
        ExportPackageToExcel(ConfigPackageTable, FileName);

        // [GIVEN] Dimension Set Entry is removed
        DimensionSetEntry.SetRange("Dimension Set ID", ExpectedDimSetID);
        DimensionSetEntry.DeleteAll;
        DimensionSetTreeNode.SetRange("Dimension Set ID", ExpectedDimSetID);
        DimensionSetTreeNode.DeleteAll;
        // [GIVEN] Gen. Journal Line is removed
        GenJournalLine.DeleteAll;
        // [GIVEN] The package 'A' is removed
        ConfigPackage.Delete(true);

        // [WHEN] Import from Excel
        ImportPackageFromExcel(FileName);

        // [THEN] Package Field "Dimension Set ID" , where "Include Field" is 'Yes'
        ConfigPackageField.Get(
          ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", GenJournalLine.FieldNo("Dimension Set ID"));
        ConfigPackageField.TestField("Include Field", true);
        // [THEN] Package 'A', where data contains dimension value 'TOYOTA'
        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageData.SetRange("Table ID", DATABASE::"Gen. Journal Line");
        ConfigPackageData.SetRange(Value, DimensionValue.Code);
        ConfigPackageData.FindFirst;
        // [THEN] Package 'A' includes the Field, where "Dimension" is 'Yes', "Field Name" is 'PROJECT'
        ConfigPackageField.Get(ConfigPackage.Code, DATABASE::"Gen. Journal Line", ConfigPackageData."Field ID");
        ConfigPackageField.TestField(Dimension);
        ConfigPackageField.TestField("Field Name", DimensionValue."Dimension Code");

        // [WHEN] Apply Package 'A'
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Gen. Journal Line, where "Dimension Set ID" is filled and includes Dimenson 'PROJECT' as 'TOYOTA'
        GenJournalLine.Find;
        GenJournalLine.TestField("Dimension Set ID");
        DimMgt.GetDimensionSet(TempDimensionSetEntry, GenJournalLine."Dimension Set ID");
        Assert.RecordCount(TempDimensionSetEntry, 1);
        TempDimensionSetEntry.FindFirst;
        TempDimensionSetEntry.TestField("Dimension Code", DimensionValue."Dimension Code");
        TempDimensionSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimImportFromExcelIntoPackageWihtoutDimensions()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ConfigPackageData: Record "Config. Package Data";
        DimensionValue: Record "Dimension Value";
        FileName: Text[1024];
        ExpectedDimSetID: Integer;
    begin
        Initialize();
        // [GIVEN] Gen. Journal Line, where Dimenson 'PROJECT' is 'TOYOTA'
        ExpectedDimSetID := CreateDimSet(DimensionValue);
        GenJournalLine.DeleteAll;
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo, 1.23);
        GenJournalLine.Validate("Dimension Set ID", ExpectedDimSetID);
        GenJournalLine.Modify(true);
        // [GIVEN] Package 'A', where Table is 'Gen. Journal Line', "Dimensions as Columns" is 'Yes'
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::"Gen. Journal Line");
        SetDimensionAsColumns(ConfigPackageTable);
        // [GIVEN] Field "Dimension Set ID" is excluded
        ConfigPackageField.Get(
          ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", GenJournalLine.FieldNo("Dimension Set ID"));
        ConfigPackageField.Validate("Include Field", false);
        ConfigPackageField.Modify(true);
        // [GIVEN] Export the package 'A'
        ExportPackageToExcel(ConfigPackageTable, FileName);

        // [GIVEN] Gen. Journal Line is removed
        GenJournalLine.DeleteAll;
        // [GIVEN] Package 'A', where Table is 'Gen. Journal Line', "Dimensions as Columns" is 'No'
        DisableDimensionAsColumns(ConfigPackageTable);

        // [WHEN] Import from Excel
        ImportPackageFromExcel(FileName);

        // [THEN] Package 'A', where is no data containing dimension value 'TOYOTA'
        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageData.SetRange("Table ID", DATABASE::"Gen. Journal Line");
        ConfigPackageData.SetRange(Value, DimensionValue.Code);
        Assert.IsFalse(ConfigPackageData.FindFirst, 'Dim data should not be imported');

        // [WHEN] Apply Package 'A'
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Gen. Journal Line, where Dimensons are <blank>
        GenJournalLine.Find;
        GenJournalLine.TestField("Dimension Set ID", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes,ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure DimensionsOnApply_PackageWithNewDimensions_DimensionRecordsCreated()
    var
        Customer: Record Customer;
        ConfigPackageError: Record "Config. Package Error";
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ConfigPackageCode: Code[20];
    begin
        Initialize();
        // [WHEN] Import and apply the package, where "Dimensions as Columns" is 'Yes', exported to Excel
        ConfigPackageCode := ExportImportAndApplyPackageWithNewDimension(Customer, false);

        // [THEN] Dimension, DimensionValue, and Default Dimension for Customer are created.
        SetDefaultDimFilter(DefaultDimension, DATABASE::Customer, Customer."No.");
        DimensionValue.SetRange("Dimension Code", DefaultDimension."Dimension Code");
        Assert.RecordCount(DimensionValue, 1);
        Assert.IsTrue(Dimension.Get(DefaultDimension."Dimension Code"), NewDimensionNotCreatedErr);
        // [THEN] No errors happened on apply
        ConfigPackageError.Init;
        ConfigPackageError.SetRange("Table ID", DATABASE::"Dimension Value");
        ConfigPackageError.SetRange("Package Code", ConfigPackageCode);
        Assert.RecordIsEmpty(ConfigPackageError);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes,ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure DimensionsValueOnApply_PackageWithDimensionValueIdField_PackageErrorCreated()
    var
        Customer: Record Customer;
    begin
        Initialize();
        ExportImportAndApplyPackageWithNewDimension(Customer, true);

        Assert.IsTrue(
          PackageErrorsContainsErrorWithSubstring(DATABASE::"Dimension Value", AutoincrementMsg), DimensionValueIdNotExistsErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifyPackageDataUpdatedWithDimAsColumns()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        CreateCustomerPackageData(ConfigPackage, ConfigPackageTable);
        SetDimensionAsColumns(ConfigPackageTable);
        CheckCustomerPackageDataUpdated(ConfigPackage.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionSet_DimAsColumnsDimTablesAdded()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
    begin
        // System do not suggests dimension tables while switch ON "Dimensions As Columns" for tables that have Dimension Set ID.
        CreateBasicPackageForDimSet(ConfigPackage, ConfigPackageTable, SalesHeader, DATABASE::"Sales Header");
        SetDimensionAsColumns(ConfigPackageTable);

        Assert.AreEqual(1, ConfigPackageTable.Count, IncorrectNumberOfTablesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionSet_ExportWithDimensionColumn()
    var
        SalesHeader: Record "Sales Header";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Dimension: Record Dimension;
        DimensionSetEntry: Record "Dimension Set Entry";
        FileName: Text;
        DimensionColumnCaption: Text[250];
    begin
        // Export table with Dimension Set: Verify Dimension Set exported as values in appropriate Dimension columns

        CreateBasicPackageForDimSet(ConfigPackage, ConfigPackageTable, SalesHeader, DATABASE::"Sales Header");
        SetDimensionAsColumns(ConfigPackageTable);

        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ExportPackageToExcel(ConfigPackageTable, FileName);
        LibraryReportValidation.OpenExcelFile;

        DimensionSetEntry.SetRange("Dimension Set ID", SalesHeader."Dimension Set ID");
        Dimension.FindSet;
        repeat
            DimensionColumnCaption := StrSubstNo(ExportedDimensionCap, Dimension."Code Caption", Dimension.TableCaption);
            DimensionSetEntry.SetRange("Dimension Code", Dimension.Code);
            LibraryReportValidation.SetColumn(DimensionColumnCaption);
            if DimensionSetEntry.FindFirst then begin
                LibraryReportValidation.SetRange(DimensionColumnCaption, DimensionSetEntry."Dimension Value Code");
                Assert.AreEqual(DimensionSetEntry."Dimension Value Code", LibraryReportValidation.GetValue, IncorrectDimensionsAsColumnsErr);
            end;
        until Dimension.Next = 0;
    end;

    [Test]
    [HandlerFunctions('ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure DimensionSet_ImportWithExistingDimension()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        ConfigPackageCode: Code[20];
        OldDimValue: Code[20];
        LastDimensionSetID: Integer;
        DimensionSetID: Integer;
        TableID: Integer;
    begin
        // Verify Dimension Set imported with existing dimension created with correct values.

        TableID := DATABASE::"Sales Header";
        PrepareAndImportPackageForDimSet(
          DimensionSetEntry, ConfigPackageCode, OldDimValue, LastDimensionSetID, DimensionSetID, TableID, false);

        VerifyImportForDimensionSet(DimensionSetEntry, ConfigPackageCode, LastDimensionSetID, DimensionSetID, TableID);

        RestoreDimSetEntry(DimensionSetEntry, OldDimValue);
    end;

    [Test]
    [HandlerFunctions('ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure DimensionSet_ImportWithNonExistingDimension()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        ConfigPackageCode: Code[20];
        OldDimValue: Code[20];
        LastDimensionSetID: Integer;
        DimensionSetID: Integer;
        TableID: Integer;
    begin
        // Verify Dimension Set is not created and config package error has been added.

        TableID := DATABASE::"Sales Header";
        PrepareAndImportPackageForDimSet(
          DimensionSetEntry, ConfigPackageCode, OldDimValue, LastDimensionSetID, DimensionSetID, TableID, true);

        VerifyImportErrorWithNonExistingDimension(DimensionSetEntry, TableID);

        RestoreDimSetEntry(DimensionSetEntry, OldDimValue);
    end;

    [Test]
    [HandlerFunctions('ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure DimensionSet_ImportAndApply()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        OldDimValCode: Code[20];
        SalesHeaderNo: Code[20];
        SalesHeaderDocType: Option;
        FileName: Text;
        OldManualNos: Boolean;
    begin
        // Verify Dimension Set applied correctly.
        CreateBasicPackageForDimSet(ConfigPackage, ConfigPackageTable, SalesHeader, DATABASE::"Sales Header");
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        SetDimensionAsColumns(ConfigPackageTable);

        DimensionSetEntry.SetRange("Dimension Set ID", SalesHeader."Dimension Set ID");
        DimensionSetEntry.FindFirst;
        OldDimValCode := DimensionSetEntry."Dimension Value Code";
        ModifyDimensionSetWithNewValue(DimensionSetEntry, DimensionValue);
        ExportPackageToExcel(ConfigPackageTable, FileName);
        RestoreDimensionSetWithOldValue(DimensionSetEntry, DimensionValue, OldDimValCode, false);

        SalesHeaderNo := SalesHeader."No.";
        SalesHeaderDocType := SalesHeader."Document Type";

        OldManualNos := SetupManualNos(SalesHeader."No. Series", true);

        SalesHeader.Delete(true);

        ImportPackageFromExcel(FileName);

        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // Verify Dimension Set ID in sales header is equal to ID in last created Dimension SetID
        SalesHeader.Get(SalesHeaderDocType, SalesHeaderNo);
        DimensionSetEntry.Reset;
        DimensionSetEntry.FindLast;
        Assert.AreEqual(DimensionSetEntry."Dimension Set ID", SalesHeader."Dimension Set ID", IncorrectDimensionSetIDErr);

        SetupManualNos(SalesHeader."No. Series", OldManualNos);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure ApplyPackageWithDimensionsAsColumnsExistingCustomer()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        Customer: Record Customer;
        DimensionCode: Code[20];
    begin
        Initialize();
        CreateConfigLineAssignPackage(ConfigPackage, ConfigLine);
        LibrarySales.CreateCustomer(Customer);
        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::Customer, 1, Customer.FieldNo("No."), Customer."No.");

        DimensionCode := SetDefaultDimensionInPackage(ConfigLine."Package Code", Customer."No.");
        ApplyConfigLineAndVerifyApplication(ConfigLine, Customer."No.", DimensionCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes')]
    [Scope('OnPrem')]
    procedure ApplyPackageWithDimensionsAsColumnsNewCustomer()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
        Customer: Record Customer;
        DimVal: Record "Dimension Value";
        NewCustomerNo: Code[20];
    begin
        NewCustomerNo := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        FindDimensionWithValue(DimVal);

        CreateConfigPackageWithNewCustomer(ConfigPackage, ConfigPackageTable, ConfigLine, NewCustomerNo);
        ExportImportPackageSetNewCustAndDim(ConfigPackage, ConfigPackageTable, NewCustomerNo, DimVal."Dimension Code", DimVal.Code);

        ApplyConfigLineAndVerifyApplication(ConfigLine, NewCustomerNo, DimVal."Dimension Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageWithDimAsColumnsWithoutSettingDimSetIDField()
    var
        DimVal: Record "Dimension Value";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
        OldManualNos: Boolean;
    begin
        // Verify that dimensions can be applied from package when field "Dimension Set ID" is not included.

        Initialize();
        CreatePackageExcludingDimSetIDField(ConfigPackage, ConfigPackageTable, SalesHeader);

        FindDimValueFromDefDim(DimVal, DATABASE::Customer, SalesHeader."Sell-to Customer No.");
        ExportImportPackageSetNewDimension(ConfigPackage, ConfigPackageTable, DimVal."Dimension Code", DimVal.Code);

        OldManualNos := SetupManualNos(SalesHeader."No. Series", true);

        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        SalesHeader.Find; // get latest version after applying package
        VerifyDimValueExistsInSalesHeaderDimSetID(SalesHeader, DimVal);

        SetupManualNos(SalesHeader."No. Series", OldManualNos);
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes,ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure ImportExcelTemplateToConfigPackageWithDimAsColumnsTwice()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        GLAccount: Record "G/L Account";
        ConfigLine: Record "Config. Line";
        DefaultDimension: array[2] of Record "Default Dimension";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        Index: Integer;
    begin
        // [FEATURE] [Excel]
        // [SCENARIO 377912] It should be possible to import same Excel Template to Configuration Package with "Dimensions As Columns" twice

        // [GIVEN] Config. Package "CP" with basic setup
        Initialize();
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        // [GIVEN] G/L Account "X" with two default dimensions "D[1]" and "D[2]"
        GLAccount.DeleteAll;
        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] Default Dimensions Code: "AREA", Value: "10" and Code: "PROJECT", Value:"TOYOTA" assigned to "X"
        CreateDefaultDimForGLAccount(GLAccount."No.", DefaultDimension[1]);
        // [GIVEN] "D[2]".Code = "DCODE2" and "D[2]".Value = "DVALUE2"
        CreateDefaultDimForGLAccount(GLAccount."No.", DefaultDimension[2]);

        // [GIVEN] "CP" assigned to Config. Line "CL" where "CL"."Table ID" = 15 (DATABASE::"G/L Account"), "Dimensions As Columns" = Yes
        LibraryRapidStart.CreateConfigLine(
          ConfigLine, ConfigLine."Line Type"::Table, DATABASE::"G/L Account", '', ConfigPackage.Code, false);
        FindConfigLineByTable(ConfigLine, DATABASE::"G/L Account");
        ConfigPackageManagement.AssignPackage(ConfigLine, ConfigPackage.Code);
        SetDimensionAsColumnsAtConfigLine(ConfigLine);

        // [GIVEN] "CP" exported and imported as Excel Template
        ConfigExcelExchange.SetHideDialog(true);
        FileName := ConfigExcelExchange.ExportExcelFromConfig(ConfigLine);
        FileName := FileManagement.UploadFile('', FileName);
        ImportPackageFromExcel(FileName);

        // [WHEN] Import "CP" as Excel Template second time
        ImportPackageFromExcel(FileName);

        // [THEN] "Config. Package Data" has value "AREA" for "Field ID" = 3 and "Rec No" = 1
        // [THEN] "Config. Package Data" has value "10" for "Field ID" = 4 and "Rec No" = 1
        // [THEN] "Config. Package Data" has value "PROJECT" for "Field ID" = 3 and "Rec No" = 2
        // [THEN] "Config. Package Data" has value "TOYOTA" for "Field ID" = 4 and "Rec No" = 2
        for Index := 1 to ArrayLen(DefaultDimension) do begin
            Assert.AreEqual(
              DefaultDimension[Index]."Dimension Code",
              GetConfigPackageDataValue(ConfigPackage.Code, DATABASE::"Default Dimension", Index, 3),
              IncorrectDefaultDimensionsImportErr);
            Assert.AreEqual(
              DefaultDimension[Index]."Dimension Value Code",
              GetConfigPackageDataValue(ConfigPackage.Code, DATABASE::"Default Dimension", Index, 4),
              IncorrectDefaultDimensionsImportErr);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmAddDimTablesHandlerYes,ImportPreviewModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDefaultDimManualPaymentImportFromExcel()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        CashFlowManualExpense: Record "Cash Flow Manual Expense";
        ConfigPackageData: Record "Config. Package Data";
        DefaultDimension: Record "Default Dimension";
        FileName: Text;
    begin
        // [FEATURE] [Excel]
        // [SCENARIO 322992] It should be possible to import a package with table containing Primary Key field of Field No = 2

        Initialize();
        // [GIVEN] Manual Payment with Default Dimension "DefDim"
        CreateManualPaymentWithDefaultDimension(CashFlowManualExpense, DefaultDimension);
        // [GIVEN] Export the package "A", where Table is 'CashFlowManualExpense', "Dimensions as Columns" is 'Yes'
        CreateAndExportBasicPackageWithManualPayment(ConfigPackage, ConfigPackageTable, CashFlowManualExpense, FileName);

        // [WHEN] Import from Excel
        ImportPackageFromExcel(FileName);

        // [THEN] Package "A", where data contains Default Dimension "DefDim" for CashFlowManualExpense
        SetDefaultDimFilter(DefaultDimension, DATABASE::"Cash Flow Manual Expense", CashFlowManualExpense.Code);
        SetPackageDataFieldFilterByDefaultDimValueCode(ConfigPackageData, ConfigPackage.Code);

        ConfigPackageData.SetRange(Value, DefaultDimension."Dimension Value Code");
        Assert.IsTrue(ConfigPackageData.FindSet, IncorrectDefaultDimensionsImportErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM RS Dimensions as Columns");

        LibraryApplicationArea.EnableFoundationSetup();

        LibraryRapidStart.CleanUp('');
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM RS Dimensions as Columns");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryRapidStart.SetAPIServicesEnabled(false);

        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM RS Dimensions as Columns");
    end;

    local procedure CreateBasicPackage(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; TableId: Integer)
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableId);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
    end;

    local procedure DisableDimensionAsColumns(var ConfigPackageTable: Record "Config. Package Table")
    begin
        ConfigPackageTable.Validate("Dimensions as Columns", false);
        ConfigPackageTable.Modify;
    end;

    local procedure SetDimensionAsColumns(var ConfigPackageTable: Record "Config. Package Table")
    begin
        ConfigPackageTable.Validate("Dimensions as Columns", true);
        ConfigPackageTable.Modify;
    end;

    local procedure SetDimensionAsColumnsAtConfigLine(var ConfigLine: Record "Config. Line")
    begin
        ConfigLine.Validate("Dimensions as Columns", true);
        ConfigLine.Modify;
    end;

    local procedure SetPackageFilterByCustomer(var Customer: Record Customer; ConfigPackageCode: Code[20])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateDefaultDimForCustomer(Customer."No.");

        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackageCode, DATABASE::Customer, 0, Customer.FieldNo("No."), Customer."No.");
    end;

    local procedure CreateDefaultDimForCustomer(CustomerNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateDefaultDimForGLAccount(GLAccountNo: Code[20]; var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateDimSet(var DimensionValue: Record "Dimension Value"): Integer
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code));
    end;

    local procedure SetDefaultDimFilter(var DefaultDimension: Record "Default Dimension"; TableID: Integer; MasterNo: Code[20])
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", MasterNo);
        DefaultDimension.FindSet;
    end;

    local procedure SetPackageDataFieldFilterByDefaultDimValueCode(var ConfigPackageData: Record "Config. Package Data"; ConfigPackageCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        ConfigPackageData.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageData.SetRange("Table ID", DATABASE::"Default Dimension");
        ConfigPackageData.SetRange("Field ID", DefaultDimension.FieldNo("Dimension Value Code"));
        ConfigPackageData.FindSet;
    end;

    local procedure ExportPackageToExcel(var ConfigPackageTable: Record "Config. Package Table"; var FileName: Text)
    var
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
        FileManagement: Codeunit "File Management";
    begin
        ConfigExcelExchange.SetHideDialog(true);
        ConfigExcelExchange.ExportExcel(FileName, ConfigPackageTable, true, false); // Returns FileName on the client
        FileName := FileManagement.UploadFileSilent(FileName);
        LibraryReportValidation.SetFullFileName(FileName);
    end;

    local procedure ImportPackageFromExcel(ClientFileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
    begin
        FileManagement.BLOBImportFromServerFile(TempBlob, FileManagement.UploadFileSilent(ClientFileName));
        ConfigExcelExchange.ImportExcel(TempBlob);
    end;

    local procedure CreateAndExportBasicPackage(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; var Customer: Record Customer; var FileName: Text)
    begin
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        SetPackageFilterByCustomer(Customer, ConfigPackage.Code);
        SetDimensionAsColumns(ConfigPackageTable);
        ExportPackageToExcel(ConfigPackageTable, FileName);
    end;

    local procedure CreateAndExportBasicPackageWithManualPayment(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; var CashFlowManualExpense: Record "Cash Flow Manual Expense"; var FileName: Text)
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::"Cash Flow Manual Expense");
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::"Cash Flow Manual Expense", 0,
          CashFlowManualExpense.FieldNo(Code), CashFlowManualExpense.Code);
        SetDimensionAsColumns(ConfigPackageTable);
        ExportPackageToExcel(ConfigPackageTable, FileName);
    end;

    local procedure CreatePackageExcludingDimSetIDField(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        ConfigPackageField: Record "Config. Package Field";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        CreateNewCustomerAndNewLinkedDimension(Customer, DefaultDimension, DimensionValue);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Header");
        SetDimensionAsColumns(ConfigPackageTable);
        ConfigPackageField.Get(ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", DATABASE::"Dimension Set Entry");
        ConfigPackageField.Validate("Include Field", false);
        ConfigPackageField.Modify(true);

        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        SetPackageFilterForTable(ConfigPackage.Code, DATABASE::"Sales Header", SalesHeader.FieldNo("No."), SalesHeader."No.");
    end;

    local procedure CreateBasicPackageForDimSet(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; var SalesHeader: Record "Sales Header"; TableID: Integer)
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        CreateNewCustomerAndNewLinkedDimension(Customer, DefaultDimension, DimensionValue);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        TableID := DATABASE::"Sales Header";
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        SetPackageFilterForTable(ConfigPackage.Code, TableID, SalesHeader.FieldNo("No."), SalesHeader."No.");
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
    end;

    local procedure CreateManualPaymentWithDefaultDimension(var CashFlowManualExpense: Record "Cash Flow Manual Expense"; var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
    begin
        LibraryCashFlowHelper.CreateManualPayment(CashFlowManualExpense);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Cash Flow Manual Expense",
          CashFlowManualExpense.Code, Dimension.Code, DimensionValue.Code);
    end;

    local procedure PrepareAndImportPackageForDimSet(var DimensionSetEntry: Record "Dimension Set Entry"; var ConfigPackageCode: Code[20]; var OldDimValue: Code[20]; var LastDimensionSetID: Integer; var DimensionSetID: Integer; TableID: Integer; DeleteDimension: Boolean)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        FileName: Text[1024];
    begin
        CreateBasicPackageForDimSet(ConfigPackage, ConfigPackageTable, SalesHeader, TableID);

        ConfigPackageCode := ConfigPackage.Code;
        SetDimensionAsColumns(ConfigPackageTable);
        DimensionSetID := SalesHeader."Dimension Set ID";

        // Save Dimension Set ID value
        DimensionSetEntry.FindLast;
        LastDimensionSetID := DimensionSetEntry."Dimension Set ID";

        // Change dimension values and import package
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst;
        OldDimValue := DimensionSetEntry."Dimension Value Code";
        ModifyDimensionSetWithNewValue(DimensionSetEntry, DimensionValue);
        ExportPackageToExcel(ConfigPackageTable, FileName);
        if DeleteDimension then
            DimensionValue.Delete;
        ImportPackageFromExcel(FileName);
    end;

    local procedure SetPackageFilterForTable(ConfigPackageCode: Code[20]; TableID: Integer; FieldID: Integer; FieldFilter: Text[250])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigPackageMgt.InsertPackageFilter(ConfigPackageFilter, ConfigPackageCode, TableID, 0, FieldID, FieldFilter);
    end;

    local procedure ModifyDimensionSetWithNewValue(var DimensionSetEntry: Record "Dimension Set Entry"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionSetEntry."Dimension Code");

        DimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        DimensionSetEntry.Modify;
    end;

    local procedure RestoreDimensionSetWithOldValue(var DimensionSetEntry: Record "Dimension Set Entry"; var DimensionValue: Record "Dimension Value"; OldDimensionValueCode: Code[20]; DeleteDimension: Boolean)
    begin
        DimensionSetEntry."Dimension Value Code" := OldDimensionValueCode;
        DimensionSetEntry.Modify;

        if DeleteDimension then
            DimensionValue.Delete;
    end;

    local procedure VerifyImportForDimensionSet(var DimensionSetEntry: Record "Dimension Set Entry"; ConfigPackageCode: Code[20]; LastDimensionSetID: Integer; FADimensionSetID: Integer; TableID: Integer)
    begin
        // Verify Dimension Set created
        DimensionSetEntry.Reset;
        DimensionSetEntry.FindLast;
        Assert.IsTrue(LastDimensionSetID < DimensionSetEntry."Dimension Set ID", DimensionSetIsNotCreatedErr);

        // Verify Dimensions is equal to exported values
        DimensionSetEntry.SetRange("Dimension Set ID", FADimensionSetID);
        VerifyDimensionSetEqualToConfigPackageData(DimensionSetEntry, ConfigPackageCode, TableID);
    end;

    local procedure VerifyDimensionSetEqualToConfigPackageData(var DimensionSetEntry: Record "Dimension Set Entry"; PackageCode: Code[20]; TableID: Integer)
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", TableID);
        DimensionSetEntry.FindFirst;
        repeat
            ConfigPackageData.SetRange(Value, DimensionSetEntry."Dimension Value Code");
            if ConfigPackageData.FindSet then
                repeat
                    Assert.IsFalse(
                      DimensionSetEntry.IsEmpty, StrSubstNo(DimensionValueCodeIsNotFoundErr, DimensionSetEntry."Dimension Value Code"));
                until ConfigPackageData.Next = 0;
        until DimensionSetEntry.Next = 0;
    end;

    local procedure VerifyDimValueExistsInSalesHeaderDimSetID(SalesHeader: Record "Sales Header"; DimVal: Record "Dimension Value")
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        SalesHeader.TestField("Dimension Set ID");
        DimSetEntry.SetRange("Dimension Set ID", SalesHeader."Dimension Set ID");
        DimSetEntry.SetRange("Dimension Code", DimVal."Dimension Code");
        DimSetEntry.SetRange("Dimension Value Code", DimVal.Code);
        Assert.IsTrue(
          not DimSetEntry.IsEmpty,
          StrSubstNo(DimValueDoesNotExistsInDimSetErr, DimVal."Dimension Code", DimVal.Code, SalesHeader."Dimension Set ID"));
    end;

    local procedure VerifyImportErrorWithNonExistingDimension(DimensionSetEntry: Record "Dimension Set Entry"; TableID: Integer)
    var
        DimensionValue: Record "Dimension Value";
        ErrorText: Text[250];
    begin
        Assert.IsFalse(DimensionValue.Get(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"),
          StrSubstNo(DimensionValueIsCreatedForDimSetErr, DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        ErrorText :=
          StrSubstNo(DimValueDoesNotExistsErr, DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code");
        Assert.IsTrue(
          PackageErrorsContainsErrorWithSubstring(TableID, ErrorText), NonExistingDimValueExistsErr);
    end;

    local procedure CreateCustomerPackageData(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table")
    var
        Customer: Record Customer;
    begin
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          ConfigPackageTable,
          ConfigPackageTable."Table ID",
          Customer.FieldNo(Name),
          LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer),
          Customer.FieldNo("No."));
    end;

    local procedure CheckCustomerPackageDataUpdated(PackageCode: Code[20])
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
        Customer: Record Customer;
    begin
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageData.SetRange("No.", Customer.FieldNo("No."));

        ConfigPackageField.SetRange("Package Code", PackageCode);
        ConfigPackageField.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageField.SetRange(Dimension, true);
        ConfigPackageField.FindSet;
        repeat
            ConfigPackageData.SetRange("Field ID", ConfigPackageField."Field ID");
            Assert.IsTrue(ConfigPackageData.FindFirst, IncorrectDimPackageDataErr);
        until ConfigPackageField.Next = 0;
    end;

    local procedure CreateNewCustomerAndNewLinkedDimension(var Customer: Record Customer; var DefaultDimension: Record "Default Dimension"; var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        Dimension.DeleteAll;
        DimensionValue.DeleteAll;
        DefaultDimension.DeleteAll;

        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        LibrarySales.CreateCustomer(Customer);

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Customer, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure ExportImportAndApplyPackageWithNewDimension(var Customer: Record Customer; AddDimValueIdField: Boolean): Code[20]
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        FileName: Text[1024];
    begin
        CreateNewCustomerAndNewLinkedDimension(Customer, DefaultDimension, DimensionValue);

        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        SetDimensionAsColumns(ConfigPackageTable);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::Customer, 0, Customer.FieldNo("No."), Customer."No.");

        if AddDimValueIdField then
            ConfigPackageMgt.InsertPackageField(
              ConfigPackageField,
              ConfigPackage.Code,
              DATABASE::"Dimension Value",
              DimensionValue.FieldNo("Dimension Value ID"),
              DimensionValue.FieldName("Dimension Value ID"),
              DimensionValue.FieldCaption("Dimension Value ID"),
              true, true, false, false);

        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ExportPackageToExcel(ConfigPackageTable, FileName);

        DefaultDimension.Delete;
        DimensionValue.Delete;

        ImportPackageFromExcel(FileName);

        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        exit(ConfigPackage.Code);
    end;

    local procedure PackageErrorsContainsErrorWithSubstring(TableId: Integer; Substring: Text[250]): Boolean
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.SetRange("Table ID", TableId);
        ConfigPackageError.FindSet;
        repeat
            if StrPos(ConfigPackageError."Error Text", Substring) <> 0 then
                exit(true);
        until ConfigPackageError.Next = 0;
    end;

    local procedure CreateConfigLineAssignPackage(var ConfigPackage: Record "Config. Package"; var ConfigLine: Record "Config. Line")
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        CreateBasicPackage(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Customer, '', ConfigPackage.Code, true);
    end;

    local procedure SetDefaultDimensionInPackage(ConfigPackageCode: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        Dimension: Record Dimension;
        DimVal: Record "Dimension Value";
        DefaultDim: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimVal, Dimension.Code);

        LibraryRapidStart.CreatePackageData(
          ConfigPackageCode, DATABASE::"Default Dimension", 1, DefaultDim.FieldNo("Table ID"), Format(DATABASE::Customer));
        LibraryRapidStart.CreatePackageData(
          ConfigPackageCode, DATABASE::"Default Dimension", 1, DefaultDim.FieldNo("No."), CustomerNo);
        LibraryRapidStart.CreatePackageData(
          ConfigPackageCode, DATABASE::"Default Dimension", 1, DefaultDim.FieldNo("Dimension Code"), Dimension.Code);
        LibraryRapidStart.CreatePackageData(
          ConfigPackageCode, DATABASE::"Default Dimension", 1, DefaultDim.FieldNo("Dimension Value Code"), DimVal.Code);

        exit(Dimension.Code);
    end;

    local procedure ApplyConfigLineAndVerifyApplication(var ConfigLine: Record "Config. Line"; CustomerNo: Code[20]; DimensionCode: Code[20])
    var
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigLine.SetRange("Line No.", ConfigLine."Line No.");
        ConfigPackageMgt.SetHideDialog(true);
        ConfigPackageMgt.ApplyConfigLines(ConfigLine);

        VerifyDefaultDimApplied(CustomerNo, DimensionCode);
    end;

    local procedure VerifyDefaultDimApplied(CustomerNo: Code[20]; DimensionCode: Code[20])
    var
        DefaultDim: Record "Default Dimension";
    begin
        DefaultDim.SetRange("Table ID", DATABASE::Customer);
        DefaultDim.SetRange("No.", CustomerNo);
        DefaultDim.SetRange("Dimension Code", DimensionCode);
        Assert.IsFalse(DefaultDim.IsEmpty, DimensionNotAppliedErr);
    end;

    local procedure CreateConfigPackageWithNewCustomer(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; var ConfigLine: Record "Config. Line"; CustomerNo: Code[20])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        Customer: Record Customer;
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigMgt: Codeunit "Config. Management";
    begin
        CreateConfigLineAssignPackage(ConfigPackage, ConfigLine);

        LibraryRapidStart.CreatePackageData(ConfigPackage.Code, DATABASE::Customer, 1, Customer.FieldNo("No."), CustomerNo);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::Customer, 0, Customer.FieldNo("No."), CustomerNo);

        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetFilter("Table ID", ConfigMgt.MakeTableFilter(ConfigLine, true));
    end;

    local procedure ExportImportPackageSetNewCustAndDim(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; CustomerNo: Code[20]; DimCode: Code[20]; DimValCode: Code[20])
    begin
        ExportImportPackageSetNewValues(ConfigPackage, ConfigPackageTable, CustomerNo, DimCode, DimValCode);
    end;

    local procedure ExportImportPackageSetNewDimension(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; DimCode: Code[20]; DimValCode: Code[20])
    begin
        ExportImportPackageSetNewValues(ConfigPackage, ConfigPackageTable, '', DimCode, DimValCode);
    end;

    local procedure ExportImportPackageSetNewValues(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; CustomerNo: Code[20]; DimCode: Code[20]; DimValCode: Code[20])
    var
        Customer: Record Customer;
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        PackageXML: DotNet XmlDocument;
    begin
        PackageXML := PackageXML.XmlDocument;
        ConfigXMLExchange.SetExcelMode(true);
        ConfigXMLExchange.ExportPackageXMLDocument(PackageXML, ConfigPackageTable, ConfigPackage, false);

        if CustomerNo <> '' then
            SetXMLNodeValue(PackageXML, ConfigXMLExchange.GetElementName(Customer.FieldName("No.")), CustomerNo);
        if DimCode <> '' then
            SetXMLNodeValue(PackageXML, ConfigXMLExchange.GetElementName(DimCode), DimValCode);

        ConfigXMLExchange.ImportPackageXMLDocument(PackageXML, '');
    end;

    local procedure SetXMLNodeValue(var PackageXML: DotNet XmlDocument; NodeName: Text[250]; NodeValue: Code[20])
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLNode := PackageXML.SelectSingleNode('//' + NodeName);
        XMLNode.InnerText := NodeValue;
    end;

    local procedure FindConfigLineByTable(var ConfigLine: Record "Config. Line"; TableId: Integer)
    begin
        ConfigLine.SetRange("Table ID", TableId);
        ConfigLine.SetRange("Line Type", ConfigLine."Line Type"::Table);

        ConfigLine.FindFirst;
        ConfigLine.SetRecFilter;
    end;

    local procedure FindDimensionWithValue(var DimVal: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimVal, Dimension.Code);
    end;

    local procedure FindDimValueFromDefDim(var DimVal: Record "Dimension Value"; SourceTableID: Integer; SourceNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", SourceTableID);
        DefaultDimension.SetRange("No.", SourceNo);
        DefaultDimension.FindFirst;

        LibraryDimension.FindDimensionValue(DimVal, DefaultDimension."Dimension Code");
    end;

    local procedure GetConfigPackageDataValue(ConfigPackageCode: Code[20]; TableId: Integer; RecNo: Integer; FieldId: Integer): Text
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageData.Get(ConfigPackageCode, TableId, RecNo, FieldId);
        exit(ConfigPackageData.Value);
    end;

    local procedure SetupManualNos(NoSeriesCode: Code[20]; NewManualNos: Boolean) ManualNos: Boolean
    var
        NoSeries: Record "No. Series";
    begin
        with NoSeries do begin
            Get(NoSeriesCode);
            ManualNos := "Manual Nos.";
            "Manual Nos." := NewManualNos;
            Modify;
        end
    end;

    local procedure RestoreDimSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; OldDimValue: Code[20])
    begin
        DimensionSetEntry.FindFirst;
        DimensionSetEntry."Dimension Value Code" := OldDimValue;
        DimensionSetEntry.Modify;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmAddDimTablesHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmAddDimTablesHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ImportPreviewModalPageHandler(var ConfigPackageImportPreview: TestPage "Config. Package Import Preview")
    begin
        ConfigPackageImportPreview.Import.Invoke;
    end;
}

