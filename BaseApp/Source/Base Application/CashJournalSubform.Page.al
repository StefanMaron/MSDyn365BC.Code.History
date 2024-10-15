page 11404 "Cash Journal Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "CBG Statement Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Date"; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the statement line was created.';

                    trigger OnValidate()
                    begin
                        if "Document No." = '' then
                            GenerateDocumentNo;
                    end;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the CBG statement line of type Cash.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the statement line will be posted to.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account that the entry on the statement line will be posted to.';

                    trigger OnValidate()
                    begin
                        ShowShortcutDimCode(ShortcutDimCode);
                        AccountNoOnAfterValidate();
                    end;
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that will be applied to, if the journal line will be applied to an already-posted sales or purchase document.';
                    Visible = false;
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that will be applied to, if the journal line will be applied to an already-posted sales or purchase document.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which salesperson/purchaser is assigned to the statement line.';
                    Visible = false;
                }
                field("VAT Type"; "VAT Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT type that will be used when you post the entry on this statement line.';
                    Visible = false;
                }
                field("Amount incl. VAT"; "Amount incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the amount in the Amount field includes VAT.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group code that will be used when you post the entry on the statement line.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s VAT specification to link transactions made for this customer with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage that will be used on the statement line.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code that the CBG statement line is linked to.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code that the CBG statement line is linked to.';
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field(Correction; Correction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this is a corrective entry.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount (including VAT), that the statement line consists of.';
                    Visible = false;
                }
                field(Debit; Debit)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the total amount (excluding VAT) that the statement line consists of, if it is a debit amount.';
                }
                field(Credit; Credit)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the total amount (excluding VAT) that the statement line consists of, if it is a credit amount.';
                }
                field("CBGStatement.""Opening Balance"" - TotalNetChange(Text1000000)"; CBGStatement."Opening Balance" - TotalNetChange(Text1000000))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    Caption = 'Current Balance';
                    Editable = false;
                    ToolTip = 'Specifies the updated balance for the account.';
                    Visible = false;
                }
                field("Current net change"; -TotalNetChange(Text1000000))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    Caption = 'Current Net Change';
                    Editable = false;
                    ToolTip = 'Specifies the updated net change for the account.';
                    Visible = false;
                }
                field("Debit VAT"; "Debit VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the debit VAT amount that the statement line consists of.';
                    Visible = false;
                }
                field("Credit VAT"; "Credit VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the credit VAT amount that the statement line consists of.';
                    Visible = false;
                }
                field("Debit Incl. VAT"; "Debit Incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the total debit amount (including VAT) that the statement line consists of.';
                    Visible = false;
                }
                field("Credit Incl. VAT"; "Credit Incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the total credit amount (including VAT) that the statement line consists of.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Apply Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select one or more ledger entries that you want to apply this entry to so that the related posted documents are closed as paid or refunded.';

                    trigger OnAction()
                    begin
                        StartApplieFunction
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the account on the line.';

                    trigger OnAction()
                    begin
                        OpenCard;
                    end;
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the bank ledger entries.';

                    trigger OnAction()
                    begin
                        OpenEntries;
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetHeader;
        ShowShortcutDimCode(ShortcutDimCode);
        AfterGetCurrentRecord;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
        GetHeader;
        if CBGStatement."No." <> 0 then
            InitRecord(xRec);
        AfterGetCurrentRecord;
    end;

    var
        Text1000000: Label 'CBI';
        CBGStatement: Record "CBG Statement";
        ShortcutDimCode: array[8] of Code[20];
        [InDataSet]
        VATStatusEnable: Boolean;
        [InDataSet]
        StatusVATAmountEnable: Boolean;

    [Scope('OnPrem')]
    procedure OpenCard()
    begin
        OpenAccountCard;
    end;

    [Scope('OnPrem')]
    procedure OpenEntries()
    begin
        OpenAccountEntries;
    end;

    [Scope('OnPrem')]
    procedure StartApplieFunction()
    var
        GenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        CreateGenJournalLine(GenJnlLine);
        if GenJnlLine."Applies-to ID" = '' then
            GenJnlLine."Applies-to ID" := "New Applies-to ID";
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJnlLine);
        ReadGenJournalLine(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ChangedHeader(Header: Record "CBG Statement")
    begin
        CBGStatement := Header;
    end;

    [Scope('OnPrem')]
    procedure GetHeader()
    var
        UseNumber: Integer;
        UseTemplate: Code[10];
    begin
        FilterGroup(4);
        UseTemplate := DelChr(GetFilter("Journal Template Name"), '<>', '''');
        Evaluate(UseNumber, '0' + GetFilter("No."));
        FilterGroup(0);

        if UseNumber <> 0 then
            if (CBGStatement."Journal Template Name" <> UseTemplate) or
               (CBGStatement."No." <> UseNumber)
            then
                CBGStatement.Get(UseTemplate, UseNumber);
    end;

    [Scope('OnPrem')]
    procedure GetCurrentRecord(var CBGStatementLine: Record "CBG Statement Line")
    begin
        CBGStatementLine := Rec;
    end;

    local procedure AccountNoOnAfterValidate()
    begin
        if "Document No." = '' then
            GenerateDocumentNo;
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        VATStatusEnable := "Account Type" = "Account Type"::"G/L Account";
        StatusVATAmountEnable := "Account Type" = "Account Type"::"G/L Account";
    end;
}

