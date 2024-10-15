codeunit 31121 "EET Entry Management"
{
    Permissions = TableData "Posted Cash Document Header" = rm,
                  TableData "EET Entry" = rimd,
                  TableData "EET Entry Status" = rimd;

    trigger OnRun()
    begin
    end;

    var
        EETServiceSetup: Record "EET Service Setup";
        TempErrorMessage: Record "Error Message" temporary;
        TempBlob: Codeunit "Temp Blob";
        InputStream: InStream;
        OutputStream: OutStream;
        HasGotSetup: Boolean;
        MoreEETLinesDeniedErr: Label 'Cash document %1 %2 cannot contain more then one EET line.', Comment = '%1 = Cash Document Type;%2 = Cash Document No.';
        EntryDescriptionTxt: Label '%1 %2', Comment = '%1 = Applied Document Type;%2 = Applied Document No.';
        WarningsTxt: Label 'Warnings...';
        EETEntryAlreadyCanceledQst: Label 'The %1 No. %2 has been already canceled by Entry No. %3.\\Continue?', Comment = '%1 = Tablecaption;%2 =  EET Entry No..;%3 = Canceled by Entry No.';
        CancelByEETEntryNoMsg: Label 'Cancel by EET Entry No. %1.', Comment = '%1 = EET Entry No.';
        CancelEntryToEntryMsg: Label 'Cancel Entry to Original Entry No. %1.', Comment = '%1 = EET Entry No.';
        CancelByEETEntryNoQst: Label 'EET Entry No. %1 will be canceled.\Continue?', Comment = '%1 = EET Entry No.';

    [Scope('OnPrem')]
    procedure IsEETEnabled(): Boolean
    begin
        exit(EETServiceSetup.Get and EETServiceSetup.Enabled);
    end;

    [Scope('OnPrem')]
    procedure IsEETTransaction(CashDocHeader: Record "Cash Document Header"; CashDocLine: Record "Cash Document Line"): Boolean
    begin
        if IsEETCashRegister(CashDocHeader."Cash Desk No.") then begin
            if CashDocLine."Cash Desk Event" <> '' then
                exit(IsEETCashDeskEvent(CashDocLine));
            exit(IsEETCashDocLine(CashDocLine));
        end;
    end;

    local procedure IsEETCashDeskEvent(CashDocLine: Record "Cash Document Line"): Boolean
    var
        CashDeskEvent: Record "Cash Desk Event";
    begin
        if CashDocLine."Cash Desk Event" <> '' then
            CashDeskEvent.Get(CashDocLine."Cash Desk Event");
        exit(CashDeskEvent."EET Transaction");
    end;

    local procedure IsEETCashDocLine(CashDocLine: Record "Cash Document Line"): Boolean
    begin
        exit(
          IsInvoicePaymentCashDoc(CashDocLine) or
          IsCrMemoRefundCashDoc(CashDocLine) or
          IsAdvPaymentCashDoc(CashDocLine) or
          IsAdvRefundCashDoc(CashDocLine));
    end;

    local procedure IsInvoicePaymentCashDoc(CashDocLine: Record "Cash Document Line"): Boolean
    begin
        // Invoice payment
        exit(
          (CashDocLine."Account Type" = CashDocLine."Account Type"::Customer) and
          (CashDocLine."Document Type" = CashDocLine."Document Type"::Payment) and
          (CashDocLine."Applies-To Doc. Type" = CashDocLine."Applies-To Doc. Type"::Invoice) and
          (CashDocLine."Applies-To Doc. No." <> ''));
    end;

    local procedure IsCrMemoRefundCashDoc(CashDocLine: Record "Cash Document Line"): Boolean
    begin
        // Credit memo refund
        exit(
          (CashDocLine."Account Type" = CashDocLine."Account Type"::Customer) and
          (CashDocLine."Document Type" = CashDocLine."Document Type"::Refund) and
          (CashDocLine."Applies-To Doc. Type" = CashDocLine."Applies-To Doc. Type"::"Credit Memo") and
          (CashDocLine."Applies-To Doc. No." <> ''));
    end;

    local procedure IsAdvPaymentCashDoc(CashDocLine: Record "Cash Document Line"): Boolean
    begin
        // Advance payment
        exit(
          (CashDocLine."Account Type" = CashDocLine."Account Type"::Customer) and
          (CashDocLine."Document Type" = CashDocLine."Document Type"::Payment) and
          CashDocLine.Prepayment and
          (CashDocLine."Advance Letter Link Code" <> ''));
    end;

    local procedure IsAdvRefundCashDoc(CashDocLine: Record "Cash Document Line"): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Advance refund
        if (CashDocLine."Account Type" = CashDocLine."Account Type"::Customer) and
           (CashDocLine."Document Type" = CashDocLine."Document Type"::Refund) and
           (CashDocLine."Applies-To Doc. Type" = CashDocLine."Applies-To Doc. Type"::Payment) and
           (CashDocLine."Applies-To Doc. No." <> '')
        then
            if SalesCrMemoHeader.Get(CashDocLine."Applies-To Doc. No.") then
                exit(SalesCrMemoHeader."Prepayment Credit Memo");
    end;

    [Scope('OnPrem')]
    procedure IsEETCashRegister(CashDeskNo: Code[20]): Boolean
    var
        EETCashReg: Record "EET Cash Register";
        EETCashRegister: Boolean;
    begin
        EETCashRegister := FindEETCashRegister(CashDeskNo, EETCashReg);
        OnBeforeIsEETCashRegister(CashDeskNo, EETCashRegister);
        exit(EETCashRegister);
    end;

    [Scope('OnPrem')]
    procedure CheckCashDocument(var CashDocHeader: Record "Cash Document Header")
    var
        CashDocLine: Record "Cash Document Line";
        NoOfLines: Integer;
        OriginalDocumentAmount: Decimal;
    begin
        if not IsEETEnabled then
            exit;

        if not CashDocHeader.IsEETTransaction then
            exit;

        SetFilterCashDocumentLine(CashDocHeader, CashDocLine);
        NoOfLines := CashDocLine.Count();

        // All lines must be of EET
        CashDocLine.SetRange("EET Transaction", true);
        if CashDocLine.Count < NoOfLines then begin
            CashDocLine.SetRange("EET Transaction", false);
            CashDocLine.FindFirst;
            CashDocLine.TestField("EET Transaction");
        end;

        // If there is a line with cash desk event then all lines must be of cash desk event
        CashDocLine.SetFilter("Cash Desk Event", '<>%1', '');
        if not CashDocLine.IsEmpty then
            if CashDocLine.Count < NoOfLines then begin
                CashDocLine.SetRange("Cash Desk Event", '');
                CashDocLine.FindFirst;
                CashDocLine.TestField("Cash Desk Event");
            end;

        // If there is a line without cash desk event then must be with customer account type
        CashDocLine.SetRange("Cash Desk Event", '');
        CashDocLine.SetFilter("Account Type", '<>%1', CashDocLine."Account Type"::Customer);
        if CashDocLine.FindFirst then
            CashDocLine.TestField("Account Type", CashDocLine."Account Type"::Customer);

        // If there is a line with customer account type then number of lines must be only one
        CashDocLine.SetRange("Cash Desk Event");
        CashDocLine.SetRange("Account Type", CashDocLine."Account Type"::Customer);
        if CashDocLine.FindFirst then begin
            if NoOfLines > 1 then
                Error(MoreEETLinesDeniedErr, CashDocLine."Cash Document Type", CashDocLine."Cash Document No.");

            CashDocLine.TestField("Account Type", CashDocLine."Account Type"::Customer);
            if CashDocLine.Prepayment then
                CashDocLine.TestField("Advance Letter Link Code")
            else
                CashDocLine.TestField("Applies-To Doc. No.");

            OriginalDocumentAmount := GetOriginalDocumentAmount(CashDocLine);
            if CashDocLine."Amount Including VAT" > OriginalDocumentAmount then
                CashDocLine.TestField("Amount Including VAT", OriginalDocumentAmount);
        end;
    end;

    local procedure GetOriginalDocumentAmount(CashDocLine: Record "Cash Document Line"): Decimal
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        case true of
            IsAdvPaymentCashDoc(CashDocLine):
                begin
                    SetFilterSalesAdvanceLetterLine(CashDocLine, SalesAdvanceLetterLine);
                    SalesAdvanceLetterLine.CalcSums("Amount Including VAT");
                    exit(SalesAdvanceLetterLine."Amount Including VAT");
                end;
            IsInvoicePaymentCashDoc(CashDocLine),
            IsCrMemoRefundCashDoc(CashDocLine),
            IsAdvRefundCashDoc(CashDocLine):
                begin
                    FindCustLedgerEntryForAppliesDocument(CashDocLine, CustLedgerEntry);
                    CustLedgerEntry.CalcFields("Original Amount");
                    exit(Abs(CustLedgerEntry."Original Amount"));
                end;
            else
                exit(0);
        end;
    end;

    local procedure CreateEntryForCashDocument(CashDocHeader: Record "Cash Document Header"; PostedCashDocHeader: Record "Posted Cash Document Header"): Integer
    var
        VATEntry: Record "VAT Entry";
        TempVATEntry: Record "VAT Entry" temporary;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CashDocLine: Record "Cash Document Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        AdvanceLink: Record "Advance Link";
        EETCashReg: Record "EET Cash Register";
        EETEntry: Record "EET Entry";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        OriginalDocumentAmountLCY: Decimal;
        RoundingAmount: Decimal;
        Coeff: Decimal;
    begin
        FindEETCashRegister(CashDocHeader."Cash Desk No.", EETCashReg);
        EETCashReg.TestField("Receipt Serial Nos.");

        InitEntry(EETEntry);
        EETEntry."Source Type" := EETEntry."Source Type"::"Cash Desk";
        EETEntry."Source No." := CashDocHeader."Cash Desk No.";
        EETEntry."Document No." := CashDocHeader."No.";
        EETEntry."Business Premises Code" := EETCashReg."Business Premises Code";
        EETEntry."Cash Register Code" := EETCashReg.Code;
        EETEntry."Receipt Serial No." := NoSeriesMgt.GetNextNo(EETCashReg."Receipt Serial Nos.", Today, true);

        SetFilterCashDocumentLine(CashDocHeader, CashDocLine);
        CashDocLine.FindFirst;

        OriginalDocumentAmountLCY := 0;
        case true of
            IsInvoicePaymentCashDoc(CashDocLine):
                begin
                    EETEntry."Applied Document Type" := EETEntry."Applied Document Type"::Invoice;
                    EETEntry."Applied Document No." := CashDocLine."Applies-To Doc. No.";
                    FindCustLedgerEntryForAppliesDocument(CashDocLine, CustLedgEntry);
                    OriginalDocumentAmountLCY := CalculateOriginalAmtLCY(CustLedgEntry);
                    SetFilterVATEntry(CustLedgEntry."Document No.", CustLedgEntry."Posting Date", VATEntry);
                end;
            IsCrMemoRefundCashDoc(CashDocLine):
                begin
                    EETEntry."Applied Document Type" := EETEntry."Applied Document Type"::"Credit Memo";
                    EETEntry."Applied Document No." := CashDocLine."Applies-To Doc. No.";
                    FindCustLedgerEntryForAppliesDocument(CashDocLine, CustLedgEntry);
                    OriginalDocumentAmountLCY := CalculateOriginalAmtLCY(CustLedgEntry);
                    SetFilterVATEntry(CustLedgEntry."Document No.", CustLedgEntry."Posting Date", VATEntry);
                end;
            IsAdvPaymentCashDoc(CashDocLine):
                begin
                    CustLedgEntry.SetCurrentKey("Document No.", "Posting Date");
                    CustLedgEntry.SetRange("Customer No.", CashDocLine."Account No.");
                    CustLedgEntry.SetRange("Document No.", PostedCashDocHeader."No.");
                    CustLedgEntry.SetRange("Posting Date", PostedCashDocHeader."Posting Date");
                    CustLedgEntry.FindFirst;
                    AdvanceLink.SetCurrentKey("CV Ledger Entry No.");
                    AdvanceLink.SetRange("CV Ledger Entry No.", CustLedgEntry."Entry No.");
                    AdvanceLink.SetRange("Entry Type", AdvanceLink."Entry Type"::"Link To Letter");
                    AdvanceLink.FindFirst;
                    EETEntry."Applied Document Type" := EETEntry."Applied Document Type"::Prepayment;
                    EETEntry."Applied Document No." := AdvanceLink."Document No.";
                    if AdvanceLink."Invoice No." <> '' then
                        SetFilterVATEntry(AdvanceLink."Invoice No.", PostedCashDocHeader."Posting Date", VATEntry);
                end;
            IsAdvRefundCashDoc(CashDocLine):
                begin
                    SalesCrMemoHeader.Get(CashDocLine."Applies-To Doc. No.");
                    EETEntry."Applied Document Type" := EETEntry."Applied Document Type"::Prepayment;
                    EETEntry."Applied Document No." := SalesCrMemoHeader."Letter No.";
                    FindCustLedgerEntryForAppliesDocument(CashDocLine, CustLedgEntry);
                    OriginalDocumentAmountLCY := CalculateOriginalAmtLCY(CustLedgEntry);
                    VATEntry.SetCurrentKey(Type, "Advance Letter No.", "Advance Letter Line No.");
                    VATEntry.SetRange(Type, VATEntry.Type::Sale);
                    VATEntry.SetRange("Advance Letter No.", SalesCrMemoHeader."Letter No.");
                    VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
                    VATEntry.SetRange("Document No.", SalesCrMemoHeader."No.");
                    if VATEntry.FindLast then
                        VATEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
                end;
        end;

        CashDocHeader.CalcFields("Amount Including VAT (LCY)");
        EETEntry."Total Sales Amount" := -CashDocHeader.SignAmount * CashDocHeader."Amount Including VAT (LCY)";

        // Collect VAT entries of applied documents
        if VATEntry.HasFilter() then
            if VATEntry.FindSet() then
                repeat
                    TempVATEntry.Init();
                    TempVATEntry := VATEntry;
                    TempVATEntry.Insert();
                until VATEntry.Next() = 0;

        // Collect VAT entries of cash document
        RoundingAmount := 0;
        VATEntry.Reset();
        SetFilterVATEntry(PostedCashDocHeader."No.", PostedCashDocHeader."Posting Date", VATEntry);
        if VATEntry.FindSet() then
            repeat
                TempVATEntry.Init();
                TempVATEntry := VATEntry;
                TempVATEntry.Insert();
                // If the cash document applies the document then the VAT entry contains the rounding amount of cash document
                if OriginalDocumentAmountLCY <> 0 then
                    RoundingAmount := -(TempVATEntry.Base + TempVATEntry.Amount);
            until VATEntry.Next() = 0;

        // Calculate coefficient for partial payment
        Coeff := 1;
        if OriginalDocumentAmountLCY <> 0 then begin
            OriginalDocumentAmountLCY += RoundingAmount;
            if OriginalDocumentAmountLCY <> CashDocHeader."Amount Including VAT (LCY)" then
                Coeff := CashDocHeader."Amount Including VAT (LCY)" / OriginalDocumentAmountLCY;
        end;

        if TempVATEntry.FindSet() then
            repeat
                CalculateAmountsFromVATEntry(TempVATEntry, Coeff, EETEntry);
            until TempVATEntry.Next() = 0;

        RoundAmounts(EETEntry);

        if EETEntry."Applied Document No." <> '' then
            EETEntry.Description := StrSubstNo(EntryDescriptionTxt, EETEntry."Applied Document Type", EETEntry."Applied Document No.");

        EETEntry.Insert();

        SetEntryStatus(EETEntry, EETEntry."EET Status"::Created, '');

        exit(EETEntry."Entry No.");
    end;

    local procedure CalculateOriginalAmtLCY(CustLedgerEntry: Record "Cust. Ledger Entry"): Decimal
    begin
        CustLedgerEntry.CalcFields("Original Amt. (LCY)");
        exit(Abs(CustLedgerEntry."Original Amt. (LCY)"));
    end;

    local procedure CalculateAmountsFromVATEntry(VATEntry: Record "VAT Entry"; Coeff: Decimal; var EETEntry: Record "EET Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        AmountArt89: Decimal;
        AmountArt90: Decimal;
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        if (VATEntry."Entry No." = 0) or (VATEntry."Unrealized VAT Entry No." <> 0) then
            exit;

        VATEntry.Base := GetVATBaseFromVATEntry(VATEntry) * Coeff;
        VATEntry.Amount := GetVATAmountFromVATEntry(VATEntry) * Coeff;

        if VATEntry.Amount = 0 then begin
            EETEntry."Amount Exempted From VAT" += -VATEntry.Base;
            exit;
        end;

        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");

        case VATPostingSetup."Supplies Mode Code" of
            VATPostingSetup."Supplies Mode Code"::"par. 89":
                AmountArt89 := VATEntry.Base + VATEntry.Amount;
            VATPostingSetup."Supplies Mode Code"::"par. 90":
                AmountArt90 := VATEntry.Base + VATEntry.Amount;
            else begin
                    VATBase := VATEntry.Base;
                    VATAmount := VATEntry.Amount;
                end;
        end;

        EETEntry."Amount - Art.89" += -AmountArt89;

        case VATPostingSetup."VAT Rate" of
            VATPostingSetup."VAT Rate"::" ":
                EETEntry."Amount Exempted From VAT" += -(VATEntry.Base + VATEntry.Amount);
            VATPostingSetup."VAT Rate"::Base:
                begin
                    EETEntry."Amount (Basic) - Art.90" += -AmountArt90;
                    EETEntry."VAT Base (Basic)" += -VATBase;
                    EETEntry."VAT Amount (Basic)" += -VATAmount;
                end;
            VATPostingSetup."VAT Rate"::Reduced:
                begin
                    EETEntry."Amount (Reduced) - Art.90" += -AmountArt90;
                    EETEntry."VAT Base (Reduced)" += -VATBase;
                    EETEntry."VAT Amount (Reduced)" += -VATAmount;
                end;
            VATPostingSetup."VAT Rate"::"Reduced 2":
                begin
                    EETEntry."Amount (Reduced 2) - Art.90" += -AmountArt90;
                    EETEntry."VAT Base (Reduced 2)" += -VATBase;
                    EETEntry."VAT Amount (Reduced 2)" += -VATAmount;
                end;
        end;
    end;

    local procedure GetVATBaseFromVATEntry(VATEntry: Record "VAT Entry"): Decimal
    begin
        with VATEntry do begin
            if "Prepayment Type" = "Prepayment Type"::Advance then
                exit("Advance Base");
            if "Unrealized Base" <> 0 then
                exit("Unrealized Base");
            exit(Base);
        end;
    end;

    local procedure GetVATAmountFromVATEntry(VATEntry: Record "VAT Entry"): Decimal
    begin
        with VATEntry do begin
            if "Unrealized Amount" <> 0 then
                exit("Unrealized Amount");
            exit(Amount);
        end;
    end;

    local procedure RoundAmounts(var EETEntry: Record "EET Entry")
    begin
        with EETEntry do begin
            "Amount Exempted From VAT" := Round("Amount Exempted From VAT");
            "VAT Base (Basic)" := Round("VAT Base (Basic)");
            "VAT Amount (Basic)" := Round("VAT Amount (Basic)");
            "VAT Base (Reduced)" := Round("VAT Base (Reduced)");
            "VAT Amount (Reduced)" := Round("VAT Amount (Reduced)");
            "VAT Base (Reduced 2)" := Round("VAT Base (Reduced 2)");
            "VAT Amount (Reduced 2)" := Round("VAT Amount (Reduced 2)");
            "Amount - Art.89" := Round("Amount - Art.89");
            "Amount (Basic) - Art.90" := Round("Amount (Basic) - Art.90");
            "Amount (Reduced) - Art.90" := Round("Amount (Reduced) - Art.90");
            "Amount (Reduced 2) - Art.90" := Round("Amount (Reduced 2) - Art.90");
        end;
    end;

    [Scope('OnPrem')]
    procedure FindEETCashRegister(CashDeskNo: Code[20]; var EETCashReg: Record "EET Cash Register"): Boolean
    begin
        if CashDeskNo = '' then
            exit(false);
        EETCashReg.Reset();
        EETCashReg.SetCurrentKey("Register Type", "Register No.");
        EETCashReg.SetRange("Register Type", EETCashReg."Register Type"::"Cash Desk");
        EETCashReg.SetRange("Register No.", CashDeskNo);
        exit(EETCashReg.FindFirst);
    end;

    local procedure FindCustLedgerEntryForAppliesDocument(CashDocLine: Record "Cash Document Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        SetFilterCustLedgerEntryForAppliesDocument(CashDocLine, CustLedgerEntry);
        exit(CustLedgerEntry.FindFirst);
    end;

    local procedure SetFilterCashDocumentLine(CashDocHeader: Record "Cash Document Header"; var CashDocLine: Record "Cash Document Line")
    begin
        CashDocLine.Reset();
        CashDocLine.SetRange("Cash Desk No.", CashDocHeader."Cash Desk No.");
        CashDocLine.SetRange("Cash Document No.", CashDocHeader."No.");
        CashDocLine.SetRange("System-Created Entry", false);
        CashDocLine.SetFilter(Amount, '<>0');
    end;

    local procedure SetFilterSalesAdvanceLetterLine(CashDocLine: Record "Cash Document Line"; var SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
        SalesAdvanceLetterLine.SetRange("Link Code", CashDocLine."Advance Letter Link Code");
        SalesAdvanceLetterLine.SetRange("Currency Code", CashDocLine."Currency Code");
    end;

    local procedure SetFilterCustLedgerEntryForAppliesDocument(CashDocLine: Record "Cash Document Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange("Document Type", CashDocLine."Applies-To Doc. Type");
        CustLedgerEntry.SetRange("Document No.", CashDocLine."Applies-To Doc. No.");
        CustLedgerEntry.SetRange("Customer No.", CashDocLine."Account No.");
        CustLedgerEntry.SetRange("Currency Code", CashDocLine."Currency Code");
    end;

    local procedure SetFilterVATEntry(DocumentNo: Code[20]; PostingDate: Date; var VATEntry: Record "VAT Entry")
    begin
        VATEntry.SetCurrentKey("Document No.", "Posting Date");
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", PostingDate);
        if VATEntry.FindLast then
            VATEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
    end;

    [Scope('OnPrem')]
    procedure SetEntryStatus(var EETEntry: Record "EET Entry"; NewStatus: Option; NewDescription: Text)
    begin
        EETEntry.TestField("Entry No.");
        EETEntry."EET Status" := NewStatus;
        EETEntry."EET Status Last Changed" := CurrentDateTime;
        EETEntry.Modify();
        LogEntryStatus(EETEntry, NewDescription);
    end;

    local procedure LogEntryStatus(EETEntry: Record "EET Entry"; Description: Text)
    var
        EETEntryStatus: Record "EET Entry Status";
        ErrorMessage: Record "Error Message";
        NextEntryNo: Integer;
    begin
        EETEntry.TestField("Entry No.");
        EETEntryStatus.LockTable();
        NextEntryNo := EETEntryStatus.GetLastEntryNo() + 1;

        EETEntryStatus.Init();
        EETEntryStatus."Entry No." := NextEntryNo;
        EETEntryStatus."EET Entry No." := EETEntry."Entry No.";
        EETEntryStatus.Status := EETEntry."EET Status";
        EETEntryStatus."Change Datetime" := EETEntry."EET Status Last Changed";
        EETEntryStatus.Description := CopyStr(Description, 1, MaxStrLen(EETEntryStatus.Description));
        EETEntryStatus.Insert();

        if TempErrorMessage.ErrorMessageCount(TempErrorMessage."Message Type"::Warning) > 0 then
            if TempErrorMessage.FindSet then
                repeat
                    ErrorMessage := TempErrorMessage;
                    ErrorMessage.ID := 0;
                    ErrorMessage.Validate("Record ID", EETEntryStatus.RecordId);
                    ErrorMessage.Validate("Context Record ID", EETEntryStatus.RecordId);
                    ErrorMessage.Insert(true);
                until TempErrorMessage.Next = 0;
    end;

    local procedure InitEntry(var EETEntry: Record "EET Entry")
    var
        NextEntryNo: Integer;
    begin
        EETEntry.Reset();
        EETEntry.LockTable();
        NextEntryNo := EETEntry.GetLastEntryNo() + 1;
        EETEntry.Init();
        EETEntry."Entry No." := NextEntryNo;
        EETEntry."User ID" := UserId;
        EETEntry."Creation Datetime" := CurrentDateTime;
    end;

    local procedure GetSetup()
    begin
        if not HasGotSetup then
            EETServiceSetup.Get();
        HasGotSetup := true;
    end;

    [Scope('OnPrem')]
    procedure SendEntryToService(var EETEntry: Record "EET Entry"; VerificationMode: Boolean)
    begin
        EETEntry.TestField("Entry No.");
        TempErrorMessage.ClearLog;
        if not VerificationMode then
            SendEntryToRegister(EETEntry)
        else
            SendEntryToVerification(EETEntry);
    end;

    local procedure SendEntryToRegister(var EETEntry: Record "EET Entry")
    var
        EETServiceMgt: Codeunit "EET Service Mgt.";
    begin
        if EETEntry."EET Status" in [EETEntry."EET Status"::Created,
                                     EETEntry."EET Status"::Sent,
                                     EETEntry."EET Status"::Success,
                                     EETEntry."EET Status"::"Success with Warnings"]
        then
            EETEntry.FieldError("EET Status");

        PrepareEntryToSend(EETEntry);
        SetEntryStatus(EETEntry, EETEntry."EET Status"::Sent, '');

        if EETServiceMgt.SendRegisteredSalesDataMessage(EETEntry) then begin
            EETEntry."Fiscal Identification Code" := EETServiceMgt.GetFIKControlCode;

            if EETServiceMgt.HasWarnings then begin
                EETServiceMgt.CopyErrorMessageToTemp(TempErrorMessage);
                SetEntryStatus(EETEntry, EETEntry."EET Status"::"Success with Warnings", WarningsTxt);
            end else
                SetEntryStatus(EETEntry, EETEntry."EET Status"::Success, '');
        end else begin
            EETServiceMgt.CopyErrorMessageToTemp(TempErrorMessage);
            SetEntryStatus(EETEntry, EETEntry."EET Status"::Failure, EETServiceMgt.GetResponseText);
        end;
    end;

    local procedure SendEntryToVerification(var EETEntry: Record "EET Entry")
    var
        EETServiceMgt: Codeunit "EET Service Mgt.";
    begin
        if EETEntry."EET Status" in [EETEntry."EET Status"::Sent,
                                     EETEntry."EET Status"::"Sent to Verification",
                                     EETEntry."EET Status"::Success,
                                     EETEntry."EET Status"::"Success with Warnings"]
        then
            EETEntry.FieldError("EET Status");

        PrepareEntryToSend(EETEntry);
        SetEntryStatus(EETEntry, EETEntry."EET Status"::"Sent to Verification", '');

        EETServiceMgt.SetVerificationMode(true);
        if EETServiceMgt.SendRegisteredSalesDataMessage(EETEntry) then
            if EETServiceMgt.HasWarnings then begin
                EETServiceMgt.CopyErrorMessageToTemp(TempErrorMessage);
                SetEntryStatus(EETEntry, EETEntry."EET Status"::"Verified with Warnings", WarningsTxt);
            end else
                SetEntryStatus(EETEntry, EETEntry."EET Status"::Verified, EETServiceMgt.GetResponseText)
        else begin
            EETServiceMgt.CopyErrorMessageToTemp(TempErrorMessage);
            SetEntryStatus(EETEntry, EETEntry."EET Status"::Failure, EETServiceMgt.GetResponseText);
        end;
    end;

    local procedure PrepareEntryToSend(var EETEntry: Record "EET Entry")
    begin
        EETEntry."Message UUID" := CreateUUID;
    end;

    local procedure GenerateControlCodes(var EETEntry: Record "EET Entry")
    begin
        EETEntry.SaveSignatureCode(EETEntry.GenerateSignatureCode);
        EETEntry."Security Code (BKP)" := EETEntry.GenerateSecurityCode;
    end;

    [Scope('OnPrem')]
    procedure GenerateSignatureCodePlainText(var EETEntry: Record "EET Entry"): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        with EETEntry do
            exit(
              StrSubstNo('%1|%2|%3|%4|%5|%6',
                CompanyInformation."VAT Registration No.", GetBusinessPremisesId, GetCashRegisterNo,
                "Receipt Serial No.", FormatDateTime("Creation Datetime"), FormatDecimal("Total Sales Amount")));
    end;

    [Scope('OnPrem')]
    procedure GenerateSignatureCode(var EETEntry: Record "EET Entry"): Text
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateCZCode: Record "Certificate CZ Code";
        Base64Convert: Codeunit "Base64 Convert";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        CertificateCZCode.Get(EETEntry.GetCertificateCode);
        if not CertificateCZCode.LoadValidCertificate(IsolatedCertificate) then
            exit;

        InitBlob();
        SignText(GenerateSignatureCodePlainText(EETEntry), IsolatedCertificate, HashAlgorithmType::SHA256, OutputStream);
        exit(Base64Convert.ToBase64(InputStream));
    end;

    [Scope('OnPrem')]
    procedure GenerateSecurityCode(SignatureCode: Text): Text[44]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        Base64Convert: Codeunit "Base64 Convert";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        Hash: Text;
    begin
        if SignatureCode = '' then
            exit;

        InitBlob();
        Base64Convert.FromBase64(SignatureCode, OutputStream);
        Hash := CryptographyManagement.GenerateHash(InputStream, HashAlgorithmType::SHA1);
        exit(
          StrSubstNo('%1-%2-%3-%4-%5',
            CopyStr(Hash, 1, 8), CopyStr(Hash, 9, 8), CopyStr(Hash, 17, 8),
            CopyStr(Hash, 25, 8), CopyStr(Hash, 33, 8)));
    end;

    local procedure SignText(InputString: Text; IsolatedCertificate: Record "Isolated Certificate"; HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512; SignatureStream: OutStream)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        DotNetAsimmetricAlgorithm: Codeunit DotNet_AsymmetricAlgorithm;
        DotNetX509Certificate2: Codeunit DotNet_X509Certificate2;
        TempBlob: Codeunit "Temp Blob";
        KeyStream: InStream;
        OutputStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutputStream);
        TempBlob.CreateInStream(KeyStream);

        IsolatedCertificate.GetDotNetX509Certificate2(DotNetX509Certificate2);
        DotNetX509Certificate2.PrivateKey(DotNetAsimmetricAlgorithm);
        OutputStream.Write(DotNetAsimmetricAlgorithm.ToXmlString(true));
        CryptographyManagement.SignData(InputString, KeyStream, HashAlgorithmType, SignatureStream);
    end;

    local procedure InitBlob()
    begin
        Clear(TempBlob);
        TempBlob.CreateInStream(InputStream);
        TempBlob.CreateOutStream(OutputStream);
    end;

    [Scope('OnPrem')]
    procedure FormatOption(Option: Option): Text
    begin
        exit(Format(Option, 0, 9));
    end;

    [Scope('OnPrem')]
    procedure FormatDecimal(Decimal: Decimal): Text
    begin
        exit(Format(Decimal, 0, '<Precision,2:2><Standard Format,2>'));
    end;

    [Scope('OnPrem')]
    procedure FormatBoolean(Boolean: Boolean): Text
    begin
        exit(Format(Boolean, 0, 9));
    end;

    [Scope('OnPrem')]
    procedure FormatDateTime(DateTime: DateTime): Text
    begin
        exit(Format(RoundDateTime(DateTime), 0, 9));
    end;

    local procedure CreateUUID(): Text[36]
    begin
        exit(DelChr(LowerCase(Format(CreateGuid)), '=', '{}'));
    end;

    [EventSubscriber(ObjectType::Codeunit, 11735, 'OnBeforePostCashDoc', '', false, false)]
    local procedure CheckCashDocumentOnBeforePostCashDoc(var CashDocHdr: Record "Cash Document Header")
    begin
        CheckCashDocument(CashDocHdr);
    end;

    [EventSubscriber(ObjectType::Codeunit, 11735, 'OnBeforeDeleteAfterPosting', '', false, false)]
    local procedure CreateEETEntryOnBeforeDeleteAfterPosting(var CashDocHdr: Record "Cash Document Header"; var PostedCashDocHdr: Record "Posted Cash Document Header")
    begin
        if not IsEETEnabled then
            exit;

        if not CashDocHdr.IsEETTransaction then
            exit;

        PostedCashDocHdr."EET Entry No." := CreateEntryForCashDocument(CashDocHdr, PostedCashDocHdr);
        PostedCashDocHdr.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, 11735, 'OnAfterFinalizePosting', '', false, false)]
    local procedure SendEntryToServiceOnAfterFinalizePosting(var CashDocHdr: Record "Cash Document Header"; var PostedCashDocHdr: Record "Posted Cash Document Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        EETEntry: Record "EET Entry";
    begin
        if not EETEntry.Get(PostedCashDocHdr."EET Entry No.") then
            exit;

        GenerateControlCodes(EETEntry);
        SetEntryStatus(EETEntry, EETEntry."EET Status"::"Send Pending", '');

        GetSetup;
        if EETServiceSetup."Sales Regime" = EETServiceSetup."Sales Regime"::Regular then
            SendEntryToService(EETEntry, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, 11735, 'OnAfterFinalizePostingPreview', '', false, false)]
    local procedure SendEntryToVerificationOnAfterFinalizePostingPreview(var CashDocHdr: Record "Cash Document Header"; var PostedCashDocHdr: Record "Posted Cash Document Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        EETEntry: Record "EET Entry";
    begin
        if not IsEETEnabled then
            exit;

        if not CashDocHdr.IsEETTransaction then
            exit;

        EETEntry.Get(CreateEntryForCashDocument(CashDocHdr, PostedCashDocHdr));
        GenerateControlCodes(EETEntry);
        SendEntryToService(EETEntry, true);
    end;

    [Scope('OnPrem')]
    procedure CreateCancelEETEntry(EETEntryNo: Integer; Send: Boolean; WithConfirmation: Boolean): Integer
    var
        EETEntryOrig: Record "EET Entry";
        NewEETEntry: Record "EET Entry";
    begin
        if not EETEntryOrig.Get(EETEntryNo) then
            exit;

        OnBeforeCreateCancelEETEntry(EETEntryOrig);

        if GuiAllowed and WithConfirmation then begin
            if EETEntryOrig."Canceled By Entry No." = 0 then
                if not Confirm(
                     CancelByEETEntryNoQst,
                     false,
                     EETEntryOrig."Entry No.")
                then
                    Error('');

            if EETEntryOrig."Canceled By Entry No." <> 0 then
                if not Confirm(
                     EETEntryAlreadyCanceledQst,
                     false,
                     EETEntryOrig.TableCaption,
                     EETEntryOrig."Entry No.",
                     EETEntryOrig."Canceled By Entry No.")
                then
                    Error('');
        end;

        NewEETEntry.CopySourceInfoFromEntry(EETEntryOrig, true);
        NewEETEntry.CopyAmountsFromEntry(EETEntryOrig);
        NewEETEntry.ReverseAmounts;

        NewEETEntry.Get(CreateEETEntrySimple(NewEETEntry, false, false, true));

        NewEETEntry."User ID" := UserId;
        NewEETEntry."Creation Datetime" := CurrentDateTime;

        SetEntryStatus(
          NewEETEntry,
          NewEETEntry."EET Status"::Created,
          StrSubstNo(
            CancelEntryToEntryMsg, EETEntryOrig."Entry No.")
          );

        EETEntryOrig."Canceled By Entry No." := NewEETEntry."Entry No.";
        EETEntryOrig.Modify();

        SetEntryStatus(
          EETEntryOrig,
          EETEntryOrig."EET Status",
          StrSubstNo(
            CancelByEETEntryNoMsg,
            EETEntryOrig."Canceled By Entry No.")
          );

        // Process entry
        if Send then
            RegisterEntry(NewEETEntry."Entry No.");

        exit(NewEETEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure CreateEETEntrySimple(EETEntrySource: Record "EET Entry"; InitializeSerialNo: Boolean; SetStatusToSendPending: Boolean; SimpleRegistration: Boolean): Integer
    var
        EETEntry: Record "EET Entry";
    begin
        InitEntry(EETEntry);
        EETEntry.CopySourceInfoFromEntry(EETEntrySource, InitializeSerialNo);
        EETEntry.CopyAmountsFromEntry(EETEntrySource);
        EETEntry."Simple Registration" := SimpleRegistration;
        EETEntry.Insert();

        GenerateControlCodes(EETEntry);
        EETEntry.Modify();

        if SetStatusToSendPending then
            SetEntryStatus(EETEntry, EETEntry."EET Status"::"Send Pending", '');

        exit(EETEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure RegisterEntry(EETEntryNo: Integer)
    var
        EETEntry: Record "EET Entry";
    begin
        // Process entry
        if EETEntryNo = 0 then
            exit;

        EETEntry.Get(EETEntryNo);

        SetEntryStatus(
          EETEntry,
          EETEntry."EET Status"::"Send Pending",
          ''
          );

        GetSetup;
        if EETServiceSetup."Sales Regime" = EETServiceSetup."Sales Regime"::Regular then
            SendEntryToService(EETEntry, false);
    end;

    [Scope('OnPrem')]
    procedure GetEETStatusStyleExpr(EETStatus: Option): Text
    var
        DummyEETEntry: Record "EET Entry";
    begin
        with DummyEETEntry do
            case EETStatus of
                "EET Status"::Created:
                    exit('Subordinate');
                "EET Status"::Failure:
                    exit('Unfavorable');
                "EET Status"::Success:
                    exit('Favorable');
                "EET Status"::Verified:
                    exit('StandardAccent');
                "EET Status"::"Verified with Warnings":
                    exit('AttentionAccent');
                "EET Status"::"Success with Warnings":
                    exit('Ambiguous');
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCancelEETEntry(OrigEETEntry: Record "EET Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEETCashRegister(CashDeskNo: Code[20]; var EETCashRegister: Boolean)
    begin
    end;
}

