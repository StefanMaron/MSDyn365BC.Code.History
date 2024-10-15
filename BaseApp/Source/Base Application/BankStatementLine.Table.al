table 11705 "Bank Statement Line"
{
    Caption = 'Bank Statement Line';
#if not CLEAN19
    DrillDownPageID = "Bank Statement Lines";
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    fields
    {
        field(1; "Bank Statement No."; Code[20])
        {
            Caption = 'Bank Statement No.';
#if not CLEAN19
            TableRelation = "Bank Statement Header"."No.";

            trigger OnValidate()
            var
                BankAccount: Record "Bank Account";
            begin
                GetBankStmt;
                "Currency Code" := BankStmtHeader."Currency Code";
                "Bank Statement Currency Code" := BankStmtHeader."Bank Statement Currency Code";
                "Bank Statement Currency Factor" := BankStmtHeader."Bank Statement Currency Factor";
                if BankAccount.Get(BankStmtHeader."Bank Account No.") then begin
                    "Constant Symbol" := BankAccount."Default Constant Symbol";
                    "Specific Symbol" := BankAccount."Default Specific Symbol";
                end;
            end;
#endif
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account';
            OptionMembers = " ",Customer,Vendor,"Bank Account";

            trigger OnValidate()
            begin
                if Type <> xRec.Type then
                    Validate("No.", '');
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(Customer)) Customer."No."
            ELSE
            IF (Type = CONST(Vendor)) Vendor."No."
            ELSE
            IF (Type = CONST("Bank Account")) "Bank Account"."No.";

            trigger OnValidate()
            var
                BankAcc: Record "Bank Account";
                Cust: Record Customer;
                Vend: Record Vendor;
            begin
                if "No." <> xRec."No." then
                    Validate("Cust./Vendor Bank Account Code", '');
                case Type of
                    Type::"Bank Account":
                        begin
                            if not BankAcc.Get("No.") then
                                BankAcc.Init();
                            "Account No." := BankAcc."Bank Account No.";
                            Name := BankAcc.Name;
                        end;
                    Type::Customer:
                        begin
                            if not Cust.Get("No.") then
                                Cust.Init();
                            Name := Cust.Name;
                        end;
                    Type::Vendor:
                        begin
                            if not Vend.Get("No.") then
                                Vend.Init();
                            Name := Vend.Name;
                        end;
                end;
            end;
        }
        field(5; "Cust./Vendor Bank Account Code"; Code[20])
        {
            Caption = 'Cust./Vendor Bank Account Code';
            TableRelation = IF (Type = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("No."))
            ELSE
            IF (Type = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("No."));

            trigger OnValidate()
            var
                VendBankAcc: Record "Vendor Bank Account";
                CustBankAcc: Record "Customer Bank Account";
            begin
                if "Cust./Vendor Bank Account Code" <> xRec."Cust./Vendor Bank Account Code" then
                    case Type of
                        Type::Vendor:
                            begin
                                if not VendBankAcc.Get("No.", "Cust./Vendor Bank Account Code") then
                                    VendBankAcc.Init();
                                "Account No." := VendBankAcc."Bank Account No.";
                            end;
                        Type::Customer:
                            begin
                                if not CustBankAcc.Get("No.", "Cust./Vendor Bank Account Code") then
                                    CustBankAcc.Init();
                                "Account No." := CustBankAcc."Bank Account No.";
                            end
                        else
                            if "Cust./Vendor Bank Account Code" <> '' then
                                FieldError(Type);
                    end;
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Account No."; Text[30])
        {
            Caption = 'Account No.';
#if not CLEAN19

            trigger OnValidate()
            var
                BankOperationsFunctions: Codeunit "Bank Operations Functions";
            begin
                BankOperationsFunctions.CheckBankAccountNoCharacters("Account No.");

                if "Account No." <> xRec."Account No." then begin
                    Type := Type::" ";
                    "No." := '';
                    "Cust./Vendor Bank Account Code" := '';
                end;
            end;
#endif
        }
        field(8; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
            Numeric = true;
        }
        field(9; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
            Numeric = true;
#if not CLEAN18
            TableRelation = "Constant Symbol";
#endif
        }
        field(10; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
            Numeric = true;
        }
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
#if not CLEAN19

            trigger OnValidate()
            begin
                GetBankStmt;
                if BankStmtHeader."Currency Code" <> '' then
                    "Amount (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(BankStmtHeader."Document Date",
                          BankStmtHeader."Currency Code", Amount, BankStmtHeader."Currency Factor"))
                else
                    "Amount (LCY)" := Amount;

                if "Bank Statement Currency Code" <> '' then begin
                    GetOrderCurrency;
                    Currency2.TestField("Amount Rounding Precision");
                    "Amount (Bank Stat. Currency)" :=
                      Round(CurrExchRate.ExchangeAmtLCYToFCY(BankStmtHeader."Document Date",
                          "Bank Statement Currency Code", "Amount (LCY)",
                          "Bank Statement Currency Factor"), Currency2."Amount Rounding Precision")
                end else
                    "Amount (Bank Stat. Currency)" := "Amount (LCY)";

                Positive := Amount > 0;
            end;
#endif
        }
        field(12; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
#if not CLEAN19

            trigger OnValidate()
            begin
                GetBankStmt;
                if BankStmtHeader."Currency Code" <> '' then begin
                    Currency.TestField("Amount Rounding Precision");
                    Amount :=
                      Round(CurrExchRate.ExchangeAmtLCYToFCY(BankStmtHeader."Document Date", BankStmtHeader."Currency Code",
                          "Amount (LCY)", BankStmtHeader."Currency Factor"), Currency."Amount Rounding Precision")
                end else
                    Amount := "Amount (LCY)";

                if "Bank Statement Currency Code" <> '' then begin
                    GetOrderCurrency;
                    Currency2.TestField("Amount Rounding Precision");
                    "Amount (Bank Stat. Currency)" :=
                      Round(CurrExchRate.ExchangeAmtLCYToFCY(BankStmtHeader."Document Date",
                          "Bank Statement Currency Code", "Amount (LCY)",
                          "Bank Statement Currency Factor"), Currency2."Amount Rounding Precision")
                end else
                    "Amount (Bank Stat. Currency)" := "Amount (LCY)";

                Positive := "Amount (LCY)" > 0;
            end;
#endif
        }
        field(17; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
        }
        field(18; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        field(20; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(25; "Bank Statement Currency Code"; Code[10])
        {
            Caption = 'Bank Statement Currency Code';
            TableRelation = Currency;
#if not CLEAN19

            trigger OnValidate()
            var
                CurrExchRate: Record "Currency Exchange Rate";
            begin
                GetBankStmt;
                if "Bank Statement Currency Code" <> '' then
                    Validate("Bank Statement Currency Factor",
                      CurrExchRate.ExchangeRate(BankStmtHeader."Document Date", "Bank Statement Currency Code"))
                else
                    Validate("Bank Statement Currency Factor", 0);

                Validate("Amount (LCY)");
            end;
#endif
        }
        field(26; "Amount (Bank Stat. Currency)"; Decimal)
        {
            AutoFormatExpression = "Bank Statement Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount (Bank Stat. Currency)';
#if not CLEAN19

            trigger OnValidate()
            begin
                GetBankStmt;
                if "Bank Statement Currency Code" = '' then
                    "Amount (LCY)" := "Amount (Bank Stat. Currency)"
                else begin
                    GetOrderCurrency;
                    "Amount (LCY)" :=
                      Round(CurrExchRate.ExchangeAmtFCYToLCY(BankStmtHeader."Document Date",
                          "Bank Statement Currency Code", "Amount (Bank Stat. Currency)", "Bank Statement Currency Factor"));
                end;

                if BankStmtHeader."Currency Code" <> '' then begin
                    Currency.TestField("Amount Rounding Precision");
                    GetOrderCurrency;
                    Amount :=
                      Round(CurrExchRate.ExchangeAmtLCYToFCY(BankStmtHeader."Document Date",
                          BankStmtHeader."Currency Code", "Amount (LCY)", BankStmtHeader."Currency Factor"), Currency."Amount Rounding Precision")
                end else
                    Amount := "Amount (LCY)";

                Positive := "Amount (Bank Stat. Currency)" > 0;
            end;
#endif
        }
        field(27; "Bank Statement Currency Factor"; Decimal)
        {
            Caption = 'Bank Statement Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
#if not CLEAN19

            trigger OnValidate()
            begin
                if "Bank Statement Currency Code" <> '' then
                    Validate("Amount (Bank Stat. Currency)");
            end;
#endif
        }
        field(40; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(45; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(70; Name; Text[100])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Bank Statement No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Statement No.", Positive)
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }
#if not CLEAN19

    var
        BankStmtHeader: Record "Bank Statement Header";
        Currency: Record Currency;
        Currency2: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure GetBankStmt()
    begin
        if "Bank Statement No." <> BankStmtHeader."No." then begin
            BankStmtHeader.Get("Bank Statement No.");
            if BankStmtHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                BankStmtHeader.TestField("Currency Factor");
                Currency.Get(BankStmtHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure GetOrderCurrency()
    begin
        if "Bank Statement Currency Code" <> Currency2.Code then
            if "Bank Statement Currency Code" = '' then
                Currency2.InitRoundingPrecision
            else begin
                TestField("Bank Statement Currency Factor");
                Currency2.Get("Bank Statement Currency Code");
                Currency2.TestField("Amount Rounding Precision");
            end;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure CopyFromBankAccReconLine(BankAccReconLn: Record "Bank Acc. Reconciliation Line")
    begin
        Validate(Amount, BankAccReconLn."Statement Amount");
        Description := BankAccReconLn.Description;
        "Account No." := CopyStr(BankAccReconLn."Related-Party Bank Acc. No.", 1, MaxStrLen("Account No."));
        "Variable Symbol" := BankAccReconLn."Variable Symbol";
        "Constant Symbol" := BankAccReconLn."Constant Symbol";
        "Specific Symbol" := BankAccReconLn."Specific Symbol";
    end;
#endif
}
