codeunit 131301 "Library - ERM Unapply"
{
    // Branching extension library for CU131300: Library - ERM
    // 
    // Encapsulates functionality for unapplying customer and vendor ledger entries because the function
    // GenJnlPostLine.UnapplyVendLedgEntry has different signatures in AU,NZ builds.


    trigger OnRun()
    begin
    end;

    procedure UnapplyCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        UnapplyCustomerLedgerEntryBase(CustLedgerEntry, 0D);
    end;

    procedure UnapplyVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        UnapplyVendorLedgerEntryBase(VendorLedgerEntry, 0D);
    end;

    procedure UnapplyEmployeeLedgerEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        UnapplyEmployeeLedgerEntryBase(EmployeeLedgerEntry, 0D);
    end;

    procedure UnapplyCustomerLedgerEntryBase(CustLedgerEntry: Record "Cust. Ledger Entry"; PostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        DetailedCustLedgEntry.FindFirst();
        with DetailedCustLedgEntry do begin
            if PostingDate = 0D then
                PostingDate := "Posting Date";
            SourceCodeSetup.Get();
            CustLedgerEntry.Get("Cust. Ledger Entry No.");
            GenJournalLine.Validate("Document No.", "Document No.");
            GenJournalLine.Validate("Posting Date", PostingDate);
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
            GenJournalLine.Validate("Account No.", "Customer No.");
            GenJournalLine.Validate(Correction, true);
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
            GenJournalLine.Validate(Description, CustLedgerEntry.Description);
            GenJournalLine.Validate("Shortcut Dimension 1 Code", CustLedgerEntry."Global Dimension 1 Code");
            GenJournalLine.Validate("Shortcut Dimension 2 Code", CustLedgerEntry."Global Dimension 2 Code");
            GenJournalLine.Validate("Posting Group", CustLedgerEntry."Customer Posting Group");
            GenJournalLine.Validate("Source Type", GenJournalLine."Source Type"::Vendor);
            GenJournalLine.Validate("Source No.", "Customer No.");
            GenJournalLine.Validate("Source Code", SourceCodeSetup."Unapplied Sales Entry Appln.");
            GenJournalLine.Validate("Source Currency Code", "Currency Code");
            GenJournalLine.Validate("System-Created Entry", true);
            GenJnlPostLine.UnapplyCustLedgEntry(GenJournalLine, DetailedCustLedgEntry);
        end;
    end;

    procedure UnapplyVendorLedgerEntryBase(VendorLedgerEntry: Record "Vendor Ledger Entry"; PostingDate: Date)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
        DetailedVendorLedgEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry.SetRange(Unapplied, false);
        DetailedVendorLedgEntry.FindFirst();
        with DetailedVendorLedgEntry do begin
            if PostingDate = 0D then
                PostingDate := "Posting Date";
            SourceCodeSetup.Get();
            VendorLedgerEntry.Get("Vendor Ledger Entry No.");
            GenJournalLine.Validate("Document No.", "Document No.");
            GenJournalLine.Validate("Posting Date", PostingDate);
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
            GenJournalLine.Validate("Account No.", "Vendor No.");
            GenJournalLine.Validate(Correction, true);
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
            GenJournalLine.Validate(Description, VendorLedgerEntry.Description);
            GenJournalLine.Validate("Shortcut Dimension 1 Code", VendorLedgerEntry."Global Dimension 1 Code");
            GenJournalLine.Validate("Shortcut Dimension 2 Code", VendorLedgerEntry."Global Dimension 2 Code");
            GenJournalLine.Validate("Posting Group", VendorLedgerEntry."Vendor Posting Group");
            GenJournalLine.Validate("Source Type", GenJournalLine."Source Type"::Vendor);
            GenJournalLine.Validate("Source No.", "Vendor No.");
            GenJournalLine.Validate("Source Code", SourceCodeSetup."Unapplied Purch. Entry Appln.");
            GenJournalLine.Validate("Source Currency Code", "Currency Code");
            GenJournalLine.Validate("System-Created Entry", true);
            GenJnlPostLine.UnapplyVendLedgEntry(GenJournalLine, DetailedVendorLedgEntry);
        end;
    end;

    procedure UnapplyEmployeeLedgerEntryBase(EmployeeLedgerEntry: Record "Employee Ledger Entry"; PostingDate: Date)
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        DetailedEmployeeLedgerEntry.SetRange("Entry Type", DetailedEmployeeLedgerEntry."Entry Type"::Application);
        DetailedEmployeeLedgerEntry.SetRange("Employee No.", EmployeeLedgerEntry."Employee No.");
        DetailedEmployeeLedgerEntry.SetRange("Document No.", EmployeeLedgerEntry."Document No.");
        DetailedEmployeeLedgerEntry.SetRange("Employee Ledger Entry No.", EmployeeLedgerEntry."Entry No.");
        DetailedEmployeeLedgerEntry.SetRange(Unapplied, false);
        DetailedEmployeeLedgerEntry.FindFirst();
        with DetailedEmployeeLedgerEntry do begin
            if PostingDate = 0D then
                PostingDate := "Posting Date";
            SourceCodeSetup.Get();
            EmployeeLedgerEntry.Get("Employee Ledger Entry No.");
            GenJournalLine.Validate("Document No.", "Document No.");
            GenJournalLine.Validate("Posting Date", PostingDate);
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Employee);
            GenJournalLine.Validate("Account No.", "Employee No.");
            GenJournalLine.Validate(Correction, true);
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
            GenJournalLine.Validate(Description, EmployeeLedgerEntry.Description);
            GenJournalLine.Validate("Posting Group", EmployeeLedgerEntry."Employee Posting Group");
            GenJournalLine.Validate("Shortcut Dimension 1 Code", EmployeeLedgerEntry."Global Dimension 1 Code");
            GenJournalLine.Validate("Shortcut Dimension 2 Code", EmployeeLedgerEntry."Global Dimension 2 Code");
            GenJournalLine.Validate("Source Type", GenJournalLine."Source Type"::Vendor);
            GenJournalLine.Validate("Source No.", "Employee No.");
            GenJournalLine.Validate("Source Code", SourceCodeSetup."Unapplied Purch. Entry Appln.");
            GenJournalLine.Validate("Source Currency Code", "Currency Code");
            GenJournalLine.Validate("System-Created Entry", true);
            GenJnlPostLine.UnapplyEmplLedgEntry(GenJournalLine, DetailedEmployeeLedgerEntry);
        end;
    end;
}

