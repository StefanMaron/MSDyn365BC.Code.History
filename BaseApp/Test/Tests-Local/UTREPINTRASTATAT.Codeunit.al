#if not CLEAN22
codeunit 142037 "UT REP INTRASTAT AT"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '22.0';
#pragma warning restore AS0072
    ObsoleteReason = 'Intrastat related functionalities are moving to Intrastat extension.';

    trigger OnRun()
    begin
    end;

    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        HeaderText: Label 'All amounts are in %1';

    [Test]
    [HandlerFunctions('IntrastatChecklistATRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistATOnPreReportAdditionalReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Purpose of the test is to validate function - OnPreReport of  Report Intrastat - Checklist AT.

        // Setup: Update Additional Reporting Currency on General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := GeneralLedgerSetup."LCY Code";
        GeneralLedgerSetup.Modify();
        CreateItemWithTariffNumber(Item);

        // Create Intrastat Journal Line with Transaction specification.
        CreateIntrastatJournalLine(IntrastatJnlLine, Item, LibraryUTUtility.GetNewCode10(), IntrastatJnlLine.Type::Receipt);
        UpdateIntrastatJnlLineTransactionSpecification(IntrastatJnlLine, '10000');  // Transaction specification should be of 5 digits.

        // Exercise: Run Report Intrastat - Checklist AT.
        REPORT.Run(REPORT::"Intrastat - Checklist AT");

        // Verify : Verify Additional Reporting Currency of General Ledger Setup is updated on Intrastat Checklist AT report.
        VerifyIntrastatChecklistATReport(StrSubstNo(HeaderText, GeneralLedgerSetup."Additional Reporting Currency"));
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistATRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistATOnPreReportLCYCode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Purpose of the test is to validate function - OnPreReport of  Report Intrastat - Checklist AT.

        // Setup: Update Additional Reporting Currency on General Ledger Setup to blank.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup.Modify();
        CreateItemWithTariffNumber(Item);

        // Create Intrastat Journal Line with Transaction specification.
        CreateIntrastatJournalLine(IntrastatJnlLine, Item, LibraryUTUtility.GetNewCode10(), IntrastatJnlLine.Type::Receipt);
        UpdateIntrastatJnlLineTransactionSpecification(IntrastatJnlLine, '10000');  // Transaction specification should be of 5 digits.

        // Exercise: Run Report Intrastat - Checklist AT.
        REPORT.Run(REPORT::"Intrastat - Checklist AT");

        // Verify : Verify LCY Code of General Ledger Setup is updated on Intrastat Checklist AT report.
        VerifyIntrastatChecklistATReport(StrSubstNo(HeaderText, GeneralLedgerSetup."LCY Code"));
    end;

    local procedure CreateItemWithTariffNumber(var Item: Record Item)
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        Item."Tariff No." := LibraryUTUtility.GetNewCode10();
        Item.Modify();
    end;

    local procedure CreateIntrastatJnlTemplateAndBatch()
    begin
        IntrastatJnlTemplate.Name := LibraryUTUtility.GetNewCode10();
        IntrastatJnlTemplate.Insert();

        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch.Name := LibraryUTUtility.GetNewCode10();
        IntrastatJnlBatch.Insert();
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion.Insert();
        CountryRegion."Intrastat Code" := CountryRegion.Code;
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure CreateIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var Item: Record Item; TransportMethod: Code[10]; Type: Option)
    var
        CountryRegionCode: Code[10];
    begin
        CreateIntrastatJnlTemplateAndBatch();
        CountryRegionCode := CreateCountryRegion();

        IntrastatJnlLine."Journal Template Name" := IntrastatJnlTemplate.Name;
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatch.Name;
        IntrastatJnlLine."Line No." := 1;
        IntrastatJnlLine.Insert();

        IntrastatJnlLine.Type := Type;
        IntrastatJnlLine."Tariff No." := Item."Tariff No.";
        IntrastatJnlLine."Country/Region Code" := CountryRegionCode;
        IntrastatJnlLine."Transaction Type" := LibraryUTUtility.GetNewCode10();
        IntrastatJnlLine."Transport Method" := TransportMethod;
        IntrastatJnlLine."Country/Region of Origin Code" := CountryRegionCode;
        IntrastatJnlLine."Item No." := Item."No.";
        IntrastatJnlLine.Modify();
    end;

    local procedure UpdateIntrastatJnlLineTransactionSpecification(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TransactionSpecification: Code[10])
    begin
        IntrastatJnlLine."Transaction Specification" := TransactionSpecification;
        IntrastatJnlLine.Modify();
    end;

    local procedure VerifyIntrastatChecklistATReport(HeaderText: Text[30])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HeaderText', HeaderText);
    end;

    local procedure VerifyIntrastatChecklistATReportForShipment(ElementName: Text; ExpectedValue: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ExpectedValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatChecklistATRequestPageHandler(var IntrastatChecklistAT: TestRequestPage "Intrastat - Checklist AT")
    var
        Type: Option Receipt,Shipment;
    begin
        IntrastatChecklistAT."Intrastat Jnl. Batch".SetFilter("Journal Template Name", IntrastatJnlTemplate.Name);
        IntrastatChecklistAT."Intrastat Jnl. Batch".SetFilter(Name, IntrastatJnlBatch.Name);
        IntrastatChecklistAT."Intrastat Jnl. Line".SetFilter(Type, Format(Type::Receipt));
        IntrastatChecklistAT.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatFormATRequestPageHandler(var IntrastatFormAT: TestRequestPage "Intrastat - Form AT")
    var
        Type: Option Receipt,Shipment;
    begin
        IntrastatFormAT."Intrastat Jnl. Batch".SetFilter("Journal Template Name", IntrastatJnlTemplate.Name);
        IntrastatFormAT."Intrastat Jnl. Batch".SetFilter(Name, IntrastatJnlBatch.Name);
        IntrastatFormAT."Intrastat Jnl. Line".SetFilter(Type, Format(Type::Receipt));
        IntrastatFormAT.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatChecklistATShipmentRequestPageHandler(var IntrastatChecklistAT: TestRequestPage "Intrastat - Checklist AT")
    var
        Type: Option Receipt,Shipment;
    begin
        IntrastatChecklistAT."Intrastat Jnl. Batch".SetFilter("Journal Template Name", IntrastatJnlTemplate.Name);
        IntrastatChecklistAT."Intrastat Jnl. Batch".SetFilter(Name, IntrastatJnlBatch.Name);
        IntrastatChecklistAT."Intrastat Jnl. Line".SetFilter(Type, Format(Type::Shipment));
        IntrastatChecklistAT.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
#endif