table 11000003 "Detail Line"
{
    Caption = 'Detail Line';
    DrillDownPageID = "Detail Lines";
    LookupPageID = "Detail Lines";

    fields
    {
        field(1; "Account Type"; Option)
        {
            Caption = 'Account Type';
            Editable = false;
            OptionCaption = 'Customer,Vendor,Employee';
            OptionMembers = Customer,Vendor,Employee;
        }
        field(2; "Serial No. (Entry)"; Integer)
        {
            Caption = 'Serial No. (Entry)';
            Editable = true;
            NotBlank = true;
            TableRelation = IF ("Account Type" = CONST(Customer)) "Cust. Ledger Entry"."Entry No."
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Ledger Entry"."Entry No.";

            trigger OnLookup()
            begin
                SerialnoPostingLookup;
            end;

            trigger OnValidate()
            var
                TrMode: Record "Transaction Mode";
                CompanyInfo: Record "Company Information";
                Custm: Record Customer;
                Vend: Record Vendor;
                Empl: Record Employee;
            begin
                TrMode.Get("Account Type", "Transaction Mode");
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            GetCustomerEntries;
                            CustEntries.TestField(Open, true);
                            CustEntries.TestField("Customer No.", "Account No.");
                            "Currency Code (Entry)" := CustEntries."Currency Code";
                            Custm.Get(CustEntries."Customer No.");
                            if Custm."Our Account No." <> '' then
                                Description :=
                                  CopyStr(
                                    StrSubstNo(
                                      Text1000001,
                                      CustEntries."Document Type",
                                      CustEntries."Document No.",
                                      Custm."Our Account No."), 1, MaxStrLen(Description))
                            else begin
                                CompanyInfo.Get;
                                Description :=
                                  CopyStr(
                                    StrSubstNo(
                                      '%1 %2 %3',
                                      CustEntries."Document Type",
                                      CustEntries."Document No.",
                                      CompanyInfo.Name), 1, MaxStrLen(Description));
                            end;
                            if TrMode."Pmt. Disc. Possible" and
                               (CustEntries."Original Pmt. Disc. Possible" <> 0) and
                               (CustEntries."Pmt. Discount Date" >= Date)
                            then
                                Validate("Amount (Entry)", -(CustEntries."Remaining Amount" - CustEntries."Original Pmt. Disc. Possible") -
                                  CalculateTotalAmount("Currency Code (Entry)"))
                            else
                                Validate("Amount (Entry)", -CustEntries."Remaining Amount" - CalculateTotalAmount("Currency Code (Entry)"));
                        end;
                    "Account Type"::Vendor:
                        begin
                            GetVendorEntries;
                            VendEntries.TestField(Open, true);
                            VendEntries.TestField("Vendor No.", "Account No.");
                            "Currency Code (Entry)" := VendEntries."Currency Code";
                            Vend.Get(VendEntries."Vendor No.");
                            if Vend."Our Account No." <> '' then
                                Description :=
                                  CopyStr(
                                    StrSubstNo(
                                      Text1000002,
                                      VendEntries."Document Type",
                                      VendEntries."External Document No.",
                                      Vend."Our Account No."), 1, MaxStrLen(Description))
                            else begin
                                CompanyInfo.Get;
                                Description :=
                                  CopyStr(
                                    StrSubstNo(
                                      '%1 %2 %3',
                                      VendEntries."Document Type",
                                      VendEntries."External Document No.",
                                      CompanyInfo.Name), 1, MaxStrLen(Description));
                            end;
                            if TrMode."Pmt. Disc. Possible" and
                               (VendEntries."Original Pmt. Disc. Possible" <> 0) and
                               (VendEntries."Pmt. Discount Date" >= Date)
                            then
                                Validate("Amount (Entry)", -(VendEntries."Remaining Amount" - VendEntries."Original Pmt. Disc. Possible") -
                                  CalculateTotalAmount("Currency Code (Entry)"))
                            else
                                Validate("Amount (Entry)", -VendEntries."Remaining Amount" - CalculateTotalAmount("Currency Code (Entry)"));
                        end;
                    "Account Type"::Employee:
                        begin
                            GetEmployeeEntries;
                            EmployeeLedgerEntry.TestField(Open, true);
                            EmployeeLedgerEntry.TestField("Employee No.", "Account No.");
                            "Currency Code (Entry)" := EmployeeLedgerEntry."Currency Code";
                            Empl.Get(EmployeeLedgerEntry."Employee No.");
                            CompanyInfo.Get;
                            Description :=
                              CopyStr(
                                StrSubstNo(
                                  '%1 %2 %3',
                                  EmployeeLedgerEntry."Document Type",
                                  EmployeeLedgerEntry."Document No.",
                                  CompanyInfo.Name), 1, MaxStrLen(Description));
                            Validate("Amount (Entry)", -EmployeeLedgerEntry."Remaining Amount" - CalculateTotalAmount("Currency Code (Entry)"));
                        end;
                end;
            end;
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            Editable = false;
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor."No.";
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            Editable = false;
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Proposal,In process,Posted,Correction';
            OptionMembers = Proposal,"In process",Posted,Correction;
        }
        field(6; Bank; Code[20])
        {
            Caption = 'Bank';
            Editable = false;
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Account No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Account No."));
        }
        field(7; "Our Bank"; Code[20])
        {
            Caption = 'Our Bank';
            Editable = false;
            TableRelation = "Bank Account"."No.";
        }
        field(8; "Transaction Mode"; Code[20])
        {
            Caption = 'Transaction Mode';
            Editable = false;
            TableRelation = "Transaction Mode".Code WHERE("Account Type" = FIELD("Account Type"));
        }
        field(9; "Order"; Option)
        {
            Caption = 'Order';
            Editable = false;
            OptionCaption = 'Both,Debit,Credit';
            OptionMembers = Both,Debit,Credit;
        }
        field(10; Amount; Decimal)
        {
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if not AmountValidate then begin
                    AmountValidate := true;
                    Validate("Amount (Entry)", CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, "Currency Code", "Currency Code (Entry)", Amount));
                    AmountValidate := false;
                end;

                GetCurrency;
                Amount := Round(Amount, BankCur."Amount Rounding Precision");
            end;
        }
        field(11; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(12; "Connect Lines"; Integer)
        {
            Caption = 'Connect Lines';
            Editable = false;
            TableRelation = IF (Status = CONST(Proposal)) "Proposal Line"."Line No." WHERE("Our Bank No." = FIELD("Our Bank"))
            ELSE
            IF (Status = CONST("In process")) "Payment History Line"."Line No." WHERE("Our Bank" = FIELD("Our Bank"),
                                                                                                          "Run No." = FIELD("Connect Batches"));
        }
        field(13; "Connect Batches"; Code[20])
        {
            Caption = 'Connect Batches';
            Editable = false;
            TableRelation = IF (Status = CONST("In process")) "Payment History"."Run No.";
        }
        field(14; Description; Text[32])
        {
            Caption = 'Description';
            Editable = true;
        }
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency.Code;
        }
        field(16; "Amount (Entry)"; Decimal)
        {
            AutoFormatExpression = "Currency Code (Entry)";
            AutoFormatType = 1;
            Caption = 'Amount (Entry)';

            trigger OnValidate()
            var
                Difference: Decimal;
                "Remaining Amount": Decimal;
            begin
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            if GetCustomerEntries then
                                "Remaining Amount" := -CustEntries."Remaining Amount"
                            else
                                "Remaining Amount" := 0;
                        end;
                    "Account Type"::Vendor:
                        begin
                            if GetVendorEntries then
                                "Remaining Amount" := -VendEntries."Remaining Amount"
                            else
                                "Remaining Amount" := 0;
                        end;
                    "Account Type"::Employee:
                        begin
                            if GetEmployeeEntries then
                                "Remaining Amount" := -EmployeeLedgerEntry."Remaining Amount"
                            else
                                "Remaining Amount" := 0;
                        end;
                end;

                if (("Remaining Amount" < 0) and ("Amount (Entry)" > 0)) or
                   (("Remaining Amount" > 0) and ("Amount (Entry)" < 0))
                then
                    Error(Text1000003);

                Difference := "Remaining Amount" - (CalculateTotalAmount("Currency Code (Entry)") + "Amount (Entry)");
                if Abs(Difference) > Abs(CalculateVariation) then
                    if (("Remaining Amount" < 0) and (Difference > 0)) or
                       (("Remaining Amount" > 0) and (Difference < 0))
                    then
                        Message(Text1000004, DelChr(Format(Abs(Difference)) + ' ' + "Currency Code (Entry)", '<>', ' '));

                if not AmountValidate then begin
                    AmountValidate := true;
                    Validate(Amount, CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, "Currency Code (Entry)", "Currency Code", "Amount (Entry)"));
                    AmountValidate := false;
                end;

                GetCurrency;
                "Amount (Entry)" := Round("Amount (Entry)", EntryCurrency."Amount Rounding Precision");
            end;
        }
        field(17; "Currency Code (Entry)"; Code[10])
        {
            Caption = 'Currency Code (Entry)';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Transaction No.")
        {
            Clustered = true;
        }
        key(Key2; "Account Type", "Serial No. (Entry)", Status, Date, "Connect Batches", "Connect Lines", "Our Bank")
        {
            SumIndexFields = Amount, "Amount (Entry)";
        }
        key(Key3; "Account Type", "Account No.", Bank, "Transaction Mode", "Currency Code", Date)
        {
        }
        key(Key4; "Our Bank", Status, "Connect Batches", "Connect Lines", Date)
        {
            SumIndexFields = Amount, "Amount (Entry)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        Date := 0D;
        Amount := 0;
        if Count > 1 then
            UpdateConnection;
    end;

    trigger OnInsert()
    var
        "Detail line": Record "Detail Line";
    begin
        if "Detail line".FindLast then
            "Transaction No." := "Detail line"."Transaction No." + 1
        else
            "Transaction No." := 1;

        UpdateConnection;
    end;

    trigger OnModify()
    begin
        UpdateConnection;
    end;

    trigger OnRename()
    begin
        Error(Text1000000, TableCaption);
    end;

    var
        Text1000000: Label '%1 cannot be renamed';
        Text1000001: Label '%1 %2 vendor no. %3';
        Text1000002: Label '%1 %2 customer no. %3';
        Text1000003: Label 'The sign does not correspond with the outstanding entry.';
        Text1000004: Label 'The outstanding amount is exceeded by %1.';
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustEntries: Record "Cust. Ledger Entry";
        VendEntries: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        AmountValidate: Boolean;
        EntryCurrency: Record Currency;
        BankCur: Record Currency;

    [Scope('OnPrem')]
    procedure CalculateBalance(UseCurrency: Code[10]) Total: Decimal
    begin
        // always in currency of the entry (Entry currency)
        if "Serial No. (Entry)" <> 0 then
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        GetCustomerEntries;
                        Total := -CustEntries."Remaining Amount";
                    end;
                "Account Type"::Vendor:
                    begin
                        GetVendorEntries;
                        VendEntries.CalcFields("Remaining Amount");
                        Total := -VendEntries."Remaining Amount";
                    end;
                "Account Type"::Employee:
                    begin
                        GetEmployeeEntries;
                        EmployeeLedgerEntry.CalcFields("Remaining Amount");
                        Total := -EmployeeLedgerEntry."Remaining Amount";
                    end;
            end;
        if UseCurrency <> "Currency Code (Entry)" then
            Total := CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, "Currency Code (Entry)", UseCurrency, Total);
    end;

    [Scope('OnPrem')]
    procedure CalculateTotalAmount(UseCurrency: Code[10]) Total: Decimal
    var
        "Detail line": Record "Detail Line";
    begin
        "Detail line".SetCurrentKey("Account Type", "Serial No. (Entry)");
        "Detail line".SetRange("Account Type", "Account Type");
        "Detail line".SetRange("Serial No. (Entry)", "Serial No. (Entry)");
        "Detail line".SetFilter(Status, '%1|%2', Status::Proposal, Status::"In process");
        "Detail line".SetFilter("Transaction No.", '<>%1', "Transaction No.");
        "Detail line".CalcSums("Amount (Entry)");
        if UseCurrency <> "Currency Code (Entry)" then
            Total := CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, "Currency Code (Entry)", UseCurrency, "Amount (Entry)")
        else
            Total := "Detail line"."Amount (Entry)";
    end;

    [Scope('OnPrem')]
    procedure CalculatePartOfBalance() Percent: Decimal
    var
        Totamount: Decimal;
    begin
        Totamount := CalculateBalance("Currency Code (Entry)");
        if Abs("Amount (Entry)" - Totamount) < CalculateVariation then
            Percent := 1
        else
            if Totamount <> 0 then
                Percent := "Amount (Entry)" / Totamount
            else
                Percent := 0;
    end;

    [Scope('OnPrem')]
    procedure GetCustomerEntries() OK: Boolean
    begin
        if "Serial No. (Entry)" <> CustEntries."Entry No." then begin
            OK := CustEntries.Get("Serial No. (Entry)");
            CustEntries.CalcFields("Remaining Amount");
        end else
            OK := true;
    end;

    [Scope('OnPrem')]
    procedure GetVendorEntries() OK: Boolean
    begin
        if "Serial No. (Entry)" <> VendEntries."Entry No." then begin
            OK := VendEntries.Get("Serial No. (Entry)");
            VendEntries.CalcFields("Remaining Amount");
        end else
            OK := true;
    end;

    [Scope('OnPrem')]
    procedure GetEmployeeEntries() OK: Boolean
    begin
        if "Serial No. (Entry)" <> EmployeeLedgerEntry."Entry No." then begin
            OK := EmployeeLedgerEntry.Get("Serial No. (Entry)");
            EmployeeLedgerEntry.CalcFields("Remaining Amount");
        end else
            OK := true;
    end;

    [Scope('OnPrem')]
    procedure UpdateConnection()
    var
        Prop: Record "Proposal Line";
        "Detail line": Record "Detail Line";
    begin
        case Status of
            Status::Proposal:
                if "Connect Lines" <> 0 then begin
                    "Detail line".SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines", Date);
                    "Detail line".SetRange("Our Bank", "Our Bank");
                    "Detail line".SetRange(Status, Status);
                    "Detail line".SetRange("Connect Batches", '');
                    "Detail line".SetRange("Connect Lines", "Connect Lines");
                    "Detail line".SetFilter("Transaction No.", '<>%1', "Transaction No.");
                    "Detail line".CalcSums(Amount);

                    Prop.Get("Our Bank", "Connect Lines");
                    Prop.Validate(Amount, "Detail line".Amount + Amount);
                    if "Detail line".FindFirst then begin
                        if (Date < "Detail line".Date) and (Date <> 0D) then
                            Prop."Transaction Date" := Date
                        else
                            Prop."Transaction Date" := "Detail line".Date;
                    end else
                        Prop."Transaction Date" := Date;
                    Prop.Modify;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitRecord()
    var
        TrMode: Record "Transaction Mode";
        BankAcc: Record "Bank Account";
    begin
        TestField("Account No.");
        TestField(Date);
        TestField("Transaction Mode");

        TrMode.Get("Account Type", "Transaction Mode");
        Order := TrMode.Order;
        if "Our Bank" = '' then
            "Our Bank" := TrMode."Our Bank";

        BankAcc.Get("Our Bank");
        "Currency Code" := BankAcc."Currency Code";
    end;

    local procedure GetCurrency()
    begin
        if "Currency Code" = '' then
            BankCur.InitRoundingPrecision
        else
            if "Currency Code" <> BankCur.Code then begin
                BankCur.Get("Currency Code");
                BankCur.TestField("Amount Rounding Precision");
            end;

        if "Currency Code (Entry)" = '' then
            EntryCurrency.InitRoundingPrecision
        else
            if "Currency Code (Entry)" <> EntryCurrency.Code then begin
                EntryCurrency.Get("Currency Code (Entry)");
                EntryCurrency.TestField("Amount Rounding Precision");
            end;
    end;

    [Scope('OnPrem')]
    procedure CalculateVariation() Variation: Decimal
    begin
        GetCurrency;
        if BankCur."Appln. Rounding Precision" <> 0 then
            Variation := CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date,
                "Currency Code",
                "Currency Code (Entry)",
                BankCur."Appln. Rounding Precision");
    end;

    [Scope('OnPrem')]
    procedure SerialnoPostingLookup()
    var
        CustEntry: Page "Customer Ledger Entries";
        VenEntry: Page "Vendor Ledger Entries";
        EmployeeLedgerEntries2: Page "Employee Ledger Entries";
    begin
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if "Serial No. (Entry)" <> 0 then
                        GetCustomerEntries;
                    CustEntries.SetCurrentKey("Customer No.", Open, Positive);
                    CustEntries.SetRange("Customer No.", "Account No.");
                    if Status = Status::Proposal then
                        CustEntries.SetRange(Open, true);
                    CustEntry.SetRecord(CustEntries);
                    CustEntry.SetTableView(CustEntries);
                    CustEntry.LookupMode(true);
                    if CustEntry.RunModal = ACTION::LookupOK then begin
                        CustEntry.GetRecord(CustEntries);
                        Validate("Serial No. (Entry)", CustEntries."Entry No.");
                    end;
                    CustEntries.Reset;
                end;
            "Account Type"::Vendor:
                begin
                    if "Serial No. (Entry)" <> 0 then
                        GetVendorEntries;
                    VendEntries.SetCurrentKey("Vendor No.", Open, Positive);
                    VendEntries.SetRange("Vendor No.", "Account No.");
                    if Status = Status::Proposal then
                        VendEntries.SetRange(Open, true);
                    VenEntry.SetRecord(VendEntries);
                    VenEntry.SetTableView(VendEntries);
                    VenEntry.LookupMode(true);
                    if VenEntry.RunModal = ACTION::LookupOK then begin
                        VenEntry.GetRecord(VendEntries);
                        Validate("Serial No. (Entry)", VendEntries."Entry No.");
                    end;
                    VendEntries.Reset;
                end;
            "Account Type"::Employee:
                begin
                    if "Serial No. (Entry)" <> 0 then
                        GetEmployeeEntries;
                    EmployeeLedgerEntry.SetCurrentKey("Employee No.", Open, Positive);
                    EmployeeLedgerEntry.SetRange("Employee No.", "Account No.");
                    if Status = Status::Proposal then
                        EmployeeLedgerEntry.SetRange(Open, true);
                    EmployeeLedgerEntries2.SetRecord(EmployeeLedgerEntry);
                    EmployeeLedgerEntries2.SetTableView(EmployeeLedgerEntry);
                    EmployeeLedgerEntries2.LookupMode(true);
                    if EmployeeLedgerEntries2.RunModal = ACTION::LookupOK then begin
                        EmployeeLedgerEntries2.GetRecord(EmployeeLedgerEntry);
                        Validate("Serial No. (Entry)", EmployeeLedgerEntry."Entry No.");
                    end;
                    EmployeeLedgerEntry.Reset;
                end;
        end;
    end;
}

