table 11709 "Payment Order Line"
{
    Caption = 'Payment Order Line';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Payment Order No."; Code[20])
        {
            Caption = 'Payment Order No.';
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
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Customer)) Customer."No."
            else
            if (Type = const(Vendor)) Vendor."No."
            else
            if (Type = const(Employee)) Employee."No."
            else
            if (Type = const("Bank Account")) "Bank Account"."No.";
        }
        field(5; "Cust./Vendor Bank Account Code"; Code[20])
        {
            Caption = 'Cust./Vendor Bank Account Code';
            TableRelation = if (Type = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("No."))
            else
            if (Type = const(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("No."));
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Account No."; Text[30])
        {
            Caption = 'Account No.';
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
        }
        field(10; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
            Numeric = true;
        }
        field(11; "Amount to Pay"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Pay';
        }
        field(12; "Amount (LCY) to Pay"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY) to Pay';
        }
        field(13; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
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
        }
        field(16; "Applies-to C/V/E Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Applies-to C/V/E Entry No.';
            TableRelation = if (Type = const(Vendor)) "Vendor Ledger Entry"."Entry No." where(Open = const(true),
                                                                                             "On Hold" = const(''))
            else
            if (Type = const(Customer)) "Cust. Ledger Entry"."Entry No." where(Open = const(true),
                                                                                                                                                                    "On Hold" = const(''))
            else
            if (Type = const(Employee)) "Employee Ledger Entry"."Entry No." where(Open = const(true));

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
                            if VendLedgEntries.RunModal() = ACTION::LookupOK then begin
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
                            if CustLedgEntries.RunModal() = ACTION::LookupOK then begin
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
                            if EmplLedgEntries.RunModal() = ACTION::LookupOK then begin
                                EmplLedgEntries.GetRecord(EmplLedgEntry);
                                Validate("Applies-to C/V/E Entry No.", EmplLedgEntry."Entry No.");
                            end else
                                Error('');
                        end;
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
        }
        field(26; "Amount(Pay.Order Curr.) to Pay"; Decimal)
        {
            AutoFormatExpression = "Payment Order Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount(Pay.Order Curr.) to Pay';
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
        }
        field(40; IBAN; Code[50])
        {
            Caption = 'IBAN';
        }
        field(45; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(50; "Amount Must Be Checked"; Boolean)
        {
            Caption = 'Amount Must Be Checked';
        }
        field(70; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(80; "Original Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
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
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';
            Editable = false;
        }
        field(150; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            OptionCaption = ' ,,Purchase';
            OptionMembers = " ",,Purchase;
        }
        field(151; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
        }
        field(152; "Letter Line No."; Integer)
        {
            Caption = 'Letter Line No.';
        }
        field(190; "VAT Uncertainty Payer"; Boolean)
        {
            Caption = 'VAT Uncertainty Payer';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(191; "Public Bank Account"; Boolean)
        {
            Caption = 'Public Bank Account';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(200; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
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
}