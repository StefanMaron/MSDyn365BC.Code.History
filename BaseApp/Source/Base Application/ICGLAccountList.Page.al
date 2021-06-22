page 607 "IC G/L Account List"
{
    Caption = 'Intercompany G/L Account List';
    CardPageID = "IC G/L Account Card";
    Editable = false;
    PageType = List;
    SourceTable = "IC G/L Account";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Intercompany;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Intercompany;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the IC general ledger account.';
                }
                field("Income/Balance"; "Income/Balance")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLine;
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    var
        [InDataSet]
        Emphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;

    local procedure FormatLine()
    begin
        NameIndent := Indentation;
        Emphasize := "Account Type" <> "Account Type"::Posting;
    end;
}

