namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

page 1702 "Deferral Schedule"
{
    Caption = 'Deferral Schedule';
    DataCaptionFields = "Start Date";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    ShowFilter = false;
    SourceTable = "Deferral Header";

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("Amount to Defer"; Rec."Amount to Defer")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount to defer per period.';
                    trigger OnValidate()
                    begin
                        ShowAllocationWarning(Rec.FieldCaption("Amount to Defer"));
                    end;
                }
                field("Calc. Method"; Rec."Calc. Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the Amount field for each period is calculated. Straight-Line: Calculated per the number of periods, distributed by period length. Equal Per Period: Calculated per the number of periods, distributed evenly on periods. Days Per Period: Calculated per the number of days in the period. User-Defined: Not calculated. You must manually fill the Amount field for each period.';
                    trigger OnValidate()
                    begin
                        ShowAllocationWarning(Rec.FieldCaption("Calc. Method"));
                    end;
                }
                field("No. of Periods"; Rec."No. of Periods")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how many accounting periods the total amounts will be deferred to.';
                    trigger OnValidate()
                    begin
                        ShowAllocationWarning(Rec.FieldCaption("No. of Periods"));
                    end;
                }
                field(PostingDate; PostingDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the source document.';
                }
                field(StartDateCalcMethod; StartDateCalcMethod)
                {
                    ApplicationArea = Suite;
                    Caption = 'Start Date Calc. Method';
                    Editable = false;
                    ToolTip = 'Specifies the method used to calculate the start date that is used for calculating deferral amounts.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when to start calculating deferral amounts.';
                    trigger OnValidate()
                    begin
                        ShowAllocationWarning(Rec.FieldCaption("Start Date"));
                    end;
                }
            }
            part(DeferralSheduleSubform; "Deferral Schedule Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Deferral Doc. Type" = field("Deferral Doc. Type"),
                              "Gen. Jnl. Template Name" = field("Gen. Jnl. Template Name"),
                              "Gen. Jnl. Batch Name" = field("Gen. Jnl. Batch Name"),
                              "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Actions")
            {
                Caption = 'Actions';
                action(CalculateSchedule)
                {
                    ApplicationArea = Suite;
                    Caption = 'Calculate Schedule';
                    Image = CalculateCalendar;
                    ToolTip = 'Calculate the deferral schedule by which revenue or expense amounts will be distributed over multiple accounting periods.';

                    trigger OnAction()
                    begin
                        Changed := Rec.CalculateSchedule();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CalculateSchedule_Promoted; CalculateSchedule)
                {
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        Changed := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Changed := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Changed := true;
    end;

    trigger OnOpenPage()
    begin
        InitForm();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralUtilities: Codeunit "Deferral Utilities";
        EarliestPostingDate: Date;
        RecCount: Integer;
        ExpectedCount: Integer;
        ShowNoofPeriodsError: Boolean;
    begin
        // Prevent closing of the window if the sum of the periods does not equal the Amount to Defer
        if DeferralHeader.Get(Rec."Deferral Doc. Type",
             Rec."Gen. Jnl. Template Name",
             Rec."Gen. Jnl. Batch Name",
             Rec."Document Type",
             Rec."Document No.", Rec."Line No.")
        then begin
            Rec.CalcFields("Schedule Line Total");
            if Rec."Schedule Line Total" <> DeferralHeader."Amount to Defer" then
                Error(TotalToDeferErr);
        end;

        DeferralLine.SetRange("Deferral Doc. Type", Rec."Deferral Doc. Type");
        DeferralLine.SetRange("Gen. Jnl. Template Name", Rec."Gen. Jnl. Template Name");
        DeferralLine.SetRange("Gen. Jnl. Batch Name", Rec."Gen. Jnl. Batch Name");
        DeferralLine.SetRange("Document Type", Rec."Document Type");
        DeferralLine.SetRange("Document No.", Rec."Document No.");
        DeferralLine.SetRange("Line No.", Rec."Line No.");
        OnOnQueryClosePageOnAfterDeferralLineSetFilters(Rec, DeferralLine);

        RecCount := DeferralLine.Count();
        ExpectedCount := DeferralUtilities.CalcDeferralNoOfPeriods(Rec."Calc. Method", Rec."No. of Periods", Rec."Start Date");
        ShowNoofPeriodsError := ExpectedCount <> RecCount;
        OnOnQueryClosePageOnAfterCalcShowNoofPeriodsError(Rec, DeferralLine, ShowNoofPeriodsError);
        if ShowNoofPeriodsError then
            Rec.FieldError("No. of Periods");

        DeferralLine.SetFilter("Posting Date", '>%1', 0D);
        if DeferralLine.FindFirst() then begin
            EarliestPostingDate := DeferralLine."Posting Date";
            if EarliestPostingDate <> DeferralHeader."Start Date" then
                Error(PostingDateErr);
        end;
    end;

    var
        TotalToDeferErr: Label 'The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.';
        Changed: Boolean;
        DisplayDeferralDocType: Enum "Deferral Document Type";
        DisplayGenJnlTemplateName: Code[10];
        DisplayGenJnlBatchName: Code[10];
        DisplayDocumentType: Integer;
        DisplayDocumentNo: Code[20];
        DisplayLineNo: Integer;
        PostingDateErr: Label 'You cannot specify a posting date that is not equal to the start date.';
        PostingDate: Date;
        StartDateCalcMethod: Text;

    procedure SetParameter(DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    begin
        DisplayDeferralDocType := Enum::"Deferral Document Type".FromInteger(DeferralDocType);
        DisplayGenJnlTemplateName := GenJnlTemplateName;
        DisplayGenJnlBatchName := GenJnlBatchName;
        DisplayDocumentType := DocumentType;
        DisplayDocumentNo := DocumentNo;
        DisplayLineNo := LineNo;
    end;

    [Scope('OnPrem')]
    procedure GetParameter(): Boolean
    begin
        exit(Changed or CurrPage.DeferralSheduleSubform.PAGE.GetChanged())
    end;

    procedure InitForm()
    var
        DeferralTemplate: Record "Deferral Template";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitForm(Rec, DisplayDeferralDocType, DisplayGenJnlTemplateName, DisplayGenJnlBatchName, DisplayDocumentType, DisplayDocumentNo, DisplayLineNo, PostingDate, StartDateCalcMethod, IsHandled);
        if IsHandled then
            exit;

        Rec.Get(DisplayDeferralDocType, DisplayGenJnlTemplateName, DisplayGenJnlBatchName, DisplayDocumentType, DisplayDocumentNo, DisplayLineNo);

        DeferralTemplate.Get(Rec."Deferral Code");
        StartDateCalcMethod := Format(DeferralTemplate."Start Date");
        case DisplayDeferralDocType of
            Rec."Deferral Doc. Type"::"G/L":
                begin
                    GenJournalLine.Get(DisplayGenJnlTemplateName, DisplayGenJnlBatchName, DisplayLineNo);
                    PostingDate := GenJournalLine."Posting Date";
                end;
            Rec."Deferral Doc. Type"::Sales:
                begin
                    SalesHeader.Get(DisplayDocumentType, DisplayDocumentNo);
                    PostingDate := SalesHeader."Posting Date";
                end;
            Rec."Deferral Doc. Type"::Purchase:
                begin
                    PurchaseHeader.Get(DisplayDocumentType, DisplayDocumentNo);
                    PostingDate := PurchaseHeader."Posting Date";
                end;
        end;
    end;

    local procedure ShowAllocationWarning(FieldName: Text)
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        ChangeDeferralScheduleErr: Label 'You can''t change the %1 for the %2 because the document line has the %3 type.', Comment = '%1 = Field Name, %2 = Page Caption, %3 = Line Type';
    begin
        case Rec."Deferral Doc. Type" of
            Rec."Deferral Doc. Type"::Sales:
                if SalesLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then
                    if SalesLine.Type = SalesLine.Type::"Allocation Account" then
                        Error(ChangeDeferralScheduleErr, FieldName, CurrPage.Caption, Format(SalesLine.Type));
            Rec."Deferral Doc. Type"::Purchase:
                if PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then
                    if PurchaseLine.Type = PurchaseLine.Type::"Allocation Account" then
                        Error(ChangeDeferralScheduleErr, FieldName, CurrPage.Caption, Format(PurchaseLine.Type));
            Rec."Deferral Doc. Type"::"G/L":
                if GenJournalLine.Get(Rec."Gen. Jnl. Template Name", Rec."Gen. Jnl. Batch Name", Rec."Line No.") then
                    if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Allocation Account") or
                    (GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Allocation Account") then
                        Error(ChangeDeferralScheduleErr, FieldName, CurrPage.Caption, Format(GenJournalLine."Account Type"));

        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitForm(var DeferralHeader: Record "Deferral Header"; DisplayDeferralDocType: Enum "Deferral Document Type"; DisplayGenJnlTemplateName: Code[10]; DisplayGenJnlBatchName: Code[10]; DisplayDocumentType: Integer; DisplayDocumentNo: Code[20]; DisplayLineNo: Integer; var PostingDate: Date; var StartDateCalcMethod: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnQueryClosePageOnAfterCalcShowNoofPeriodsError(DeferralHeader: Record "Deferral Header"; DeferralLine: Record "Deferral Line"; var ShowNoofPeriodsError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnQueryClosePageOnAfterDeferralLineSetFilters(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line")
    begin
    end;
}

