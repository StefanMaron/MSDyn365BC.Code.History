codeunit 31050 CreditManagement
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        ApplyDocManuallyMsg: Label 'Document was not applied with 0 remaining amount, you have to apply it manually.';

    [Scope('OnPrem')]
    procedure SuggestCreditLines(var CreditHeader: Record "Credit Header")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CreditLine: Record "Credit Line";
        CreditProposal: Page "Credit Proposal";
        LineNo: Integer;
    begin
        CreditHeader.TestField(Status, CreditHeader.Status::Open);
        CreditHeader.TestField("Posting Date");
        CreditProposal.SetCreditHeader(CreditHeader);
        if CreditProposal.RunModal = ACTION::LookupOK then begin
            CreditProposal.GetLedgEntries(CustLedgEntry, VendLedgEntry);

            Clear(CreditLine);
            CreditLine.SetRange("Credit No.", CreditHeader."No.");
            LineNo := 10000;
            if CreditLine.FindLast then
                LineNo := CreditLine."Line No." + 10000;

            if CustLedgEntry.Find('-') then begin
                repeat
                    Clear(CreditLine);
                    CreditLine.Init();
                    CreditLine.Validate("Credit No.", CreditHeader."No.");
                    CreditLine."Line No." := LineNo;
                    CreditLine.Validate("Source Type", CreditLine."Source Type"::Customer);
                    CreditLine.Validate("Source Entry No.", CustLedgEntry."Entry No.");
                    CreditLine.Insert();
                    LineNo += 10000;
                until CustLedgEntry.Next = 0;
            end;
            if VendLedgEntry.Find('-') then begin
                repeat
                    Clear(CreditLine);
                    CreditLine.Init();
                    CreditLine.Validate("Credit No.", CreditHeader."No.");
                    CreditLine."Line No." := LineNo;
                    CreditLine.Validate("Source Type", CreditLine."Source Type"::Vendor);
                    CreditLine.Validate("Source Entry No.", VendLedgEntry."Entry No.");
                    CreditLine.Insert();
                    LineNo += 10000;
                until VendLedgEntry.Next = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetAppliesToID(CreditLine: Record "Credit Line"; AppliesToID: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        case CreditLine."Source Type" of
            CreditLine."Source Type"::Customer:
                begin
                    CustLedgEntry.Get(CreditLine."Source Entry No.");
                    CustLedgEntry.TestField(Prepayment, false);
                    CustLedgEntry.TestField("Prepayment Type", CustLedgEntry."Prepayment Type"::" ");
                    if AppliesToID <> '' then begin
                        CustLedgEntry.Validate("Applies-to ID", AppliesToID);
                        CustLedgEntry."Amount to Apply" := CreditLine.Amount;
                    end else begin
                        CustLedgEntry."Applies-to ID" := AppliesToID;
                        CustLedgEntry."Amount to Apply" := 0;
                    end;
                    CustLedgEntry.Modify();
                end;
            CreditLine."Source Type"::Vendor:
                begin
                    VendLedgEntry.Get(CreditLine."Source Entry No.");
                    VendLedgEntry.TestField(Prepayment, false);
                    VendLedgEntry.TestField("Prepayment Type", VendLedgEntry."Prepayment Type"::" ");

                    if AppliesToID <> '' then begin
                        VendLedgEntry.Validate("Applies-to ID", AppliesToID);
                        VendLedgEntry."Amount to Apply" := CreditLine.Amount;
                    end else begin
                        VendLedgEntry."Applies-to ID" := AppliesToID;
                        VendLedgEntry."Amount to Apply" := 0;
                    end;
                    VendLedgEntry.Modify();
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure BalanceCredits(CreditHeader: Record "Credit Header")
    var
        CreditLine: Record "Credit Line";
        Amt: Decimal;
    begin
        CreditHeader.TestField(Status, CreditHeader.Status::Open);
        CreditLine.SetRange("Credit No.", CreditHeader."No.");
        CreditLine.CalcSums("Amount (LCY)");

        if CreditLine."Amount (LCY)" = 0 then
            exit;

        Amt := CreditLine."Amount (LCY)";

        CreditLine.Reset();
        CreditLine.SetRange("Credit No.", CreditHeader."No.");
        CreditLine.SetRange("Manual Change Only", false);
        if CreditLine.FindSet then
            repeat
                if ((CreditLine."Amount (LCY)" > 0) and (Amt > 0)) or
                   ((CreditLine."Amount (LCY)" < 0) and (Amt < 0))
                then begin
                    if Abs(Amt) >= Abs(CreditLine."Amount (LCY)") then begin
                        Amt -= CreditLine."Amount (LCY)";
                        CreditLine.Amount := 0;
                        CreditLine."Remaining Amount" := CreditLine."Ledg. Entry Remaining Amount";
                        CreditLine.ConvertLCYAmounts;
                    end else begin
                        CreditLine.Validate("Amount (LCY)", CreditLine."Amount (LCY)" - Amt);
                        Amt := 0;
                    end;

                    CreditLine.Modify(true);
                end;
            until (CreditLine.Next = 0) or (Amt = 0);

        if Amt <> 0 then
            Message(ApplyDocManuallyMsg);
    end;
}

