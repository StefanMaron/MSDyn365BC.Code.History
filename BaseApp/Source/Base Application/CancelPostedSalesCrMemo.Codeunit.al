codeunit 1339 "Cancel Posted Sales Cr. Memo"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        UnapplyEntries(Rec);
        CreateCopyDocument(Rec, SalesHeader);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
        SetTrackInfoForCancellation(Rec);

        Commit();
    end;

    var
        AlreadyCancelledErr: Label 'You cannot cancel this posted sales credit memo because it has already been cancelled.';
        NotCorrectiveDocErr: Label 'You cannot cancel this posted sales credit memo because it is not a corrective document.';
        CustomerIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because customer %1 is blocked.', Comment = '%1 = Customer name';
        ItemIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because item %1 %2 is blocked.', Comment = '%1 = Item No. %2 = Item Description';
        AccountIsBlockedCancelErr: Label 'You cannot cancel this posted sales credit memo because %1 %2 is blocked.', Comment = '%1 = Table Caption %2 = Account number.';
        NoFreeInvoiceNoSeriesCancelErr: Label 'You cannot cancel this posted sales credit memo because no unused invoice numbers are available. \\You must extend the range of the number series for sales invoices.';
        NoFreePostInvSeriesCancelErr: Label 'You cannot cancel this posted sales credit memo because no unused posted invoice numbers are available. \\You must extend the range of the number series for posted invoices.';
        PostingNotAllowedCancelErr: Label 'You cannot cancel this posted sales credit memo because it was posted in a posting period that is closed.';
        InvalidDimCodeCancelErr: Label 'You cannot cancel this posted sales credit memo because the dimension rule setup for account ''%1'' %2 prevents %3 %4 from being cancelled.', Comment = '%1 = Table caption %2 = Account number %3 = Item no. %4 = Item description.';
        InvalidDimCombinationCancelErr: Label 'You cannot cancel this posted sales credit memo because the dimension combination for item %1 %2 is not allowed.', Comment = '%1 = Item no. %2 = Item description.';
        InvalidDimCombHeaderCancelErr: Label 'You cannot cancel this posted sales credit memo because the combination of dimensions on the credit memo is blocked.';
        ExternalDocCancelErr: Label 'You cannot cancel this posted sales credit memo because the external document number is required on the credit memo.';
        InventoryPostClosedCancelErr: Label 'You cannot cancel this posted sales credit memo because the inventory period is already closed.';
        PostingCreditMemoFailedOpenPostedInvQst: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is posted. Do you want to open the posted invoice?', Comment = '%1 = error text';
        PostingCreditMemoFailedOpenInvQst: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is created but not posted. Do you want to open the invoice?', Comment = '%1 = error text';
        CreatingInvFailedNothingCreatedErr: Label 'Canceling the credit memo failed because of the following error: \\%1.', Comment = '%1 = error text';
        ErrorType: Option CustomerBlocked,ItemBlocked,AccountBlocked,IsAppliedIncorrectly,IsUnapplied,IsCanceled,IsCorrected,SerieNumInv,SerieNumPostInv,FromOrder,PostingNotAllowed,DimErr,DimCombErr,DimCombHeaderErr,ExtDocErr,InventoryPostClosed;
        UnappliedErr: Label 'You cannot cancel this posted sales credit memo because it is fully or partially applied.\\To reverse an applied sales credit memo, you must manually unapply all applied entries.';
        NotAppliedCorrectlyErr: Label 'You cannot cancel this posted sales credit memo because it is not fully applied to an invoice.';

    procedure CancelPostedCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        TestCorrectCrMemoIsAllowed(SalesCrMemoHeader);
        if not CODEUNIT.Run(CODEUNIT::"Cancel Posted Sales Cr. Memo", SalesCrMemoHeader) then begin
            SalesInvHeader.SetRange("Applies-to Doc. No.", SalesCrMemoHeader."No.");
            if SalesInvHeader.FindFirst then begin
                if Confirm(StrSubstNo(PostingCreditMemoFailedOpenPostedInvQst, GetLastErrorText)) then
                    PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvHeader);
            end else begin
                SalesHeader.SetRange("Applies-to Doc. No.", SalesCrMemoHeader."No.");
                if SalesHeader.FindFirst then begin
                    if Confirm(StrSubstNo(PostingCreditMemoFailedOpenInvQst, GetLastErrorText)) then
                        PAGE.Run(PAGE::"Sales Invoice", SalesHeader);
                end else
                    Error(CreatingInvFailedNothingCreatedErr, GetLastErrorText);
            end;
            exit(false);
        end;
        exit(true);
    end;

    local procedure CreateCopyDocument(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header")
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        Clear(SalesHeader);
        SalesHeader."No." := '';
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Insert(true);
        CopyDocMgt.SetPropertiesForInvoiceCorrection(false);
        CopyDocMgt.CopySalesDocForCrMemoCancelling(SalesCrMemoHeader."No.", SalesHeader);
    end;

    procedure TestCorrectCrMemoIsAllowed(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        TestIfPostingIsAllowed(SalesCrMemoHeader);
        TestIfCustomerIsBlocked(SalesCrMemoHeader, SalesCrMemoHeader."Sell-to Customer No.");
        TestIfCustomerIsBlocked(SalesCrMemoHeader, SalesCrMemoHeader."Bill-to Customer No.");
        TestIfInvoiceIsCorrectedOnce(SalesCrMemoHeader);
        TestIfCrMemoIsCorrectiveDoc(SalesCrMemoHeader);
        TestCustomerDimension(SalesCrMemoHeader, SalesCrMemoHeader."Bill-to Customer No.");
        TestDimensionOnHeader(SalesCrMemoHeader);
        TestSalesLines(SalesCrMemoHeader);
        TestIfAnyFreeNumberSeries(SalesCrMemoHeader);
        TestExternalDocument(SalesCrMemoHeader);
        TestInventoryPostingClosed(SalesCrMemoHeader);
    end;

    local procedure SetTrackInfoForCancellation(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CancelledDocument: Record "Cancelled Document";
    begin
        SalesInvHeader.SetRange("Applies-to Doc. No.", SalesCrMemoHeader."No.");
        if SalesInvHeader.FindLast then
            CancelledDocument.InsertSalesCrMemoToInvCancelledDocument(SalesCrMemoHeader."No.", SalesInvHeader."No.");
    end;

    local procedure TestDimensionOnHeader(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if not DimensionManagement.CheckDimIDComb(SalesCrMemoHeader."Dimension Set ID") then
            ErrorHelperHeader(ErrorType::DimCombHeaderErr, SalesCrMemoHeader);
    end;

    local procedure TestIfCustomerIsBlocked(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        if Customer.Blocked in [Customer.Blocked::Invoice, Customer.Blocked::All] then
            ErrorHelperHeader(ErrorType::CustomerBlocked, SalesCrMemoHeader);
    end;

    local procedure TestIfAppliedCorrectly(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PartiallyApplied: Boolean;
    begin
        CustLedgEntry.CalcFields(Amount, "Remaining Amount");
        PartiallyApplied :=
          ((CustLedgEntry.Amount <> CustLedgEntry."Remaining Amount") and (CustLedgEntry."Remaining Amount" <> 0));
        if (CalcDtldCustLedgEntryCount(DetailedCustLedgEntry."Entry Type"::"Initial Entry", CustLedgEntry."Entry No.") <> 1) or
           (not (CalcDtldCustLedgEntryCount(DetailedCustLedgEntry."Entry Type"::Application, CustLedgEntry."Entry No.") in [0, 1])) or
           AnyDtldCustLedgEntriesExceptInitialAndApplicaltionExists(CustLedgEntry."Entry No.") or
           PartiallyApplied
        then
            ErrorHelperHeader(ErrorType::IsAppliedIncorrectly, SalesCrMemoHeader);
    end;

    local procedure TestIfUnapplied(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        SalesCrMemoHeader.CalcFields("Remaining Amount");
        if SalesCrMemoHeader."Amount Including VAT" <> -SalesCrMemoHeader."Remaining Amount" then
            ErrorHelperHeader(ErrorType::IsUnapplied, SalesCrMemoHeader);
    end;

    local procedure TestCustomerDimension(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        Customer.Get(CustNo);
        TableID[1] := DATABASE::Customer;
        No[1] := Customer."No.";
        if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesCrMemoHeader."Dimension Set ID") then
            ErrorHelperAccount(ErrorType::DimErr, Customer.TableCaption, Customer."No.", Customer."No.", Customer.Name);
    end;

    local procedure TestSalesLines(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.Find('-') then
            repeat
                if not IsCommentLine(SalesCrMemoLine) then begin
                    if SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item then begin
                        Item.Get(SalesCrMemoLine."No.");

                        if Item.Blocked then
                            ErrorHelperLine(ErrorType::ItemBlocked, SalesCrMemoLine);

                        TableID[1] := DATABASE::Item;
                        No[1] := SalesCrMemoLine."No.";
                        if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesCrMemoLine."Dimension Set ID") then
                            ErrorHelperAccount(ErrorType::DimErr, Item.TableCaption, No[1], Item."No.", Item.Description);

                        if Item.Type = Item.Type::Inventory then
                            TestInventoryPostingSetup(SalesCrMemoLine);
                    end;

                    TestGenPostingSetup(SalesCrMemoLine);
                    TestCustomerPostingGroup(SalesCrMemoLine, SalesCrMemoHeader."Customer Posting Group");
                    TestVATPostingSetup(SalesCrMemoLine);

                    if not DimensionManagement.CheckDimIDComb(SalesCrMemoLine."Dimension Set ID") then
                        ErrorHelperLine(ErrorType::DimCombErr, SalesCrMemoLine);
                end;
            until SalesCrMemoLine.Next = 0;
    end;

    local procedure TestGLAccount(AccountNo: Code[20]; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        GLAccount.Get(AccountNo);
        if GLAccount.Blocked then
            ErrorHelperAccount(ErrorType::AccountBlocked, GLAccount.TableCaption, AccountNo, '', '');
        TableID[1] := DATABASE::"G/L Account";
        No[1] := AccountNo;

        if SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item then begin
            Item.Get(SalesCrMemoLine."No.");
            if not DimensionManagement.CheckDimValuePosting(TableID, No, SalesCrMemoLine."Dimension Set ID") then
                ErrorHelperAccount(ErrorType::DimErr, GLAccount.TableCaption, AccountNo, Item."No.", Item.Description);
        end;
    end;

    local procedure TestIfInvoiceIsCorrectedOnce(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if CancelledDocument.FindSalesCancelledCrMemo(SalesCrMemoHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCorrected, SalesCrMemoHeader);
    end;

    local procedure TestIfCrMemoIsCorrectiveDoc(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        if not CancelledDocument.FindSalesCorrectiveCrMemo(SalesCrMemoHeader."No.") then
            ErrorHelperHeader(ErrorType::IsCanceled, SalesCrMemoHeader);
    end;

    local procedure TestIfPostingIsAllowed(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        if GenJnlCheckLine.DateNotAllowed(SalesCrMemoHeader."Posting Date") then
            ErrorHelperHeader(ErrorType::PostingNotAllowed, SalesCrMemoHeader);
    end;

    local procedure TestIfAnyFreeNumberSeries(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PostingDate: Date;
    begin
        PostingDate := WorkDate;
        SalesReceivablesSetup.Get();

        if NoSeriesManagement.TryGetNextNo(SalesReceivablesSetup."Invoice Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumInv, SalesCrMemoHeader);

        if NoSeriesManagement.TryGetNextNo(SalesReceivablesSetup."Posted Invoice Nos.", PostingDate) = '' then
            ErrorHelperHeader(ErrorType::SerieNumPostInv, SalesCrMemoHeader);
    end;

    local procedure TestExternalDocument(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if (SalesCrMemoHeader."External Document No." = '') and SalesReceivablesSetup."Ext. Doc. No. Mandatory" then
            ErrorHelperHeader(ErrorType::ExtDocErr, SalesCrMemoHeader);
    end;

    local procedure TestInventoryPostingClosed(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        InventoryPeriod: Record "Inventory Period";
    begin
        InventoryPeriod.SetRange(Closed, true);
        InventoryPeriod.SetFilter("Ending Date", '>=%1', SalesCrMemoHeader."Posting Date");
        if InventoryPeriod.FindFirst then
            ErrorHelperHeader(ErrorType::InventoryPostClosed, SalesCrMemoHeader);
    end;

    local procedure TestGenPostingSetup(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        Item: Record Item;
    begin
        with GenPostingSetup do begin
            Get(SalesCrMemoLine."Gen. Bus. Posting Group", SalesCrMemoLine."Gen. Prod. Posting Group");
            TestField("Sales Account");
            TestGLAccount("Sales Account", SalesCrMemoLine);
            TestField("Sales Credit Memo Account");
            TestGLAccount("Sales Credit Memo Account", SalesCrMemoLine);
            TestField("Sales Line Disc. Account");
            TestGLAccount("Sales Line Disc. Account", SalesCrMemoLine);
            if SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item then begin
                Item.Get(SalesCrMemoLine."No.");
                if Item.IsInventoriableType then
                    TestGLAccount(GetCOGSAccount, SalesCrMemoLine);
            end;
        end;
    end;

    local procedure TestCustomerPostingGroup(SalesCrMemoLine: Record "Sales Cr.Memo Line"; CustomerPostingGr: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        with CustomerPostingGroup do begin
            Get(CustomerPostingGr);
            TestField("Receivables Account");
            TestGLAccount("Receivables Account", SalesCrMemoLine);
        end;
    end;

    local procedure TestVATPostingSetup(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with VATPostingSetup do begin
            Get(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group");
            if "VAT Calculation Type" <> "VAT Calculation Type"::"Sales Tax" then begin
                TestField("Sales VAT Account");
                TestGLAccount("Sales VAT Account", SalesCrMemoLine);
            end;
        end;
    end;

    local procedure TestInventoryPostingSetup(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        with InventoryPostingSetup do begin
            Get(SalesCrMemoLine."Location Code", SalesCrMemoLine."Posting Group");
            TestField("Inventory Account");
            TestGLAccount("Inventory Account", SalesCrMemoLine);
        end;
    end;

    local procedure UnapplyEntries(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        FindCustLedgEntry(CustLedgEntry, SalesCrMemoHeader."No.");
        TestIfAppliedCorrectly(SalesCrMemoHeader, CustLedgEntry);
        if CustLedgEntry.Open then
            exit;

        FindDetailedApplicationEntry(DetailedCustLedgEntry, CustLedgEntry);
        CustEntryApplyPostedEntries.PostUnApplyCustomer(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Document No.", DetailedCustLedgEntry."Posting Date");
        TestIfUnapplied(SalesCrMemoHeader);
    end;

    local procedure FindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; DocNo: Code[20])
    begin
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast;
    end;

    local procedure FindDetailedApplicationEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Customer No.", CustLedgEntry."Customer No.");
        DetailedCustLedgEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        DetailedCustLedgEntry.FindFirst;
    end;

    local procedure AnyDtldCustLedgEntriesExceptInitialAndApplicaltionExists(CustLedgEntryNo: Integer): Boolean
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetFilter(
          "Entry Type", '<>%1&<>%2', DetailedCustLedgEntry."Entry Type"::"Initial Entry", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        exit(not DetailedCustLedgEntry.IsEmpty);
    end;

    local procedure CalcDtldCustLedgEntryCount(EntryType: Option; CustLedgEntryNo: Integer): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        exit(DetailedCustLedgEntry.Count);
    end;

    local procedure IsCommentLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"): Boolean
    begin
        exit((SalesCrMemoLine.Type = SalesCrMemoLine.Type::" ") or (SalesCrMemoLine."No." = ''));
    end;

    local procedure ErrorHelperHeader(ErrorOption: Option; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Customer: Record Customer;
    begin
        case ErrorOption of
            ErrorType::CustomerBlocked:
                begin
                    Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
                    Error(CustomerIsBlockedCancelErr, Customer.Name);
                end;
            ErrorType::IsAppliedIncorrectly:
                Error(NotAppliedCorrectlyErr);
            ErrorType::IsUnapplied:
                Error(UnappliedErr);
            ErrorType::IsCorrected:
                Error(AlreadyCancelledErr);
            ErrorType::IsCanceled:
                Error(NotCorrectiveDocErr);
            ErrorType::SerieNumInv:
                Error(NoFreeInvoiceNoSeriesCancelErr);
            ErrorType::SerieNumPostInv:
                Error(NoFreePostInvSeriesCancelErr);
            ErrorType::PostingNotAllowed:
                Error(PostingNotAllowedCancelErr);
            ErrorType::ExtDocErr:
                Error(ExternalDocCancelErr);
            ErrorType::InventoryPostClosed:
                Error(InventoryPostClosedCancelErr);
            ErrorType::DimCombHeaderErr:
                Error(InvalidDimCombHeaderCancelErr);
        end
    end;

    local procedure ErrorHelperLine(ErrorOption: Option; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        Item: Record Item;
    begin
        case ErrorOption of
            ErrorType::ItemBlocked:
                begin
                    Item.Get(SalesCrMemoLine."No.");
                    Error(ItemIsBlockedCancelErr, Item."No.", Item.Description);
                end;
            ErrorType::DimCombErr:
                Error(InvalidDimCombinationCancelErr, SalesCrMemoLine."No.", SalesCrMemoLine.Description);
        end
    end;

    local procedure ErrorHelperAccount(ErrorOption: Option; AccountNo: Code[20]; AccountCaption: Text; No: Code[20]; Name: Text)
    begin
        case ErrorOption of
            ErrorType::AccountBlocked:
                Error(AccountIsBlockedCancelErr, AccountCaption, AccountNo);
            ErrorType::DimErr:
                Error(InvalidDimCodeCancelErr, AccountCaption, AccountNo, No, Name);
        end;
    end;
}

