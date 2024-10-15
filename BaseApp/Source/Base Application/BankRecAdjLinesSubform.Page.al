page 10123 "Bank Rec. Adj. Lines Subform"
{
    AutoSplitKey = true;
    Caption = 'Bank Rec. Adj. Lines Subform';
    PageType = ListPart;
    SourceTable = "Bank Rec. Line";
    SourceTableView = SORTING("Bank Account No.", "Statement No.", "Record Type", "Line No.")
                      WHERE("Record Type" = CONST(Adjustment));

    layout
    {
        area(content)
        {
            field("BankRecHdr.""Bank Account No."""; BankRecHdr."Bank Account No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account No.';
                Editable = false;
                ToolTip = 'Specifies the bank account that the bank statement line applies to.';
            }
            field("BankRecHdr.""Statement No."""; BankRecHdr."Statement No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement No.';
                Editable = false;
                ToolTip = 'Specifies the bank reconciliation statement number that this line applies to.';
            }
            field("BankRecHdr.""Statement Date"""; BankRecHdr."Statement Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement Date';
                Editable = false;
                ToolTip = 'Specifies the bank reconciliation statement date that this line applies to.';
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Statement Date for Check or Deposit type. For Adjustment type lines, the entry will be the actual date the posting.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that the entry on the journal line is.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the journal line.';
                }
                field("External Document No."; "External Document No.")
                {
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the journal line entry will be posted to.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number that the journal line entry will be posted to.';

                    trigger OnValidate()
                    begin
                        AccountNoOnAfterValidate();
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the transaction on the bank reconciliation line.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the item, such as a check, that was deposited.';

                    trigger OnValidate()
                    begin
                        AmountOnAfterValidate;
                    end;
                }
                field("Currency Code"; "Currency Code")
                {
                    ToolTip = 'Specifies the currency code for the amounts on the line, as it will be posted to the G/L.';
                    Visible = false;
                }
                field("Currency Factor"; "Currency Factor")
                {
                    ToolTip = 'Specifies a currency factor for the reconciliation sub-line entry. The value is calculated based on currency code, exchange rate, and the bank record header''s statement date.';
                    Visible = false;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the Balance Account Type that will be posted to the general ledger.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can select the number of the G/L, customer, vendor or bank account to which a balancing entry for the line will posted.';

                    trigger OnValidate()
                    begin
                        BalAccountNoOnAfterValidate();
                    end;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code the journal line is linked to.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code the journal line is linked to.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
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
                field("Adj. Source Record ID"; "Adj. Source Record ID")
                {
                    ToolTip = 'Specifies what type of Bank Rec. Line record was the source for the created Adjustment line. The valid types are Check or Deposit.';
                    Visible = false;
                }
                field("Adj. Source Document No."; "Adj. Source Document No.")
                {
                    ToolTip = 'Specifies the Document number from the Bank Rec. Line record that was the source for the created Adjustment line.';
                    Visible = false;
                }
            }
            field(AccName; AccName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Account Name';
                Editable = false;
                ToolTip = 'Specifies the name of the bank account.';
            }
            field(BalAccName; BalAccName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bal. Account Name';
                Editable = false;
                ToolTip = 'Specifies the name of the balancing account.';
            }
            field(TotalAdjustments; BankRecHdr."Total Adjustments" - BankRecHdr."Total Balanced Adjustments")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Total Adjustments';
                Editable = false;
                ToolTip = 'Specifies the total amount of the lines that are adjustments.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("&Adjustment Dimensions")
                {
                    ApplicationArea = Suite;
                    Caption = '&Adjustment Dimensions';
                    ToolTip = 'View this adjustment''s default dimensions.';

                    trigger OnAction()
                    begin
                        LookupLineDimensions;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OnActivateForm;
        ShowShortcutDimCode(ShortcutDimCode);
        AfterGetCurrentRecord;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(xRec, 0, BelowxRec);
        AfterGetCurrentRecord;
    end;

    var
        AccName: Text[100];
        BalAccName: Text[100];
        ShortcutDimCode: array[8] of Code[20];
        BankRecHdr: Record "Bank Rec. Header";
        LastBankRecLine: Record "Bank Rec. Line";

    procedure SetupTotals()
    begin
        if BankRecHdr.Get("Bank Account No.", "Statement No.") then
            BankRecHdr.CalcFields("Total Adjustments", "Total Balanced Adjustments");
    end;

    procedure LookupLineDimensions()
    begin
        ShowDimensions();
        CurrPage.SaveRecord;
    end;

    procedure GetTableID(): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        AllObj.FindFirst;
        exit(AllObj."Object ID");
    end;

    procedure GetAccounts(var BankRecLine: Record "Bank Rec. Line"; var AccName: Text[100]; var BalAccName: Text[100])
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
    begin
        if (BankRecLine."Account Type" <> LastBankRecLine."Account Type") or
           (BankRecLine."Account No." <> LastBankRecLine."Account No.")
        then begin
            AccName := '';
            if BankRecLine."Account No." <> '' then
                case BankRecLine."Account Type" of
                    BankRecLine."Account Type"::"G/L Account":
                        if GLAcc.Get(BankRecLine."Account No.") then
                            AccName := GLAcc.Name;
                    BankRecLine."Account Type"::Customer:
                        if Cust.Get(BankRecLine."Account No.") then
                            AccName := Cust.Name;
                    BankRecLine."Account Type"::Vendor:
                        if Vend.Get(BankRecLine."Account No.") then
                            AccName := Vend.Name;
                    BankRecLine."Account Type"::"Bank Account":
                        if BankAcc.Get(BankRecLine."Account No.") then
                            AccName := BankAcc.Name;
                    BankRecLine."Account Type"::"Fixed Asset":
                        if FA.Get(BankRecLine."Account No.") then
                            AccName := FA.Description;
                end;
        end;

        if (BankRecLine."Bal. Account Type" <> LastBankRecLine."Bal. Account Type") or
           (BankRecLine."Bal. Account No." <> LastBankRecLine."Bal. Account No.")
        then begin
            BalAccName := '';
            if BankRecLine."Bal. Account No." <> '' then
                case BankRecLine."Bal. Account Type" of
                    BankRecLine."Bal. Account Type"::"G/L Account":
                        if GLAcc.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := GLAcc.Name;
                    BankRecLine."Bal. Account Type"::Customer:
                        if Cust.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := Cust.Name;
                    BankRecLine."Bal. Account Type"::Vendor:
                        if Vend.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := Vend.Name;
                    BankRecLine."Bal. Account Type"::"Bank Account":
                        if BankAcc.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := BankAcc.Name;
                    BankRecLine."Bal. Account Type"::"Fixed Asset":
                        if FA.Get(BankRecLine."Bal. Account No.") then
                            BalAccName := FA.Description;
                end;
        end;

        LastBankRecLine := BankRecLine;
    end;

    local procedure AccountNoOnAfterValidate()
    begin
        GetAccounts(Rec, AccName, BalAccName);
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    local procedure AmountOnAfterValidate()
    begin
        CurrPage.Update(true);
        SetupTotals;
    end;

    local procedure BalAccountNoOnAfterValidate()
    begin
        GetAccounts(Rec, AccName, BalAccName);
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        GetAccounts(Rec, AccName, BalAccName);
    end;

    local procedure OnActivateForm()
    begin
        SetupTotals;
    end;
}

