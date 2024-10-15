codeunit 137210 "SCM Copy Production BOM"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Production BOM] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        ErrAutoCopy: Label 'The Production BOM Header cannot be copied to itself.';
        ErrBOMIsCertified: Label 'Status on Production BOM Header %1 must not be Certified';
        ProdBOMVersionCode: Code[20];
        ErrBomVersionIsCertified: Label 'Status on Production BOM Version %1';
        ProdBOMNo: Code[20];
        CountError: Label 'Version Count Must Match.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Copy Production BOM");
        Clear(ProdBOMNo);
        Clear(ProdBOMVersionCode);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Copy Production BOM");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Copy Production BOM");
    end;

    [Normal]
    local procedure CopyToHeader(var ProductionBOMHeader: Record "Production BOM Header"; BOMStatus: Enum "BOM Status")
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and Version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, BOMStatus);

        // Create destination Production BOM Header.
        CreateProductionBOM(ProductionBOMHeader);

        // Set status on destination BOM Header.
        ProductionBOMHeader.Validate(Status, BOMStatus);
        ProductionBOMHeader.Modify(true);

        // Exercise: Copy BOM from source Production BOM Header.
        ProductionBOMCopy.CopyBOM(ProdBOMNo, '', ProductionBOMHeader, '');

        // Verify: Production BOM lines are retrieved from source Production BOM.
        VerifyProductionBOMLines(ProdBOMNo, ProductionBOMHeader."No.", '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CopyToHeader(ProductionBOMHeader, ProductionBOMHeader.Status::New);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToCertifiedHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        asserterror CopyToHeader(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // Verify: Error: Destination BOM should not be certified.
        Assert.AreEqual(StrSubstNo(ErrBOMIsCertified, ProductionBOMHeader."No."), GetLastErrorText, '');
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToSameHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyToHeader(ProductionBOMHeader, ProductionBOMHeader.Status::New);

        // Exercise: Copy BOM from the same Production BOM Header.
        ProductionBOMHeader.Get(ProdBOMNo);
        asserterror ProductionBOMCopy.CopyBOM(ProdBOMNo, '', ProductionBOMHeader, '');

        // Verify: Error: BOM header cannot be copied to itself.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrAutoCopy) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromSameHeaderTwiceToHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyToHeader(ProductionBOMHeader, ProductionBOMHeader.Status::New);

        // Exercise: Copy again from Production BOM Header.
        ProductionBOMCopy.CopyBOM(ProdBOMNo, '', ProductionBOMHeader, '');

        // Verify: Production BOM lines are retrieved from source Production BOM.
        VerifyProductionBOMLines(ProdBOMNo, ProductionBOMHeader."No.", '', '');
    end;

    [Normal]
    local procedure CopyFromHeaderToVersion(var ProductionBOMVersion: Record "Production BOM Version"; BOMStatus: Enum "BOM Status")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, BOMStatus);

        // Exercise: Copy BOM from source Production BOM Header.
        ProductionBOMCopy.CopyBOM(ProductionBOMHeader."No.", '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate("Unit of Measure Code", ProductionBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Modify(true);

        // Verify: Production BOM lines are retrieved from source Production BOM Header.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", '', ProductionBOMVersion."Version Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        CopyFromHeaderToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromHeaderToCertifiedVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        asserterror CopyFromHeaderToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::Certified);

        // Verify: Error: destination should not be certified.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrBomVersionIsCertified, ProdBOMNo)) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FromSameHeaderTwiceToVersion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyFromHeaderToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);

        // Exercise: Copy BOM from source Production BOM Header again.
        ProductionBOMHeader.Get(ProdBOMNo);
        ProductionBOMCopy.CopyBOM(ProdBOMNo, '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate("Unit of Measure Code", ProductionBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Modify(true);

        // Verify: Production BOM lines are retrieved from source Production BOM Header.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", '', ProductionBOMVersion."Version Code");
    end;

    [Normal]
    local procedure CopyFromVersionToVersion(var ProductionBOMVersion: Record "Production BOM Version"; BOMStatus: Enum "BOM Status")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, BOMStatus);

        // Exercise: Copy BOM version from the desired BOM version.
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);

        // Verify: Production BOM lines are retrieved from source Production BOM Version.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", ProdBOMVersionCode,
          ProductionBOMVersion."Version Code");
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromVersionToVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        CopyFromVersionToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromVersionToSameVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyFromVersionToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);

        // Exercise: Copy BOM version to same BOM version.
        ProductionBOMVersion.Get(ProdBOMNo, ProdBOMVersionCode);
        asserterror ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);

        // Verify: Error: Cannot use the same version as source.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrAutoCopy) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromVersionToCertifiedVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        asserterror CopyFromVersionToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::Certified);

        // Verify: Error: destination should not be certified.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrBomVersionIsCertified, ProdBOMNo)) > 0, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromSameVersionTwiceToVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        CopyFromVersionToVersion(ProductionBOMVersion, ProductionBOMVersion.Status::New);

        // Exercise: Copy again from same version.
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);

        // Verify: Production BOM lines are retrieved from source Production BOM Version.
        VerifyProductionBOMLines(ProdBOMNo, ProdBOMNo, ProdBOMVersionCode, ProductionBOMVersion."Version Code");
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromVersionThenHeader()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMHeader.Status::New);

        // Exercise: Copy BOM version, first from the BOM version, then from the Production BOM header.
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);
        ProductionBOMCopy.CopyBOM(ProductionBOMHeader."No.", '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate("Unit of Measure Code", ProductionBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Modify(true);

        // Verify: BOM lines are copied from previous header only once.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", '', ProductionBOMVersion."Version Code");
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure FromHeaderThenVersion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMHeader.Status::New);

        // Exercise: Copy BOM version from Header, then from the other Production BOM version.
        ProductionBOMCopy.CopyBOM(ProductionBOMHeader."No.", '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);

        // Verify: Error: BOM lines are copied from previous version only once.
        VerifyProductionBOMLines(ProductionBOMHeader."No.", ProductionBOMHeader."No.", ProdBOMVersionCode,
          ProductionBOMVersion."Version Code");
    end;

    [Test]
    [HandlerFunctions('ProdBOMListHandler')]
    [Scope('OnPrem')]
    procedure MatrixPageVersionToVersion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
        VersionCode: array[32] of Text[80];
        VersionCount: Integer;
    begin
        // Setup: Create source Production BOM and version.
        Initialize();
        SetupCopyBOM(ProductionBOMHeader, ProductionBOMVersion, ProductionBOMVersion.Status::New);

        // Exercise: Copy BOM version from the desired BOM version, Generating Matrix Data and Calculating Total No. of Version Count And
        // version.
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);
        VersionCount := GenerateMatrixData(VersionCode, ProductionBOMHeader."No.");

        // Verify : BOM Matrix Column Count And Column with source Production BOM Version.
        VerifyMatrixBOMVersion(ProductionBOMHeader."No.", VersionCode, VersionCount);
    end;

    [Normal]
    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header")
    var
        ProductionBOMLine: Record "Production BOM Line";
        UnitOfMeasure: Record "Unit of Measure";
        Item: Record Item;
        Counter: Integer;
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);
        ProductionBOMHeader.Validate("Version Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ProductionBOMHeader.Modify(true);

        for Counter := 1 to 2 do begin
            LibraryInventory.CreateItem(Item);
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.",
              LibraryRandom.RandInt(10));
        end;
    end;

    [Normal]
    local procedure FindProductionBOMLines(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20]; VersionCode: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.FindSet();
    end;

    [Normal]
    local procedure VerifyProductionBOMLines(FromProductionBOMNo: Code[20]; ToProductionBOMNo: Code[20]; FromVersionCode: Code[20]; ToVersionCode: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMLine1: Record "Production BOM Line";
        IsLastRecord: Integer;
    begin
        FindProductionBOMLines(ProductionBOMLine, FromProductionBOMNo, FromVersionCode);
        FindProductionBOMLines(ProductionBOMLine1, ToProductionBOMNo, ToVersionCode);

        // Navigate through source and destination Production BOM Lines in parallel.
        repeat
            ProductionBOMLine1.TestField(Type, ProductionBOMLine.Type);
            ProductionBOMLine1.TestField("No.", ProductionBOMLine."No.");
            ProductionBOMLine1.TestField("Unit of Measure Code", ProductionBOMLine."Unit of Measure Code");
            ProductionBOMLine1.TestField(Quantity, ProductionBOMLine.Quantity);
            ProductionBOMLine1.TestField("Variant Code", ProductionBOMLine."Variant Code");
            ProductionBOMLine1.TestField("Starting Date", ProductionBOMLine."Starting Date");
            ProductionBOMLine1.TestField("Ending Date", ProductionBOMLine."Ending Date");
            ProductionBOMLine1.TestField("Calculation Formula", ProductionBOMLine."Calculation Formula");
            ProductionBOMLine1.TestField("Quantity per", ProductionBOMLine."Quantity per");
            IsLastRecord := ProductionBOMLine1.Next();
        until ProductionBOMLine.Next() = 0;

        Assert.AreEqual(0, IsLastRecord, 'There are more lines in the destination Production BOM.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdBOMListHandler(var ProdBOMVersionList: Page "Prod. BOM Version List"; var Response: Action)
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Select source version from Production BOM Version List lookup page.
        ProductionBOMVersion.SetRange("Production BOM No.", ProdBOMNo);
        ProductionBOMVersion.SetRange("Version Code", ProdBOMVersionCode);
        ProductionBOMVersion.FindFirst();
        ProdBOMVersionList.SetTableView(ProductionBOMVersion);
        ProdBOMVersionList.SetRecord(ProductionBOMVersion);
        Response := ACTION::LookupOK;
    end;

    [Normal]
    local procedure SetupCopyBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMVersion: Record "Production BOM Version"; BOMStatus: Enum "BOM Status")
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        NoSeries: Codeunit "No. Series";
        VersionCode: Text[20];
    begin
        // Create source Production BOM Header.
        CreateProductionBOM(ProductionBOMHeader);
        ProdBOMNo := ProductionBOMHeader."No.";

        // Add first version to BOM Header.
        VersionCode := NoSeries.GetNextNo(ProductionBOMHeader."Version Nos.");
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.",
          CopyStr(VersionCode, StrLen(VersionCode) - 9, 10), ProductionBOMHeader."Unit of Measure Code");
        ProdBOMVersionCode := ProductionBOMVersion."Version Code";

        // Make sure the first version is not empty.
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code",
          ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // Create destination version.
        Clear(ProductionBOMVersion);
        VersionCode := NoSeries.GetNextNo(ProductionBOMHeader."Version Nos.");
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.",
          CopyStr(VersionCode, StrLen(VersionCode) - 9, 10), ProductionBOMHeader."Unit of Measure Code");

        // Set status on version.
        ProductionBOMVersion.Validate(Status, BOMStatus);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure GenerateMatrixData(var VersionCode: array[32] of Text[80]; ProductionBOMNo: Code[20]): Integer
    var
        ProductionBOMVersion: Record "Production BOM Version";
        MatrixManagement: Codeunit "Matrix Management";
        RecRef: RecordRef;
        SetWanted: Option First,Previous,Same,Next;
        CaptionRange: Text;
        FirstMatrixRecInSet: Text;
        ColumnCount: Integer;
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        RecRef.GetTable(ProductionBOMVersion);
        MatrixManagement.GenerateMatrixData(
          RecRef, SetWanted::First, ArrayLen(VersionCode), ProductionBOMVersion.FieldNo("Version Code"),
          FirstMatrixRecInSet, VersionCode, CaptionRange, ColumnCount);
        exit(ColumnCount);
    end;

    local procedure VerifyMatrixBOMVersion(ProductionBOMNo: Code[20]; VersionCode: array[32] of Text[80]; VersionCount: Integer)
    var
        ProductionBOMVersion: Record "Production BOM Version";
        I: Integer;
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMVersion.FindFirst();
        Assert.AreEqual(VersionCount, ProductionBOMVersion.Count, CountError);

        for I := 1 to VersionCount do begin
            ProductionBOMVersion.SetRange("Version Code", VersionCode[VersionCount]);
            ProductionBOMVersion.FindFirst();
        end;
    end;
}

