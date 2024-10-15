report 12 "VAT Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VATStatement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Statement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = SORTING("Statement Template Name", Name);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Statement Template Name", Name;
            column(StmtName1_VatStmtName; "Statement Template Name")
            {
            }
            column(Name1_VatStmtName; Name)
            {
            }
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = FIELD("Statement Template Name"), "Statement Name" = FIELD(Name);
                DataItemTableView = SORTING("Statement Template Name", "Statement Name") WHERE(Print = CONST(true));
                RequestFilterFields = "Row No.";
                column(Heading; Heading)
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(StmtName_VatStmtName; "VAT Statement Name"."Statement Template Name")
                {
                }
                column(Name_VatStmtName; "VAT Statement Name".Name)
                {
                }
                column(Heading2; Heading2)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(GlSetupLCYCode; GLSetup."LCY Code")
                {
                }
                column(Allamountsarein; AllamountsareinLbl)
                {
                }
                column(TxtGLSetupAddnalReportCur; StrSubstNo(Text003, GLSetup."Additional Reporting Currency"))
                {
                }
                column(GLSetupAddRepCurrency; GLSetup."Additional Reporting Currency")
                {
                }
                column(VatStmLineTableCaptFilter; TableCaption + ': ' + VATStmtLineFilter)
                {
                }
                column(VatStmtLineFilter; VATStmtLineFilter)
                {
                }
                column(VatStmtLineRowNo; "Row No.")
                {
                    IncludeCaption = true;
                }
                column(Description_VatStmtLine; Description)
                {
                    IncludeCaption = true;
                }
                column(TotalAmount; TotalAmount)
                {
                    AutoFormatExpression = GetCurrency;
                    AutoFormatType = 1;
                }
                column(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                }
                column(Selection; Selection)
                {
                }
                column(PeriodSelection; PeriodSelection)
                {
                }
                column(PrintInIntegers; PrintInIntegers)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(VATStmtCaption; VATStmtCaptionLbl)
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(VATStmtTemplateCaption; VATStmtTemplateCaptionLbl)
                {
                }
                column(VATStmtNameCaption; VATStmtNameCaptionLbl)
                {
                }
                column(AmtsareinwholeLCYsCaption; AmtsareinwholeLCYsCaptionLbl)
                {
                }
                column(ReportinclallVATentriesCaption; ReportinclallVATentriesCaptionLbl)
                {
                }
                column(RepinclonlyclosedVATentCaption; RepinclonlyclosedVATentCaptionLbl)
                {
                }
                column(TotalAmountCaption; TotalAmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    CorrectionAmount: Decimal;
                begin
                    CalcLineTotal("VAT Statement Line", TotalAmount, CorrectionAmount, NetAmountLCY, '', 0);
                    if PrintInIntegers then begin
                        TotalAmount := Round(TotalAmount, 1, '<');
                        CorrectionAmount := Round(CorrectionAmount, 1, '<');
                    end;
                    TotalAmount := TotalAmount + CorrectionAmount;
                    if "Print with" = "Print with"::"Opposite Sign" then
                        TotalAmount := -TotalAmount;
                    PageGroupNo := NextPageGroupNo;
                    if "New Page" then
                        NextPageGroupNo := PageGroupNo + 1;
                end;

                trigger OnPreDataItem()
                begin
                    PageGroupNo := 1;
                    NextPageGroupNo := 1;
                end;
            }

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Statement Period")
                    {
                        Caption = 'Statement Period';
                        field(StartingDate; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the date from which the report or batch job processes information.';
                        }
                        field(EndingDate; EndDateReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date for the time interval for VAT statement lines in the report.';
                        }
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to include open VAT entries in the report.';
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to include VAT entries from before the specified time period in the report.';
                    }
                    field(RoundToWholeNumbers; PrintInIntegers)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Round to Whole Numbers';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want the amounts in the report to be rounded to whole numbers.';
                    }
                    field(ShowAmtInAddCurrency; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        Importance = Additional;
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the amounts to be printed in the additional reporting currency. If you leave this check box empty, the amounts will be printed in LCY.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;
        VATStmtLine.SetRange("Date Filter", StartDate, EndDateReq);
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            Heading := Text000
        else
            Heading := Text004;
        Heading2 := StrSubstNo(Text005, StartDate, EndDateReq);
        VATStmtLineFilter := VATStmtLine.GetFilters;
    end;

    var
        Text000: Label 'VAT entries before and within the period';
        Text003: Label 'Amounts are in %1, rounded without decimals.';
        Text004: Label 'VAT entries within the period';
        Text005: Label 'Period: %1..%2';
        GLAcc: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        GLSetup: Record "General Ledger Setup";
        VATStmtLine: Record "VAT Statement Line";
        GLEntry: Record "G/L Entry";
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        PrintInIntegers: Boolean;
        VATStmtLineFilter: Text;
        Heading: Text[50];
        Amount: Decimal;
        TotalAmount: Decimal;
        RowNo: array[6] of Code[10];
        ErrorText: Text[80];
        i: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        UseAmtsInAddCurr: Boolean;
        HeaderText: Text[50];
        EndDate: Date;
        StartDate: Date;
        EndDateReq: Date;
        Heading2: Text[50];
        Amount2: Decimal;
        NetAmountLCY: Decimal;
        AllamountsareinLbl: Label 'All amounts are in';
        VATStmtCaptionLbl: Label 'VAT Statement';
        CurrReportPageNoCaptionLbl: Label 'Page';
        VATStmtTemplateCaptionLbl: Label 'VAT Statement Template';
        VATStmtNameCaptionLbl: Label 'VAT Statement Name';
        AmtsareinwholeLCYsCaptionLbl: Label 'Amounts are in whole LCYs.';
        ReportinclallVATentriesCaptionLbl: Label 'The report includes all VAT entries.';
        RepinclonlyclosedVATentCaptionLbl: Label 'The report includes only closed VAT entries.';
        TotalAmountCaptionLbl: Label 'Amount';

    procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var CorrectionAmount: Decimal; var NetAmountLCY: Decimal; JournalTempl: Code[10]; Level: Integer): Boolean
    begin
        if Level = 0 then begin
            TotalAmount := 0;
            NetAmountLCY := 0;
            CorrectionAmount := 0;
        end;
        CalcCorrection(VATStmtLine2, CorrectionAmount);
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                begin
                    GLAcc.SetFilter("No.", VATStmtLine2."Account Totaling");
                    if EndDateReq = 0D then
                        EndDate := DMY2Date(31, 12, 9999)
                    else
                        EndDate := EndDateReq;
                    GLEntry.SetCurrentKey("Journal Template Name", "G/L Account No.", "Posting Date", "Document Type");
                    GLEntry.SetRange("Posting Date", GetPeriodStartDate, EndDate);
                    if JournalTempl <> '' then
                        GLEntry.SetRange("Journal Template Name", JournalTempl);

                    if VATStmtLine2."Document Type" = VATStmtLine2."Document Type"::"All except Credit Memo" then
                        GLEntry.SetFilter("Document Type", '<>%1', VATStmtLine2."Document Type"::"Credit Memo")
                    else
                        GLEntry.SetRange("Document Type", VATStmtLine2."Document Type");
                    Amount := 0;
                    Amount2 := 0;
                    if GLAcc.Find('-') and (VATStmtLine2."Account Totaling" <> '') then
                        repeat
                            GLEntry.SetRange("G/L Account No.", GLAcc."No.");
                            GLEntry.CalcSums(Amount, GLEntry."Additional-Currency Amount");
                            Amount := ConditionalAdd(Amount, GLEntry.Amount, GLEntry."Additional-Currency Amount");
                            Amount2 := Amount;
                        until GLAcc.Next = 0;
                    OnCalcLineTotalOnBeforeCalcTotalAmountAccountTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
                    CalcTotalAmount(VATStmtLine2, TotalAmount, NetAmountLCY);
                end;
            VATStmtLine2.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset();
                    VATEntry.SetCurrentKey(
                      "Journal Template Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Document Type", "Posting Date");
                    VATEntry.SetRange("VAT Bus. Posting Group", VATStmtLine2."VAT Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
                    if JournalTempl <> '' then
                        VATEntry.SetRange("Journal Template Name", JournalTempl);
                    VATEntry.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    if VATStmtLine2."Document Type" = VATStmtLine2."Document Type"::"All except Credit Memo" then
                        VATEntry.SetFilter("Document Type", '<>%1', VATStmtLine2."Document Type"::"Credit Memo")
                    else
                        VATEntry.SetRange("Document Type", VATStmtLine2."Document Type");
                    if (EndDateReq <> 0D) or (StartDate <> 0D) then
                        VATEntry.SetRange("Posting Date", GetPeriodStartDate, EndDate);
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount, "Additional-Currency Amount");
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                                if VATStmtLine2."Incl. Non Deductible VAT" then begin
                                    VATEntry.CalcSums("Non Ded. VAT Amount", "Non Ded. Source Curr. VAT Amt.");
                                    Amount := ConditionalAdd(Amount, VATEntry."Non Ded. VAT Amount", VATEntry."Non Ded. Source Curr. VAT Amt.");
                                end;
                                Amount2 := Amount;
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base", "Base Before Pmt. Disc.");
                                Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                if VATStmtLine2."Incl. Non Deductible VAT" then begin
                                    VATEntry.CalcSums("Non Ded. VAT Amount", "Non Ded. Source Curr. VAT Amt.");
                                    Amount := ConditionalAdd(Amount, -VATEntry."Non Ded. VAT Amount", -VATEntry."Non Ded. Source Curr. VAT Amt.");
                                end;
                                Amount2 := ConditionalAdd(0, VATEntry."Base Before Pmt. Disc.", 0);
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Amount", "Add.-Curr. Rem. Unreal. Amount");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                                Amount2 := Amount;
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Base", "Add.-Curr. Rem. Unreal. Base");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Base", VATEntry."Add.-Curr. Rem. Unreal. Base");
                                Amount2 := Amount;
                            end;
                    end;
                    OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
                    CalcTotalAmount(VATStmtLine2, TotalAmount, NetAmountLCY);
                end;
            VATStmtLine2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := VATStmtLine2."Row No.";

                    if VATStmtLine2."Row Totaling" = '' then
                        exit(true);
                    VATStmtLine2.SetRange("Statement Template Name", VATStmtLine2."Statement Template Name");
                    VATStmtLine2.SetRange("Statement Name", VATStmtLine2."Statement Name");
                    VATStmtLine2.SetFilter("Row No.", VATStmtLine2."Row Totaling");
                    if VATStmtLine2.Find('-') then
                        repeat
                            if not CalcLineTotal(VATStmtLine2, TotalAmount, CorrectionAmount, NetAmountLCY, JournalTempl, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                VATStmtLine2.FieldError("Row No.", ErrorText);
                            end;
                        until VATStmtLine2.Next = 0;
                end;
        end;

        exit(true);
    end;

    local procedure CalcTotalAmount(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var NetAmountLCY: Decimal)
    begin
        if VATStmtLine2."Calculate with" = 1 then begin
            Amount := -Amount;
            Amount2 := -Amount2;
        end;
        if PrintInIntegers and VATStmtLine2.Print then begin
            Amount := Round(Amount, 1, '<');
            Amount2 := Round(Amount2, 1, '<');
        end;
        TotalAmount := TotalAmount + Amount;
        NetAmountLCY := NetAmountLCY + Amount2;
    end;

    procedure InitializeRequest(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean)
    begin
        ClearAll;
        "VAT Statement Name".Copy(NewVATStmtName);
        "VAT Statement Line".Copy(NewVATStatementLine);
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        PrintInIntegers := NewPrintInIntegers;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        if NewVATStatementLine.GetFilter("Date Filter") <> '' then begin
            StartDate := NewVATStatementLine.GetRangeMin("Date Filter");
            EndDateReq := NewVATStatementLine.GetRangeMax("Date Filter");
            EndDate := EndDateReq;
        end else begin
            StartDate := 0D;
            EndDateReq := 0D;
            EndDate := DMY2Date(31, 12, 9999);
        end;
    end;

    local procedure ConditionalAdd(Amount: Decimal; AmountToAdd: Decimal; AddCurrAmountToAdd: Decimal): Decimal
    begin
        if UseAmtsInAddCurr then
            exit(Amount + AddCurrAmountToAdd);

        exit(Amount + AmountToAdd);
    end;

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    local procedure CalcCorrection(VATStmtLine2: Record "VAT Statement Line"; var CorrectionAmount: Decimal)
    var
        ManualVATCorrection: Record "Manual VAT Correction";
    begin
        CalcManualVATCorrectionSums(VATStmtLine2, ManualVATCorrection);
        Amount := ConditionalAdd(0, ManualVATCorrection.Amount, ManualVATCorrection."Additional-Currency Amount");
        if VATStmtLine2."Calculate with" = VATStmtLine2."Calculate with"::"Opposite Sign" then
            Amount := -Amount;
        if PrintInIntegers and VATStmtLine2.Print then
            Amount := Round(Amount, 1, '<');
        CorrectionAmount := CorrectionAmount + Amount;
    end;

    local procedure CalcManualVATCorrectionSums(VATStmtLine2: Record "VAT Statement Line"; var ManualVATCorrection: Record "Manual VAT Correction")
    begin
        with ManualVATCorrection do begin
            Reset;
            SetRange("Statement Template Name", VATStmtLine2."Statement Template Name");
            SetRange("Statement Name", VATStmtLine2."Statement Name");
            SetRange("Statement Line No.", VATStmtLine2."Line No.");
            SetRange("Posting Date", GetPeriodStartDate, EndDate);
            CalcSums(Amount, "Additional-Currency Amount");
        end;
    end;

    local procedure GetPeriodStartDate(): Date
    begin
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            exit(0D);
        exit(StartDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; var Amount: Decimal; UseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnBeforeCalcTotalAmountAccountTotaling(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; var Amount: Decimal; UseAmtsInAddCurr: Boolean)
    begin
    end;
}

