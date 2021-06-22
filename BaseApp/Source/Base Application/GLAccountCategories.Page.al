page 790 "G/L Account Categories"
{
    AccessByPermission = TableData "G/L Account Category" = R;
    AdditionalSearchTerms = 'general ledger account categories';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Account Categories';
    InsertAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,General';
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "G/L Account Category";
    SourceTableView = SORTING("Presentation Order", "Sibling Sequence No.");
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Indentation;
                IndentationControls = Description;
                ShowAsTree = true;
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = "Has Children" OR (Indentation = 0);
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Account Category"; "Account Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category of the G/L account.';
                }
                field(GLAccTotaling; GLAccTotaling)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Accounts in Category';
                    TableRelation = "G/L Account";
                    ToolTip = 'Specifies which G/L accounts are included in the account category.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupTotaling;
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateTotaling(GLAccTotaling);
                    end;
                }
                field("Additional Report Definition"; "Additional Report Definition")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional attributes that are used to create the cash flow statement.';
                }
                field(GetBalance; GetBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = "Has Children" OR (Indentation = 0);
                    ToolTip = 'Specifies the balance of the G/L account.';
                }
            }
        }
        area(factboxes)
        {
            part("G/L Accounts in Category"; "G/L Accounts ListPart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Accounts in Category';
                Editable = false;
                SubPageLink = "Account Subcategory Entry No." = FIELD("Entry No.");
            }
            part("G/L Accounts without Category"; "G/L Accounts ListPart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Accounts without Category';
                SubPageView = WHERE("Account Subcategory Entry No." = CONST(0));
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(New)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New';
                Enabled = PageEditable;
                Image = NewChartOfAccounts;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Create a new G/L account category.';

                trigger OnAction()
                begin
                    SetRow(InsertRow);
                end;
            }
        }
        area(processing)
        {
            action(MoveUp)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Up';
                Enabled = PageEditable;
                Image = MoveUp;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Change the sorting of the account categories.';

                trigger OnAction()
                begin
                    MoveUp;
                end;
            }
            action(MoveDown)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Down';
                Enabled = PageEditable;
                Image = MoveDown;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Change the sorting of the account categories.';

                trigger OnAction()
                begin
                    MoveDown;
                end;
            }
            action(Indent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Indent';
                Enabled = PageEditable;
                Image = Indent;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Move the account category to the right.';

                trigger OnAction()
                begin
                    MakeChildOfPreviousSibling;
                end;
            }
            action(Outdent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Outdent';
                Enabled = PageEditable;
                Image = DecreaseIndent;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Move the account category to the left.';

                trigger OnAction()
                begin
                    MakeSiblingOfParent;
                end;
            }
            action(GenerateAccSched)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Generate Account Schedules';
                Enabled = PageEditable;
                Image = CreateLinesFromJob;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                RunObject = Codeunit "Categ. Generate Acc. Schedules";
                ToolTip = 'Generate account schedules.';
            }
        }
        area(navigation)
        {
            action(GLSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'General Ledger Setup';
                Image = GeneralLedger;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "General Ledger Setup";
                ToolTip = 'View or edit the way to handle certain accounting issues in your company.';
            }
            action(AccSchedules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Account Schedules';
                Image = Accounts;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Account Schedule Names";
                ToolTip = 'Open your account schedules to analyze figures in general ledger accounts or to compare general ledger entries with general ledger budget entries.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        PageEditable := CurrPage.Editable;
    end;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Has Children");
        GLAccTotaling := GetTotaling;
    end;

    trigger OnOpenPage()
    begin
        if IsEmpty then
            InitializeDataSet;
        SetAutoCalcFields("Has Children");

        PageEditable := CurrPage.Editable;
    end;

    var
        GLAccTotaling: Code[250];
        PageEditable: Boolean;

    local procedure SetRow(EntryNo: Integer)
    begin
        if EntryNo = 0 then
            exit;
        if Get(EntryNo) then;
        CurrPage.Update(false);
    end;
}

