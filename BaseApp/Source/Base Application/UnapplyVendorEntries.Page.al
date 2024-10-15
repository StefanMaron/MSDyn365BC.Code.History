page 624 "Unapply Vendor Entries"
{
    Caption = 'Unapply Vendor Entries';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Detailed Vendor Ledg. Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(DocuNo; DocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number that will be assigned to the entries that will be created when you click Unapply.';
                }
                field(PostDate; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date that will be assigned to the general ledger entries that will be created when you click Unapply.';
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the detailed vendor ledger entry.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry type of the detailed vendor ledger entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the detailed vendor ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the transaction that created the entry.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor account to which the entry is posted.';
                }
                field("Agreement No."; "Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement number associated with the detailed vendor ledger entry.';
                }
                field("Initial Document Type"; "Initial Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that the initial vendor ledger entry was created with.';
                }
                field(DocumentNo; GetDocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Initial Document No.';
                    ToolTip = 'Specifies the number of the document for which the entry is unapplied.';
                }
                field("Initial Entry Global Dim. 1"; "Initial Entry Global Dim. 1")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the Global Dimension 1 code of the initial vendor ledger entry.';
                    Visible = false;
                }
                field("Initial Entry Global Dim. 2"; "Initial Entry Global Dim. 2")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the Global Dimension 2 code of the initial vendor ledger entry.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the currency if the amount is in a foreign currency.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the detailed vendor ledger entry.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Debit Amount (LCY)"; "Debit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Credit Amount (LCY)"; "Credit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in LCY.';
                    Visible = false;
                }
                field("Initial Entry Due Date"; "Initial Entry Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the initial entry is due for payment.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Vendor Ledger Entry No."; "Vendor Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the vendor ledger entry that the detailed vendor ledger entry line was created for.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Unapply)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Unapply';
                Image = UnApply;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Unselect one or more ledger entries that you want to unapply this record.';

                trigger OnAction()
                var
                    ApplyUnapplyParameters: Record "Apply Unapply Parameters";
                    VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
                    ConfirmManagement: Codeunit "Confirm Management";
                begin
                    if Rec.IsEmpty() then
                        Error(Text010);
                    if not ConfirmManagement.GetResponseOrDefault(Text011, true) then
                        exit;

                    ApplyUnapplyParameters."Document No." := DocNo;
                    ApplyUnapplyParameters."Posting Date" := PostingDate;
                    VendEntryApplyPostedEntries.PostUnApplyVendor(DtldVendLedgEntry2, ApplyUnapplyParameters);
                    PostingDate := 0D;
                    DocNo := '';
                    Rec.DeleteAll();
                    Message(Text009);

                    CurrPage.Close();
                end;
            }
            action(Preview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview Unapply';
                Image = ViewPostedOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Preview how unapplying one or more ledger entries will look like.';

                trigger OnAction()
                var
                    ApplyUnapplyParameters: Record "Apply Unapply Parameters";
                    VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
                begin
                    if Rec.IsEmpty() then
                        Error(Text010);

                    ApplyUnapplyParameters."Document No." := DocNo;
                    ApplyUnapplyParameters."Posting Date" := PostingDate;
                    VendEntryApplyPostedEntries.PreviewUnapply(DtldVendLedgEntry2, ApplyUnapplyParameters);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertEntries;
    end;

    var
        Text009: Label 'The entries were successfully unapplied.';
        Text010: Label 'There is nothing to unapply.';
        Text011: Label 'To unapply these entries, correcting entries will be posted.\Do you want to unapply the entries?';

    protected var
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        Vend: Record Vendor;
        DocNo: Code[20];
        PostingDate: Date;
        VendLedgEntryNo: Integer;

    procedure SetDtldVendLedgEntry(EntryNo: Integer)
    begin
        DtldVendLedgEntry2.Get(EntryNo);
        VendLedgEntryNo := DtldVendLedgEntry2."Vendor Ledger Entry No.";
        PostingDate := DtldVendLedgEntry2."Posting Date";
        DocNo := DtldVendLedgEntry2."Document No.";
        Vend.Get(DtldVendLedgEntry2."Vendor No.");
    end;

    local procedure InsertEntries()
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if DtldVendLedgEntry2."Transaction No." = 0 then begin
            DtldVendLedgEntry.SetCurrentKey("Application No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry.SetRange("Application No.", DtldVendLedgEntry2."Application No.");
        end else begin
            DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry.SetRange("Transaction No.", DtldVendLedgEntry2."Transaction No.");
        end;
        DtldVendLedgEntry.SetRange("Vendor No.", DtldVendLedgEntry2."Vendor No.");
        DeleteAll();
        if DtldVendLedgEntry.Find('-') then
            repeat
                if (DtldVendLedgEntry."Entry Type" <> DtldVendLedgEntry."Entry Type"::"Initial Entry") and
                   not DtldVendLedgEntry.Unapplied
                then begin
                    Rec := DtldVendLedgEntry;
                    OnBeforeRecInsert(Rec, DtldVendLedgEntry, DtldVendLedgEntry2);
                    Insert;
                end;
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure GetDocumentNo(): Code[20]
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if VendLedgEntry.Get("Vendor Ledger Entry No.") then;
        exit(VendLedgEntry."Document No.");
    end;

    procedure Caption(): Text
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        exit(StrSubstNo(
            '%1 %2 %3 %4',
            Vend."No.",
            Vend.Name,
            VendLedgEntry.FieldCaption("Entry No."),
            VendLedgEntryNo));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecInsert(var RecDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    begin
    end;
}

