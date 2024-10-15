namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Period;

table 1701 "Deferral Header"
{
    Caption = 'Deferral Header';
    DataCaptionFields = "Schedule Description";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
        }
        field(2; "Gen. Jnl. Template Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Template Name';
        }
        field(3; "Gen. Jnl. Batch Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Batch Name';
        }
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(7; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            NotBlank = true;
        }
        field(8; "Amount to Defer"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Defer';

            trigger OnValidate()
            begin
                if "Initial Amount to Defer" < 0 then begin// Negative amount
                    if "Amount to Defer" < "Initial Amount to Defer" then
                        Error(AmountToDeferErr);
                    if "Amount to Defer" > 0 then
                        Error(AmountToDeferErr)
                end;

                if "Initial Amount to Defer" >= 0 then begin// Positive amount
                    if "Amount to Defer" > "Initial Amount to Defer" then
                        Error(AmountToDeferErr);
                    if "Amount to Defer" < 0 then
                        Error(AmountToDeferErr);
                end;

                if "Amount to Defer" = 0 then
                    Error(ZeroAmountToDeferErr);
            end;
        }
        field(9; "Amount to Defer (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount to Defer (LCY)';
        }
        field(10; "Calc. Method"; Enum "Deferral Calculation Method")
        {
            Caption = 'Calc. Method';
        }
        field(11; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            var
                AccountingPeriod: Record "Accounting Period";
                GenJnlBatch: Record "Gen. Journal Batch";
                ThrowScheduleOutOfBoundError: Boolean;
            begin
                if GenJnlBatch.Get("Gen. Jnl. Template Name", "Gen. Jnl. Batch Name") then
                    GenJnlCheckLine.SetGenJnlBatch(GenJnlBatch);
                if GenJnlCheckLine.DeferralPostingDateNotAllowed("Start Date") then
                    Error(InvalidPostingDateErr, "Start Date");

                if AccountingPeriod.IsEmpty() then
                    exit;

                AccountingPeriod.SetFilter("Starting Date", '>=%1', "Start Date");
                ThrowScheduleOutOfBoundError := AccountingPeriod.IsEmpty();
                OnValidateStartDateOnAfterCalcThrowScheduleOutOfBoundError(Rec, ThrowScheduleOutOfBoundError);
                if ThrowScheduleOutOfBoundError then
                    Error(DeferSchedOutOfBoundsErr);
            end;
        }
        field(12; "No. of Periods"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Periods';
            NotBlank = true;

            trigger OnValidate()
            begin
                if "No. of Periods" < 1 then
                    Error(NumberofPeriodsErr);
            end;
        }
        field(13; "Schedule Description"; Text[100])
        {
            Caption = 'Schedule Description';
        }
        field(14; "Initial Amount to Defer"; Decimal)
        {
            Caption = 'Initial Amount to Defer';
        }
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(20; "Schedule Line Total"; Decimal)
        {
            CalcFormula = sum("Deferral Line".Amount where("Deferral Doc. Type" = field("Deferral Doc. Type"),
                                                            "Gen. Jnl. Template Name" = field("Gen. Jnl. Template Name"),
                                                            "Gen. Jnl. Batch Name" = field("Gen. Jnl. Batch Name"),
                                                            "Document Type" = field("Document Type"),
                                                            "Document No." = field("Document No."),
                                                            "Line No." = field("Line No.")));
            Caption = 'Schedule Line Total';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Gen. Jnl. Template Name", "Gen. Jnl. Batch Name", "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DeferralLine: Record "Deferral Line";
    begin
        // If the user deletes the header, all associated lines should also be deleted
        DeferralUtilities.FilterDeferralLines(
          DeferralLine, "Deferral Doc. Type".AsInteger(), "Gen. Jnl. Template Name", "Gen. Jnl. Batch Name",
          "Document Type", "Document No.", "Line No.");
        OnDeleteOnBeforeDeleteAll(Rec, DeferralLine);
        DeferralLine.DeleteAll();
    end;

    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        DeferralUtilities: Codeunit "Deferral Utilities";

        AmountToDeferErr: Label 'The deferred amount cannot be greater than the document line amount.';
        InvalidPostingDateErr: Label '%1 is not within the range of posting dates for your company.', Comment = '%1=The date passed in for the posting date.';
        DeferSchedOutOfBoundsErr: Label 'The deferral schedule falls outside the accounting periods that have been set up for the company.';
        SelectionMsg: Label 'You must specify a deferral code for this line before you can view the deferral schedule.';
        NumberofPeriodsErr: Label 'You must specify one or more periods.';
        ZeroAmountToDeferErr: Label 'The Amount to Defer cannot be 0.';

    procedure CalculateSchedule(): Boolean
    var
        DeferralDescription: Text[100];
    begin
        OnBeforeCalculateSchedule(Rec);
        if "Deferral Code" = '' then begin
            Message(SelectionMsg);
            exit(false);
        end;
        DeferralDescription := "Schedule Description";
        DeferralUtilities.CreateDeferralSchedule(
            "Deferral Code", "Deferral Doc. Type".AsInteger(), "Gen. Jnl. Template Name",
            "Gen. Jnl. Batch Name", "Document Type", "Document No.", "Line No.", "Amount to Defer",
            "Calc. Method", "Start Date", "No. of Periods", false, DeferralDescription, false, "Currency Code");
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSchedule(var DeferralHeader: Record "Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeDeleteAll(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStartDateOnAfterCalcThrowScheduleOutOfBoundError(DeferralHeader: Record "Deferral Header"; var ThrowScheduleOutOfBoundError: Boolean)
    begin
    end;
}

