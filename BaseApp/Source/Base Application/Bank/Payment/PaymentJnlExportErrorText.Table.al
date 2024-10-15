namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;

table 1228 "Payment Jnl. Export Error Text"
{
    Caption = 'Payment Jnl. Export Error Text';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(3; "Journal Line No."; Integer)
        {
            Caption = 'Journal Line No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Error Text"; Text[250])
        {
            Caption = 'Error Text';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; "Additional Information"; Text[250])
        {
            Caption = 'Additional Information';
        }
        field(8; "Support URL"; Text[250])
        {
            Caption = 'Support URL';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Document No.", "Journal Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CreateNew(GenJnlLine: Record "Gen. Journal Line"; NewText: Text; NewAddnlInfo: Text; NewExtSupportInfo: Text)
    begin
        SetLineFilters(GenJnlLine);
        if FindLast() then;
        "Journal Template Name" := GenJnlLine."Journal Template Name";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
        "Document No." := GenJnlLine."Document No.";
        "Journal Line No." := GenJnlLine."Line No.";
        "Line No." += 1;
        "Error Text" := CopyStr(NewText, 1, MaxStrLen("Error Text"));
        "Additional Information" := CopyStr(NewAddnlInfo, 1, MaxStrLen("Additional Information"));
        "Support URL" := CopyStr(NewExtSupportInfo, 1, MaxStrLen("Support URL"));
        Insert();
    end;

    procedure JnlLineHasErrors(GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        SetLineFilters(GenJnlLine);
        exit(not IsEmpty);
    end;

    procedure JnlBatchHasErrors(GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        SetBatchFilters(GenJnlLine);
        exit(not IsEmpty);
    end;

    procedure DeleteJnlLineErrors(GenJnlLine: Record "Gen. Journal Line")
    begin
        if JnlLineHasErrors(GenJnlLine) then
            DeleteAll();
    end;

    procedure DeleteJnlBatchErrors(GenJnlLine: Record "Gen. Journal Line")
    begin
        if JnlBatchHasErrors(GenJnlLine) then
            DeleteAll();
    end;

    procedure DeleteJnlLineErrorsWhenRecDeleted(GenJnlLine: Record "Gen. Journal Line")
    begin
        if JnlLineHasErrorsWhenRecDeleted(GenJnlLine) then
            DeleteAll();
    end;

    procedure JnlLineHasErrorsWhenRecDeleted(GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        SetLineFiltersWhenRecDeleted(GenJnlLine);
        exit(not IsEmpty);
    end;

    local procedure SetLineFiltersWhenRecDeleted(GenJnlLine: Record "Gen. Journal Line")
    begin
        SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        SetRange("Journal Line No.", GenJnlLine."Line No.");
    end;

    local procedure SetBatchFilters(GenJnlLine: Record "Gen. Journal Line")
    begin
        SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if ((GenJnlLine."Journal Template Name" = '') and (GenJnlLine."Journal Batch Name" = '')) or (GenJnlLine."Document No." <> '') then
            SetRange("Document No.", GenJnlLine."Document No.");
    end;

    local procedure SetLineFilters(GenJnlLine: Record "Gen. Journal Line")
    begin
        SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        SetRange("Document No.", GenJnlLine."Document No.");
        SetRange("Journal Line No.", GenJnlLine."Line No.");
    end;
}

