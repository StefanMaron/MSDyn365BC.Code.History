codeunit 142036 "UT COD INTRASTAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintIntrastatFormDocumentPrint()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Item: Record Item;
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // Purpose of the test is to validate function - PrintIntrastatForm from Codeunit - DocumentPrint.
        Initialize();

        // Setup: Create DACH Report Selections with Usage Intrastat Form.
        CreateDACHReportSelections(DACHReportSelections.Usage::"Intrastat Form", 11012, 'Intrastat - Form DE');  // Report ID of Intrastat - Form DE.

        CreateItemWithTariffNumber(Item);
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, Item, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Print Intrastat Form from Codeunit - DocumentPrint. Verification is done in IntrastatFormDERequestHandler.
        DocumentPrint.PrintIntrastatForm(IntrastatJnlLine);  // Invokes IntrastatFormDERequestHandler.
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintIntrastatDiskDocumentPrint()
    var
        DACHReportSelections: Record "DACH Report Selections";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
        DocumentPrint: Codeunit "Document-Print";
    begin
        // Purpose of the test is to validate function - PrintIntrastatDisk from Codeunit - DocumentPrint.
        Initialize();

        // Setup: Create DACH Report Selections with Usage Intrastat Disk.
        CreateDACHReportSelections(DACHReportSelections.Usage::"Intrastat Disk", 593, 'Intrastat - Make Disk Tax Auth');  // Report ID of Intrastat - Make Disk Tax Auth'.

        CreateItemWithTariffNumber(Item);
        CreateIntrastatJnlTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        CreateIntrastatJournalLine(IntrastatJnlLine, Item, IntrastatJnlTemplate.Name, IntrastatJnlBatch.Name);

        // Exercise & verify: Print Intrastat Disk from Codeunit - DocumentPrint. Verification is done in IntrastatMakeDiskTaxAuthRequestPageHandler.
        DocumentPrint.PrintIntrastatDisk(IntrastatJnlLine);  // Invokes IntrastatMakeDiskTaxAuthRequestPageHandler..
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintIntrastatDisklabelDocumentPrint()
    var
        DACHReportSelections: Record "DACH Report Selections";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // Purpose of the test is to validate function - PrintIntrastatDisklabel from Codeunit - DocumentPrint.
        Initialize();

        // Setup: Create DACH Report Selections with Usage Intrastat Disklabel.
        CreateDACHReportSelections(DACHReportSelections.Usage::"Intrastat Disklabel", 11014, 'Intrastat - Disk Tax Auth DE');  // Report ID of Intrastat - Disk Tax Auth DE

        // Exercise & verify: Print Intrastat Disk from Codeunit - DocumentPrint. Verification is done in IntrastatDiskTaxAuthDERequestPageHandler.
        DocumentPrint.PrintIntrastatDisklabel;  // Invokes IntrastatDiskTaxAuthDERequestPageHandler.
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        isInitialized := true;

        UpdateReceiptsShipmentsOnIntrastatSetup(true, true);
        LibrarySetupStorage.Save(Database::"Intrastat Setup");
    end;

    local procedure CreateIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var Item: Record Item; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := CreateCountryRegion;

        IntrastatJnlLine."Journal Template Name" := JournalTemplateName;
        IntrastatJnlLine."Journal Batch Name" := JournalBatchName;
        IntrastatJnlLine."Line No." := 1;
        IntrastatJnlLine.Insert();

        IntrastatJnlLine.Type := IntrastatJnlLine.Type::Receipt;
        IntrastatJnlLine."Tariff No." := Item."Tariff No.";
        IntrastatJnlLine."Country/Region Code" := CountryRegionCode;
        IntrastatJnlLine."Transaction Type" := GetNewCode;
        IntrastatJnlLine."Transport Method" := GetNewCode;
        IntrastatJnlLine."Country/Region of Origin Code" := CountryRegionCode;
        IntrastatJnlLine."Item No." := Item."No.";
        IntrastatJnlLine.Modify();
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := GetNewCode;
        CountryRegion.Insert();
        CountryRegion."Intrastat Code" := CountryRegion.Code;
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure CreateIntrastatJnlTemplateAndBatch(var IntrastatJnlTemplate: Record "Intrastat Jnl. Template"; var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        IntrastatJnlTemplate.Name := GetNewCode;
        IntrastatJnlTemplate.Insert();

        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch.Name := GetNewCode;
        IntrastatJnlBatch.Insert();
    end;

    local procedure CreateItemWithTariffNumber(var Item: Record Item)
    begin
        Item."No." := LibraryUTUtility.GetNewCode;
        Item.Insert();
        Item."Tariff No." := GetNewCode;
        Item.Modify();
    end;

    local procedure CreateDACHReportSelections(Usage: Option; ReportID: Integer; ReportName: Text[30])
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        DACHReportSelections.DeleteAll();

        DACHReportSelections.Usage := Usage;
        DACHReportSelections.Sequence := GetNewCode;
        DACHReportSelections.Insert();
        DACHReportSelections."Report ID" := ReportID;
        DACHReportSelections."Report Name" := ReportName;
        DACHReportSelections.Modify();
    end;

    local procedure GetNewCode(): Code[10]
    begin
        exit(CopyStr(LibraryUTUtility.GetNewCode, 11, 20));
    end;

    local procedure UpdateReceiptsShipmentsOnIntrastatSetup(ReportReceipts: Boolean; ReportShipments: Boolean)
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        IntrastatSetup.Get();
        IntrastatSetup."Report Receipts" := ReportReceipts;
        IntrastatSetup."Report Shipments" := ReportShipments;
        IntrastatSetup.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatFormDERequestHandler(var IntrastatFormDE: TestRequestPage "Intrastat - Form DE")
    var
        Type: Option Receipt,Shipment;
    begin
        IntrastatFormDE."Intrastat Jnl. Line".SetFilter(Type, Format(Type::Receipt));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatMakeDiskTaxAuthRequestPageHandler(var IntrastatMakeDiskTaxAuth: TestRequestPage "Intrastat - Make Disk Tax Auth")
    var
        Type: Option Receipt,Shipment;
    begin
        IntrastatMakeDiskTaxAuth."Intrastat Jnl. Line".SetFilter(Type, Format(Type::Receipt))
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatDiskTaxAuthDERequestPageHandler(var IntrastatDiskTaxAuthDE: TestRequestPage "Intrastat - Disk Tax Auth DE")
    begin
    end;
}

