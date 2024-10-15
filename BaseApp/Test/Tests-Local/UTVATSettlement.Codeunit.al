codeunit 144186 "UT VAT Settlement"
{
    // 1. Purpose of the test is to validate VAT Period - OnValidate Trigger of Table ID - 12135 Periodic Settlement VAT Entry, Verify error 'VAT Period must be 7 characters, for example, YYYY/MM'
    // 2. Purpose of the test is to validate VAT Period - OnValidate Trigger of Table ID - 12135 Periodic Settlement VAT Entry, Verify error 'Please check the month number.'
    // 
    // Covers Test Cases for WI - 346255.
    // ---------------------------------------------------------------
    // Test Function Name                                       TFS ID
    // ---------------------------------------------------------------
    // OnValidateVATPeriodPeriodicVATSettlementEntryPeriodError 278492
    // OnValidateVATPeriodPeriodicSettlementVATEntryMonthError

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        VATPeriodTxt: Label '2014/13';
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        CellEmptyContentErr: Label 'Excel cell''s (row=%1, column=%2) content must not be empty', Comment = '%1 - row, %2 - column';
        PriorPeriodColumnNameTxt: Label 'Prior Period Input VAT';
        CellValueNotFoundErr: Label 'Excel cell (row=%1, column=%2) value is not found.', Comment = '%1 - row, %2 - column';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATPeriodPeriodicVATSettlementEntryPeriodError()
    begin
        // Purpose of the test is to validate VAT Period - OnValidate Trigger of Table ID - 12135 Periodic Settlement VAT Entry.
        // Verify error 'VAT Period must be 7 characters, for example, YYYY/MM'
        OnValidateVATPeriodPeriodicSettlement(LibraryUTUtility.GetNewCode10());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATPeriodPeriodicSettlementVATEntryMonthError()
    begin
        // Purpose of the test is to validate VAT Period - OnValidate Trigger of Table ID - 12135 Periodic Settlement VAT Entry.
        // Verify error 'Please check the month number.'
        OnValidateVATPeriodPeriodicSettlement(VATPeriodTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementReportWithSetPlafondPeriod()
    var
        GLAccount: Record "G/L Account";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        InitialDate: Date;
    begin
        // Initialize
        Initialize();
        InitialDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3) - 1); // 1/1/Y-1
        InitLastSettlementDate(CalcDate('<1M-1D>', InitialDate)); // 31/1/Y-1
        InitVATPlafondPeriod(InitialDate, 0); // 1/1/CY-1 (Year will be used)
        LibraryERM.CreateGLAccount(GLAccount);

        // Exercise
        CalcAndPostVATSettlement.InitializeRequest(
          CalcDate('<1M>', InitialDate),// 1/2/Y-1
          CalcDate('<2M-1D>', InitialDate),// 28/2/Y-1
          CalcDate('<2M-1D>', InitialDate),
          '',// DocNo is not used in test
          GLAccount."No.", GLAccount."No.", GLAccount."No.", true, false);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        CalcAndPostVATSettlement.SaveAsExcel(LibraryReportValidation.GetFileName());

        // Verify and Tear down
        VerifyCalcAndPostVATSettlementReportContentExistence();
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure InitVATPlafondPeriod(InitialDate: Date; CalculatedAmount: Decimal)
    var
        VATPlafondPeriod: Record "VAT Plafond Period";
    begin
        VATPlafondPeriod.DeleteAll();
        VATPlafondPeriod.Init();
        VATPlafondPeriod.Year := Date2DMY(InitialDate, 3);
        VATPlafondPeriod.Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        VATPlafondPeriod."Calculated Amount" := CalculatedAmount;
        VATPlafondPeriod.Insert();
    end;

    local procedure InitLastSettlementDate(InitialDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Last Settlement Date" := CalcDate('<1M>', InitialDate);
        GeneralLedgerSetup.Modify();
    end;

    local procedure OnValidateVATPeriodPeriodicSettlement(VATPeriod: Code[10])
    var
        PeriodicVATSettlementCard: TestPage "Periodic VAT Settlement Card";
    begin
        // Setup.
        PeriodicVATSettlementCard.OpenNew();

        // Exercise.
        asserterror PeriodicVATSettlementCard."VAT Period".SetValue(VATPeriod);

        // Verify: Verify actual error 'VAT Period must be 7 characters, for example, YYYY/MM' and 'Please check the month number.'
        Assert.ExpectedErrorCode('TestValidation');
    end;

    local procedure VerifyCalcAndPostVATSettlementReportContentExistence()
    var
        Row: Integer;
        Column: Integer;
        CellContent: Text;
        ValueFound: Boolean;
    begin
        // Verify Saved Report's Data.
        LibraryReportValidation.DownloadFile();
        LibraryReportValidation.OpenExcelFile();

        Row := LibraryReportValidation.FindRowNoFromColumnCaption(PriorPeriodColumnNameTxt);
        Column := LibraryReportValidation.FindColumnNoFromColumnCaption(PriorPeriodColumnNameTxt) + 31;
        CellContent := LibraryReportValidation.GetValueAt(ValueFound, Row, Column);
        Assert.IsTrue(ValueFound, StrSubstNo(CellValueNotFoundErr, Row, Column));
        Assert.AreNotEqual(0, StrLen(CellContent), CellEmptyContentErr);
    end;
}

