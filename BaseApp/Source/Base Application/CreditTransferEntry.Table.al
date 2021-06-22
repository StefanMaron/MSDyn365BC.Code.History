table 1206 "Credit Transfer Entry"
{
    Caption = 'Credit Transfer Entry';
    DataCaptionFields = "Account Type", "Account No.", "Transaction ID";
    DrillDownPageID = "Credit Transfer Reg. Entries";
    LookupPageID = "Credit Transfer Reg. Entries";

    fields
    {
        field(1; "Credit Transfer Register No."; Integer)
        {
            Caption = 'Credit Transfer Register No.';
            TableRelation = "Credit Transfer Register";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Customer,Vendor,Employee';
            OptionMembers = Customer,Vendor,Employee;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor;
        }
        field(5; "Applies-to Entry No."; Integer)
        {
            Caption = 'Applies-to Entry No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Cust. Ledger Entry"
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Ledger Entry";
        }
        field(6; "Transfer Date"; Date)
        {
            Caption = 'Transfer Date';
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(8; "Transfer Amount"; Decimal)
        {
            Caption = 'Transfer Amount';
        }
        field(9; "Transaction ID"; Text[35])
        {
            Caption = 'Transaction ID';
        }
        field(10; Canceled; Boolean)
        {
            CalcFormula = Exist ("Credit Transfer Register" WHERE("No." = FIELD("Credit Transfer Register No."),
                                                                  Status = CONST(Canceled)));
            Caption = 'Canceled';
            FieldClass = FlowField;
        }
        field(11; "Recipient Bank Acc. No."; Code[50])
        {
            Caption = 'Recipient Bank Acc. No.';
        }
        field(12; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';
        }
    }

    keys
    {
        key(Key1; "Credit Transfer Register No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";

    procedure CreateNew(RegisterNo: Integer; EntryNo: Integer; GenJnlAccountType: Option; AccountNo: Code[20]; LedgerEntryNo: Integer; TransferDate: Date; CurrencyCode: Code[10]; TransferAmount: Decimal; TransActionID: Text[35]; RecipientBankAccount: Code[20]; MessageToRecipient: Text[140])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        "Credit Transfer Register No." := RegisterNo;
        if EntryNo = 0 then begin
            SetRange("Credit Transfer Register No.", RegisterNo);
            LockTable();
            if FindLast then;
            "Entry No." += 1;
        end else
            "Entry No." := EntryNo;
        Init;
        GenJnlLine.Init();
        case GenJnlAccountType of
            GenJnlLine."Account Type"::Customer:
                "Account Type" := "Account Type"::Customer;
            GenJnlLine."Account Type"::Vendor:
                "Account Type" := "Account Type"::Vendor;
            GenJnlLine."Account Type"::Employee:
                "Account Type" := "Account Type"::Employee;
        end;
        "Account No." := AccountNo;
        "Applies-to Entry No." := LedgerEntryNo;
        "Transfer Date" := TransferDate;
        "Currency Code" := CurrencyCode;
        "Transfer Amount" := TransferAmount;
        "Transaction ID" := TransActionID;
        "Recipient Bank Acc. No." := RecipientBankAccount;
        "Message to Recipient" := MessageToRecipient;
        Insert;
    end;

    procedure CreditorName(): Text
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
    begin
        if "Account No." = '' then
            exit('');
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if Customer.Get("Account No.") then
                        exit(Customer.Name);
                end;
            "Account Type"::Vendor:
                begin
                    if Vendor.Get("Account No.") then
                        exit(Vendor.Name);
                end;
            "Account Type"::Employee:
                begin
                    if Employee.Get("Account No.") then
                        exit(Employee.FullName);
                end;
        end;
        exit('');
    end;

    procedure GetRecipientIBANOrBankAccNo(GetIBAN: Boolean): Text
    var
        CustomerBankAccount: Record "Customer Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        Employee: Record Employee;
    begin
        if "Account No." = '' then
            exit('');

        case "Account Type" of
            "Account Type"::Customer:
                if CustomerBankAccount.Get("Account No.", "Recipient Bank Acc. No.") then begin
                    if GetIBAN then
                        exit(CustomerBankAccount.IBAN);

                    exit(CustomerBankAccount."Bank Account No.");
                end;
            "Account Type"::Vendor:
                if VendorBankAccount.Get("Account No.", "Recipient Bank Acc. No.") then begin
                    if GetIBAN then
                        exit(VendorBankAccount.IBAN);

                    exit(VendorBankAccount."Bank Account No.");
                end;
            "Account Type"::Employee:
                if Employee.Get("Account No.") then begin
                    if GetIBAN then
                        exit(Employee.IBAN);

                    exit(Employee."Bank Account No.");
                end;
        end;

        exit('');
    end;

    local procedure GetAppliesToEntry(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        CVLedgerEntryBuffer.Init();
        if "Applies-to Entry No." = 0 then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if CustLedgerEntry."Entry No." <> "Applies-to Entry No." then
                        if CustLedgerEntry.Get("Applies-to Entry No.") then
                            CustLedgerEntry.CalcFields(Amount, "Remaining Amount")
                        else
                            Clear(CustLedgerEntry);
                    CVLedgerEntryBuffer.CopyFromCustLedgEntry(CustLedgerEntry)
                end;
            "Account Type"::Vendor:
                begin
                    if VendLedgerEntry."Entry No." <> "Applies-to Entry No." then
                        if VendLedgerEntry.Get("Applies-to Entry No.") then
                            VendLedgerEntry.CalcFields(Amount, "Remaining Amount")
                        else
                            Clear(VendLedgerEntry);
                    CVLedgerEntryBuffer.CopyFromVendLedgEntry(VendLedgerEntry)
                end;
            "Account Type"::Employee:
                begin
                    if EmployeeLedgerEntry."Entry No." <> "Applies-to Entry No." then
                        if EmployeeLedgerEntry.Get("Applies-to Entry No.") then
                            EmployeeLedgerEntry.CalcFields(Amount, "Remaining Amount")
                        else
                            Clear(EmployeeLedgerEntry);
                    CVLedgerEntryBuffer.CopyFromEmplLedgEntry(EmployeeLedgerEntry)
                end;
        end;
    end;

    procedure AppliesToEntryDocumentNo(): Code[20]
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer."Document No.");
    end;

    procedure AppliesToEntryDescription(): Text
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer.Description);
    end;

    procedure AppliesToEntryPostingDate(): Date
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer."Posting Date");
    end;

    procedure AppliesToEntryCurrencyCode(): Code[10]
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer."Currency Code");
    end;

    procedure AppliesToEntryAmount(): Decimal
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer.Amount);
    end;

    procedure AppliesToEntryRemainingAmount(): Decimal
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer."Remaining Amount");
    end;
}

