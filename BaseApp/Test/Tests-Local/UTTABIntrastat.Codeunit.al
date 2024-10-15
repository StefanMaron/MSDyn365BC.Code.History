#if not CLEAN22
codeunit 142038 "UT TAB Intrastat"
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
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DACHReportSelectionsNewRecordIntrastatForm()
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        // Purpose of the test is to validate the NewRecord function in DACH Report Selections Table.

        DACHReportSelectionsNewRecord(DACHReportSelections.Usage::"Intrastat Form");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DACHReportSelectionsNewRecordIntrastatDisk()
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        // Purpose of the test is to validate the NewRecord function in DACH Report Selections Table.

        DACHReportSelectionsNewRecord(DACHReportSelections.Usage::"Intrastat Disk");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DACHReportSelectionsNewRecordIntrastatChecklist()
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        // Purpose of the test is to validate the NewRecord function in DACH Report Selections Table.

        DACHReportSelectionsNewRecord(DACHReportSelections.Usage::"Intrastat Checklist");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DACHReportSelectionsNewRecordIntrastatDisklabel()
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        // Purpose of the test is to validate the NewRecord function in DACH Report Selections Table.

        DACHReportSelectionsNewRecord(DACHReportSelections.Usage::"Intrastat Disklabel");
    end;

    local procedure DACHReportSelectionsNewRecord(Usage: Option)
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        DACHReportSelections.DeleteAll();

        // Create DACH Report Selections without Sequence.
        DACHReportSelections.Usage := Usage;
        DACHReportSelections.Sequence := '';
        DACHReportSelections.Insert();

        // Exercise: Call New Record function on DACH Report Selections Table.
        DACHReportSelections.NewRecord();

        // Verify: Verify that Sequense No is updated to 1 and Usage is correct on DACH Report Selections Table.
        DACHReportSelections.TestField(Sequence, '1');  // Sequence is updated to 1 if the Sequence is blank.
        DACHReportSelections.TestField(Usage, Usage);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DACHReportSelectionsNewRecordIntrastatFormWithSequence()
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        // Purpose of the test is to validate the NewRecord function in DACH Report Selections Table.

        // Setup: Create DACH Report Selections with Sequence.
        DACHReportSelections.DeleteAll();

        DACHReportSelections.Usage := DACHReportSelections.Usage::"Intrastat Form";
        DACHReportSelections.Sequence := '1';
        DACHReportSelections.Insert();

        // Exercise: Call New Record function on DACH Report Selections Table.
        DACHReportSelections.NewRecord();

        // Verify: Verify that Sequense No is incremented by 1 and Usage is correct on DACH Report Selections Table.
        DACHReportSelections.TestField(Sequence, '2');  // Value increment by 1.
        DACHReportSelections.TestField(Usage, DACHReportSelections.Usage::"Intrastat Form");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountIntrastatJournalLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Purpose of the test is to validate, Amount - OnValidate of Intrastat Journal Line Table.

        // Setup.
        IntrastatJnlLine."Indirect Cost" := 1;

        // Exercise: Validate Amount on Intrastat Journal Line for Cost Regulation % equal to 0.
        IntrastatJnlLine.Validate(Amount, 1);

        // Verify: Verify Statistical value is sum of Amount and Indirect Cost on Intrastat Journal Line.
        IntrastatJnlLine.TestField("Statistical Value", IntrastatJnlLine.Amount + IntrastatJnlLine."Indirect Cost");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCostRegulationIntrastatJournalLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Purpose of the test is to validate, CostRegulation% - OnValidate of Intrastat Journal Line Table.

        // Setup.
        IntrastatJnlLine."Cost Regulation %" := 1;

        // Exercise: Validate Amount on Intrastat Journal Line for Cost Regulation % more than 0.
        IntrastatJnlLine.Validate(Amount, 100);  // Large value required for Indirect Cost.

        // Verify: Verify Indirect Cost and Statistical value on Intrastat Journal Line.
        IntrastatJnlLine.TestField("Indirect Cost", Round(IntrastatJnlLine.Amount * IntrastatJnlLine."Cost Regulation %" / 100, 1));
        IntrastatJnlLine.TestField("Statistical Value", IntrastatJnlLine.Amount + IntrastatJnlLine."Indirect Cost");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateIndirectCostIntrastatJournalLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Purpose of the test is to validate, IndirectCost - OnValidate of Intrastat Journal Line Table.

        // Setup.
        IntrastatJnlLine.Amount := 1;

        // Exercise: Validate Indirect Cost of Intrastat Journal Line.
        IntrastatJnlLine.Validate("Indirect Cost", 1);

        // Verify: Verify Statistical value is sum of Amount and Indirect Cost on Intrastat Journal Line.
        IntrastatJnlLine.TestField("Statistical Value", IntrastatJnlLine.Amount + IntrastatJnlLine."Indirect Cost");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateItemNoWithoutRegionIntrastatJnlLine()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Purpose of the test is to validate, Item No - OnValidate of Intrastat Journal Line.

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line of Type Receipt.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(IntrastatJnlLine, Item."No.", IntrastatJnlLine.Type::Receipt);

        // Exercise: Update Item No on Intrastat Journal Line.
        IntrastatJnlLine.Validate("Item No.", Item."No.");

        // Verify: Verify that Country / Region of Origin Code is populated as Country/Region Code on Intrastat Journal Line.
        IntrastatJnlLine.TestField("Country/Region of Origin Code", IntrastatJnlLine."Country/Region Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateItemNoWithRegionIntrastatJnlLine()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Purpose of the test is to validate, Item No - OnValidate of Intrastat Journal Line for Intrastat Journal Line Country Region of Origin Code from Item.

        // Setup: Create Item with Tariff Number. Update Country / Region Of Origin Code on Item. Create Intrastat Journal Line of Type Receipt.
        CreateItemWithTariffNumber(Item);
        Item."Country/Region of Origin Code" := CreateCountryRegion();
        Item.Modify();
        CreateIntrastatJournalLine(IntrastatJnlLine, Item."No.", IntrastatJnlLine.Type::Receipt);

        // Exercise: Update Item No on Intrastat Journal Line.
        IntrastatJnlLine.Validate("Item No.", Item."No.");

        // Verify: Verify that Country / Region of Origin Code on Intrastat Journal Line is populated as Country / Region of Origin Code On Item.
        IntrastatJnlLine.TestField("Country/Region of Origin Code", Item."Country/Region of Origin Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionOfOriginCodeIntrastatJnlLine()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 391776] Validate Country Region of Origin Code - OnValidate of Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(IntrastatJnlLine, Item."No.", IntrastatJnlLine.Type::Shipment);
        IntrastatJnlLine.Validate("Country/Region of Origin Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePartnerVATIDShipment()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 391678] Partner VAT ID is validated in shipment Intrastat Journal Line with any value
        IntrastatJnlLine.Init();
        IntrastatJnlLine.Type := IntrastatJnlLine.Type::Shipment;
        IntrastatJnlLine.Validate("Partner VAT ID", LibraryUTUtility.GetNewCode());
        IntrastatJnlLine.Validate("Partner VAT ID", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePartnerVATIDReceipt()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 391678] Partner VAT ID gives error when validated in receipt Intrastat Journal Line
        IntrastatJnlLine.Init();
        IntrastatJnlLine.Type := IntrastatJnlLine.Type::Receipt;
        asserterror IntrastatJnlLine.Validate("Partner VAT ID", LibraryUTUtility.GetNewCode());
        Assert.ExpectedError('Type must be equal to ''Shipment''');
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePartnerVATIDReceiptBlank()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 391678] Partner VAT ID is validated in receipt Intrastat Journal Line with blank value
        IntrastatJnlLine.Init();
        IntrastatJnlLine.Type := IntrastatJnlLine.Type::Receipt;
        IntrastatJnlLine."Partner VAT ID" := LibraryUTUtility.GetNewCode();
        IntrastatJnlLine.Validate("Partner VAT ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatisticalValueNotRoundedOnCostRegulationPctValidationInIntrastatJnlLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 432342] Statistical value not rounded on the "Cost Regulation %" validation in the intrastat journal line

        IntrastatJnlLine.Amount := LibraryRandom.RandDec(100, 2);
        IntrastatJnlLine."Indirect Cost" := LibraryRandom.RandDec(100, 2);
        IntrastatJnlLine.Validate("Cost Regulation %");
        IntrastatJnlLine.TestField("Statistical Value", IntrastatJnlLine.Amount + IntrastatJnlLine."Indirect Cost");
    end;

    local procedure CreateItemWithTariffNumber(var Item: Record Item)
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber."No." := LibraryUTUtility.GetNewCode10();
        TariffNumber.Insert();
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Tariff No." := TariffNumber."No.";
        Item.Insert();
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion."Intrastat Code" := CountryRegion.Code;
        CountryRegion.Insert();
        exit(CountryRegion.Code);
    end;

    local procedure CreateIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ItemNo: Code[20]; Type: Option)
    var
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := CreateCountryRegion();
        IntrastatJnlLine.Type := Type;
        IntrastatJnlLine."Country/Region Code" := CountryRegionCode;
        IntrastatJnlLine."Item No." := ItemNo;
        IntrastatJnlLine.Insert();
    end;
}
#endif