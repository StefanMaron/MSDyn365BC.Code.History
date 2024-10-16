// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;

#pragma warning disable AS0106 // Protected variable VATDateType was removed before AS0106 was introduced.
page 475 "VAT Statement Preview Line"
#pragma warning restore AS0106
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Statement Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT statement line.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what the VAT statement line will include.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT statement line shows the VAT amounts, or the base amounts on which the VAT is calculated.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a tax jurisdiction code for the statement.';
                    Visible = false;
                }
                field("Use Tax"; Rec."Use Tax")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies whether to use only entries from the VAT Entry table that are marked as Use Tax to be totaled on this line.';
                    Visible = false;
                }
                field(ColumnValue; ColumnValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Column Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the type of entries that will be included in the amounts in columns.';

                    trigger OnDrillDown()
                    begin
                        case Rec.Type of
                            Rec.Type::"Account Totaling":
                                begin
                                    GLEntry.SetCurrentKey("Journal Templ. Name", "G/L Account No.", "VAT Reporting Date", "Document Type");
                                    GLEntry.SetFilter("G/L Account No.", Rec."Account Totaling");
                                    Rec.CopyFilter("Date Filter", GLEntry."VAT Reporting Date");
                                    if Rec."Document Type" = Rec."Document Type"::"All except Credit Memo" then
                                        GLEntry.SetFilter("Document Type", '<>%1', Rec."Document Type"::"Credit Memo")
                                    else
                                        GLEntry.SetRange("Document Type", Rec."Document Type");
                                    OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(VATEntry, GLEntry, Rec);
                                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                                end;
                            Rec.Type::"VAT Entry Totaling":
                                begin
                                    VATEntry.Reset();
                                    VATEntry.SetCurrentKey("Journal Templ. Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date");
                                    VATEntry.SetRange(Type, Rec."Gen. Posting Type");
                                    VATEntry.SetRange("VAT Bus. Posting Group", Rec."VAT Bus. Posting Group");
                                    VATEntry.SetRange("VAT Prod. Posting Group", Rec."VAT Prod. Posting Group");
                                    VATEntry.SetRange("Tax Jurisdiction Code", Rec."Tax Jurisdiction Code");
                                    VATEntry.SetRange("Use Tax", Rec."Use Tax");
                                    if Rec."Document Type" = Rec."Document Type"::"All except Credit Memo" then
                                        VATEntry.SetFilter("Document Type", '<>%1', Rec."Document Type"::"Credit Memo")
                                    else
                                        VATEntry.SetRange("Document Type", Rec."Document Type");
                                    if Rec.GetFilter("Date Filter") <> '' then
                                        SetDateFilterForVATEntry(VATEntry);

                                    case Selection of
                                        Selection::Open:
                                            VATEntry.SetRange(Closed, false);
                                        Selection::Closed:
                                            VATEntry.SetRange(Closed, true);
                                        Selection::"Open and Closed":
                                            VATEntry.SetRange(Closed);
                                    end;
                                    OnBeforeOpenPageVATEntryTotaling(VATEntry, Rec, GLEntry);
                                    PAGE.Run(PAGE::"VAT Entries", VATEntry);
                                end;
                            Rec.Type::"Row Totaling",
                            Rec.Type::Description:
                                Error(Text000, Rec.FieldCaption(Type), Rec.Type);
                        end;
                    end;
                }
                field(CorrectionValue; CorrectionValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Correction Amount';
                    ToolTip = 'Specifies the amount of the VAT correction. You must enter the correction amount, not the new amount.';

                    trigger OnDrillDown()
                    begin
                        DrillDownCorrectionValue();
                    end;
                }
                field(TotalAmount; ColumnValue + CorrectionValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies the total amount minus any invoice discount amount for the service order. The value does not include VAT.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Clear(VATStatement);
        VATStatement.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        CalcColumnValue(Rec, ColumnValue, CorrectionValue, NetAmountLCY, '', 0);
        if Rec."Print with" = Rec."Print with"::"Opposite Sign" then begin
            ColumnValue := -ColumnValue;
            CorrectionValue := -CorrectionValue;
        end;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Drilldown is not possible when %1 is %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VATStmtName: Record "VAT Statement Name";
        VATStatement: Report "VAT Statement";
        ColumnValue: Decimal;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        UseAmtsInAddCurr: Boolean;
        CorrectionValue: Decimal;
        NetAmountLCY: Decimal;

    local procedure SetDateFilterForVATEntry(var VATEntryLocal: Record "VAT Entry")
    begin
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            VATEntryLocal.SetRange("VAT Reporting Date", 0D, Rec.GetRangeMax("Date Filter"))
        else
            Rec.CopyFilter("Date Filter", VATEntryLocal."VAT Reporting Date");
    end;

    local procedure CalcColumnValue(VATStatementLine: Record "VAT Statement Line"; var ColumnValue: Decimal; var CorrectionValue: Decimal; var NetAmountLCY: Decimal; JournalTempl: Code[10]; Level: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcColumnValue(VATStatementLine, ColumnValue, CorrectionValue, NetAmountLCY, JournalTempl, Level, IsHandled, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        if IsHandled then
            exit;

        VATStatement.CalcLineTotal(VATStatementLine, ColumnValue, CorrectionValue, NetAmountLCY, JournalTempl, Level);
    end;

    procedure UpdateForm(var VATStmtName: Record "VAT Statement Name"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewUseAmtsInAddCurr: Boolean)
    begin
        VATStmtName.CopyFilter("Date Filter", Rec."Date Filter");
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        OnUpdateFormOnBeforeVatStatementInitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        VATStatement.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        OnUpdateFormOnBeforePageUpdate(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        CurrPage.Update();

        OnAfterUpdateForm();
    end;

    local procedure ApplyDateFilter(var ManualVATCorrection: Record "Manual VAT Correction")
    begin
        if Rec.GetFilter("Date Filter") <> '' then
            if PeriodSelection = PeriodSelection::"Before and Within Period" then
                ManualVATCorrection.SetRange("Posting Date", 0D, Rec.GetRangeMax("Date Filter"))
            else
                Rec.CopyFilter("Date Filter", ManualVATCorrection."Posting Date");
    end;

    procedure DrillDownCorrectionValue()
    var
        ManualVATCorrection: Record "Manual VAT Correction";
        ManualVATCorrectionListPage: Page "Manual VAT Correction List";
        IncludesRowTotaling: Boolean;
    begin
        Clear(ManualVATCorrectionListPage);
        ManualVATCorrection.Reset();
        ManualVATCorrection.FilterGroup(2);
        IncludesRowTotaling := MarkManVATCorrections(Rec, ManualVATCorrection);
        if IncludesRowTotaling then begin
            ManualVATCorrectionListPage.SetCorrStatementLineNo(Rec."Line No.");
            ManualVATCorrection.SetRange("Statement Line No.");
            ManualVATCorrection.MarkedOnly(true);
        end;
        ManualVATCorrection.FilterGroup(0);
        ManualVATCorrectionListPage.SetTableView(ManualVATCorrection);
        ManualVATCorrectionListPage.Run();
    end;

    local procedure MarkLinesManVATCorrections(VATStatementLine: Record "VAT Statement Line"; var ManualVATCorrection: Record "Manual VAT Correction")
    begin
        ManualVATCorrection.SetRange("Statement Template Name", VATStatementLine."Statement Template Name");
        ManualVATCorrection.SetRange("Statement Name", VATStatementLine."Statement Name");
        ManualVATCorrection.SetRange("Statement Line No.", VATStatementLine."Line No.");
        ApplyDateFilter(ManualVATCorrection);
        if ManualVATCorrection.FindSet() then
            repeat
                ManualVATCorrection.Mark(true);
            until ManualVATCorrection.Next() = 0;
    end;

    local procedure MarkManVATCorrections(VATStatementLine: Record "VAT Statement Line"; var ManualVATCorrection: Record "Manual VAT Correction"): Boolean
    begin
        MarkLinesManVATCorrections(VATStatementLine, ManualVATCorrection);
        if (VATStatementLine.Type = VATStatementLine.Type::"Row Totaling") and
           (VATStatementLine."Row Totaling" <> '')
        then begin
            VATStatementLine.SetRange("Statement Template Name", VATStatementLine."Statement Template Name");
            VATStatementLine.SetRange("Statement Name", VATStatementLine."Statement Name");
            VATStatementLine.SetFilter("Row No.", VATStatementLine."Row Totaling");
            if VATStatementLine.FindSet() then
                repeat
                    MarkManVATCorrections(VATStatementLine, ManualVATCorrection);
                until VATStatementLine.Next() = 0;
            exit(true);
        end;
        exit(false);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcColumnValue(VATStatementLine: Record "VAT Statement Line"; var TotalAmount: Decimal; var CorrectionValue: Decimal; var NetAmountLCY: Decimal; JournalTempl: Code[10]; Level: Integer; var IsHandled: Boolean; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PrintInIntegers: Boolean; UseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOpenPageVATEntryTotaling(var VATEntry: Record "VAT Entry"; var VATStatementLine: Record "VAT Statement Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(var VATEntry: Record "VAT Entry"; var GLEntry: Record "G/L Entry"; var VATStatementLine: Record "VAT Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFormOnBeforePageUpdate(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateForm()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFormOnBeforeVatStatementInitializeRequest(var NewVATStatementName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean)
    begin
    end;
}

