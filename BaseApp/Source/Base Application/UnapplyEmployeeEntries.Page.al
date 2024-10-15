page 625 "Unapply Employee Entries"
{
    Caption = 'Unapply Employee Entries';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Detailed Employee Ledger Entry";
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
                    ApplicationArea = BasicHR;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number that will be assigned to the entries that will be created when you click Unapply.';
                }
                field(PostDate; PostingDate)
                {
                    ApplicationArea = BasicHR;
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
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the posting date of the detailed vendor ledger entry.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the entry type of the detailed vendor ledger entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the document type of the detailed vendor ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the document number of the transaction that created the entry.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number of the vendor account to which the entry is posted.';
                }
                field("Initial Document Type"; "Initial Document Type")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the document type that the initial vendor ledger entry was created with.';
                }
                field(DocumentNo; GetDocumentNo)
                {
                    ApplicationArea = BasicHR;
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
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the code for the currency if the amount is in a foreign currency.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount of the detailed vendor ledger entry.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Debit Amount (LCY)"; "Debit Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Credit Amount (LCY)"; "Credit Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in the local currency.';
                    Visible = false;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = BasicHR;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Employee Ledger Entry No."; "Employee Ledger Entry No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the entry number of the vendor ledger entry that the detailed vendor ledger entry line was created for.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the entry number of the detailed vendor ledger entry.';
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
                ApplicationArea = BasicHR;
                Caption = '&Unapply';
                Image = UnApply;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Unselect one or more ledger entries that you want to unapply this record.';

                trigger OnAction()
                var
                    EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
                begin
                    if IsEmpty() then
                        Error(NothingToApplyErr);
                    if not Confirm(UnapplyEntriesQst, false) then
                        exit;

                    EmplEntryApplyPostedEntries.PostUnApplyEmployee(DtldEmplLedgEntry2, DocNo, PostingDate);
                    PostingDate := 0D;
                    DocNo := '';
                    DeleteAll();
                    Message(EntriesUnappliedMsg);

                    CurrPage.Close;
                end;
            }
            action(Preview)
            {
                ApplicationArea = BasicHR;
                Caption = 'Preview Unapply';
                Image = ViewPostedOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Preview how unapplying one or more ledger entries will look like.';

                trigger OnAction()
                var
                    EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
                begin
                    if IsEmpty() then
                        Error(NothingToApplyErr);

                    EmplEntryApplyPostedEntries.PreviewUnapply(DtldEmplLedgEntry2, DocNo, PostingDate);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertEntries;
    end;

    var
        DtldEmplLedgEntry2: Record "Detailed Employee Ledger Entry";
        Employee: Record Employee;
        DocNo: Code[20];
        PostingDate: Date;
        EmplLedgEntryNo: Integer;
        EntriesUnappliedMsg: Label 'The entries were successfully unapplied.';
        NothingToApplyErr: Label 'There is nothing to unapply.';
        UnapplyEntriesQst: Label 'To unapply these entries, correcting entries will be posted.\Do you want to unapply the entries?';

    procedure SetDtldEmplLedgEntry(EntryNo: Integer)
    begin
        DtldEmplLedgEntry2.Get(EntryNo);
        EmplLedgEntryNo := DtldEmplLedgEntry2."Employee Ledger Entry No.";
        PostingDate := DtldEmplLedgEntry2."Posting Date";
        DocNo := DtldEmplLedgEntry2."Document No.";
        Employee.Get(DtldEmplLedgEntry2."Employee No.");
    end;

    local procedure InsertEntries()
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        if DtldEmplLedgEntry2."Transaction No." = 0 then begin
            DtldEmplLedgEntry.SetCurrentKey("Application No.", "Employee No.", "Entry Type");
            DtldEmplLedgEntry.SetRange("Application No.", DtldEmplLedgEntry2."Application No.");
        end else begin
            DtldEmplLedgEntry.SetCurrentKey("Transaction No.", "Employee No.", "Entry Type");
            DtldEmplLedgEntry.SetRange("Transaction No.", DtldEmplLedgEntry2."Transaction No.");
        end;
        DtldEmplLedgEntry.SetRange("Employee No.", DtldEmplLedgEntry2."Employee No.");
        DeleteAll();
        if DtldEmplLedgEntry.Find('-') then
            repeat
                if (DtldEmplLedgEntry."Entry Type" <> DtldEmplLedgEntry."Entry Type"::"Initial Entry") and
                   not DtldEmplLedgEntry.Unapplied
                then begin
                    Rec := DtldEmplLedgEntry;
                    Insert;
                end;
            until DtldEmplLedgEntry.Next() = 0;
    end;

    local procedure GetDocumentNo(): Code[20]
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        if EmployeeLedgerEntry.Get("Employee Ledger Entry No.") then;
        exit(EmployeeLedgerEntry."Document No.");
    end;

    procedure Caption(): Text
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        exit(StrSubstNo(
            '%1 %2 %3 %4',
            Employee."No.",
            Employee.FullName,
            EmployeeLedgerEntry.FieldCaption("Entry No."),
            EmplLedgEntryNo));
    end;
}

