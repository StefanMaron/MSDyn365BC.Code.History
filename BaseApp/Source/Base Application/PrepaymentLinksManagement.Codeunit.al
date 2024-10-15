#if not CLEAN19
codeunit 31032 "Prepayment Links Management"
{
    TableNo = "Advance Link Buffer";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    var
        TempAdvanceLinkBuf: Record "Advance Link Buffer" temporary;
        TempAdvanceLinkBufCurrLn: Record "Advance Link Buffer" temporary;
        AdvanceLinkBufDefEntry: Record "Advance Link Buffer";
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        LinkID: Code[20];
        LinkType: Option ,GenJnlLine;
        Text001Err: Label '%1 can''t be %2.', Comment = '%1=Fieldcaption account type;%2=account type';

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure FillBuf(var AdvanceLinkBuf: Record "Advance Link Buffer"; CustMode: Boolean)
    begin
        with AdvanceLinkBuf do begin
            Reset();
            DeleteAll();
            Clear(TempAdvanceLinkBufCurrLn);
            Clear(TempAdvanceLinkBuf);

            if CustMode then begin
                CollectSalesLetters(AdvanceLinkBuf);
                CollectSalesPayments(AdvanceLinkBuf);
            end else begin
                CollectPurchLetters(AdvanceLinkBuf);
                CollectPurchPayments(AdvanceLinkBuf);
            end;

            // Set Pointers
            SetFilters(AdvanceLinkBuf);
            if FindFirst() then
                TempAdvanceLinkBufCurrLn := AdvanceLinkBuf;
            Reset();
            if not IsEmpty() then begin
                AdvanceLinkBuf := AdvanceLinkBufDefEntry;
                if not Find() then
                    FindFirst();
                TempAdvanceLinkBuf := AdvanceLinkBuf;
                SetLinkingEntry(AdvanceLinkBuf, false);
            end;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        LinkType := LinkType::GenJnlLine;

        Clear(AdvanceLinkBufDefEntry);
        AdvanceLinkBufDefEntry."Entry Type" := AdvanceLinkBufDefEntry."Entry Type"::Payment;
        AdvanceLinkBufDefEntry."CV No." := GenJnlLine."Account No.";
        AdvanceLinkBufDefEntry."Remaining Amount" := GenJnlLine.Amount;
        AdvanceLinkBufDefEntry."Document No." := GenJnlLine."Document No.";
        AdvanceLinkBufDefEntry."Entry No." := 1;
        AdvanceLinkBufDefEntry."Currency Code" := GenJnlLine."Currency Code";
        AdvanceLinkBufDefEntry."Due Date" := GenJnlLine."Due Date";
        AdvanceLinkBufDefEntry."Posting Date" := GenJnlLine."Posting Date";
        AdvanceLinkBufDefEntry.Description := GenJnlLine.Description;
        AdvanceLinkBufDefEntry."External Document No." := GenJnlLine."External Document No.";
        AdvanceLinkBufDefEntry."Posting Date" := GenJnlLine."Posting Date";
        AdvanceLinkBufDefEntry."No." := AdvanceLinkBufDefEntry."CV No.";

        AdvanceLinkBufDefEntry."Link Code" := GenJnlLine."Advance Letter Link Code";
        case true of
            (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer),
          GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer:
                AdvanceLinkBufDefEntry."Source Type" := AdvanceLinkBufDefEntry."Source Type"::Customer;
            (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor),
          GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor:
                AdvanceLinkBufDefEntry."Source Type" := AdvanceLinkBufDefEntry."Source Type"::Vendor;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetLinkingCustPayment(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        Clear(AdvanceLinkBufDefEntry);
        AdvanceLinkBufDefEntry."Entry No." := CustLedgEntry."Entry No.";
        AdvanceLinkBufDefEntry."Document No." := CustLedgEntry."Document No.";
        AdvanceLinkBufDefEntry."Entry Type" := AdvanceLinkBufDefEntry."Entry Type"::Payment;
        AdvanceLinkBufDefEntry."CV No." := CustLedgEntry."Customer No.";
        AdvanceLinkBufDefEntry."Currency Code" := CustLedgEntry."Currency Code";
        AdvanceLinkBufDefEntry."Posting Date" := CustLedgEntry."Posting Date";
        AdvanceLinkBufDefEntry."Due Date" := CustLedgEntry."Due Date";
        AdvanceLinkBufDefEntry.Description := CustLedgEntry.Description;

        AdvanceLinkBufDefEntry."Source Type" := AdvanceLinkBufDefEntry."Source Type"::Customer;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetLinkingVendPayment(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        Clear(AdvanceLinkBufDefEntry);
        AdvanceLinkBufDefEntry."Entry No." := VendLedgEntry."Entry No.";
        AdvanceLinkBufDefEntry."Document No." := VendLedgEntry."Document No.";
        AdvanceLinkBufDefEntry."Entry Type" := AdvanceLinkBufDefEntry."Entry Type"::Payment;
        AdvanceLinkBufDefEntry."CV No." := VendLedgEntry."Vendor No.";
        AdvanceLinkBufDefEntry."Currency Code" := VendLedgEntry."Currency Code";
        AdvanceLinkBufDefEntry."Posting Date" := VendLedgEntry."Posting Date";
        AdvanceLinkBufDefEntry."Due Date" := VendLedgEntry."Due Date";
        AdvanceLinkBufDefEntry.Description := VendLedgEntry.Description;

        AdvanceLinkBufDefEntry."Source Type" := AdvanceLinkBufDefEntry."Source Type"::Vendor;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetLinkingSalesLetter(SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        Clear(AdvanceLinkBufDefEntry);
        AdvanceLinkBufDefEntry."Entry No." := 0;
        AdvanceLinkBufDefEntry."Document No." := SalesAdvanceLetterHeader."No.";
        AdvanceLinkBufDefEntry."Entry Type" := AdvanceLinkBufDefEntry."Entry Type"::"Letter Line";
        AdvanceLinkBufDefEntry."CV No." := SalesAdvanceLetterHeader."Bill-to Customer No.";
        AdvanceLinkBufDefEntry."Currency Code" := SalesAdvanceLetterHeader."Currency Code";
        AdvanceLinkBufDefEntry."Posting Date" := SalesAdvanceLetterHeader."Document Date";

        AdvanceLinkBufDefEntry."Source Type" := AdvanceLinkBufDefEntry."Source Type"::Customer;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetLinkingPurchLetter(PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        Clear(AdvanceLinkBufDefEntry);
        AdvanceLinkBufDefEntry."Entry No." := 0;
        AdvanceLinkBufDefEntry."Document No." := PurchAdvanceLetterHeader."No.";
        AdvanceLinkBufDefEntry."Entry Type" := AdvanceLinkBufDefEntry."Entry Type"::"Letter Line";
        AdvanceLinkBufDefEntry."CV No." := PurchAdvanceLetterHeader."Pay-to Vendor No.";
        AdvanceLinkBufDefEntry."Currency Code" := PurchAdvanceLetterHeader."Currency Code";
        AdvanceLinkBufDefEntry."Posting Date" := PurchAdvanceLetterHeader."Document Date";

        AdvanceLinkBufDefEntry."Source Type" := AdvanceLinkBufDefEntry."Source Type"::Vendor;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetLinkingSalesLetterLine(SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
        Clear(AdvanceLinkBufDefEntry);
        AdvanceLinkBufDefEntry."Entry No." := SalesAdvanceLetterLine."Line No.";
        AdvanceLinkBufDefEntry."Entry Type" := AdvanceLinkBufDefEntry."Entry Type"::"Letter Line";
        AdvanceLinkBufDefEntry."Document No." := SalesAdvanceLetterLine."Letter No.";
        AdvanceLinkBufDefEntry."CV No." := SalesAdvanceLetterLine."Bill-to Customer No.";
        AdvanceLinkBufDefEntry."Currency Code" := SalesAdvanceLetterLine."Currency Code";
        AdvanceLinkBufDefEntry."Posting Date" := SalesAdvanceLetterLine."Advance Due Date";
        AdvanceLinkBufDefEntry."Due Date" := SalesAdvanceLetterLine."Advance Due Date";
        AdvanceLinkBufDefEntry.Description := SalesAdvanceLetterLine.Description;

        AdvanceLinkBufDefEntry."Source Type" := AdvanceLinkBufDefEntry."Source Type"::Customer;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetLinkingPurchLetterLine(PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
        Clear(AdvanceLinkBufDefEntry);
        AdvanceLinkBufDefEntry."Entry No." := PurchAdvanceLetterLine."Line No.";
        AdvanceLinkBufDefEntry."Entry Type" := AdvanceLinkBufDefEntry."Entry Type"::"Letter Line";
        AdvanceLinkBufDefEntry."Document No." := PurchAdvanceLetterLine."Letter No.";
        AdvanceLinkBufDefEntry."CV No." := PurchAdvanceLetterLine."Pay-to Vendor No.";
        AdvanceLinkBufDefEntry."Currency Code" := PurchAdvanceLetterLine."Currency Code";
        AdvanceLinkBufDefEntry."Posting Date" := PurchAdvanceLetterLine."Advance Due Date";
        AdvanceLinkBufDefEntry."Due Date" := PurchAdvanceLetterLine."Advance Due Date";
        AdvanceLinkBufDefEntry.Description := PurchAdvanceLetterLine.Description;

        AdvanceLinkBufDefEntry."Source Type" := AdvanceLinkBufDefEntry."Source Type"::Vendor;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetLinkingEntry(var AdvanceLinkBuf: Record "Advance Link Buffer"; Manual: Boolean)
    begin
        with AdvanceLinkBuf do begin
            if IsEmpty() then
                exit;
            if Manual and (LinkType = LinkType::GenJnlLine) then
                exit;

            if Manual then
                TempAdvanceLinkBufCurrLn := AdvanceLinkBuf;

            Reset();
            if TempAdvanceLinkBuf."Linking Entry" then begin
                UpdateLinkingEntry(AdvanceLinkBuf, false);
                TempAdvanceLinkBuf := TempAdvanceLinkBufCurrLn;
                TempAdvanceLinkBufCurrLn := AdvanceLinkBuf;
            end;
            UpdateLinkingEntry(AdvanceLinkBuf, true);
            TempAdvanceLinkBuf := AdvanceLinkBuf;

            SetFilters(AdvanceLinkBuf);
            if TempAdvanceLinkBufCurrLn."Entry No." = 0 then
                if FindFirst() then
                    TempAdvanceLinkBufCurrLn := AdvanceLinkBuf;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure UpdateLinkingEntry(var AdvanceLinkBuf: Record "Advance Link Buffer"; Set: Boolean)
    begin
        with AdvanceLinkBuf do begin
            AdvanceLinkBuf := TempAdvanceLinkBuf;
            Find();
            "Linking Entry" := Set;
            if Set then begin
                AdvanceLinkBufDefEntry := AdvanceLinkBuf;
                "Amount To Link" := -CalcBalance(AdvanceLinkBuf);
            end;
            Modify();
            TempAdvanceLinkBuf := AdvanceLinkBuf;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetLinkIDToRec(var AdvanceLinkBuf: Record "Advance Link Buffer"; AdvanceLinkBuf2: Record "Advance Link Buffer"): Boolean
    var
        Diff: Decimal;
    begin
        with AdvanceLinkBuf do begin
            Reset();

            SetRange("Entry Type", AdvanceLinkBuf2."Entry Type");
            SetRange("Document No.", AdvanceLinkBuf2."Document No.");
            if AdvanceLinkBuf2."Entry No." <> 0 then
                SetRange("Entry No.", AdvanceLinkBuf2."Entry No.");
            if IsEmpty() then
                exit(false);

            FindFirst();
            "Links-To ID" := TempAdvanceLinkBuf."Document No.";
            Modify();

            if AdvanceLinkBuf2."Amount To Link" <> 0 then begin
                if AdvanceLinkBuf2."Amount To Link" * "Remaining Amount" < 0 then
                    AdvanceLinkBuf2."Amount To Link" := -AdvanceLinkBuf2."Amount To Link";
                Diff := AdvanceLinkBuf2."Amount To Link"
            end else
                Diff := "Remaining Amount";
            SetLinkID(AdvanceLinkBuf, Diff);
            exit(true);
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SetLinkID(var AdvanceLinkBuf: Record "Advance Link Buffer"; Difference: Decimal)
    var
        Limit: Decimal;
        Manual: Boolean;
        Adjustment: Decimal;
    begin
        with AdvanceLinkBuf do begin
            if IsEmpty() then
                exit;
            TempAdvanceLinkBufCurrLn := AdvanceLinkBuf;
            if AdvanceLinkBufDefEntry."Link Code" = '' then
                GetLinkID();

            Limit := TempAdvanceLinkBuf."Remaining Amount" - TempAdvanceLinkBuf."Amount To Link";
            Manual := Difference <> 0;

            if AdvanceLinkBufDefEntry."Link Code" <> '' then
                if "Link Code" = AdvanceLinkBufDefEntry."Link Code" then
                    if Manual then begin
                        if "Remaining Amount" / Difference < 0 then // negative adjustment
                            Limit := TempAdvanceLinkBuf."Amount To Link";
                    end else begin
                        Limit := TempAdvanceLinkBuf."Amount To Link";
                        Difference := -"Amount To Link";
                    end
                else begin
                    if "Link Code" <> '' then
                        Adjustment := "Amount To Link" - Difference;
                    if Manual then
                        Difference := "Amount To Link"
                    else
                        Difference := "Remaining Amount";
                end
            else
                if "Links-To ID" = TempAdvanceLinkBuf."Document No." then
                    if Manual then begin
                        if "Remaining Amount" / Difference < 0 then // negative adjustment
                            Limit := TempAdvanceLinkBuf."Amount To Link";
                    end else begin
                        Limit := TempAdvanceLinkBuf."Amount To Link";
                        Difference := -"Amount To Link";
                    end
                else begin
                    if "Links-To ID" <> '' then
                        Adjustment := "Amount To Link" - Difference;
                    if Manual then
                        Difference := "Amount To Link"
                    else
                        Difference := "Remaining Amount";
                end;

            if Abs(Difference) > Abs(Limit) then
                Difference := -Limit;

            Reset();
            UpdateAmount(AdvanceLinkBuf, TempAdvanceLinkBuf, -Difference);
            UpdateAmount(AdvanceLinkBuf, TempAdvanceLinkBufCurrLn, Difference - Adjustment);
            SetFilters(AdvanceLinkBuf);
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure CalcBalance(var AdvanceLinkBuf: Record "Advance Link Buffer") Balance: Decimal
    var
        AdvanceLinkBuf2: Record "Advance Link Buffer";
    begin
        with AdvanceLinkBuf do begin
            AdvanceLinkBuf2 := AdvanceLinkBuf;
            AdvanceLinkBuf2.SetView(GetView());
            Reset();
            if AdvanceLinkBufDefEntry."Link Code" <> '' then begin
                SetCurrentKey("Link Code", "Linking Entry");
                SetFilter("Link Code", TempAdvanceLinkBuf."Link Code");
            end else begin
                SetCurrentKey("Links-To ID", "Linking Entry");
                SetFilter("Links-To ID", TempAdvanceLinkBuf."Document No.");
            end;
            SetRange("Linking Entry", false);
            if FindSet() then
                repeat
                    Balance := Balance + "Amount To Link";
                until Next() = 0;
            SetView(AdvanceLinkBuf2.GetView());
            AdvanceLinkBuf := AdvanceLinkBuf2;
            if Find() then;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure LinkEntries(var AdvanceLinkBuf: Record "Advance Link Buffer"; CustMode: Boolean)
    begin
        with AdvanceLinkBuf do begin
            Reset();
            SetCurrentKey("Links-To ID", "Linking Entry");
            SetFilter("Links-To ID", TempAdvanceLinkBuf."Links-To ID");
            if CustMode then
                SalesPostAdvances.HandleLinksBuf(AdvanceLinkBuf)
            else
                PurchPostAdvances.HandleLinksBuf(AdvanceLinkBuf);
            FillBuf(AdvanceLinkBuf, CustMode);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFilters(var AdvanceLinkBuf: Record "Advance Link Buffer")
    begin
        with AdvanceLinkBuf do begin
            Reset();
            SetRange("Linking Entry", false);
            if TempAdvanceLinkBuf."Entry Type" = TempAdvanceLinkBuf."Entry Type"::"Letter Line" then
                SetRange("Entry Type", "Entry Type"::Payment)
            else
                SetRange("Entry Type", "Entry Type"::"Letter Line");
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetLinkingEntry(var AdvanceLinkBuf: Record "Advance Link Buffer")
    begin
        AdvanceLinkBuf := TempAdvanceLinkBuf;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetLinkID(): Code[20]
    begin
        LinkID := AdvanceLinkBufDefEntry."Document No.";
        if LinkID = '' then
            LinkID := CopyStr(UserId, 1, MaxStrLen(LinkID));
        if LinkID = '' then
            LinkID := '***';
        exit(LinkID);
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure RunCustPaymentLink(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        SetAdvanceLink: Page "Set Advance Link";
    begin
        with CustLedgEntry do begin
            TestField("Prepayment Type", "Prepayment Type"::Advance);
            TestField("Open For Advance Letter", true);
            SetAdvanceLink.SetLinkingCustPayment(CustLedgEntry);
            SetAdvanceLink.LookupMode(false);
            SetAdvanceLink.RunModal();
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure RunVendPaymentLink(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        SetAdvanceLink: Page "Set Advance Link";
    begin
        with VendLedgEntry do begin
            TestField("Prepayment Type", "Prepayment Type"::Advance);
            TestField("Open For Advance Letter", true);
            SetAdvanceLink.SetLinkingVendPayment(VendLedgEntry);
            SetAdvanceLink.LookupMode(false);
            SetAdvanceLink.RunModal();
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure RunSalesLetterLink(var SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    var
        SetAdvanceLink: Page "Set Advance Link";
    begin
        with SalesAdvanceLetterLine do begin
            TestField(Status, Status::"Pending Advance Payment");
            SetAdvanceLink.SetLinkingSalesLetterLine(SalesAdvanceLetterLine);
            SetAdvanceLink.LookupMode(false);
            SetAdvanceLink.RunModal();
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure RunPurchLetterLink(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    var
        SetAdvanceLink: Page "Set Advance Link";
    begin
        with PurchAdvanceLetterLine do begin
            TestField(Status, Status::"Pending Advance Payment");
            SetAdvanceLink.SetLinkingPurchLetterLine(PurchAdvanceLetterLine);
            SetAdvanceLink.LookupMode(false);
            SetAdvanceLink.RunModal();
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure CollectSalesLetters(var AdvanceLinkBuf: Record "Advance Link Buffer")
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        TotalAmount: Decimal;
        AdjAmount: Decimal;
    begin
        with AdvanceLinkBuf do begin
            SalesAdvanceLetterLine.SetRange("Bill-to Customer No.", AdvanceLinkBufDefEntry."CV No.");
            SalesAdvanceLetterLine.SetRange("Currency Code", AdvanceLinkBufDefEntry."Currency Code");
            SalesAdvanceLetterLine.SetFilter("Amount To Link", '>%1', 0);
            OnCollectSalesLettersOnAfterSetSalesAdvanceLetterLineFilters(SalesAdvanceLetterLine);
            if SalesAdvanceLetterLine.FindSet() then
                repeat
                    Init();
                    "Entry No." := SalesAdvanceLetterLine."Line No.";
                    if AdvanceLinkBufDefEntry."Entry No." = 0 then
                        if AdvanceLinkBufDefEntry."Document No." = "Document No." then
                            AdvanceLinkBufDefEntry."Entry No." := SalesAdvanceLetterLine."Line No.";
                    "Entry Type" := "Entry Type"::"Letter Line";
                    "Document No." := SalesAdvanceLetterLine."Letter No.";
                    "CV No." := SalesAdvanceLetterLine."Bill-to Customer No.";
                    Type := Type::"G/L Account";
                    "No." := SalesAdvanceLetterLine."No.";
                    "Currency Code" := SalesAdvanceLetterLine."Currency Code";
                    "Remaining Amount" := SalesAdvanceLetterLine."Amount To Link";
                    "Posting Date" := SalesAdvanceLetterLine."Advance Due Date";
                    "Due Date" := SalesAdvanceLetterLine."Advance Due Date";
                    Description := SalesAdvanceLetterLine.Description;
                    if AdvanceLinkBufDefEntry."Link Code" <> '' then begin
                        if SalesAdvanceLetterLine."Link Code" = AdvanceLinkBufDefEntry."Link Code" then begin
                            TotalAmount := TotalAmount + Abs(SalesAdvanceLetterLine."Amount Linked To Journal Line");
                            AdjAmount := Abs(TotalAmount) - Abs(AdvanceLinkBufDefEntry."Remaining Amount");
                            if AdjAmount > 0 then
                                TotalAmount := TotalAmount - AdjAmount
                            else
                                AdjAmount := 0;
                        end
                    end else
                        if SalesAdvanceLetterLine."Applies-to ID" = AdvanceLinkBufDefEntry."Document No." then begin
                            TotalAmount := TotalAmount + Abs(SalesAdvanceLetterLine."Amount Linked To Journal Line");
                            AdjAmount := Abs(TotalAmount) - Abs(AdvanceLinkBufDefEntry."Remaining Amount");
                            if AdjAmount > 0 then
                                TotalAmount := TotalAmount - AdjAmount
                            else
                                AdjAmount := 0;
                        end;

                    "Amount To Link" := SalesAdvanceLetterLine."Amount Linked To Journal Line" - AdjAmount;
                    if "Amount To Link" <> 0 then
                        if AdvanceLinkBufDefEntry."Link Code" <> '' then
                            "Link Code" := SalesAdvanceLetterLine."Link Code"
                        else
                            "Links-To ID" := SalesAdvanceLetterLine."Applies-to ID";

                    "Source Type" := "Source Type"::Customer;

                    Insert();
                until SalesAdvanceLetterLine.Next() = 0;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure CollectPurchLetters(var AdvanceLinkBuf: Record "Advance Link Buffer")
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        TotalAmount: Decimal;
        AdjAmount: Decimal;
    begin
        with AdvanceLinkBuf do begin
            PurchAdvanceLetterLine.SetRange("Pay-to Vendor No.", AdvanceLinkBufDefEntry."CV No.");
            PurchAdvanceLetterLine.SetRange("Currency Code", AdvanceLinkBufDefEntry."Currency Code");
            PurchAdvanceLetterLine.SetFilter("Amount To Link", '>%1', 0);
            OnCollectPurchLettersOnAfterSetPurchAdvanceLetterLineFilters(PurchAdvanceLetterLine);
            if PurchAdvanceLetterLine.FindSet() then
                repeat
                    Init();
                    "Entry No." := PurchAdvanceLetterLine."Line No.";
                    if AdvanceLinkBufDefEntry."Entry No." = 0 then
                        if AdvanceLinkBufDefEntry."Document No." = "Document No." then
                            AdvanceLinkBufDefEntry."Entry No." := PurchAdvanceLetterLine."Line No.";
                    "Entry Type" := "Entry Type"::"Letter Line";
                    "Document No." := PurchAdvanceLetterLine."Letter No.";
                    "CV No." := PurchAdvanceLetterLine."Pay-to Vendor No.";
                    Type := Type::"G/L Account";
                    "No." := PurchAdvanceLetterLine."No.";
                    "Currency Code" := PurchAdvanceLetterLine."Currency Code";
                    "Remaining Amount" := -PurchAdvanceLetterLine."Amount To Link";
                    "Due Date" := PurchAdvanceLetterLine."Advance Due Date";
                    "Posting Date" := PurchAdvanceLetterLine."Advance Due Date";
                    Description := PurchAdvanceLetterLine.Description;
                    if AdvanceLinkBufDefEntry."Link Code" <> '' then begin
                        if PurchAdvanceLetterLine."Link Code" = AdvanceLinkBufDefEntry."Link Code" then begin
                            TotalAmount := TotalAmount + Abs(PurchAdvanceLetterLine."Amount Linked To Journal Line");
                            AdjAmount := Abs(TotalAmount) - Abs(AdvanceLinkBufDefEntry."Remaining Amount");
                            if AdjAmount > 0 then
                                TotalAmount := TotalAmount - AdjAmount
                            else
                                AdjAmount := 0;
                        end
                    end else
                        if PurchAdvanceLetterLine."Applies-to ID" = AdvanceLinkBufDefEntry."Document No." then begin
                            TotalAmount := TotalAmount + Abs(PurchAdvanceLetterLine."Amount Linked To Journal Line");
                            AdjAmount := Abs(TotalAmount) - Abs(AdvanceLinkBufDefEntry."Remaining Amount");
                            if AdjAmount > 0 then
                                TotalAmount := TotalAmount - AdjAmount
                            else
                                AdjAmount := 0;
                        end;
                    "Amount To Link" := PurchAdvanceLetterLine."Amount Linked To Journal Line" + AdjAmount;
                    if "Amount To Link" <> 0 then
                        if AdvanceLinkBufDefEntry."Link Code" <> '' then
                            "Link Code" := PurchAdvanceLetterLine."Link Code"
                        else
                            "Links-To ID" := PurchAdvanceLetterLine."Applies-to ID";
                    "Source Type" := "Source Type"::Vendor;

                    Insert();
                until PurchAdvanceLetterLine.Next() = 0;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure CollectSalesPayments(var AdvanceLinkBuf: Record "Advance Link Buffer")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        LinkedNotUsedAmt: Decimal;
    begin
        with AdvanceLinkBuf do
            if LinkType = LinkType::GenJnlLine then begin
                Init();
                TransferFields(AdvanceLinkBufDefEntry);
                Type := Type::Customer;
                Insert();
            end else begin
                CustLedgEntry.SetRange("Open For Advance Letter", true);
                CustLedgEntry.SetRange("Customer No.", AdvanceLinkBufDefEntry."CV No.");
                CustLedgEntry.SetRange("Currency Code", AdvanceLinkBufDefEntry."Currency Code");
                CustLedgEntry.SetRange(Positive, false);
                if CustLedgEntry.FindSet() then
                    repeat
                        Init();
                        "Entry No." := CustLedgEntry."Entry No.";
                        "Document No." := CustLedgEntry."Document No.";
                        "Entry Type" := "Entry Type"::Payment;
                        "CV No." := CustLedgEntry."Customer No.";
                        Type := Type::Customer;
                        "No." := "CV No.";
                        "Currency Code" := CustLedgEntry."Currency Code";
                        CustLedgEntry.CalcFields("Remaining Amount to Link");
                        "Remaining Amount" := CustLedgEntry."Remaining Amount to Link";

                        CustLedgEntry.CalcFields("Remaining Amount");
                        LinkedNotUsedAmt := CustLedgEntry.CalcLinkAdvAmount();
                        if Abs(CustLedgEntry."Remaining Amount" + LinkedNotUsedAmt) < Abs(CustLedgEntry."Remaining Amount to Link") then
                            "Remaining Amount" := CustLedgEntry."Remaining Amount" + LinkedNotUsedAmt;

                        "Due Date" := CustLedgEntry."Due Date";
                        "Posting Date" := CustLedgEntry."Posting Date";
                        Description := CustLedgEntry.Description;
                        "External Document No." := CustLedgEntry."External Document No.";
                        "CV No." := CustLedgEntry."Customer No.";

                        "Source Type" := "Source Type"::Customer;

                        Insert();
                    until CustLedgEntry.Next() = 0;
            end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure CollectPurchPayments(var AdvanceLinkBuf: Record "Advance Link Buffer")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        LinkedNotUsedAmt: Decimal;
    begin
        with AdvanceLinkBuf do
            if LinkType = LinkType::GenJnlLine then begin
                Init();
                TransferFields(AdvanceLinkBufDefEntry);
                Type := Type::Vendor;
                Insert();
            end else begin
                VendLedgEntry.SetRange("Open For Advance Letter", true);
                VendLedgEntry.SetRange("Vendor No.", AdvanceLinkBufDefEntry."CV No.");
                VendLedgEntry.SetRange("Currency Code", AdvanceLinkBufDefEntry."Currency Code");
                VendLedgEntry.SetRange(Positive, true);
                if VendLedgEntry.FindSet() then
                    repeat
                        Init();
                        "Entry No." := VendLedgEntry."Entry No.";
                        "Document No." := VendLedgEntry."Document No.";
                        "Entry Type" := "Entry Type"::Payment;
                        "CV No." := VendLedgEntry."Vendor No.";
                        Type := Type::Vendor;
                        "No." := "CV No.";
                        "Currency Code" := VendLedgEntry."Currency Code";
                        VendLedgEntry.CalcFields("Remaining Amount to Link");
                        "Remaining Amount" := VendLedgEntry."Remaining Amount to Link";

                        VendLedgEntry.CalcFields("Remaining Amount");
                        LinkedNotUsedAmt := VendLedgEntry.CalcLinkAdvAmount();
                        if Abs(VendLedgEntry."Remaining Amount" + LinkedNotUsedAmt) <
                           Abs(VendLedgEntry."Remaining Amount to Link")
                        then
                            "Remaining Amount" := VendLedgEntry."Remaining Amount" + LinkedNotUsedAmt;

                        "Due Date" := VendLedgEntry."Due Date";
                        "Posting Date" := VendLedgEntry."Posting Date";
                        Description := VendLedgEntry.Description;
                        "External Document No." := VendLedgEntry."External Document No.";
                        "CV No." := VendLedgEntry."Vendor No.";

                        "Source Type" := "Source Type"::Vendor;

                        Insert();
                    until VendLedgEntry.Next() = 0;
            end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure UpdateAmount(var AdvanceLinkBuf: Record "Advance Link Buffer"; var AdvanceLinkBuf2: Record "Advance Link Buffer"; Amount: Decimal)
    begin
        with AdvanceLinkBuf do begin
            AdvanceLinkBuf := AdvanceLinkBuf2;
            Find();
            "Amount To Link" := "Amount To Link" + Amount;
            if AdvanceLinkBufDefEntry."Link Code" <> '' then begin
                if "Amount To Link" = 0 then
                    "Link Code" := ''
                else
                    "Link Code" := AdvanceLinkBufDefEntry."Link Code";
            end else
                if "Amount To Link" = 0 then
                    "Links-To ID" := ''
                else
                    "Links-To ID" := LinkID;
            Modify();
            AdvanceLinkBuf2 := AdvanceLinkBuf;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure SaveLinkIDToLetterLines(var AdvanceLinkBuf: Record "Advance Link Buffer"; Cust: Boolean)
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        OnBeforeSaveLinkIDToLetterLines(AdvanceLinkBuf);
        with AdvanceLinkBuf do begin
            Reset();
            SetCurrentKey("Links-To ID", "Linking Entry");
            SetRange("Linking Entry", false);
            if FindSet() then
                repeat
                    if Cust then begin
                        if SalesAdvanceLetterLine.Get("Document No.", "Entry No.") then begin
                            if AdvanceLinkBufDefEntry."Link Code" <> '' then
                                SalesAdvanceLetterLine."Link Code" := "Link Code"
                            else
                                SalesAdvanceLetterLine."Applies-to ID" := "Links-To ID";
                            SalesAdvanceLetterLine."Amount Linked To Journal Line" := "Amount To Link";
                            SalesAdvanceLetterLine.Modify();
                            OnSaveLinkIDToLetterLinesOnAfterModifySalesAdvanceLetterLine(AdvanceLinkBuf, AdvanceLinkBufDefEntry);
                        end;
                    end else
                        if PurchAdvanceLetterLine.Get("Document No.", "Entry No.") then begin
                            if AdvanceLinkBufDefEntry."Link Code" <> '' then
                                PurchAdvanceLetterLine."Link Code" := "Link Code"
                            else
                                PurchAdvanceLetterLine."Applies-to ID" := "Links-To ID";
                            PurchAdvanceLetterLine."Amount Linked To Journal Line" := "Amount To Link";
                            PurchAdvanceLetterLine.Modify();
                            OnSaveLinkIDToLetterLinesOnAfterModifyPurchAdvanceLetterLine(AdvanceLinkBuf, AdvanceLinkBufDefEntry);
                        end;
                until Next() = 0;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    procedure LinkWholeSalesLetter(CustCode: Code[20]; CurrencyCode: Code[10]; LinkCode: Code[30]; var CustPostingGroup: Code[20]) Result: Decimal
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        if LinkCode = '' then
            exit;
        SalesAdvanceLetterHeader.SetCurrentKey("Bill-to Customer No.");
        SalesAdvanceLetterHeader.SetRange("Bill-to Customer No.", CustCode);
        SalesAdvanceLetterHeader.SetRange("Currency Code", CurrencyCode);
        SalesAdvanceLetterHeader.SetFilter("Amount To Link", '>0');
        OnLinkWholeSalesLetterOnAfterSetSalesAdvanceLetterHeaderFilters(SalesAdvanceLetterHeader);
        if PAGE.RunModal(0, SalesAdvanceLetterHeader) = ACTION::LookupOK then begin
            CustPostingGroup := SalesAdvanceLetterHeader."Customer Posting Group";
            SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
            SalesAdvanceLetterLine.SetFilter("Amount To Link", '>0');
            OnLinkWholeSalesLetterOnBeforeFindSalesAdvanceLetterLine(SalesAdvanceLetterLine);
            if SalesAdvanceLetterLine.FindSet(true, false) then
                repeat
                    SalesAdvanceLetterLine.TestField("Link Code", '');
                    SalesAdvanceLetterLine.TestField("Amount Linked To Journal Line", 0);
                    SalesAdvanceLetterLine."Link Code" := LinkCode;
                    SalesAdvanceLetterLine."Amount Linked To Journal Line" := SalesAdvanceLetterLine."Amount To Link";
                    SalesAdvanceLetterLine.Modify();
                    Result := Result + SalesAdvanceLetterLine."Amount To Link";
                until SalesAdvanceLetterLine.Next() = 0;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    procedure UnLinkWholeSalesLetter(LinkCode: Code[30])
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        SalesAdvanceLetterLine2: Record "Sales Advance Letter Line";
    begin
        if LinkCode = '' then
            exit;
        SalesAdvanceLetterLine.SetCurrentKey("Link Code");
        SalesAdvanceLetterLine.SetRange("Link Code", LinkCode);
        if SalesAdvanceLetterLine.FindSet() then
            repeat
                SalesAdvanceLetterLine2 := SalesAdvanceLetterLine;
                SalesAdvanceLetterLine2."Link Code" := '';
                SalesAdvanceLetterLine2."Amount Linked To Journal Line" := 0;
                SalesAdvanceLetterLine2.Modify();
            until SalesAdvanceLetterLine.Next() = 0;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    procedure LinkWholePurchLetter(VendCode: Code[20]; CurrencyCode: Code[10]; LinkCode: Code[30]; var VendPostingGroup: Code[20]) Result: Decimal
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        if LinkCode = '' then
            exit;
        PurchAdvanceLetterHeader.SetCurrentKey("Pay-to Vendor No.");
        PurchAdvanceLetterHeader.SetRange("Pay-to Vendor No.", VendCode);
        PurchAdvanceLetterHeader.SetRange("Currency Code", CurrencyCode);
        PurchAdvanceLetterHeader.SetFilter("Amount To Link", '>0');
        OnLinkWholePurchLetterOnAfterSetPurchAdvanceLetterHeaderFilters(PurchAdvanceLetterHeader);
        if PAGE.RunModal(0, PurchAdvanceLetterHeader) = ACTION::LookupOK then begin
            VendPostingGroup := PurchAdvanceLetterHeader."Vendor Posting Group";
            PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
            PurchAdvanceLetterLine.SetFilter("Amount To Link", '>0');
            OnLinkWholePurchLetterOnAfterSetPurchAdvanceLetterLineFilters(PurchAdvanceLetterLine);
            if PurchAdvanceLetterLine.FindSet(true, false) then
                repeat
                    PurchAdvanceLetterLine.TestField("Link Code", '');
                    PurchAdvanceLetterLine.TestField("Amount Linked To Journal Line", 0);
                    PurchAdvanceLetterLine."Link Code" := LinkCode;
                    PurchAdvanceLetterLine."Amount Linked To Journal Line" := -PurchAdvanceLetterLine."Amount To Link";
                    PurchAdvanceLetterLine.Modify();
                    Result := Result + PurchAdvanceLetterLine."Amount To Link";
                until PurchAdvanceLetterLine.Next() = 0;
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    procedure UnLinkWholePurchLetter(LinkCode: Code[30])
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PurchAdvanceLetterLine2: Record "Purch. Advance Letter Line";
    begin
        if LinkCode = '' then
            exit;
        PurchAdvanceLetterLine.SetCurrentKey("Link Code");
        PurchAdvanceLetterLine.SetRange("Link Code", LinkCode);
        if PurchAdvanceLetterLine.FindSet() then
            repeat
                PurchAdvanceLetterLine2 := PurchAdvanceLetterLine;
                PurchAdvanceLetterLine2."Link Code" := '';
                PurchAdvanceLetterLine2."Amount Linked To Journal Line" := 0;
                PurchAdvanceLetterLine2.Modify();
            until PurchAdvanceLetterLine.Next() = 0;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure LinkGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        LinkCode: Code[30];
        AmountToLink: Decimal;
        PostingGroupCode: Code[20];
    begin
        GenJnlLine.TestField("Advance Letter Link Code", '');
        if not (GenJnlLine."Account Type" in
                [GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor])
        then
            Error(Text001Err, GenJnlLine.FieldCaption("Account Type"), GenJnlLine."Account Type");

        GenJnlLine.TestField("Account No.");
        GenJnlLine.TestField("Document Type", GenJnlLine."Document Type"::Payment);

        LinkCode := GenJnlLine."Document No." + ' ' + Format(GenJnlLine."Line No.");
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then
            AmountToLink := LinkWholeSalesLetter(GenJnlLine."Account No.",
                GenJnlLine."Currency Code",
                LinkCode,
                PostingGroupCode)
        else
            AmountToLink := LinkWholePurchLetter(GenJnlLine."Account No.",
                GenJnlLine."Currency Code",
                LinkCode,
                PostingGroupCode);
        if AmountToLink <> 0 then begin
            GenJnlLine.Validate(Prepayment, true);
            GenJnlLine.TestField("Prepayment Type", GenJnlLine."Prepayment Type"::Advance);
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then
                GenJnlLine.Validate(Amount, -AmountToLink)
            else
                GenJnlLine.Validate(Amount, AmountToLink);
            GenJnlLine.Validate("Advance Letter Link Code", LinkCode);
            GenJnlLine.Validate("Posting Group", PostingGroupCode);
            OnLinkGenJnlLineOnBeforeModifyGenJnlLine(GenJnlLine);
            GenJnlLine.Modify();
        end;
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure UnLinkGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.TestField("Advance Letter Link Code");
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then
            UnLinkWholeSalesLetter(GenJnlLine."Advance Letter Link Code")
        else
            UnLinkWholePurchLetter(GenJnlLine."Advance Letter Link Code");
        GenJnlLine.Validate("Advance Letter Link Code", '');
        OnUnLinkGenJnlLineOnBeforeModifyGenJnlLine(GenJnlLine);
        GenJnlLine.Modify();
    end;

    [Obsolete('Replaced by Advance Payments Localization for Czech.', '19.0')]
    [Scope('OnPrem')]
    procedure GetLinkedPostingGroup(IsCust: Boolean; LinkCode: Code[30]) Result: Code[20]
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        SalesAdvPmtTemplate: Record "Sales Adv. Payment Template";
        PurchAdvPmtTemplate: Record "Purchase Adv. Payment Template";
        IsCheckUnique: Boolean;
    begin
        if IsCust then begin
            SalesAdvanceLetterLine.SetCurrentKey("Link Code");
            SalesAdvanceLetterLine.SetRange("Link Code", LinkCode);
            if SalesAdvanceLetterLine.FindSet() then
                repeat
                    SalesAdvanceLetterHeader.Get(SalesAdvanceLetterLine."Letter No.");
                    if SalesAdvanceLetterHeader."Template Code" <> '' then begin
                        SalesAdvPmtTemplate.Get(SalesAdvanceLetterHeader."Template Code");
                        IsCheckUnique := IsCheckUnique or SalesAdvPmtTemplate."Check Posting Group on Link";
                    end;
                    if Result = '' then
                        Result := SalesAdvanceLetterHeader."Customer Posting Group"
                    else
                        if Result <> SalesAdvanceLetterHeader."Customer Posting Group" then
                            if IsCheckUnique then
                                SalesAdvanceLetterHeader.TestField("Customer Posting Group", Result)
                            else
                                exit('');
                until SalesAdvanceLetterLine.Next() = 0;
        end else begin
            PurchAdvanceLetterLine.SetCurrentKey("Link Code");
            PurchAdvanceLetterLine.SetRange("Link Code", LinkCode);
            if PurchAdvanceLetterLine.FindSet() then
                repeat
                    PurchAdvanceLetterHeader.Get(PurchAdvanceLetterLine."Letter No.");
                    if PurchAdvanceLetterHeader."Template Code" <> '' then begin
                        PurchAdvPmtTemplate.Get(PurchAdvanceLetterHeader."Template Code");
                        IsCheckUnique := IsCheckUnique or SalesAdvPmtTemplate."Check Posting Group on Link";
                    end;
                    if Result = '' then
                        Result := PurchAdvanceLetterHeader."Vendor Posting Group"
                    else
                        if Result <> PurchAdvanceLetterHeader."Vendor Posting Group" then
                            if IsCheckUnique then
                                PurchAdvanceLetterHeader.TestField("Vendor Posting Group", Result)
                            else
                                exit('');
                until PurchAdvanceLetterLine.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectSalesLettersOnAfterSetSalesAdvanceLetterLineFilters(var SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectPurchLettersOnAfterSetPurchAdvanceLetterLineFilters(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkWholePurchLetterOnAfterSetPurchAdvanceLetterHeaderFilters(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkWholePurchLetterOnAfterSetPurchAdvanceLetterLineFilters(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkGenJnlLineOnBeforeModifyGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveLinkIDToLetterLines(AdvanceLinkBuffer: Record "Advance Link Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveLinkIDToLetterLinesOnAfterModifySalesAdvanceLetterLine(AdvanceLinkBuf: Record "Advance Link Buffer"; AdvanceLinkBufDefEntry: Record "Advance Link Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveLinkIDToLetterLinesOnAfterModifyPurchAdvanceLetterLine(AdvanceLinkBuf: Record "Advance Link Buffer"; AdvanceLinkBufDefEntry: Record "Advance Link Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkWholeSalesLetterOnAfterSetSalesAdvanceLetterHeaderFilters(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkWholeSalesLetterOnBeforeFindSalesAdvanceLetterLine(var SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnLinkGenJnlLineOnBeforeModifyGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
}
#endif