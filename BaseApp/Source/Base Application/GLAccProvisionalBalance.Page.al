page 11500 "G/L Acc. Provisional Balance"
{
    Caption = 'G/L Account temp. Balance';
    DataCaptionExpression = '';
    Editable = false;
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Text003; Text003)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Control1150005; Text003)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                fixed(Control1900886701)
                {
                    ShowCaption = false;
                    group(Account)
                    {
                        Caption = 'Account';
                        field(AccNumber; AccNumber)
                        {
                            ApplicationArea = All;
                            Caption = 'No.';
                            ToolTip = 'Specifies the number.';
                        }
                        field(AccName; AccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Description';
                            ToolTip = 'Specifies a description.';
                        }
                        field("GLSetup.""LCY Code"""; GLSetup."LCY Code")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Currency';
                            ToolTip = 'Specifies the currency. ';
                        }
                        field(AccBalance; AccBalance)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                            Caption = 'Balance';
                            DrillDown = false;
                            ToolTip = 'Specifies the balance. ';
                        }
                        field(AccNotPosted; AccNotPosted)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                            Caption = 'Not Posted (w/o VAT)';
                        }
                        field("AccBalance + AccNotPosted"; AccBalance + AccNotPosted)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                            Caption = 'Total';
                            ToolTip = 'Specifies the total.';
                        }
                    }
                    group(Control1901339601)
                    {
                        ShowCaption = false;
                        field(Control1150004; Text003)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Control1150015; Text003)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(AccCurrency; AccCurrency)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(AccBalanceFC; AccBalanceFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                            DrillDown = false;
                        }
                        field(AccNotPostedFC; AccNotPostedFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field("AccBalanceFC + AccNotPostedFC"; AccBalanceFC + AccNotPostedFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                    }
                    group("Counter Acc.")
                    {
                        Caption = 'Counter Acc.';
                        field(BalAccNo; BalAccNo)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(BalAccName; BalAccName)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(Control1150013; GLSetup."LCY Code")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(BalAccBalance; BalAccBalance)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field(BalAccNotPosted; BalAccNotPosted)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field("BalAccBalance + BalAccNotPosted"; BalAccBalance + BalAccNotPosted)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                    }
                    group(Control1901850901)
                    {
                        ShowCaption = false;
                        field(Control1150014; Text003)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Control1150016; Text003)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(BalAccCurrency; BalAccCurrency)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field(BalAccBalanceFC; BalAccBalanceFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field(BalAccNotPostedFC; BalAccNotPostedFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                        field("BalAccBalanceFC + BalAccNotPostedFC"; BalAccBalanceFC + BalAccNotPostedFC)
                        {
                            ApplicationArea = Basic, Suite;
                            BlankZero = true;
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Balance")
            {
                Caption = '&Balance';
                action("&All Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&All Journals';
                    Image = Journals;
                    ShortCutKey = 'F7';
                    ToolTip = 'Calculate and display the balance of the final posted entries and the balance of the postings entered in the current journal. The unposted balance for all general ledger registers is calculated. It also includes values from ledgers that have another journal name not shown at the time.';

                    trigger OnAction()
                    begin
                        AllJournals := AllJournals xor true;
                        if AllJournals then
                            CurrPage.Caption := Text000
                        else
                            CurrPage.Caption := Text001;
                        CalcBalance;
                    end;
                }
                action("A&ctual Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'A&ctual Journal';
                    Image = Journals;
                    ToolTip = 'Calculate and display the balance of the final posted entries and the balance of the postings entered in the current journal. Only values from ledgers that have another journal name are shown.';

                    trigger OnAction()
                    begin
                        AllJournals := false;
                        CurrPage.Caption := Text002 + ' ' + "Journal Batch Name";
                        CalcBalance;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcBalance;
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get;
        if not GLLines2.Get("Journal Template Name", "Journal Batch Name", "Line No.") then
            Error('');
    end;

    var
        Text000: Label 'GL Account temp. Balance all Journals';
        Text001: Label 'GL Account temp. Balance actuals Journal';
        Text002: Label 'Balance Journal';
        GlLines: Record "Gen. Journal Line";
        GLLines2: Record "Gen. Journal Line";
        GlAcc: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Bank: Record "Bank Account";
        GLSetup: Record "General Ledger Setup";
        AccNumber: Code[20];
        AccName: Text[100];
        AccBalance: Decimal;
        AccBalanceFC: Decimal;
        AccNotPosted: Decimal;
        AccNotPostedFC: Decimal;
        AccCurrency: Code[10];
        BalAccNo: Code[20];
        BalAccName: Text[100];
        BalAccBalance: Decimal;
        BalAccBalanceFC: Decimal;
        BalAccNotPosted: Decimal;
        BalAccNotPostedFC: Decimal;
        BalAccCurrency: Code[10];
        JournalAmtLCY: Decimal;
        JournalAmtFCY: Decimal;
        AllJournals: Boolean;
        Text003: Label 'Placeholder';

    [Scope('OnPrem')]
    procedure CalcBalance()
    begin
        case "Account Type" of
            "Account Type"::"G/L Account":
                if GlAcc.Get("Account No.") then begin
                    GlAcc.CalcFields(Balance, "Balance (FCY)");
                    AddNotPosted("Account No.", GlAcc."Currency Code", "Account Type");
                    AccNumber := GlAcc."No.";
                    AccName := GlAcc.Name;
                    AccBalance := GlAcc.Balance;
                    AccCurrency := GlAcc."Currency Code";
                    AccBalanceFC := GlAcc."Balance (FCY)";
                end;
            "Account Type"::"Bank Account":
                if Bank.Get("Account No.") then begin
                    Bank.CalcFields(Balance, "Balance (LCY)");
                    AddNotPosted("Account No.", Bank."Currency Code", "Account Type");
                    AccNumber := Bank."No.";
                    AccName := CopyStr(Bank.Name, 1, MaxStrLen(AccName));
                    AccBalance := Bank.Balance;
                    AccBalance := Bank."Balance (LCY)";
                    AccCurrency := Bank."Currency Code";
                    AccBalanceFC := Bank.Balance;
                end;
            "Account Type"::Customer:
                if Customer.Get("Account No.") then begin
                    Customer.CalcFields("Balance (LCY)");
                    AddNotPosted("Account No.", '', "Account Type");
                    AccNumber := Customer."No.";
                    AccName := CopyStr(Customer.Name, 1, MaxStrLen(AccName));
                    AccBalance := Customer."Balance (LCY)";
                end;
            "Account Type"::Vendor:
                if Vendor.Get("Account No.") then begin
                    Vendor.CalcFields("Balance (LCY)");
                    AddNotPosted("Account No.", '', "Account Type");
                    AccNumber := Vendor."No.";
                    AccName := CopyStr(Vendor.Name, 1, MaxStrLen(AccName));
                    AccBalance := -Vendor."Balance (LCY)";
                end;
        end;

        if AccNumber = '' then
            AddNotPosted('', '', "Account Type");

        AccNotPosted := JournalAmtLCY;
        AccNotPostedFC := JournalAmtFCY;

        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                if GlAcc.Get("Bal. Account No.") then begin
                    GlAcc.CalcFields(Balance, "Balance (FCY)");
                    AddNotPosted("Bal. Account No.", GlAcc."Currency Code", "Bal. Account Type");
                    BalAccNo := GlAcc."No.";
                    BalAccName := GlAcc.Name;
                    BalAccBalance := GlAcc.Balance;
                    BalAccCurrency := GlAcc."Currency Code";
                    BalAccBalanceFC := GlAcc."Balance (FCY)";
                end;
            "Bal. Account Type"::"Bank Account":
                if Bank.Get("Bal. Account No.") then begin
                    Bank.CalcFields(Balance, "Balance (LCY)");
                    AddNotPosted("Bal. Account No.", Bank."Currency Code", "Bal. Account Type");
                    BalAccNo := Bank."No.";
                    BalAccName := CopyStr(Bank.Name, 1, MaxStrLen(AccName));
                    BalAccBalance := Bank."Balance (LCY)";
                    BalAccCurrency := Bank."Currency Code";
                    BalAccBalanceFC := Bank.Balance;
                end;
            "Bal. Account Type"::Customer:
                if Customer.Get("Bal. Account No.") then begin
                    Customer.CalcFields("Balance (LCY)");
                    AddNotPosted("Bal. Account No.", '', "Bal. Account Type");
                    BalAccNo := Customer."No.";
                    BalAccName := CopyStr(Customer.Name, 1, MaxStrLen(AccName));
                    BalAccBalance := Customer."Balance (LCY)";
                end;
            "Bal. Account Type"::Vendor:
                if Vendor.Get("Bal. Account No.") then begin
                    Vendor.CalcFields("Balance (LCY)");
                    AddNotPosted("Bal. Account No.", '', "Bal. Account Type");
                    BalAccNo := Vendor."No.";
                    BalAccName := CopyStr(Vendor.Name, 1, MaxStrLen(AccName));
                    BalAccBalance := -Vendor."Balance (LCY)";
                end;
        end;

        if BalAccNo = '' then
            AddNotPosted('', '', "Bal. Account Type");

        BalAccNotPosted := JournalAmtLCY;
        BalAccNotPostedFC := JournalAmtFCY;
    end;

    [Scope('OnPrem')]
    procedure AddNotPosted(_No: Code[20]; _Currency: Code[10]; _AccType: Integer)
    begin
        JournalAmtLCY := 0;
        JournalAmtFCY := 0;

        if _No = '' then
            exit;

        GlLines.Reset;
        if not AllJournals then begin
            GlLines.SetRange("Journal Template Name", "Journal Template Name");
            GlLines.SetRange("Journal Batch Name", "Journal Batch Name");
            GlLines.SetRange("Line No.", 0, "Line No.");
        end;

        GlLines.SetRange("Account Type", _AccType);
        GlLines.SetRange("Account No.", _No);
        if GlLines.Find('-') then
            repeat
                JournalAmtLCY := JournalAmtLCY + GlLines."Amount (LCY)" - GlLines."VAT Amount (LCY)";

                if (_Currency <> '') and (GlLines."Currency Code" = _Currency) then
                    JournalAmtFCY := JournalAmtFCY + GlLines.Amount - GlLines."VAT Amount";

            until GlLines.Next = 0;
        GlLines.SetRange("Account Type");
        GlLines.SetRange("Account No.");

        GlLines.SetRange("Bal. Account Type", _AccType);
        GlLines.SetRange("Bal. Account No.", _No);
        if GlLines.Find('-') then
            repeat
                JournalAmtLCY := JournalAmtLCY - GlLines."Amount (LCY)" - GlLines."Bal. VAT Amount (LCY)";

                if (_Currency <> '') and (GlLines."Currency Code" = _Currency) then
                    JournalAmtFCY := JournalAmtFCY - GlLines.Amount - GlLines."Bal. VAT Amount";

            until GlLines.Next = 0;
    end;
}

