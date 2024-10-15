table 11709 "Payment Order Line"
{
    Caption = 'Payment Order Line';
    DrillDownPageID = "Payment Order Lines";
    LookupPageID = "Payment Order Lines";

    fields
    {
        field(1; "Payment Order No."; Code[20])
        {
            Caption = 'Payment Order No.';
            TableRelation = "Payment Order Header"."No.";

            trigger OnValidate()
            begin
                GetPaymentOrder;
                "Currency Code" := PmtOrdHdr."Currency Code";
                "Payment Order Currency Code" := PmtOrdHdr."Payment Order Currency Code";
                "Payment Order Currency Factor" := PmtOrdHdr."Payment Order Currency Factor";
                "Due Date" := PmtOrdHdr."Document Date";
                if BankAccount.Get(PmtOrdHdr."Bank Account No.") then begin
                    "Constant Symbol" := BankAccount."Default Constant Symbol";
                    "Specific Symbol" := BankAccount."Default Specific Symbol";
                end;
            end;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account,Employee';
            OptionMembers = " ",Customer,Vendor,"Bank Account",Employee;

            trigger OnValidate()
            begin
                TestStatusOpen;
                if Type <> xRec.Type then begin
                    PmtOrdLn := Rec;
                    Init;
                    Validate("Payment Order No.");
                    Type := PmtOrdLn.Type;
                end;
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(Customer)) Customer."No."
            ELSE
            IF (Type = CONST(Vendor)) Vendor."No."
            ELSE
            IF (Type = CONST(Employee)) Employee."No."
            ELSE
            IF (Type = CONST("Bank Account")) "Bank Account"."No." WHERE("Account Type" = CONST("Bank Account"));

            trigger OnValidate()
            var
                BankAcc: Record "Bank Account";
                CustBankAcc: Record "Customer Bank Account";
                VendBankAcc: Record "Vendor Bank Account";
                Vend: Record Vendor;
                Cust: Record Customer;
                Employee: Record Employee;
            begin
                TestStatusOpen;
                if "No." <> xRec."No." then begin
                    if CurrFieldNo = FieldNo("No.") then begin
                        PmtOrdLn := Rec;
                        Init;
                        Validate("Payment Order No.");
                        Type := PmtOrdLn.Type;
                        "No." := PmtOrdLn."No.";
                    end;
                    case Type of
                        Type::Customer:
                            begin
                                if not Cust.Get("No.") then
                                    Cust.Init();
                                Cust.TestField(Blocked, Cust.Blocked::" ");
                                Cust.TestField("Privacy Blocked", false);
                                Name := Cust.Name;
                                "Payment Method Code" := Cust."Payment Method Code";
                                CustBankAcc.SetRange("Customer No.", "No.");
                                if CustBankAcc.SetCurrentKey("Customer No.", Priority) then begin
                                    CustBankAcc.SetFilter(Priority, '%1..', 1);
                                    if CustBankAcc.FindFirst then begin
                                        Validate("Cust./Vendor Bank Account Code", CustBankAcc.Code);
                                        exit;
                                    end;
                                end;
                                if CustBankAcc.FindFirst then
                                    Validate("Cust./Vendor Bank Account Code", CustBankAcc.Code);
                            end;
                        Type::Vendor:
                            begin
                                if not Vend.Get("No.") then
                                    Vend.Init();
                                Vend.TestField(Blocked, Vend.Blocked::" ");
                                Vend.TestField("Privacy Blocked", false);
                                Name := Vend.Name;
                                "Payment Method Code" := Vend."Payment Method Code";
                                VendBankAcc.SetRange("Vendor No.", "No.");
                                if VendBankAcc.SetCurrentKey("Vendor No.", Priority) then begin
                                    VendBankAcc.SetFilter(Priority, '%1..', 1);
                                    if VendBankAcc.FindFirst then begin
                                        Validate("Cust./Vendor Bank Account Code", VendBankAcc.Code);
                                        exit;
                                    end;
                                end;
                                if VendBankAcc.FindFirst then
                                    Validate("Cust./Vendor Bank Account Code", VendBankAcc.Code);
                            end;
                        Type::Employee:
                            begin
                                TestField("Currency Code", '');
                                if not Employee.Get("No.") then
                                    Employee.Init();
                                Employee.TestField("Privacy Blocked", false);
                                Name := CopyStr(Employee.FullName, 1, MaxStrLen(Name));
                                "Account No." := Employee."Bank Account No.";
                                IBAN := Employee.IBAN;
                                "SWIFT Code" := Employee."SWIFT Code";
                            end;
                    end;
                end;
                case Type of
                    Type::"Bank Account":
                        begin
                            if not BankAcc.Get("No.") then
                                BankAcc.Init();
                            BankAcc.TestField(Blocked, false);
                            "Account No." := BankAcc."Bank Account No.";
                            "Specific Symbol" := BankAcc."Specific Symbol";
                            "Transit No." := BankAcc."Transit No.";
                            IBAN := BankAcc.IBAN;
                            "SWIFT Code" := BankAcc."SWIFT Code";
                            Name := BankAcc.Name;
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
                TestStatusOpen;
                case Type of
                    Type::Vendor:
                        begin
                            if not VendBankAcc.Get("No.", "Cust./Vendor Bank Account Code") then
                                VendBankAcc.Init();
                            "Account No." := VendBankAcc."Bank Account No.";
                            "Specific Symbol" := VendBankAcc."Specific Symbol";
                            "Transit No." := VendBankAcc."Transit No.";
                            IBAN := VendBankAcc.IBAN;
                            "SWIFT Code" := VendBankAcc."SWIFT Code";
                        end;
                    Type::Customer:
                        begin
                            if not CustBankAcc.Get("No.", "Cust./Vendor Bank Account Code") then
                                CustBankAcc.Init();
                            "Account No." := CustBankAcc."Bank Account No.";
                            "Specific Symbol" := CustBankAcc."Specific Symbol";
                            "Transit No." := CustBankAcc."Transit No.";
                            IBAN := CustBankAcc.IBAN;
                            "SWIFT Code" := CustBankAcc."SWIFT Code";
                        end
                    else
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

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
                BankOperationsFunctions: Codeunit "Bank Operations Functions";
            begin
                TestStatusOpen;

                GetPaymentOrder();
                if not PmtOrdHdr."Foreign Payment Order" then begin
                    BankOperationsFunctions.CheckBankAccountNoCharacters("Account No.");

                    CompanyInfo.Get();
                    CompanyInfo.CheckCzBankAccountNo("Account No.");
                end;

                if "Account No." <> xRec."Account No." then begin
                    Type := Type::" ";
                    "No." := '';
                    "Cust./Vendor Bank Account Code" := '';
                    "Specific Symbol" := '';
                    "Transit No." := '';
                    IBAN := '';
                    "SWIFT Code" := '';
                    "Applies-to C/V/E Entry No." := 0;
                end;
            end;
        }
        field(8; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
            Numeric = true;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(9; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
            Numeric = true;
            TableRelation = "Constant Symbol";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(10; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
            Numeric = true;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(11; "Amount to Pay"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Pay';

            trigger OnValidate()
            begin
                TestStatusOpen;
                GetPaymentOrder;
                if PmtOrdHdr."Currency Code" <> '' then
                    "Amount (LCY) to Pay" :=
                      Round(CurrExchRateG.ExchangeAmtFCYToLCY(PmtOrdHdr."Document Date",
                          PmtOrdHdr."Currency Code",
                          "Amount to Pay",
                          PmtOrdHdr."Currency Factor"))
                else
                    "Amount (LCY) to Pay" := "Amount to Pay";

                if "Payment Order Currency Code" <> '' then begin
                    GetOrderCurrency;
                    CurrencyG2.TestField("Amount Rounding Precision");
                    "Amount(Pay.Order Curr.) to Pay" :=
                      Round(CurrExchRateG.ExchangeAmtLCYToFCY(PmtOrdHdr."Document Date",
                          "Payment Order Currency Code",
                          "Amount (LCY) to Pay",
                          "Payment Order Currency Factor"),
                        CurrencyG2."Amount Rounding Precision")
                end else
                    "Amount(Pay.Order Curr.) to Pay" := "Amount (LCY) to Pay";

                Positive := ("Amount to Pay" > 0);
            end;
        }
        field(12; "Amount (LCY) to Pay"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY) to Pay';

            trigger OnValidate()
            begin
                TestStatusOpen;
                GetPaymentOrder;
                if PmtOrdHdr."Currency Code" <> '' then begin
                    CurrencyG.TestField("Amount Rounding Precision");
                    "Amount to Pay" := Round(CurrExchRateG.ExchangeAmtLCYToFCY(PmtOrdHdr."Document Date", PmtOrdHdr."Currency Code",
                          "Amount (LCY) to Pay", PmtOrdHdr."Currency Factor"),
                        CurrencyG."Amount Rounding Precision")
                end else
                    "Amount to Pay" := "Amount (LCY) to Pay";

                if "Payment Order Currency Code" <> '' then begin
                    GetOrderCurrency;
                    CurrencyG2.TestField("Amount Rounding Precision");
                    "Amount(Pay.Order Curr.) to Pay" := Round(CurrExchRateG.ExchangeAmtLCYToFCY(PmtOrdHdr."Document Date",
                          "Payment Order Currency Code",
                          "Amount (LCY) to Pay",
                          "Payment Order Currency Factor"),
                        CurrencyG2."Amount Rounding Precision")
                end else
                    "Amount(Pay.Order Curr.) to Pay" := "Amount (LCY) to Pay";

                Positive := ("Amount (LCY) to Pay" > 0);
            end;
        }
        field(13; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';

            trigger OnValidate()
            begin
                TestStatusOpen;
                TestField("Applies-to C/V/E Entry No.", 0);
            end;
        }
        field(14; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
                SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                PurchInvoiceHeader: Record "Purch. Inv. Header";
                PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
            begin
                if not (Type in [Type::Customer, Type::Vendor]) then
                    FieldError(Type);
                if not ("Applies-to Doc. Type" in ["Applies-to Doc. Type"::Invoice, "Applies-to Doc. Type"::"Credit Memo"]) then
                    FieldError("Applies-to Doc. Type");

                case true of
                    (Type = Type::Customer) and ("Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice):
                        begin
                            if "No." <> '' then
                                SalesInvoiceHeader.SetRange("Bill-to Customer No.", "No.");
                            if SalesInvoiceHeader.Get("Applies-to Doc. No.") then;
                            if PAGE.RunModal(0, SalesInvoiceHeader) = ACTION::LookupOK then begin
                                TestField("Applies-to C/V/E Entry No.", 0);
                                Validate("Applies-to Doc. No.", SalesInvoiceHeader."No.");
                            end;
                        end;
                    (Type = Type::Customer) and ("Applies-to Doc. Type" = "Applies-to Doc. Type"::"Credit Memo"):
                        begin
                            if "No." <> '' then
                                SalesCrMemoHeader.SetRange("Bill-to Customer No.", "No.");
                            if SalesCrMemoHeader.Get("Applies-to Doc. No.") then;
                            if PAGE.RunModal(0, SalesCrMemoHeader) = ACTION::LookupOK then begin
                                TestField("Applies-to C/V/E Entry No.", 0);
                                Validate("Applies-to Doc. No.", SalesCrMemoHeader."No.");
                            end;
                        end;
                    (Type = Type::Vendor) and ("Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice):
                        begin
                            if "No." <> '' then
                                PurchInvoiceHeader.SetRange("Pay-to Vendor No.", "No.");
                            if PurchInvoiceHeader.Get("Applies-to Doc. No.") then;
                            if PAGE.RunModal(0, PurchInvoiceHeader) = ACTION::LookupOK then begin
                                TestField("Applies-to C/V/E Entry No.", 0);
                                Validate("Applies-to Doc. No.", PurchInvoiceHeader."No.");
                            end;
                        end;
                    (Type = Type::Vendor) and ("Applies-to Doc. Type" = "Applies-to Doc. Type"::"Credit Memo"):
                        begin
                            if "No." <> '' then
                                PurchCrMemoHeader.SetRange("Pay-to Vendor No.", "No.");
                            if PurchCrMemoHeader.Get("Applies-to Doc. No.") then;
                            if PAGE.RunModal(0, PurchCrMemoHeader) = ACTION::LookupOK then begin
                                TestField("Applies-to C/V/E Entry No.", 0);
                                Validate("Applies-to Doc. No.", PurchCrMemoHeader."No.");
                            end;
                        end;
                end;
            end;

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
            begin
                TestStatusOpen;
                TestField("Applies-to C/V/E Entry No.", 0);
                if not (Type in [Type::Customer, Type::Vendor]) then
                    FieldError(Type);
                if not ("Applies-to Doc. Type" in ["Applies-to Doc. Type"::Invoice, "Applies-to Doc. Type"::"Credit Memo"]) then
                    FieldError("Applies-to Doc. Type");

                case Type of
                    Type::Customer:
                        begin
                            CustLedgEntry.SetCurrentKey("Document No.");
                            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                            case "Applies-to Doc. Type" of
                                "Applies-to Doc. Type"::Invoice:
                                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                                "Applies-to Doc. Type"::"Credit Memo":
                                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
                            end;
                            if "No." <> '' then
                                CustLedgEntry.SetRange("Customer No.", "No.");
                            case true of
                                CustLedgEntry.IsEmpty:
                                    Error(NotExistEntryErr, CustLedgEntry.FieldCaption("Document No."), CustLedgEntry.TableCaption, "Applies-to Doc. No.");
                                CustLedgEntry.Count > 1:
                                    Error(ExistEntryErr, CustLedgEntry.FieldCaption("Document No."), CustLedgEntry.TableCaption, "Applies-to Doc. No.");
                                else begin
                                        CustLedgEntry.FindFirst;
                                        Validate("Applies-to C/V/E Entry No.", CustLedgEntry."Entry No.");
                                    end;
                            end;
                        end;
                    Type::Vendor:
                        begin
                            VendLedgEntry.SetCurrentKey("Document No.");
                            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                            case "Applies-to Doc. Type" of
                                "Applies-to Doc. Type"::Invoice:
                                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
                                "Applies-to Doc. Type"::"Credit Memo":
                                    VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                            end;
                            if "No." <> '' then
                                VendLedgEntry.SetRange("Vendor No.", "No.");
                            case true of
                                VendLedgEntry.IsEmpty:
                                    Error(NotExistEntryErr, VendLedgEntry.FieldCaption("Document No."), VendLedgEntry.TableCaption, "Applies-to Doc. No.");
                                VendLedgEntry.Count > 1:
                                    Error(ExistEntryErr, VendLedgEntry.FieldCaption("Document No."), VendLedgEntry.TableCaption, "Applies-to Doc. No.");
                                else begin
                                        VendLedgEntry.FindFirst;
                                        Validate("Applies-to C/V/E Entry No.", VendLedgEntry."Entry No.");
                                    end;
                            end;
                        end;
                end;
            end;
        }
        field(16; "Applies-to C/V/E Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Applies-to C/V/E Entry No.';
            TableRelation = IF (Type = CONST(Vendor)) "Vendor Ledger Entry"."Entry No." WHERE(Open = CONST(true),
                                                                                             "On Hold" = CONST(''))
            ELSE
            IF (Type = CONST(Customer)) "Cust. Ledger Entry"."Entry No." WHERE(Open = CONST(true),
                                                                                                                                                                    "On Hold" = CONST(''))
            ELSE
            IF (Type = CONST(Employee)) "Employee Ledger Entry"."Entry No." WHERE(Open = CONST(true));
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnLookup()
            var
                VendLedgEntry: Record "Vendor Ledger Entry";
                CustLedgEntry: Record "Cust. Ledger Entry";
                EmplLedgEntry: Record "Employee Ledger Entry";
                VendLedgEntries: Page "Vendor Ledger Entries";
                CustLedgEntries: Page "Customer Ledger Entries";
                EmplLedgEntries: Page "Employee Ledger Entries";
            begin
                case Type of
                    Type::Vendor:
                        begin
                            VendLedgEntry.SetCurrentKey("Vendor No.", Open);
                            VendLedgEntry.SetRange("On Hold", '');
                            VendLedgEntry.SetRange(Open, true);
                            VendLedgEntry.SetRange(Positive, false);
                            if VendLedgEntry.Get("Applies-to C/V/E Entry No.") then
                                VendLedgEntries.SetRecord(VendLedgEntry);
                            if "No." <> '' then
                                VendLedgEntry.SetRange("Vendor No.", "No.");
                            VendLedgEntries.SetTableView(VendLedgEntry);
                            VendLedgEntries.LookupMode(true);
                            if VendLedgEntries.RunModal = ACTION::LookupOK then begin
                                VendLedgEntries.GetRecord(VendLedgEntry);
                                Validate("Applies-to C/V/E Entry No.", VendLedgEntry."Entry No.");
                            end else
                                Error('');
                        end;
                    Type::Customer:
                        begin
                            CustLedgEntry.SetCurrentKey("Customer No.", Open);
                            CustLedgEntry.SetRange("On Hold", '');
                            CustLedgEntry.SetRange(Open, true);
                            CustLedgEntry.SetRange(Positive, false);
                            if CustLedgEntry.Get("Applies-to C/V/E Entry No.") then
                                CustLedgEntries.SetRecord(CustLedgEntry);
                            if "No." <> '' then
                                CustLedgEntry.SetRange("Customer No.", "No.");
                            CustLedgEntries.SetTableView(CustLedgEntry);
                            CustLedgEntries.LookupMode(true);
                            if CustLedgEntries.RunModal = ACTION::LookupOK then begin
                                CustLedgEntries.GetRecord(CustLedgEntry);
                                Validate("Applies-to C/V/E Entry No.", CustLedgEntry."Entry No.");
                            end else
                                Error('');
                        end;
                    Type::Employee:
                        begin
                            EmplLedgEntry.SetRange(Open, true);
                            EmplLedgEntry.SetRange(Positive, false);
                            if EmplLedgEntry.Get("Applies-to C/V/E Entry No.") then
                                EmplLedgEntries.SetRecord(EmplLedgEntry);
                            if "No." <> '' then
                                EmplLedgEntry.SetRange("Employee No.", "No.");
                            EmplLedgEntries.SetTableView(EmplLedgEntry);
                            EmplLedgEntries.LookupMode(true);
                            if EmplLedgEntries.RunModal = ACTION::LookupOK then begin
                                EmplLedgEntries.GetRecord(EmplLedgEntry);
                                Validate("Applies-to C/V/E Entry No.", EmplLedgEntry."Entry No.");
                            end else
                                Error('');
                        end;
                end;
            end;

            trigger OnValidate()
            begin
                if "Applies-to C/V/E Entry No." <> 0 then
                    if CurrFieldNo = FieldNo("Applies-to C/V/E Entry No.") then
                        if not PaymentOrderManagement.CheckPaymentOrderLineApply(Rec, false) then begin
                            if not Confirm(StrSubstNo(LedgerAlreadyAppliedQst, "Applies-to C/V/E Entry No.")) then
                                Error('');
                            "Amount Must Be Checked" := true;
                        end;

                TestStatusOpen;
                GetPaymentOrder;
                "Original Amount" := 0;
                "Original Amount (LCY)" := 0;
                "Orig. Amount(Pay.Order Curr.)" := 0;
                "Original Due Date" := 0D;
                "Pmt. Discount Date" := 0D;
                "Pmt. Discount Possible" := false;
                "Remaining Pmt. Disc. Possible" := 0;
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                "Applies-to Doc. No." := '';

                PaymentOrderManagement.ClearErrorMessageLog;

                if "Applies-to C/V/E Entry No." = 0 then
                    exit;

                case Type of
                    Type::Vendor:
                        AppliesToVendLedgEntryNo;
                    Type::Customer:
                        AppliesToCustLedgEntryNo;
                    Type::Employee:
                        AppliesToEmplLedgEntryNo;
                    else
                        FieldError(Type);
                end;
            end;
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
        field(24; "Applied Currency Code"; Code[10])
        {
            Caption = 'Applied Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(25; "Payment Order Currency Code"; Code[10])
        {
            Caption = 'Payment Order Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                CurrExchRate: Record "Currency Exchange Rate";
            begin
                TestStatusOpen;
                GetPaymentOrder;
                if "Payment Order Currency Code" <> '' then
                    Validate("Payment Order Currency Factor",
                      CurrExchRate.ExchangeRate(PmtOrdHdr."Document Date", "Payment Order Currency Code"))
                else
                    Validate("Payment Order Currency Factor", 0);
                case true of
                    ("Applies-to C/V/E Entry No." <> 0):
                        begin
                            "Amount to Pay" := 0;
                            Validate("Applies-to C/V/E Entry No.");
                        end
                    else
                        Validate("Amount (LCY) to Pay");
                end;
            end;
        }
        field(26; "Amount(Pay.Order Curr.) to Pay"; Decimal)
        {
            AutoFormatExpression = "Payment Order Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount(Pay.Order Curr.) to Pay';

            trigger OnValidate()
            begin
                TestStatusOpen;
                GetPaymentOrder;
                if "Payment Order Currency Code" <> '' then begin
                    GetOrderCurrency;
                    "Amount (LCY) to Pay" := Round(CurrExchRateG.ExchangeAmtFCYToLCY(PmtOrdHdr."Document Date",
                          "Payment Order Currency Code",
                          "Amount(Pay.Order Curr.) to Pay",
                          "Payment Order Currency Factor"));
                end else
                    "Amount (LCY) to Pay" := "Amount(Pay.Order Curr.) to Pay";

                if PmtOrdHdr."Currency Code" <> '' then begin
                    CurrencyG.TestField("Amount Rounding Precision");
                    "Amount to Pay" := Round(CurrExchRateG.ExchangeAmtLCYToFCY(PmtOrdHdr."Document Date",
                          PmtOrdHdr."Currency Code",
                          "Amount (LCY) to Pay",
                          PmtOrdHdr."Currency Factor"),
                        CurrencyG."Amount Rounding Precision")
                end else
                    "Amount to Pay" := "Amount (LCY) to Pay";

                Positive := ("Amount(Pay.Order Curr.) to Pay" > 0);
            end;
        }
        field(27; "Payment Order Currency Factor"; Decimal)
        {
            Caption = 'Payment Order Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;

            trigger OnValidate()
            begin
                if ("Payment Order Currency Code" = "Applied Currency Code") and ("Payment Order Currency Code" <> '') then
                    Validate("Amount(Pay.Order Curr.) to Pay")
                else
                    Validate("Amount (LCY) to Pay");
            end;
        }
        field(30; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(40; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                TestStatusOpen;
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(45; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(50; "Amount Must Be Checked"; Boolean)
        {
            Caption = 'Amount Must Be Checked';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(70; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(80; "Original Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Amount';
            Editable = false;
        }
        field(90; "Original Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Original Amount (LCY)';
            Editable = false;
        }
        field(100; "Orig. Amount(Pay.Order Curr.)"; Decimal)
        {
            AutoFormatExpression = "Payment Order Currency Code";
            AutoFormatType = 1;
            Caption = 'Orig. Amount(Pay.Order Curr.)';
            Editable = false;
        }
        field(110; "Original Due Date"; Date)
        {
            Caption = 'Original Due Date';
            Editable = false;
        }
        field(120; "Skip Payment"; Boolean)
        {
            Caption = 'Skip Payment';

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(130; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            Editable = false;
        }
        field(135; "Pmt. Discount Possible"; Boolean)
        {
            Caption = 'Pmt. Discount Possible';
            Editable = false;
        }
        field(140; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';
            Editable = false;
        }
        field(150; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            OptionCaption = ' ,,Purchase';
            OptionMembers = " ",,Purchase;

            trigger OnValidate()
            begin
                TestStatusOpen;
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                "Applies-to Doc. No." := '';
                "Applies-to C/V/E Entry No." := 0;
                "Original Amount" := 0;
                "Original Amount (LCY)" := 0;
                "Orig. Amount(Pay.Order Curr.)" := 0;
                "Original Due Date" := 0D;
                "Pmt. Discount Date" := 0D;
                "Pmt. Discount Possible" := false;
                "Remaining Pmt. Disc. Possible" := 0;
            end;
        }
        field(151; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
            TableRelation = IF ("Letter Type" = CONST(Purchase)) "Purch. Advance Letter Header";

            trigger OnValidate()
            var
                PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
                Vendor: Record Vendor;
                Currency: Record Currency;
                RemAmount: Decimal;
            begin
                TestStatusOpen;
                GetPaymentOrder;
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                "Applies-to Doc. No." := '';
                "Applies-to C/V/E Entry No." := 0;
                "Original Amount" := 0;
                "Original Amount (LCY)" := 0;
                "Orig. Amount(Pay.Order Curr.)" := 0;
                "Original Due Date" := 0D;
                "Pmt. Discount Date" := 0D;
                "Pmt. Discount Possible" := false;
                "Remaining Pmt. Disc. Possible" := 0;
                "Letter Line No." := 0;

                RemAmount := 0;
                PaymentOrderManagement.ClearErrorMessageLog;
                case "Letter Type" of
                    "Letter Type"::Purchase:
                        begin
                            if "Letter No." <> '' then begin
                                if CurrFieldNo = FieldNo("Letter No.") then
                                    if not PaymentOrderManagement.CheckPaymentOrderLineApply(Rec, false) then begin
                                        if not Confirm(StrSubstNo(AdvanceAlreadyAppliedQst, "Letter No.")) then
                                            Error('');
                                        "Amount Must Be Checked" := true;
                                    end;
                                PurchAdvLetterHeader.Get("Letter No.");
                                PurchAdvLetterHeader.CalcFields("Amount on Payment Order (LCY)");
                                "Variable Symbol" := PurchAdvLetterHeader."Variable Symbol";
                                if PurchAdvLetterHeader."Constant Symbol" <> '' then
                                    "Constant Symbol" := PurchAdvLetterHeader."Constant Symbol";
                                BankAccount.Get(PmtOrdHdr."Bank Account No.");
                                if BankAccount."Payment Order Line Description" = '' then
                                    Description := PurchAdvLetterHeader."Posting Description"
                                else begin
                                    Vendor.Get(PurchAdvLetterHeader."Pay-to Vendor No.");
                                    Description := CreateDescription(AdvTxt, PurchAdvLetterHeader."No.",
                                        Vendor."No.", Vendor.Name, PurchAdvLetterHeader."Vendor Adv. Payment No.");
                                end;
                                Type := Type::Vendor;
                                "No." := PurchAdvLetterHeader."Pay-to Vendor No.";
                                Validate("No.", PurchAdvLetterHeader."Pay-to Vendor No.");
                                "Cust./Vendor Bank Account Code" := PurchAdvLetterHeader."Bank Account Code";
                                "Account No." := PurchAdvLetterHeader."Bank Account No.";
                                "Specific Symbol" := PurchAdvLetterHeader."Specific Symbol";
                                "Transit No." := PurchAdvLetterHeader."Transit No.";
                                IBAN := PurchAdvLetterHeader.IBAN;
                                "SWIFT Code" := PurchAdvLetterHeader."SWIFT Code";
                                "Applied Currency Code" := PurchAdvLetterHeader."Currency Code";
                                if PurchAdvLetterHeader."Advance Due Date" > "Due Date" then
                                    "Due Date" := PurchAdvLetterHeader."Advance Due Date";
                                "Original Due Date" := PurchAdvLetterHeader."Advance Due Date";
                                if "Amount to Pay" = 0 then begin
                                    RemAmount := PurchAdvLetterHeader.GetRemAmount();
                                    if "Payment Order Currency Code" = PurchAdvLetterHeader."Currency Code" then begin
                                        "Amount(Pay.Order Curr.) to Pay" := RemAmount;
                                        Validate("Amount(Pay.Order Curr.) to Pay");
                                    end else begin
                                        if PurchAdvLetterHeader."Currency Code" <> '' then begin
                                            Currency.Get(PurchAdvLetterHeader."Currency Code");
                                            Currency.InitRoundingPrecision;
                                            "Amount (LCY) to Pay" := Round(CurrExchRateG.ExchangeAmtFCYToLCY(PurchAdvLetterHeader."Document Date",
                                                  PurchAdvLetterHeader."Currency Code",
                                                  RemAmount,
                                                  PurchAdvLetterHeader."Currency Factor"))
                                        end else
                                            "Amount (LCY) to Pay" := RemAmount;

                                        Validate("Amount (LCY) to Pay");
                                    end;
                                end;
                            end;
                            "Original Amount" := "Amount to Pay";
                            "Original Amount (LCY)" := "Amount (LCY) to Pay";
                            "Orig. Amount(Pay.Order Curr.)" := "Amount(Pay.Order Curr.) to Pay";
                        end;
                    else
                        FieldError(Type);
                end;
            end;
        }
        field(152; "Letter Line No."; Integer)
        {
            Caption = 'Letter Line No.';
            TableRelation = IF ("Letter Type" = CONST(Purchase)) "Purch. Advance Letter Line"."Line No." WHERE("Letter No." = FIELD("Letter No."));

            trigger OnValidate()
            var
                PurchAdvLetterHeader: Record "Purch. Advance Letter Header";
                PurchAdvLetterLine: Record "Purch. Advance Letter Line";
                Vendor: Record Vendor;
                Currency: Record Currency;
                RemAmount: Decimal;
            begin
                TestStatusOpen;
                GetPaymentOrder;
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                "Applies-to Doc. No." := '';
                "Applies-to C/V/E Entry No." := 0;
                "Original Amount" := 0;
                "Original Amount (LCY)" := 0;
                "Orig. Amount(Pay.Order Curr.)" := 0;
                "Original Due Date" := 0D;
                "Pmt. Discount Date" := 0D;
                "Pmt. Discount Possible" := false;
                "Remaining Pmt. Disc. Possible" := 0;

                RemAmount := 0;
                PaymentOrderManagement.ClearErrorMessageLog;
                case "Letter Type" of
                    "Letter Type"::Purchase:
                        begin
                            if "Letter Line No." <> 0 then begin
                                TestField("Letter No.");
                                if CurrFieldNo = FieldNo("Letter Line No.") then
                                    if not PaymentOrderManagement.CheckPaymentOrderLineApply(Rec, false) then begin
                                        if not Confirm(StrSubstNo(LedgerAlreadyAppliedLineQst, "Letter No.")) then
                                            Error('');
                                        "Amount Must Be Checked" := true;
                                    end;

                                PurchAdvLetterHeader.Get("Letter No.");
                                PurchAdvLetterHeader.TestField("Due Date from Line", true);
                                PurchAdvLetterLine.Get("Letter No.", "Letter Line No.");
                                PurchAdvLetterLine.CalcFields("Amount on Payment Order (LCY)");

                                "Variable Symbol" := PurchAdvLetterHeader."Variable Symbol";
                                if PurchAdvLetterHeader."Constant Symbol" <> '' then
                                    "Constant Symbol" := PurchAdvLetterHeader."Constant Symbol";
                                BankAccount.Get(PmtOrdHdr."Bank Account No.");
                                if BankAccount."Payment Order Line Description" = '' then
                                    Description := PurchAdvLetterHeader."Posting Description"
                                else begin
                                    Vendor.Get(PurchAdvLetterHeader."Pay-to Vendor No.");
                                    Description := CreateDescription(AdvLineTxt, PurchAdvLetterHeader."No.",
                                        Vendor."No.", Vendor.Name, PurchAdvLetterHeader."Vendor Adv. Payment No.");
                                end;
                                Type := Type::Vendor;
                                "No." := PurchAdvLetterHeader."Pay-to Vendor No.";
                                Validate("No.", PurchAdvLetterHeader."Pay-to Vendor No.");
                                "Cust./Vendor Bank Account Code" := PurchAdvLetterHeader."Bank Account Code";
                                "Account No." := PurchAdvLetterHeader."Bank Account No.";
                                "Specific Symbol" := PurchAdvLetterHeader."Specific Symbol";
                                "Transit No." := PurchAdvLetterHeader."Transit No.";
                                IBAN := PurchAdvLetterHeader.IBAN;
                                "SWIFT Code" := PurchAdvLetterHeader."SWIFT Code";
                                "Applied Currency Code" := PurchAdvLetterHeader."Currency Code";
                                if PurchAdvLetterLine."Advance Due Date" > "Due Date" then
                                    "Due Date" := PurchAdvLetterLine."Advance Due Date";
                                "Original Due Date" := PurchAdvLetterLine."Advance Due Date";
                                if "Amount to Pay" = 0 then begin
                                    RemAmount := PurchAdvLetterLine."Amount To Link";
                                    if "Payment Order Currency Code" = PurchAdvLetterHeader."Currency Code" then begin
                                        "Amount(Pay.Order Curr.) to Pay" := RemAmount;
                                        Validate("Amount(Pay.Order Curr.) to Pay");
                                    end else begin
                                        if PurchAdvLetterHeader."Currency Code" <> '' then begin
                                            Currency.Get(PurchAdvLetterHeader."Currency Code");
                                            Currency.InitRoundingPrecision;
                                            "Amount (LCY) to Pay" := Round(CurrExchRateG.ExchangeAmtFCYToLCY(PurchAdvLetterHeader."Document Date",
                                                  PurchAdvLetterHeader."Currency Code",
                                                  RemAmount,
                                                  PurchAdvLetterHeader."Currency Factor"))
                                        end else
                                            "Amount (LCY) to Pay" := RemAmount;

                                        Validate("Amount (LCY) to Pay");
                                    end;
                                end;
                            end;
                            "Original Amount" := "Amount to Pay";
                            "Original Amount (LCY)" := "Amount (LCY) to Pay";
                            "Orig. Amount(Pay.Order Curr.)" := "Amount(Pay.Order Curr.) to Pay";
                        end;
                    else
                        FieldError(Type);
                end;
            end;
        }
        field(190; "VAT Uncertainty Payer"; Boolean)
        {
            Caption = 'VAT Uncertainty Payer';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.5';
        }
        field(191; "Public Bank Account"; Boolean)
        {
            Caption = 'Public Bank Account';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.5';
        }
        field(192; "Third Party Bank Account"; Boolean)
        {
            CalcFormula = Lookup("Vendor Bank Account"."Third Party Bank Account" WHERE("Vendor No." = FIELD("No."),
                                                                                         Code = FIELD("Cust./Vendor Bank Account Code")));
            Caption = 'Third Party Bank Account';
            Editable = false;
            FieldClass = FlowField;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.5';
        }
        field(200; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
    }

    keys
    {
        key(Key1; "Payment Order No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Payment Order No.", Positive, "Skip Payment")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Amount to Pay", "Amount (LCY) to Pay";
        }
        key(Key3; "Payment Order No.", "Due Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "Payment Order No.", "Amount to Pay")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "Payment Order No.", Type, "No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "Payment Order No.", "Skip Payment")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Amount(Pay.Order Curr.) to Pay";
        }
        key(Key7; "Payment Order No.", "Original Due Date")
        {
            MaintainSQLIndex = false;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatusOpen;
    end;

    trigger OnInsert()
    begin
        TestStatusOpen;
        ModifyPayOrderHeader;
    end;

    trigger OnModify()
    begin
        ModifyPayOrderHeader;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PmtOrdHdr: Record "Payment Order Header";
        PmtOrdLn: Record "Payment Order Line";
        CurrencyG: Record Currency;
        CurrencyG2: Record Currency;
        CurrExchRateG: Record "Currency Exchange Rate";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        PaymentOrderManagement: Codeunit "Payment Order Management";
        GLSetupRead: Boolean;
        ExistEntryErr: Label 'For the field %1 in table %2 exist more than one value %3.', Comment = '%1=FIELDCAPTION,%2=TABLECAPTION,%3=Applies-to Doc. No.';
        NotExistEntryErr: Label 'For the field %1 in table %2 not exist value %3.', Comment = '%1=FIELDCAPTION,%2=TABLECAPTION,%3=Applies-to Doc. No.';
        LedgerAlreadyAppliedQst: Label 'Ledger entry %1 is already applied on payment order. Continue?', Comment = '%1=Applies-to C/V Entry No.';
        AdvanceAlreadyAppliedQst: Label 'Advanced payment %1 is already applied on payment order. Continue?', Comment = '%1=Letter No.';
        AdvTxt: Label 'Advance Payment';
        LedgerAlreadyAppliedLineQst: Label 'Advanced payment %1 is already applied on payment order. Continue?', Comment = '%1=Letter No.';
        AdvLineTxt: Label 'Advance Payment Line';
        StatusCheckSuspended: Boolean;

    [Scope('OnPrem')]
    procedure GetPaymentOrder()
    begin
        if "Payment Order No." <> PmtOrdHdr."No." then begin
            PmtOrdHdr.Get("Payment Order No.");
            if PmtOrdHdr."Currency Code" = '' then
                CurrencyG.InitRoundingPrecision
            else begin
                PmtOrdHdr.TestField("Currency Factor");
                CurrencyG.Get(PmtOrdHdr."Currency Code");
                CurrencyG.TestField("Amount Rounding Precision");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetOrderCurrency()
    begin
        if "Payment Order Currency Code" <> CurrencyG2.Code then
            if "Payment Order Currency Code" = '' then
                CurrencyG2.InitRoundingPrecision
            else begin
                TestField("Payment Order Currency Factor");
                CurrencyG2.Get("Payment Order Currency Code");
                CurrencyG2.TestField("Amount Rounding Precision");
            end;
    end;

    [Scope('OnPrem')]
    procedure CreateDescription(DocType: Text[30]; DocNo: Text[20]; PartnerNo: Text[20]; PartnerName: Text[100]; ExtNo: Text[35]): Text[50]
    begin
        exit(
          CopyStr(
            StrSubstNo(BankAccount."Payment Order Line Description", DocType, DocNo, PartnerNo, PartnerName, ExtNo),
            1, 50));
    end;

    [Scope('OnPrem')]
    procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetupRead := true;
            GLSetup.Get();
        end;
    end;

    [Scope('OnPrem')]
    procedure ModifyPayOrderHeader()
    begin
        GetPaymentOrder;
        if PmtOrdHdr."Uncertainty Pay.Check DateTime" <> 0DT then begin
            PmtOrdHdr."Uncertainty Pay.Check DateTime" := 0DT;
            PmtOrdHdr.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure AppliesToCustLedgEntryNo()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CurrencyAmount: Decimal;
        CurrFactor: Decimal;
    begin
        CustLedgEntry.Get("Applies-to C/V/E Entry No.");
        "Applies-to Doc. Type" := CustLedgEntry."Document Type";
        "Applies-to Doc. No." := CustLedgEntry."Document No.";
        "Variable Symbol" := CustLedgEntry."Variable Symbol";
        if CustLedgEntry."Constant Symbol" <> '' then
            "Constant Symbol" := CustLedgEntry."Constant Symbol";
        BankAccount.Get(PmtOrdHdr."Bank Account No.");
        if BankAccount."Payment Order Line Description" = '' then
            Description := CustLedgEntry.Description
        else begin
            Customer.Get(CustLedgEntry."Customer No.");
            Description := CreateDescription(Format(CustLedgEntry."Document Type"), CustLedgEntry."Document No.",
                Customer."No.", Customer.Name, CustLedgEntry."External Document No.");
        end;
        Type := Type::Customer;
        "No." := CustLedgEntry."Customer No.";
        Validate("No.", CustLedgEntry."Customer No.");
        "Cust./Vendor Bank Account Code" :=
          CopyStr(CustLedgEntry."Bank Account Code", 1, MaxStrLen("Cust./Vendor Bank Account Code"));
        "Account No." := CustLedgEntry."Bank Account No.";
        "Specific Symbol" := CustLedgEntry."Specific Symbol";
        "Transit No." := CustLedgEntry."Transit No.";
        IBAN := CustLedgEntry.IBAN;
        "SWIFT Code" := CustLedgEntry."SWIFT Code";
        Validate("Applied Currency Code", CustLedgEntry."Currency Code");
        if CustLedgEntry."Due Date" > "Due Date" then
            "Due Date" := CustLedgEntry."Due Date";
        "Original Due Date" := CustLedgEntry."Due Date";
        if "Amount to Pay" = 0 then begin
            CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            if "Payment Order Currency Code" = CustLedgEntry."Currency Code" then begin
                if (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice) and
                   (PmtOrdHdr."Document Date" <= CustLedgEntry."Pmt. Discount Date")
                then begin
                    "Amount(Pay.Order Curr.) to Pay" :=
                        -(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible");
                    "Pmt. Discount Date" := CustLedgEntry."Pmt. Discount Date";
                    "Pmt. Discount Possible" := true;
                    "Remaining Pmt. Disc. Possible" := CustLedgEntry."Remaining Pmt. Disc. Possible";
                end else
                    "Amount(Pay.Order Curr.) to Pay" := -CustLedgEntry."Remaining Amount";
                Validate("Amount(Pay.Order Curr.) to Pay");
            end else begin
                if (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice) and
                   (PmtOrdHdr."Document Date" <= CustLedgEntry."Pmt. Discount Date")
                then begin
                    CurrencyAmount := -(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible");
                    CurrFactor := CurrExchRateG.ExchangeRate(PmtOrdHdr."Document Date", CustLedgEntry."Currency Code");
                    "Amount (LCY) to Pay" := Round(CurrExchRateG.ExchangeAmtFCYToLCY(PmtOrdHdr."Document Date",
                          CustLedgEntry."Currency Code", CurrencyAmount, CurrFactor));
                    "Pmt. Discount Date" := CustLedgEntry."Pmt. Discount Date";
                    "Pmt. Discount Possible" := true;
                    "Remaining Pmt. Disc. Possible" := CustLedgEntry."Remaining Pmt. Disc. Possible";
                end else
                    "Amount (LCY) to Pay" := -CustLedgEntry."Remaining Amt. (LCY)";
                Validate("Amount (LCY) to Pay");
            end;
            "Original Amount" := "Amount to Pay";
            "Original Amount (LCY)" := "Amount (LCY) to Pay";
            "Orig. Amount(Pay.Order Curr.)" := "Amount(Pay.Order Curr.) to Pay";
        end;
    end;

    [Scope('OnPrem')]
    procedure AppliesToVendLedgEntryNo()
    var
        VendorLedgEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        CurrencyAmount: Decimal;
        CurrFactor: Decimal;
    begin
        VendorLedgEntry.Get("Applies-to C/V/E Entry No.");
        "Applies-to Doc. Type" := VendorLedgEntry."Document Type";
        "Applies-to Doc. No." := VendorLedgEntry."Document No.";
        "Variable Symbol" := VendorLedgEntry."Variable Symbol";
        if VendorLedgEntry."Constant Symbol" <> '' then
            "Constant Symbol" := VendorLedgEntry."Constant Symbol";
        BankAccount.Get(PmtOrdHdr."Bank Account No.");
        if BankAccount."Payment Order Line Description" = '' then
            Description := VendorLedgEntry.Description
        else begin
            Vendor.Get(VendorLedgEntry."Vendor No.");
            Description := CreateDescription(Format(VendorLedgEntry."Document Type"), VendorLedgEntry."Document No.",
                Vendor."No.", Vendor.Name, VendorLedgEntry."External Document No.");
        end;
        Type := Type::Vendor;
        "No." := VendorLedgEntry."Vendor No.";
        Validate("No.", VendorLedgEntry."Vendor No.");
        "Cust./Vendor Bank Account Code" :=
          CopyStr(VendorLedgEntry."Bank Account Code", 1, MaxStrLen("Cust./Vendor Bank Account Code"));
        "Account No." := VendorLedgEntry."Bank Account No.";
        "Specific Symbol" := VendorLedgEntry."Specific Symbol";
        "Transit No." := VendorLedgEntry."Transit No.";
        IBAN := VendorLedgEntry.IBAN;
        "SWIFT Code" := VendorLedgEntry."SWIFT Code";
        Validate("Applied Currency Code", VendorLedgEntry."Currency Code");
        if VendorLedgEntry."Due Date" > "Due Date" then
            "Due Date" := VendorLedgEntry."Due Date";
        "Original Due Date" := VendorLedgEntry."Due Date";
        if "Amount to Pay" = 0 then begin
            VendorLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            if "Payment Order Currency Code" = VendorLedgEntry."Currency Code" then begin
                if (VendorLedgEntry."Document Type" = VendorLedgEntry."Document Type"::Invoice) and
                   (PmtOrdHdr."Document Date" <= VendorLedgEntry."Pmt. Discount Date")
                then begin
                    "Amount(Pay.Order Curr.) to Pay" :=
                        -(VendorLedgEntry."Remaining Amount" - VendorLedgEntry."Remaining Pmt. Disc. Possible");
                    "Pmt. Discount Date" := VendorLedgEntry."Pmt. Discount Date";
                    "Pmt. Discount Possible" := true;
                    "Remaining Pmt. Disc. Possible" := VendorLedgEntry."Remaining Pmt. Disc. Possible";
                    if ("Remaining Pmt. Disc. Possible" <> 0) and ("Pmt. Discount Date" <> 0D) then
                        "Due Date" := "Pmt. Discount Date";
                end else
                    "Amount(Pay.Order Curr.) to Pay" := -VendorLedgEntry."Remaining Amount";
                Validate("Amount(Pay.Order Curr.) to Pay");
            end else begin
                if (VendorLedgEntry."Document Type" = VendorLedgEntry."Document Type"::Invoice) and
                   (PmtOrdHdr."Document Date" <= VendorLedgEntry."Pmt. Discount Date")
                then begin
                    CurrencyAmount := -(VendorLedgEntry."Remaining Amount" - VendorLedgEntry."Remaining Pmt. Disc. Possible");
                    CurrFactor := CurrExchRateG.ExchangeRate(PmtOrdHdr."Document Date", VendorLedgEntry."Currency Code");
                    "Amount (LCY) to Pay" := Round(CurrExchRateG.ExchangeAmtFCYToLCY(PmtOrdHdr."Document Date",
                          VendorLedgEntry."Currency Code", CurrencyAmount, CurrFactor));
                    "Pmt. Discount Date" := VendorLedgEntry."Pmt. Discount Date";
                    "Pmt. Discount Possible" := true;
                    "Remaining Pmt. Disc. Possible" := VendorLedgEntry."Remaining Pmt. Disc. Possible";
                    if ("Remaining Pmt. Disc. Possible" <> 0) and ("Pmt. Discount Date" <> 0D) then
                        "Due Date" := "Pmt. Discount Date";
                end else
                    "Amount (LCY) to Pay" := -VendorLedgEntry."Remaining Amt. (LCY)";
                Validate("Amount (LCY) to Pay");
            end;
            "Original Amount" := "Amount to Pay";
            "Original Amount (LCY)" := "Amount (LCY) to Pay";
            "Orig. Amount(Pay.Order Curr.)" := "Amount(Pay.Order Curr.) to Pay";
        end;
    end;

    [Scope('OnPrem')]
    procedure AppliesToEmplLedgEntryNo()
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        Employee: Record Employee;
    begin
        EmplLedgEntry.Get("Applies-to C/V/E Entry No.");
        Employee.Get(EmplLedgEntry."Employee No.");

        "Applies-to Doc. Type" := EmplLedgEntry."Document Type";
        "Applies-to Doc. No." := EmplLedgEntry."Document No.";
        "Variable Symbol" := EmplLedgEntry."Variable Symbol";
        "Specific Symbol" := EmplLedgEntry."Specific Symbol";
        if EmplLedgEntry."Constant Symbol" <> '' then
            "Constant Symbol" := EmplLedgEntry."Constant Symbol";
        BankAccount.Get(PmtOrdHdr."Bank Account No.");
        if BankAccount."Payment Order Line Description" = '' then
            Description := EmplLedgEntry.Description
        else
            Description := CreateDescription(Format(EmplLedgEntry."Document Type"), EmplLedgEntry."Document No.",
                Employee."No.", CopyStr(Employee.FullName, 1, MaxStrLen(Description)), '');

        Type := Type::Employee;
        Validate("No.", EmplLedgEntry."Employee No.");
        "Account No." := Employee."Bank Account No.";
        IBAN := Employee.IBAN;
        "SWIFT Code" := Employee."SWIFT Code";
        Validate("Applied Currency Code", EmplLedgEntry."Currency Code");
        if "Amount to Pay" = 0 then begin
            EmplLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            if "Payment Order Currency Code" = EmplLedgEntry."Currency Code" then
                Validate("Amount(Pay.Order Curr.) to Pay", -EmplLedgEntry."Remaining Amount")
            else
                Validate("Amount (LCY) to Pay", -EmplLedgEntry."Remaining Amt. (LCY)");
            "Original Amount" := "Amount to Pay";
            "Original Amount (LCY)" := "Amount (LCY) to Pay";
            "Orig. Amount(Pay.Order Curr.)" := "Amount(Pay.Order Curr.) to Pay";
        end;
    end;

    local procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;
        GetPaymentOrder;
        PmtOrdHdr.TestField(Status, PmtOrdHdr.Status::Open);
    end;

    [Scope('OnPrem')]
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    local procedure GetVendor(): Boolean
    begin
        if Type <> Type::Vendor then
            exit(false);

        if Vendor."No." <> "No." then
            exit(Vendor.Get("No."));

        exit(true);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.5')]
    procedure IsUncertaintyPayerCheckPossible(): Boolean
    begin
        if not GetVendor then
            exit(false);

        exit(Vendor.IsUncertaintyPayerCheckPossible);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.5')]
    procedure GetUncertaintyPayerStatus(): Integer
    begin
        if not GetVendor then
            exit(0);

        exit(Vendor.GetUncertaintyPayerStatus);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.5')]
    procedure HasUncertaintyPayer(): Boolean
    var
        UncertaintyPayerEntry: Record "Uncertainty Payer Entry";
    begin
        exit(GetUncertaintyPayerStatus = UncertaintyPayerEntry."Uncertainty Payer"::YES);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.5')]
    procedure HasPublicBankAccount(): Boolean
    var
        UncPayerMgt: Codeunit "Unc. Payer Mgt.";
    begin
        if not GetVendor then
            exit(false);

        exit(UncPayerMgt.IsPublicBankAccount('', Vendor."VAT Registration No.", "Account No.", IBAN));
    end;
}

