codeunit 134474 "ERM Dimension Locations"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Locations]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        IsInitialized: Boolean;
        DimPostErr: Label 'Select a Dimension Value Code for the Dimension Code';

    [Test]
    [Scope('OnPrem')]
    procedure LocationWithDefaultDimensions()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        // [SCENARIO 324149] Create default dimensions for location
        Initialize();

        // [GIVEN] Location "L"
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] Create default dimensions "DD1" and "DD2" for "L"
        for i := 1 to 2 do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        end;

        // [THEN] There are two records in "Default Dimension" table for "L"
        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", Database::Location);
        DefaultDimension.SetRange("No.", Location.Code);
        Assert.RecordCount(DefaultDimension, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLocationWithDefaultDimensions()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO 324149] Delete location with default dimensions
        Initialize();

        // [GIVEN] Location "L" with default dimensions
        CreateLocationWithDefaultDimensions(Location);

        // [WHEN] Delete "L"
        Location.Delete(true);

        // [THEN] There are no records in "Default Dimension" table for "L"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordIsEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameLocationWithDefaultDimemsions()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        OldLocationCode: Code[10];
    begin
        // [SCENARIO 324149] Rename location with default dimensions
        Initialize();

        // [GIVEN] Location "L" with default dimensions
        OldLocationCode := CreateLocationWithDefaultDimensions(Location);

        // [WHEN] Rename "L" to "L1"
        Location.Rename(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), Database::Location));

        // [THEN] There are no records in "Default Dimension" for "L"
        GetLocationDefaultDimensions(DefaultDimension, OldLocationCode);
        Assert.RecordIsEmpty(DefaultDimension);
        // [THEN] There are records in "Default Dimension" table for "L1"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordIsNotEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDefaultDimensionsLocationCard()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LocationCard: TestPage "Location Card";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [SCENARIO 324149] Create default dimensions for location on the "Location Card" page
        Initialize();

        // [GIVEN] Location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Dimension "D" with dimension value "DV"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [WHEN] Invoke "Dimensions" action on the "Location Card" page
        LocationCard.OpenView();
        LocationCard.GoToRecord(Location);
        DefaultDimensions.Trap();
        LocationCard.Dimensions.Invoke();
        // [WHEN] Assign "Dimension Code" = "D", "Dimension Value Code" = "DV"
        DefaultDimensions."Dimension Code".SetValue(DimensionValue."Dimension Code");
        DefaultDimensions."Dimension Value Code".SetValue(DimensionValue.Code);
        DefaultDimensions.Close();

        // [THEN] There is one record in "Default Dimension" table for "L"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordCount(DefaultDimension, 1);
        // [THEN] Default "Dimension Code" = "D", default "Dimension Value Code" = "DV"
        DefaultDimension.FindFirst();
        DefaultDimension.TestField("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDefaultDimensionsLocationList()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LocationList: TestPage "Location List";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [SCENARIO 324149] Create single default dimensions for location on the "Location List" page
        Initialize();

        // [GIVEN] Location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Dimension "D" with dimension value "DV"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [WHEN] Invoke "Dimensions-Single" action on the "Location List" page
        LocationList.OpenView();
        LocationList.GoToRecord(Location);
        DefaultDimensions.Trap();
        LocationList.DimensionsSingle.Invoke();
        // [WHEN] Assign "Dimension Code" = "D", "Dimension Value Code" = "DV"
        DefaultDimensions."Dimension Code".SetValue(DimensionValue."Dimension Code");
        DefaultDimensions."Dimension Value Code".SetValue(DimensionValue.Code);
        DefaultDimensions.Close();

        // [THEN] There is one record in "Default Dimension" table for "L"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordCount(DefaultDimension, 1);
        // [THEN] Default "Dimension Code" = "D", default "Dimension Value Code" = "DV"
        DefaultDimension.FindFirst();
        DefaultDimension.TestField("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DefaultDimensionsMultipleModalPageHandler')]
    procedure SetDefaultDimensionsMultipleLocationList()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LocationList: TestPage "Location List";
    begin
        // [SCENARIO 324149] Create multiple default dimensions for location on the "Location List" page
        Initialize();

        // [GIVEN] Location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Dimension "D" with dimension value "DV"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);

        // [WHEN] Invoke "Dimensions-Multiple" action on the "Location List" page
        LocationList.OpenView();
        LocationList.GoToRecord(Location);
        LocationList.DimensionsMultiple.Invoke();
        // [WHEN] Assign "Dimension Code" = "D", "Dimension Value Code" = "DV" (DefaultDimensionsMultipleModalPageHandler)

        // [THEN] There is one record in "Default Dimension" table for "L"
        GetLocationDefaultDimensions(DefaultDimension, Location.Code);
        Assert.RecordCount(DefaultDimension, 1);
        // [THEN] Default "Dimension Code" = "D", default "Dimension Value Code" = "DV"
        DefaultDimension.FindFirst();
        DefaultDimension.TestField("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesHeaderWithLocationWithMandatoryDefaultDimension()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 436796] Post sales order with header with location with mandatory default dimension
        Initialize();

        // [GIVEN] Location "L" with mandatory default dimension "D"
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // Sales order with header with "L" and removed "D"
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Validate("Dimension Set ID", 0);
        SalesHeader.Modify(true);

        // [WHEN] Post sales order
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There is error that document cannot be posted without "D"
        Assert.ExpectedError(DimPostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesLineWithLocationWithMandatoryDefaultDimension()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 436796] Post sales order with line with location with mandatory default dimension
        Initialize();

        // [GIVEN] Location "L" with mandatory default dimension "D"
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // Sales order with line with "L" and removed "D"
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Dimension Set ID", 0);
        SalesLine.Modify(true);

        // [WHEN] Post sales order
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There is error that document cannot be posted without "D"
        Assert.ExpectedError(DimPostErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseHeaderWithLocationWithMandatoryDefaultDimension()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 436796] Post Purchase order with header with location with mandatory default dimension
        Initialize();

        // [GIVEN] Location "L" with mandatory default dimension "D"
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // Purchase order with header with "L" and removed "D"
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Validate("Dimension Set ID", 0);
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There is error that document cannot be posted without "D"
        Assert.ExpectedError(DimPostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseLineWithLocationWithMandatoryDefaultDimension()
    var
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 436796] Post Purchase order with line with location with mandatory default dimension
        Initialize();

        // [GIVEN] Location "L" with mandatory default dimension "D"
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // Purchase order with line with "L" and removed "D"
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Dimension Set ID", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There is error that document cannot be posted without "D"
        Assert.ExpectedError(DimPostErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Dimension Locations");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Dimension Locations");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Dimension Locations");
    end;

    local procedure CreateLocationWithDefaultDimensions(var Location: Record Location): Code[10]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        LibraryWarehouse.CreateLocation(Location);
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        end;
    end;

    local procedure GetLocationDefaultDimensions(var DefaultDimension: Record "Default Dimension"; LocationCode: Code[10])
    begin
        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", Database::Location);
        DefaultDimension.SetRange("No.", LocationCode);
    end;

    [ModalPageHandler]
    procedure DefaultDimensionsMultipleModalPageHandler(var DefaultDimensionsMultiple: TestPage "Default Dimensions-Multiple")
    begin
        DefaultDimensionsMultiple.New();
        DefaultDimensionsMultiple."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        DefaultDimensionsMultiple."Dimension Value Code".SetValue(LibraryVariableStorage.DequeueText());
        DefaultDimensionsMultiple.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}