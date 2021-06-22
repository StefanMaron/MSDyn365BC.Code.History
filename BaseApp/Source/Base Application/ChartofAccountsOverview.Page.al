page 634 "Chart of Accounts Overview"
{
    Caption = 'Chart of Accounts Overview';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "G/L Account";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowAsTree = true;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the general ledger account.';
                }
                field("Income/Balance"; "Income/Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';
                }
                field("Net Change"; "Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                }
                field("Balance at Date"; "Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the G/L account balance on the last date included in the Date Filter field.';
                    Visible = false;
                }
                field(Balance; Balance)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the balance on this account.';
                }
                field("Additional-Currency Net Change"; "Additional-Currency Net Change")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net change in the account balance.';
                    Visible = false;
                }
                field("Add.-Currency Balance at Date"; "Add.-Currency Balance at Date")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the G/L account balance, in the additional reporting currency, on the last date included in the Date Filter field.';
                    Visible = false;
                }
                field("Additional-Currency Balance"; "Additional-Currency Balance")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the balance on this account, in the additional reporting currency.';
                    Visible = false;
                }
                field("Budgeted Amount"; "Budgeted Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies either the G/L account''s total budget or, if you have specified a name in the Budget Name field, a specific budget.';
                    Visible = false;
                }
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

    trigger OnOpenPage()
    begin
        ExpandAll
    end;

    var
        [InDataSet]
        Emphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;

    local procedure ExpandAll()
    begin
        CopyGLAccToTemp(false);
    end;

    local procedure CopyGLAccToTemp(OnlyRoot: Boolean)
    var
        GLAcc: Record "G/L Account";
    begin
        Reset;
        DeleteAll();
        SetCurrentKey("No.");

        if OnlyRoot then
            GLAcc.SetRange(Indentation, 0);
        GLAcc.SetFilter("Account Type", '<>%1', GLAcc."Account Type"::"End-Total");
        if GLAcc.Find('-') then
            repeat
                Rec := GLAcc;
                if GLAcc."Account Type" = GLAcc."Account Type"::"Begin-Total" then
                    Totaling := GetEndTotal(GLAcc);
                Insert;
            until GLAcc.Next = 0;

        if FindFirst then;
    end;

    local procedure GetEndTotal(var GLAcc: Record "G/L Account"): Text[250]
    var
        GLAcc2: Record "G/L Account";
    begin
        GLAcc2.SetFilter("No.", '>%1', GLAcc."No.");
        GLAcc2.SetRange(Indentation, GLAcc.Indentation);
        GLAcc2.SetRange("Account Type", GLAcc2."Account Type"::"End-Total");
        if GLAcc2.FindFirst then
            exit(GLAcc2.Totaling);

        exit('');
    end;

    local procedure FormatLine()
    begin
        NameIndent := Indentation;
        Emphasize := "Account Type" <> "Account Type"::Posting;
    end;
}

