page 18431 "Update Reference Inv. Journals"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Reference Invoice No.";
    Caption = 'Update Reference Inv. Journals';

    layout
    {
        area(Content)
        {
            repeater(control1)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = '';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = '';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = '';
                }
                field("Reference Invoice Nos."; Rec."Reference Invoice Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = '';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        RefInvNoMgt: Codeunit "Reference Invoice No. Mgt.";
                    begin
                        if Rec."Source Type" = Rec."Source Type"::Vendor then
                            RefInvNoMgt.UpdateReferenceInvoiceNoforPurchJournals(
                                Rec,
                                Rec."Document Type",
                                Rec."Document No.",
                                Rec."Journal Template Name",
                                Rec."Journal Batch Name")
                        else
                            RefInvNoMgt.UpdateReferenceInvoiceNoforSalesJournals(
                                Rec,
                                Rec."Document Type",
                                Rec."Document No.",
                                Rec."Journal Template Name",
                                Rec."Journal Batch Name");

                        if xRec."Reference Invoice Nos." <> '' then
                            if (xRec."Reference Invoice Nos." <> Rec."Reference Invoice Nos.") and Rec.Verified then
                                Error(RefNoAlterErr);
                    end;
                }
                field("Description"; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = '';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = '';
                }
                field("Verified"; Rec.Verified)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = '';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Verify)
            {
                ApplicationArea = All;
                Caption = 'Verify';
                Image = UpdateDescription;
                Promoted = true;
                PromotedCategory = Process;
                Scope = Repeater;
                Tooltip = '';

                trigger OnAction()
                var
                    RefInvNoMgt: Codeunit "Reference Invoice No. Mgt.";
                begin
                    RefInvNoMgt.VerifyReferenceNoJournals(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec."Source Type" := SourceTypeExternal;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
        GenJournalLine: Record "Gen. Journal Line";
        RefInvNoMgt: Codeunit "Reference Invoice No. Mgt.";
        CheckValue: Boolean;
    begin
        ReferenceInvoiceNo.SetRange("Document No.", Rec."Document No.");
        ReferenceInvoiceNo.SetRange("Document Type", Rec."Document Type");
        ReferenceInvoiceNo.SetRange("Source No.", Rec."Source No.");
        ReferenceInvoiceNo.SetRange(Verified, false);
        if ReferenceInvoiceNo.FindFirst() then
            if Confirm(VerifyQst, false) then begin
                CheckValue := true;
                ReferenceInvoiceNo.DeleteAll();
            end else
                exit(false);

        CheckBlankLines();

        if Rec."Document Type" = Rec."Document Type"::"Credit Memo" then begin
            GenJournalLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            GenJournalLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            GenJournalLine.SetRange("Document Type", Rec."Document Type");
            GenJournalLine.SetRange("Document No.", Rec."Document No.");
            if GenJournalLine.FindFirst() then
                if CheckValue then begin
                    GenJournalLine."RCM Exempt" := false;
                    GenJournalLine.Modify(true);
                end else begin
                    GenJournalLine."RCM Exempt" := RefInvNoMgt.CheckRCMExemptDateJournal(GenJournalLine);
                    GenJournalLine.Modify(true);
                end;
        end;
    end;

    var
        SourceTypeExternal: Enum "Party Type";
        VerifyQst: Label 'Do you want to delete unverified reference invoice no.?';
        ReferenceErr: Label 'Please Update Reference Invoice No for selected Document.';
        RefNoAlterErr: Label 'Reference Invoice No cannot be updated after verification.';

    procedure SetSourceType(SourceType: Enum "Party Type")
    begin
        SourceTypeExternal := SourceType;
    end;

    local procedure CheckBlankLines()
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ReferenceInvoiceNo.SetRange("Document No.", Rec."Document No.");
        ReferenceInvoiceNo.SetRange("Document Type", Rec."Document Type");
        ReferenceInvoiceNo.SetRange("Source No.", Rec."Source No.");
        ReferenceInvoiceNo.SetRange(Verified, true);
        if not ReferenceInvoiceNo.FindFirst() then begin
            VendorLedgerEntry.SetRange("Document No.", Rec."Document No.");
            if VendorLedgerEntry.FindFirst() and not Rec.Verified then
                Error(ReferenceErr);
            CustLedgerEntry.SetRange("Document No.", Rec."Document No.");
            if CustLedgerEntry.FindFirst() and not Rec.Verified then
                Error(ReferenceErr);
        end;
    end;
}