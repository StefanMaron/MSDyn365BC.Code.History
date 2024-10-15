page 32000001 "Ref. Payment - Import"
{
    Caption = 'Ref. Payment - Import';
    DataCaptionFields = "Reference No.";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Ref. Payment - Imported";
    SourceTableView = SORTING("No.")
                      ORDER(Ascending)
                      WHERE("Filing Code" = FILTER(<> ''));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an entry number for the reference payment.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment amount for the reference payment.';
                }
                field("Filing Code"; "Filing Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a filing code for the reference payment.';
                }
                field("Bank Account Code"; "Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank account code for the reference payment.';
                }
                field("Banks Posting Date"; "Banks Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date that is used by the bank.';
                }
                field("Banks Payment Date"; "Banks Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment date used by the bank.';
                }
                field("Reference No."; "Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference number that is calculated from a reference number sequence.';
                }
                field("Payers Name"; "Payers Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer name that is associated with the reference payment.';
                }
                field("Currency Code 2"; "Currency Code 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a currency code for the reference payment.';
                }
                field("Name Source"; "Name Source")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the general ledger source account.';
                }
                field("Correction Code"; "Correction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a correction code for the reference payment.';
                }
                field("Delivery Method"; "Delivery Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payment delivery method.';
                }
                field("Feedback Code"; "Feedback Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a feedback code for the reference payment.';
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
                    Navigate.Run();
                end;
            }
        }
    }

    var
        Navigate: Page Navigate;
}

