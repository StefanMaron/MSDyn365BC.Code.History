codeunit 143051 "Library - Credit"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        CreditMgt: Codeunit CreditManagement;
        ReleaseCreditDocument: Codeunit "Release Credit Document";

    [Scope('OnPrem')]
    procedure CreateCreditHeader(var CreditHeader: Record "Credit Header"; CompanyNo: Code[20])
    begin
        CreditHeader.Init;
        CreditHeader.Insert(true);

        UpdateCreditHeader(CreditHeader, CompanyNo, WorkDate);
    end;

    [Scope('OnPrem')]
    procedure CreateCreditLine(var CreditLine: Record "Credit Line"; CreditHeader: Record "Credit Header"; SourceType: Option; SourceEntryNo: Integer)
    var
        RecRef: RecordRef;
    begin
        CreditLine.Init;
        CreditLine.Validate("Credit No.", CreditHeader."No.");
        RecRef.GetTable(CreditLine);
        CreditLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, CreditLine.FieldNo("Line No.")));
        CreditLine.Validate("Source Type", SourceType);
        CreditLine.Validate("Source Entry No.", SourceEntryNo);
        CreditLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure FindCustomerLedgerEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; DocumentType: Option)
    begin
        CustLedgEntry.Reset;
        CustLedgEntry.SetRange("Document Type", DocumentType);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Amount on Credit (LCY)", 0);
        CustLedgEntry.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure FindVendorLedgerEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; DocumentType: Option)
    begin
        VendLedgEntry.Reset;
        VendLedgEntry.SetRange("Document Type", DocumentType);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange("Amount on Credit (LCY)", 0);
        VendLedgEntry.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure RunPostCredit(var CreditHeader: Record "Credit Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Credit - Post", CreditHeader);
    end;

    [Scope('OnPrem')]
    procedure RunPrintCredit(var CreditHeader: Record "Credit Header"; ShowRequestPage: Boolean)
    var
        CreditHeader2: Record "Credit Header";
    begin
        CreditHeader2.Get(CreditHeader."No.");
        CreditHeader2.SetRecFilter;
        CreditHeader2.PrintRecords(ShowRequestPage);
    end;

    [Scope('OnPrem')]
    procedure RunPrintPostedCredit(var PostedCreditHeader: Record "Posted Credit Header"; ShowRequestPage: Boolean)
    var
        PostedCreditHeader2: Record "Posted Credit Header";
    begin
        PostedCreditHeader2.Get(PostedCreditHeader."No.");
        PostedCreditHeader2.SetRecFilter;
        PostedCreditHeader2.PrintRecords(ShowRequestPage);
    end;

    [Scope('OnPrem')]
    procedure RunReleaseCredit(var CreditHeader: Record "Credit Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Release Credit Document", CreditHeader);
    end;

    [Scope('OnPrem')]
    procedure RunReopenCredit(var CreditHeader: Record "Credit Header")
    begin
        ReleaseCreditDocument.Reopen(CreditHeader);
    end;

    [Scope('OnPrem')]
    procedure RunSuggestCreditLines(var CreditHeader: Record "Credit Header")
    begin
        CreditMgt.SuggestCreditLines(CreditHeader);
    end;

    [Scope('OnPrem')]
    procedure UpdateCreditHeader(var CreditHeader: Record "Credit Header"; CompanyNo: Code[20]; DocumentDate: Date)
    begin
        CreditHeader.Validate("Company No.", CompanyNo);
        CreditHeader.Validate("Document Date", DocumentDate);
        CreditHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateCreditLine(var CreditLine: Record "Credit Line"; Amount: Decimal)
    begin
        CreditLine.Validate("Amount (LCY)", Amount);
        CreditLine.Modify(true);
    end;
}

