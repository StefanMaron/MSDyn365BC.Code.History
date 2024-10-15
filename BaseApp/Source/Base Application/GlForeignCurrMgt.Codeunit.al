codeunit 3010536 GlForeignCurrMgt
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Currency codes are only allowed for assets and liabilities and linetype account.';
        Text001: Label 'In order to change the currency code, the balance of the account must be zero.';
        Text002: Label 'This function only regulated customer, vendor and bank accounts and additional currency. If you use foreign currencies in G/L, you have to run the report "Adjust Exchange Rates G/L".';
        Text004: Label 'The currency code %1 on G/L journal line does not match with the currency code %2  of G/L account %3.';
        Text005: Label 'The currency code %1 on G/L journal line does not match with the currency code %2 of the customer a/r account %4 for customer %3.';
        Text006: Label 'The currency code %1 on G/L journal line does not match with the currency code %2 of the vendor a/p account %4 for vendor %3.';
        Text007: Label 'The currency code %1 on G/L journal line does not match with the currency code %2 of the G/L bank account %4 for bank %3.';
        GLSetup: Record "General Ledger Setup";
        GlAcc: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Bank: Record "Bank Account";
        CustPostGrp: Record "Customer Posting Group";
        VendPostGrp: Record "Vendor Posting Group";
        BankPostGrp: Record "Bank Account Posting Group";
        ACYOnlyPosting: Boolean;
        Text008: Label 'This feature is designed for bank accounts in foreign currency and should only be used for this purpose.';

    [Scope('OnPrem')]
    procedure NewCurrCode(GlAcc: Record "G/L Account"; xGlAcc: Record "G/L Account")
    begin
        // CHeck line type and entries if currency code is change in chart of account
        // Call from GlAcc.Currency Code

        if (GlAcc."Currency Code" <> '') and (xGlAcc."Currency Code" = '') then
            Message(Text008);

        with GlAcc do begin
            if ("Currency Code" <> '') and (("Account Type" <> "Account Type"::Posting) or
                                            ("Income/Balance" <> "Income/Balance"::"Balance Sheet"))
            then
                Error(Text000);

            if "Currency Code" <> xGlAcc."Currency Code" then begin
                CalcFields(Balance, "Balance (FCY)");
                if (Balance <> 0) or ("Balance (FCY)" <> 0) then
                    Error(Text001);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCurrCode(AccNo: Code[20]; var GlLine: Record "Gen. Journal Line")
    begin
        // Transfer Currency Code from GL Account to GlLine.Account or Bal. Account

        GLSetup.Get;
        GlAcc.Get(AccNo);
        if (GlLine."Currency Code" = '') or (GlLine."Currency Code" = GLSetup."LCY Code") then
            GlLine."Currency Code" := GlAcc."Currency Code";
    end;

    [Scope('OnPrem')]
    procedure CheckCurrCode(GlLine: Record "Gen. Journal Line")
    begin
        // CHeck if Acc and Bal. Acc have same Curr Code as in Gl Line

        GLSetup.Get;

        ACYOnlyPosting :=
          (GLSetup."Additional Reporting Currency" <> '') and
          (GlLine."Additional-Currency Posting" =
           GlLine."Additional-Currency Posting"::"Additional-Currency Amount Only") and
          (GlLine."Currency Code" = GLSetup."Additional Reporting Currency");

        if (GlLine."Currency Code" <> '') and (GlLine."Currency Code" <> GLSetup."LCY Code") then begin
            CheckCurrOnAccount(GlLine."Account No.", GlLine."Account Type", GlLine."Currency Code", ACYOnlyPosting);
            CheckCurrOnAccount(GlLine."Bal. Account No.", GlLine."Bal. Account Type", GlLine."Currency Code", ACYOnlyPosting);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckCurrOnAccount(AccNo: Code[20]; AccType: Option "GL Account",Customer,Vendor,Bank; CurrCode: Code[10]; ACYOnly: Boolean)
    begin
        // CHeck if Acc or Bal Acc (GL, Cust, Venor, Bank Summary) matches
        // Call from Function CheckCurrCode in this Codeunit.

        GLSetup.Get;
        if (AccNo = '') or ACYOnly then
            exit;

        case AccType of
            AccType::"GL Account":  // G/L Account
                begin
                    GlAcc.Get(AccNo);
                    if (CurrCode <> GlAcc."Currency Code") and
                       (GlAcc."Currency Code" <> '') and
                       (GlAcc."Currency Code" <> GLSetup."LCY Code")
                    then
                        Error(Text004, CurrCode, GlAcc."Currency Code", AccNo);
                end;
            AccType::Customer:  // Cust. G/L Account
                begin
                    Customer.Get(AccNo);
                    CustPostGrp.Get(Customer."Customer Posting Group");
                    GlAcc.Get(CustPostGrp."Receivables Account");
                    if (CurrCode <> GlAcc."Currency Code") and
                       (GlAcc."Currency Code" <> '') and
                       (GlAcc."Currency Code" <> GLSetup."LCY Code")
                    then
                        Error(Text005, CurrCode, GlAcc."Currency Code", AccNo, GlAcc."No.");
                end;
            AccType::Vendor:  // Vendor G/L Account
                begin
                    Vendor.Get(AccNo);
                    VendPostGrp.Get(Vendor."Vendor Posting Group");
                    GlAcc.Get(VendPostGrp."Payables Account");
                    if (CurrCode <> GlAcc."Currency Code") and
                       (GlAcc."Currency Code" <> '') and
                       (GlAcc."Currency Code" <> GLSetup."LCY Code")
                    then
                        Error(Text006, CurrCode, GlAcc."Currency Code", AccNo, GlAcc."No.");
                end;
            AccType::Bank:  // Bank G/L Account
                begin
                    Bank.Get(AccNo);
                    BankPostGrp.Get(Bank."Bank Acc. Posting Group");
                    GlAcc.Get(BankPostGrp."G/L Account No.");
                    if (CurrCode <> GlAcc."Currency Code") and
                       (GlAcc."Currency Code" <> '') and
                       (GlAcc."Currency Code" <> GLSetup."LCY Code")
                    then
                        Error(Text007, CurrCode, GlAcc."Currency Code", AccNo, GlAcc."No.");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowGlRegMessage()
    begin
        // G/L Acc with Currency Code found
        GlAcc.SetFilter("Currency Code", '<>%1', '');
        if not GlAcc.IsEmpty then
            Message(Text002);
    end;
}

