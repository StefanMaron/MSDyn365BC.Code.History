#if not CLEAN19
page 11776 "Unapply General Ledger Entries"
{
    Caption = 'Unapply General Ledger Entries (Obsolete)';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Detailed G/L Entry";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
    ObsoleteTag = '19.0';

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
                    ToolTip = 'Specifies the document''s number.';
                }
                field(PostDate; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the entry''s Posting Date.';
                }
            }
            repeater(Control1220000)
            {
                Editable = false;
                ShowCaption = false;
                field("G/L Entry No."; "G/L Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of G/L entry.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the posting of the unapply general ledger entries will be recorded.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s Document No.';
                }
                field("G/L Account No."; "G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of G/L entries.';
                }
                field("Applied G/L Entry No."; "Applied G/L Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of applied G/L entry.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
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
                    GLEntryPostApplication: Codeunit "G/L Entry -Post Application";
                begin
                    if DtldGLEntry."Entry No." = 0 then
                        Error(NothingToUnapplyErr);
                    GLEntryPostApplication.PostUnApplyGLEntry(DtldGLEntry, DocNo, PostingDate);
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertEntries;
    end;

    var
        GLAccount: Record "G/L Account";
        DtldGLEntry: Record "Detailed G/L Entry";
        DocNo: Code[20];
        PostingDate: Date;
        NothingToUnapplyErr: Label 'There is nothing to unapply.';

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetDtldGLEntry(EntryNo: Integer)
    begin
        DtldGLEntry.Get(EntryNo);
        PostingDate := DtldGLEntry."Posting Date";
        DocNo := DtldGLEntry."Document No.";
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure InsertEntries()
    var
        DtldGLEntry2: Record "Detailed G/L Entry";
    begin
        DtldGLEntry2.SetCurrentKey("Entry No.");
        DtldGLEntry2.SetRange("Transaction No.", DtldGLEntry."Transaction No.");
        DtldGLEntry2.SetRange("G/L Account No.", DtldGLEntry."G/L Account No.");
        DeleteAll();
        if DtldGLEntry2.FindSet() then
            repeat
                Rec := DtldGLEntry2;
                Insert;
            until DtldGLEntry2.Next() = 0;
        GLAccount.Get(DtldGLEntry."G/L Account No.");
    end;

    [Obsolete('Moved to Advanced Localization Pack for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure Caption(): Text
    begin
        exit(StrSubstNo(
            '%1 %2 %3 %4',
            GLAccount."No.",
            GLAccount.Name,
            DtldGLEntry.FieldCaption("G/L Entry No."),
            DtldGLEntry."G/L Entry No."));
    end;
}
#endif
