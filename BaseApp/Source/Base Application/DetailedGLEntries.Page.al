#if not CLEAN19
page 11778 "Detailed G/L Entries"
{
    Caption = 'Detailed G/L Entries (Obsolete)';
    DataCaptionFields = "G/L Entry No.", "G/L Account No.";
    Editable = false;
    PageType = List;
    SourceTable = "Detailed G/L Entry";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220011)
            {
                ShowCaption = false;
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of G/L entry.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s Document No.';
                }
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Transaction No. assigned to all the entries involved in the same transaction.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of G/L entries.';
                }
                field("Applied G/L Entry No."; Rec."Applied G/L Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of applied G/L entry.';
                }
                field(Unapplied; Unapplied)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the line was unapplied';
                }
                field("Unapplied by Entry No."; Rec."Unapplied by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the apply was canceled by entries No.';
                }
                field("User ID"; Rec."User ID")
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
                field("Entry No."; Rec."Entry No.")
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
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    var
        Navigate: Page Navigate;
}
#endif
