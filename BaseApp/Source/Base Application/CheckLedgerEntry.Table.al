table 272 "Check Ledger Entry"
{
    Caption = 'Check Ledger Entry';
    DrillDownPageID = "Check Ledger Entries";
    LookupPageID = "Check Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(3; "Bank Account Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank;
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(9; "Check Date"; Date)
        {
            Caption = 'Check Date';
        }
        field(10; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        field(11; "Check Type"; Option)
        {
            Caption = 'Check Type';
            OptionCaption = 'Total Check,Partial Check';
            OptionMembers = "Total Check","Partial Check";
        }
        field(12; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            Caption = 'Bank Payment Type';
        }
        field(13; "Entry Status"; Option)
        {
            Caption = 'Entry Status';
            OptionCaption = ',Printed,Voided,Posted,Financially Voided,Test Print,Exported,Transmitted';
            OptionMembers = ,Printed,Voided,Posted,"Financially Voided","Test Print",Exported,Transmitted;
        }
        field(14; "Original Entry Status"; Option)
        {
            Caption = 'Original Entry Status';
            OptionCaption = ' ,Printed,Voided,Posted,Financially Voided';
            OptionMembers = " ",Printed,Voided,Posted,"Financially Voided";
        }
        field(15; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(16; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset";
        }
        field(17; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(18; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed;
        }
        field(19; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(20; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                                        "Statement No." = FIELD("Statement No."));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(21; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(22; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(23; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(24; "Data Exch. Voided Entry No."; Integer)
        {
            Caption = 'Data Exch. Voided Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(25; "Positive Pay Exported"; Boolean)
        {
            Caption = 'Positive Pay Exported';
        }
        field(26; "Record ID to Print"; RecordID)
        {
            Caption = 'Record ID to Print';
            DataClassification = SystemMetadata;
        }
        field(12400; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(12401; "Beneficiary Bank Code"; Code[20])
        {
            Caption = 'Beneficiary Bank Code';
            TableRelation = IF ("Bal. Account Type" = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Bal. Account No."))
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Bal. Account No."));
        }
        field(12402; "Payment Purpose"; Text[250])
        {
            Caption = 'Payment Purpose';
        }
        field(12403; "Cash Order Including"; Text[250])
        {
            Caption = 'Cash Order Including';
        }
        field(12404; "Cash Order Supplement"; Text[100])
        {
            Caption = 'Cash Order Supplement';
        }
        field(12405; "Payment Method"; Option)
        {
            Caption = 'Payment Method';
            OptionCaption = ' ,Mail,Telegraph,Through Moscow,Clearing';
            OptionMembers = " ",Mail,Telegraph,"Through Moscow",Clearing;
        }
        field(12406; "Payment Before Date"; Date)
        {
            Caption = 'Payment Before Date';
        }
        field(12407; "Payment Subsequence"; Text[2])
        {
            Caption = 'Payment Subsequence';
        }
        field(12408; "Payment Code"; Text[20])
        {
            Caption = 'Payment Code';
        }
        field(12409; "Payment Assignment"; Text[15])
        {
            Caption = 'Payment Assignment';
        }
        field(12410; "Payment Type"; Text[5])
        {
            Caption = 'Payment Type';
        }
        field(12411; "Payer BIC"; Text[20])
        {
            Caption = 'Payer BIC';
        }
        field(12412; "Payer Corr. Account No."; Text[20])
        {
            Caption = 'Payer Corr. Account No.';
        }
        field(12413; "Payer Bank Account No."; Text[20])
        {
            Caption = 'Payer Bank Account No.';
        }
        field(12414; "Payer Name"; Text[100])
        {
            Caption = 'Payer Name';
        }
        field(12415; "Payer Bank"; Text[100])
        {
            Caption = 'Payer Bank';
        }
        field(12416; "Payer VAT Reg. No."; Text[12])
        {
            Caption = 'Payer VAT Reg. No.';
        }
        field(12417; "Beneficiary BIC"; Text[20])
        {
            Caption = 'Beneficiary BIC';
        }
        field(12418; "Beneficiary Corr. Acc. No."; Text[20])
        {
            Caption = 'Beneficiary Corr. Acc. No.';
        }
        field(12419; "Beneficiary Bank Acc. No."; Text[20])
        {
            Caption = 'Beneficiary Bank Acc. No.';
        }
        field(12420; "Beneficiary Name"; Text[100])
        {
            Caption = 'Beneficiary Name';
        }
        field(12421; "Beneficiary VAT Reg No."; Text[12])
        {
            Caption = 'Beneficiary VAT Reg No.';
        }
        field(12422; "Cashier Report Printed"; Integer)
        {
            Caption = 'Cashier Report Printed';
            Editable = true;
        }
        field(12423; "Cashier Report No."; Code[20])
        {
            Caption = 'Cashier Report No.';
        }
        field(12424; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank;
            AutoFormatType = 1;
            Caption = 'Debit Amount';
        }
        field(12425; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank;
            AutoFormatType = 1;
            Caption = 'Credit Amount';
        }
        field(12427; "Bank Account Type"; Option)
        {
            CalcFormula = Lookup ("Bank Account"."Account Type" WHERE("No." = FIELD("Bank Account No.")));
            Caption = 'Bank Account Type';
            FieldClass = FlowField;
            OptionCaption = 'Bank Account,Cash Account';
            OptionMembers = "Bank Account","Cash Account";
        }
        field(12428; "Payer KPP"; Code[10])
        {
            Caption = 'Payer KPP';
        }
        field(12429; "Beneficiary KPP"; Code[10])
        {
            Caption = 'Beneficiary KPP';
        }
        field(12430; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = IF ("Bal. Account Type" = CONST(Customer)) "Customer Posting Group"
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) "Vendor Posting Group"
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account Posting Group"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "FA Posting Group";
        }
        field(12480; KBK; Code[20])
        {
            Caption = 'KBK';
            TableRelation = KBK;
        }
        field(12481; OKATO; Code[11])
        {
            Caption = 'OKATO';
            TableRelation = OKATO;
        }
        field(12482; "Period Code"; Option)
        {
            Caption = 'Period Code';
            OptionCaption = ' ,0,D1-payment for the first decade of month,D2-payment for the second decade of month,D3-payment for the third decade of month,MH-monthly payments,QT-quarter payment,HY-half-year payments,YR-year payments';
            OptionMembers = " ","0",D1,D2,D3,MH,QT,HY,YR;
        }
        field(12483; "Payment Reason Code"; Code[10])
        {
            Caption = 'Payment Reason Code';
            TableRelation = "Payment Order Code".Code WHERE(Type = CONST("Payment Reason"));
        }
        field(12484; "Reason Document No."; Code[10])
        {
            Caption = 'Reason Document No.';
        }
        field(12485; "Reason Document Date"; Date)
        {
            Caption = 'Reason Document Date';
        }
        field(12486; "Tax Payment Type"; Code[10])
        {
            Caption = 'Tax Payment Type';
            TableRelation = "Payment Order Code".Code WHERE(Type = CONST("Tax Payment Type"));
        }
        field(12487; "Tax Period"; Code[10])
        {
            Caption = 'Tax Period';
        }
        field(12488; "Reason Document Type"; Option)
        {
            Caption = 'Reason Document Type';
            OptionCaption = ' ,TR-Number of requirement about taxes payment from TA,RS-Number of decision about installment,OT-Number of decision about deferral,VU-Number of act of materials in court,PR-Number of decision about suspension of penalty,AP-Number of control act,AR-number of executive document';
            OptionMembers = " ",TR,RS,OT,VU,PR,AP,AR;
        }
        field(12489; "Taxpayer Status"; Option)
        {
            Caption = 'Taxpayer Status';
            OptionCaption = ' ,01-taxpayer (charges payer),02-tax agent,03-collector of taxes and charges,04-tax authority,05-service of officers of justice of Department of Justice of Russian Federation,06-participant of foreign-economic activity,07-tax authority,08-payer of other mandatory payments';
            OptionMembers = " ","01","02","03","04","05","06","07","08";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Check Date")
        {
        }
        key(Key3; "Bank Account No.", "Entry Status", "Check No.", "Statement Status")
        {
        }
        key(Key4; "Bank Account Ledger Entry No.")
        {
        }
        key(Key5; "Bank Account No.", Open)
        {
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        NothingToExportErr: Label 'There is nothing to export.';

    procedure GetCurrencyCodeFromBank(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc."No." then
            exit(BankAcc."Currency Code");

        if BankAcc.Get("Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;

    procedure CopyFromBankAccLedgEntry(BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        "Bank Account No." := BankAccLedgEntry."Bank Account No.";
        "Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
        "Posting Date" := BankAccLedgEntry."Posting Date";
        "Document Type" := BankAccLedgEntry."Document Type";
        "Document No." := BankAccLedgEntry."Document No.";
        "External Document No." := BankAccLedgEntry."External Document No.";
        Description := BankAccLedgEntry.Description;
        "Bal. Account Type" := BankAccLedgEntry."Bal. Account Type";
        "Bal. Account No." := BankAccLedgEntry."Bal. Account No.";
        "Entry Status" := "Entry Status"::Posted;
        Open := true;
        "User ID" := UserId;
        "Check Date" := BankAccLedgEntry."Posting Date";
        "Check No." := BankAccLedgEntry."Document No.";

        OnAfterCopyFromBankAccLedgEntry(Rec, BankAccLedgEntry);
    end;

    procedure ExportCheckFile()
    var
        BankAcc: Record "Bank Account";
    begin
        if not FindSet then
            Error(NothingToExportErr);

        if not BankAcc.Get("Bank Account No.") then
            Error(NothingToExportErr);

        if BankAcc.GetPosPayExportCodeunitID > 0 then
            CODEUNIT.Run(BankAcc.GetPosPayExportCodeunitID, Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Exp. Launcher Pos. Pay", Rec);
    end;

    procedure GetPayee() Payee: Text[100]
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                if "Bal. Account No." <> '' then begin
                    GLAccount.Get("Bal. Account No.");
                    Payee := GLAccount.Name;
                end;
            "Bal. Account Type"::Customer:
                if "Bal. Account No." <> '' then begin
                    Customer.Get("Bal. Account No.");
                    Payee := Customer.Name;
                end;
            "Bal. Account Type"::Vendor:
                if "Bal. Account No." <> '' then begin
                    Vendor.Get("Bal. Account No.");
                    Payee := Vendor.Name;
                end;
            "Bal. Account Type"::"Bank Account":
                if "Bal. Account No." <> '' then begin
                    BankAccount.Get("Bal. Account No.");
                    Payee := BankAccount.Name;
                end;
            "Bal. Account Type"::"Fixed Asset":
                Payee := "Bal. Account No.";
        end;
    end;

    procedure SetFilterBankAccNoOpen(BankAccNo: Code[20])
    begin
        Reset;
        SetCurrentKey("Bank Account No.", Open);
        SetRange("Bank Account No.", BankAccNo);
        SetRange(Open, true);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromBankAccLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;
}

