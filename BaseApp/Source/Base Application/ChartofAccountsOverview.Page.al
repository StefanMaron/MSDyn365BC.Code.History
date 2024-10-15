page 634 "Chart of Accounts Overview"
{
    Caption = 'Chart of Accounts Overview';
    ApplicationArea = Basic, Suite;
    PageType = List;
    UsageCategory = Lists;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
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
                field("Net Change"; "Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    BlankZero = true;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                }
                field(Balance; Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    BlankZero = true;
                    ToolTip = 'Specifies the balance on this account.';
                }
                field("Account Category"; "Account Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category of the G/L account.';
                    Visible = false;
                }
                field("Income/Balance"; "Income/Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
                }
                field("Account Subcategory Descript."; "Account Subcategory Descript.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Caption = 'Account Subcategory';
                    DrillDown = false;
                    ToolTip = 'Specifies the subcategory of the account category of the G/L account.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';
                }
                field("Direct Posting"; "Direct Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether you will be able to post directly or only indirectly to this general ledger account.';
                    Visible = false;
                }
                field(Totaling; Totaling)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLaccList: Page "G/L Account List";
                    begin
                        GLaccList.LookupMode(true);
                        if not (GLaccList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := GLaccList.GetSelectionFilter();
                        exit(true);
                    end;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type to use when posting to this account.';
                    Editable = false;
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Editable = false;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Editable = false;
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Editable = false;
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Editable = false;
                    Visible = false;
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Editable = false;
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Editable = false;
                    Visible = false;
                }
                field("Balance at Date"; "Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the G/L account balance on the last date included in the Date Filter field.';
                    Editable = false;
                    Visible = false;
                }
                field("Additional-Currency Net Change"; "Additional-Currency Net Change")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net change in the account balance.';
                    Editable = false;
                    Visible = false;
                }
                field("Add.-Currency Balance at Date"; "Add.-Currency Balance at Date")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the G/L account balance, in the additional reporting currency, on the last date included in the Date Filter field.';
                    Editable = false;
                    Visible = false;
                }
                field("Additional-Currency Balance"; "Additional-Currency Balance")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the balance on this account, in the additional reporting currency.';
                    Editable = false;
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
                field("Consol. Debit Acc."; "Consol. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number in a consolidated company to transfer credit balances.';
                    Editable = false;
                    Visible = false;
                }
                field("Consol. Credit Acc."; "Consol. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if amounts without any payment tolerance amount from the customer and vendor ledger entries are used.';
                    Editable = false;
                    Visible = false;
                }
                field("Cost Type No."; "Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a cost type number to establish which cost type a general ledger account belongs to.';
                    Editable = false;
                    Visible = false;
                }
                field("Consol. Translation Method"; "Consol. Translation Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the consolidation translation method that will be used for the account.';
                    Editable = false;
                    Visible = false;
                }
                field("Default IC Partner G/L Acc. No"; "Default IC Partner G/L Acc. No")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies accounts that you often enter in the Bal. Account No. field on intercompany journal or document lines.';
                    Editable = false;
                    Visible = false;
                }
                field("Default Deferral Template Code"; "Default Deferral Template Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Deferral Template';
                    ToolTip = 'Specifies the default deferral template that governs how to defer revenues and expenses to the periods when they occurred.';
                    Editable = false;
                    Visible = false;
                }
                field("No. 2"; "No. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternative account number which can be used internally in the company.';
                    Editable = false;
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
        GLAcc.SetFilter("Account Type", '<>%1', 4);
        if GLAcc.Find('-') then
            repeat
                Rec := GLAcc;
                if GLAcc."Account Type" = 3 then
                    Totaling := GetEndTotal(GLAcc);
                Insert;
            until GLAcc.Next() = 0;

        if FindFirst() then;
    end;

    local procedure GetEndTotal(var GLAcc: Record "G/L Account"): Text[250]
    var
        GLAcc2: Record "G/L Account";
    begin
        GLAcc2.SetFilter("No.", '>%1', GLAcc."No.");
        GLAcc2.SetRange(Indentation, GLAcc.Indentation);
        GLAcc2.SetRange("Account Type", 4);
        if GLAcc2.FindFirst() then
            exit(GLAcc2.Totaling);

        exit('');
    end;

    local procedure FormatLine()
    begin
        NameIndent := Indentation;
        Emphasize := "Account Type" <> "Account Type"::Posting;
    end;
}
