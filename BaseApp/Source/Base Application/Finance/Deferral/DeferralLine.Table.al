namespace Microsoft.Finance.Deferral;

using Microsoft.Foundation.Period;

table 1702 "Deferral Line"
{
    Caption = 'Deferral Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
            TableRelation = "Deferral Header"."Deferral Doc. Type";
        }
        field(2; "Gen. Jnl. Template Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Template Name';
            TableRelation = "Deferral Header"."Gen. Jnl. Template Name";
        }
        field(3; "Gen. Jnl. Batch Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Batch Name';
            TableRelation = "Deferral Header"."Gen. Jnl. Batch Name";
        }
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
            TableRelation = "Deferral Header"."Document Type";
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Deferral Header"."Document No.";
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Deferral Header"."Line No.";
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                AccountingPeriod: Record "Accounting Period";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostingDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if DeferralUtilities.IsDateNotAllowed("Posting Date") then
                    Error(InvalidPostingDateErr, "Posting Date");

                if AccountingPeriod.IsEmpty() then
                    exit;

                AccountingPeriod.SetFilter("Starting Date", '>=%1', "Posting Date");
                if AccountingPeriod.IsEmpty() then
                    Error(DeferSchedOutOfBoundsErr);
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if Amount = 0 then
                    Error(ZeroAmountToDeferErr);

                if DeferralHeader.Get("Deferral Doc. Type", "Gen. Jnl. Template Name", "Gen. Jnl. Batch Name", "Document Type", "Document No.", "Line No.") then begin
                    if DeferralHeader."Amount to Defer" > 0 then
                        if Amount < 0 then
                            Error(AmountToDeferPositiveErr);
                    if DeferralHeader."Amount to Defer" < 0 then
                        if Amount > 0 then
                            Error(AmountToDeferNegativeErr);
                end;
            end;
        }
        field(10; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Gen. Jnl. Template Name", "Gen. Jnl. Batch Name", "Document Type", "Document No.", "Line No.", "Posting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Posting Date" = 0D then
            Error(InvalidDeferralLineDateErr);
    end;

    var
        DeferralHeader: Record "Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
        InvalidPostingDateErr: Label '%1 is not within the range of posting dates for deferrals for your company. Check the user setup for the allowed deferrals posting dates.', Comment = '%1=The date passed in for the posting date.';
        DeferSchedOutOfBoundsErr: Label 'The deferral schedule falls outside the accounting periods that have been set up for the company.';
        InvalidDeferralLineDateErr: Label 'The posting date for this deferral schedule line is not valid.';
        ZeroAmountToDeferErr: Label 'The deferral amount cannot be 0.';
        AmountToDeferPositiveErr: Label 'The deferral amount must be positive.';
        AmountToDeferNegativeErr: Label 'The deferral amount must be negative.';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostingDate(var DeferralLine: Record "Deferral Line"; xDeferralLine: Record "Deferral Line"; CallingFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;
}

