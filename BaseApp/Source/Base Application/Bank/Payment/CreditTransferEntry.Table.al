namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 1206 "Credit Transfer Entry"
{
    Caption = 'Credit Transfer Entry';
    DataCaptionFields = "Account Type", "Account No.", "Transaction ID";
    DrillDownPageID = "Credit Transfer Reg. Entries";
    LookupPageID = "Credit Transfer Reg. Entries";
    DataClassification = CustomerContent;

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
        field(3; "Account Type"; Enum "Credit Transfer Account Type")
        {
            Caption = 'Account Type';
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor;
        }
        field(5; "Applies-to Entry No."; Integer)
        {
            Caption = 'Applies-to Entry No.';
            TableRelation = if ("Account Type" = const(Customer)) "Cust. Ledger Entry"
            else
            if ("Account Type" = const(Vendor)) "Vendor Ledger Entry";
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
            CalcFormula = exist("Credit Transfer Register" where("No." = field("Credit Transfer Register No."),
                                                                  Status = const(Canceled)));
            Caption = 'Canceled';
            FieldClass = FlowField;
        }
        field(11; "Recipient Bank Acc. No."; Code[50])
        {
            Caption = 'Recipient Bank Account';
        }
        field(12; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';
        }
        field(13; "Recipient IBAN"; Code[50])
        {
            Caption = 'Recipient IBAN';
        }
        field(14; "Recipient Bank Account No."; Code[30])
        {
            Caption = 'Recipient Bank Account No.';
        }
        field(15; "Recipient Name"; Text[100])
        {
            Caption = 'Recipient Name';
            DataClassification = EndUserIdentifiableInformation;
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

    procedure CreateNew(RegisterNo: Integer; EntryNo: Integer; GenJnlAccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LedgerEntryNo: Integer; TransferDate: Date; CurrencyCode: Code[10]; TransferAmount: Decimal; TransActionID: Text[35]; RecipientBankAccount: Code[20]; MessageToRecipient: Text[140])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        "Credit Transfer Register No." := RegisterNo;
        if EntryNo = 0 then begin
            SetRange("Credit Transfer Register No.", RegisterNo);
            LockTable();
            if FindLast() then;
            "Entry No." += 1;
        end else
            "Entry No." := EntryNo;
        Init();
        GenJnlLine.Init();
        case GenJnlAccountType of
            GenJnlLine."Account Type"::Customer:
                "Account Type" := "Account Type"::Customer;
            GenJnlLine."Account Type"::Vendor:
                "Account Type" := "Account Type"::Vendor;
            GenJnlLine."Account Type"::Employee:
                "Account Type" := "Account Type"::Employee;
        end;
        OnCreateNewOnAfterInitAccountType(Rec, GenJnlAccountType);

        "Account No." := AccountNo;
        "Applies-to Entry No." := LedgerEntryNo;
        "Transfer Date" := TransferDate;
        "Currency Code" := CurrencyCode;
        "Transfer Amount" := TransferAmount;
        "Transaction ID" := TransActionID;
        "Recipient Bank Acc. No." := RecipientBankAccount;
        "Message to Recipient" := MessageToRecipient;
        FillRecipientData();
        Insert();
    end;

    procedure FillRecipientData()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        Employee: Record Employee;
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        if "Account No." = '' then begin
            "Recipient Name" := '';
            "Recipient IBAN" := '';
            "Recipient Bank Account No." := '';
            exit;
        end;
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if "Recipient Name" = '' then
                        if Customer.Get("Account No.") then
                            "Recipient Name" := Customer.Name;
                    if ("Recipient IBAN" = '') and ("Recipient Bank Account No." = '') then
                        if CustomerBankAccount.Get("Account No.", "Recipient Bank Acc. No.") then begin
                            "Recipient IBAN" := CustomerBankAccount.IBAN;
                            "Recipient Bank Account No." := CustomerBankAccount."Bank Account No.";
                        end;
                end;
            "Account Type"::Vendor:
                begin
                    if "Recipient Name" = '' then
                        if Vendor.Get("Account No.") then
                            "Recipient Name" := Vendor.Name;
                    if ("Recipient IBAN" = '') and ("Recipient Bank Account No." = '') then
                        if VendorBankAccount.Get("Account No.", "Recipient Bank Acc. No.") then begin
                            "Recipient IBAN" := VendorBankAccount.IBAN;
                            "Recipient Bank Account No." := VendorBankAccount."Bank Account No.";
                        end;
                end;
            "Account Type"::Employee:
                begin
                    if "Recipient Name" = '' then
                        if Employee.Get("Account No.") then
                            "Recipient Name" := Employee.FullName();
                    if ("Recipient IBAN" = '') and ("Recipient Bank Account No." = '') then begin
                        "Recipient IBAN" := Employee.IBAN;
                        "Recipient Bank Account No." := Employee."Bank Account No.";
                    end;
                end;
        end;

        OnAfterFillRecipientData(Rec);
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

        OnAfterGetAppliesToEntry(Rec, CVLedgerEntryBuffer);
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillRecipientData(var CreditTransferEntry: Record "Credit Transfer Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliesToEntry(var CreditTransferEntry: Record "Credit Transfer Entry"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewOnAfterInitAccountType(var CreditTransferEntry: Record "Credit Transfer Entry"; GenJnlAccountType: Enum "Gen. Journal Account Type")
    begin
    end;
}

