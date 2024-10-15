page 17348 "Person Income Entries"
{
    AutoSplitKey = true;
    Caption = 'Person Income Entries';
    DelayedInsert = true;
    PageType = Card;
    PopulateAllFields = true;
    SourceTable = "Person Income Entry";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Person Income No."; "Person Income No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Person Income Line No."; "Person Income Line No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field(Interim; Interim)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Advance Payment"; "Advance Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if advance payments made by the employee are included.';
                }
                field("Tax Code"; "Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Base; Base)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax %"; "Tax %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field("Tax Deduction Code"; "Tax Deduction Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Deduction Amount"; "Tax Deduction Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field("Vendor Ledger Entry No."; "Vendor Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Employee Ledger Entry No."; "Employee Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Person No."; "Person No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := ModifyAllowed;
    end;

    var
        ModifyAllowed: Boolean;

    [Scope('OnPrem')]
    procedure Set(NewModifyAllowed: Boolean)
    begin
        ModifyAllowed := NewModifyAllowed;
    end;
}

