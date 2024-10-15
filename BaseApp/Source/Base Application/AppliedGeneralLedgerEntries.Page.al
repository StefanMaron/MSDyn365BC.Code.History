#if not CLEAN19
page 11777 "Applied General Ledger Entries"
{
    Caption = 'Applied General Ledger Entries (Obsolete)';
    DataCaptionExpression = Caption;
    Editable = false;
    PageType = List;
    SourceTable = "G/L Entry";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220000)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the posting of the apply general ledger entries was posted.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original document type which will be applied.';
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
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Amount of the entry.';
                }
                field("Applied Amount"; "Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the amounts in the Amount to Apply field.';
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
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Reset;
        if "Entry No." <> 0 then begin
            GLEntry := Rec;
            FindApplnEntriesDtldtLedgEntry;
            GLAccount.Get("G/L Account No.");
        end;
        MarkedOnly(true);
    end;

    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        Navigate: Page Navigate;

    [Scope('OnPrem')]
    procedure FindApplnEntriesDtldtLedgEntry()
    var
        DtldGLEntry1: Record "Detailed G/L Entry";
        DtldGLEntry2: Record "Detailed G/L Entry";
    begin
        DtldGLEntry1.SetCurrentKey("G/L Entry No.", "Posting Date");
        DtldGLEntry1.SetRange("G/L Entry No.", GLEntry."Entry No.");
        DtldGLEntry1.SetRange(Unapplied, false);
        if DtldGLEntry1.Find('-') then
            repeat
                if DtldGLEntry1."G/L Entry No." = DtldGLEntry1."Applied G/L Entry No." then begin
                    DtldGLEntry2.SetRange("Applied G/L Entry No.", DtldGLEntry1."Applied G/L Entry No.");
                    DtldGLEntry2.SetRange(Unapplied, false);
                    if DtldGLEntry2.FindSet then
                        repeat
                            if DtldGLEntry2."G/L Entry No." <>
                               DtldGLEntry2."Applied G/L Entry No."
                            then
                                if Get(DtldGLEntry2."G/L Entry No.") then
                                    Mark(true);
                        until DtldGLEntry2.Next() = 0;
                end else
                    if Get(DtldGLEntry1."Applied G/L Entry No.") then
                        Mark(true);
            until DtldGLEntry1.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Caption(): Text
    begin
        exit(StrSubstNo(
            '%1 %2',
            GLAccount."No.",
            GLAccount.Name));
    end;
}
#endif
