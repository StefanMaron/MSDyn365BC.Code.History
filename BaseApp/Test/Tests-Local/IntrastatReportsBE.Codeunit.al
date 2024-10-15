codeunit 144011 "Intrastat Reports BE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat]
        IsInitialized := false;
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReportHandlerIntrastatForm')]
    [Scope('OnPrem')]
    procedure IntrastatFormOnMoreThanHundredRecords()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        i: Integer;
    begin
        // [SCENARIO 272795] When Stan runs "Intrastat - Forms" report on more than 100 "Intrastat Jnl Line" records, the report is successfully executed.
        Initialize;

        // [GIVEN] 100 or more Intrastat Jnl Lines.
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        for i := 1 to LibraryRandom.RandIntInRange(100, 200) do
            MockIntrastatJnlLine(
              IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, IntrastatJnlLine.Type::Shipment,
              LibraryRandom.RandIntInRange(1, 100), LibraryRandom.RandDecInRange(1, 100, 2));

        // [WHEN] Run "Intrastat - Forms" report on these Intrastat Jnl Lines.
        RunIntrastatForm(IntrastatJnlBatch.Name, IntrastatJnlLine.Type::Shipment);

        // [THEN] The report is successfully executed.
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Intrastat Reports BE");

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Intrastat Reports BE");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Intrastat Reports BE");
    end;

    local procedure CreateItemWithTariff(var Item: Record Item)
    begin
        LibraryInventory.CreateItemWithTariffNo(Item, CreateTariffNumber);
        Item.Validate("Net Weight", LibraryRandom.RandDecInRange(1, 100, 2));
        Item.Modify(true);
    end;

    local procedure CreateTariffNumber(): Code[20]
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.Init();
        TariffNumber.Validate("No.", LibraryUtility.GenerateGUID);
        TariffNumber.Insert(true);
        exit(TariffNumber."No.");
    end;

    local procedure GetArea(): Code[10]
    var
        "Area": Record "Area";
    begin
        Area.FindFirst;
        exit(Area.Code);
    end;

    local procedure GetCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SetFilter("Intrastat Code", '<>%1', '');
        CountryRegion.FindFirst;
        exit(CountryRegion.Code);
    end;

    local procedure GetTransactionSpecification(): Code[10]
    var
        TransactionSpecification: Record "Transaction Specification";
    begin
        TransactionSpecification.FindFirst;
        exit(TransactionSpecification.Code);
    end;

    local procedure GetTransactionType(): Code[10]
    var
        TransactionType: Record "Transaction Type";
    begin
        TransactionType.FindFirst;
        exit(TransactionType.Code);
    end;

    local procedure GetTransportMethod(): Code[10]
    var
        TransportMethod: Record "Transport Method";
    begin
        TransportMethod.FindFirst;
        exit(TransportMethod.Code);
    end;

    local procedure MockIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; Type: Option; Quantity: Integer; Amount: Decimal)
    var
        Item: Record Item;
    begin
        CreateItemWithTariff(Item);

        IntrastatJnlLine.Init();
        IntrastatJnlLine."Journal Template Name" := JnlTemplateName;
        IntrastatJnlLine."Journal Batch Name" := JnlBatchName;
        IntrastatJnlLine."Line No." := LibraryUtility.GetNewRecNo(IntrastatJnlLine, IntrastatJnlLine.FieldNo("Line No."));
        IntrastatJnlLine.Type := Type;
        IntrastatJnlLine."Item No." := Item."No.";
        IntrastatJnlLine."Tariff No." := Item."Tariff No.";
        IntrastatJnlLine."Country/Region Code" := GetCountryRegionCode;
        IntrastatJnlLine."Transaction Type" := GetTransactionType;
        IntrastatJnlLine."Transport Method" := GetTransportMethod;
        IntrastatJnlLine.Area := GetArea;
        IntrastatJnlLine."Transaction Specification" := GetTransactionSpecification;
        IntrastatJnlLine.Quantity := Quantity;
        IntrastatJnlLine.Validate("Net Weight", Item."Net Weight");  // set "Total Weight"
        IntrastatJnlLine.Validate(Amount, Amount);   // set "Statistical Value"
        IntrastatJnlLine.Insert();
    end;

    local procedure RunIntrastatForm(JnlBatchName: Code[10]; Type: Option)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatForm: Report "Intrastat - Form";
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", JnlBatchName);
        IntrastatJnlLine.SetRange(Type, Type);

        Commit();
        IntrastatForm.SetTableView(IntrastatJnlLine);
        IntrastatForm.Run;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerIntrastatForm(var IntrastatForm: TestRequestPage "Intrastat - Form")
    begin
        IntrastatForm.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

