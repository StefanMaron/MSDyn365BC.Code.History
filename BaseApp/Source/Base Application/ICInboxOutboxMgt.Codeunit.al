codeunit 427 ICInboxOutboxMgt
{
    Permissions = TableData "General Ledger Setup" = rm;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        DimMgt: Codeunit DimensionManagement;
        GLSetupFound: Boolean;
        CompanyInfoFound: Boolean;
        Text000: Label 'Do you want to re-create the transaction?';
        Text001: Label '%1 %2 does not exist as a %3 in %1 %4.';
        Text002: Label 'You cannot send IC document because %1 %2 has %3 %4.';
        Text004: Label 'Transaction %1 for %2 %3 already exists in the %4 table.';
        Text005: Label '%1 must be %2 or %3 in order to be re-created.';
        NoItemForCommonItemErr: Label 'There is no Item related to Common Item No. %1.', Comment = '%1 = Common Item No value';

    procedure CreateOutboxJnlTransaction(TempGenJnlLine: Record "Gen. Journal Line" temporary; Rejection: Boolean): Integer
    var
        ICPartner: Record "IC Partner";
        OutboxJnlTransaction: Record "IC Outbox Transaction";
        ICTransactionNo: Integer;
    begin
        ICPartner.Get(TempGenJnlLine."IC Partner Code");
        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
            exit(0);

        GLSetup.LockTable;
        GetGLSetup;
        if GLSetup."Last IC Transaction No." < 0 then
            GLSetup."Last IC Transaction No." := 0;
        ICTransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := ICTransactionNo;
        GLSetup.Modify;

        with TempGenJnlLine do begin
            OutboxJnlTransaction.Init;
            OutboxJnlTransaction."Transaction No." := ICTransactionNo;
            OutboxJnlTransaction."IC Partner Code" := "IC Partner Code";
            OutboxJnlTransaction."Source Type" := OutboxJnlTransaction."Source Type"::"Journal Line";
            OutboxJnlTransaction."Document Type" := "Document Type";
            OutboxJnlTransaction."Document No." := "Document No.";
            OutboxJnlTransaction."Posting Date" := "Posting Date";
            OutboxJnlTransaction."Document Date" := "Document Date";
            OutboxJnlTransaction."IC Partner G/L Acc. No." := "IC Partner G/L Acc. No.";
            OutboxJnlTransaction."Source Line No." := "Source Line No.";
            if Rejection then
                OutboxJnlTransaction."Transaction Source" := OutboxJnlTransaction."Transaction Source"::"Rejected by Current Company"
            else
                OutboxJnlTransaction."Transaction Source" := OutboxJnlTransaction."Transaction Source"::"Created by Current Company";
            OutboxJnlTransaction.Insert;
        end;
        OnInsertICOutboxTransaction(OutboxJnlTransaction);
        exit(ICTransactionNo);
    end;

    procedure SendSalesDoc(var SalesHeader: Record "Sales Header"; Post: Boolean)
    var
        ICPartner: Record "IC Partner";
    begin
        SalesHeader.TestField("Send IC Document");
        if SalesHeader."Sell-to IC Partner Code" <> '' then
            ICPartner.Get(SalesHeader."Sell-to IC Partner Code")
        else
            ICPartner.Get(SalesHeader."Bill-to IC Partner Code");
        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
            if Post then
                exit
            else
                Error(Text002, ICPartner.TableCaption, ICPartner.Code, ICPartner.FieldCaption("Inbox Type"), ICPartner."Inbox Type");
        ICPartner.TestField(Blocked, false);
        if not Post then
            CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);
        if SalesHeader."Sell-to IC Partner Code" <> '' then
            CreateOutboxSalesDocTrans(SalesHeader, false, Post);
    end;

    procedure SendPurchDoc(var PurchHeader: Record "Purchase Header"; Post: Boolean)
    var
        ICPartner: Record "IC Partner";
    begin
        PurchHeader.TestField("Send IC Document");
        ICPartner.Get(PurchHeader."Buy-from IC Partner Code");
        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
            if Post then
                exit
            else
                Error(Text002, ICPartner.TableCaption, ICPartner.Code, ICPartner.FieldCaption("Inbox Type"), ICPartner."Inbox Type");
        ICPartner.TestField(Blocked, false);
        if not Post then
            CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchHeader);
        CreateOutboxPurchDocTrans(PurchHeader, false, Post);
    end;

    procedure CreateOutboxSalesDocTrans(SalesHeader: Record "Sales Header"; Rejection: Boolean; Post: Boolean)
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ICOutBoxSalesHeader: Record "IC Outbox Sales Header";
        ICOutBoxSalesLine: Record "IC Outbox Sales Line";
        TransactionNo: Integer;
        LinesCreated: Boolean;
    begin
        GLSetup.LockTable;
        GetGLSetup;
        TransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := TransactionNo;
        GLSetup.Modify;
        Customer.Get(SalesHeader."Sell-to Customer No.");
        with SalesHeader do begin
            OutboxTransaction.Init;
            OutboxTransaction."Transaction No." := TransactionNo;
            OutboxTransaction."IC Partner Code" := Customer."IC Partner Code";
            OutboxTransaction."Source Type" := OutboxTransaction."Source Type"::"Sales Document";
            case "Document Type" of
                "Document Type"::Order:
                    OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Order;
                "Document Type"::Invoice:
                    OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Invoice;
                "Document Type"::"Credit Memo":
                    OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Credit Memo";
                "Document Type"::"Return Order":
                    OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Return Order";
            end;
            OutboxTransaction."Document No." := "No.";
            OutboxTransaction."Posting Date" := "Posting Date";
            OutboxTransaction."Document Date" := "Document Date";
            if Rejection then
                OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Rejected by Current Company"
            else
                OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
            OnBeforeOutBoxTransactionInsert(OutboxTransaction, SalesHeader);
            OutboxTransaction.Insert;
        end;
        ICOutBoxSalesHeader.TransferFields(SalesHeader);
        OnAfterICOutBoxSalesHeaderTransferFields(ICOutBoxSalesHeader, SalesHeader);
        if OutboxTransaction."Document Type" = OutboxTransaction."Document Type"::Order then
            ICOutBoxSalesHeader."Order No." := SalesHeader."No.";
        ICOutBoxSalesHeader."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICOutBoxSalesHeader."IC Transaction No." := OutboxTransaction."Transaction No.";
        ICOutBoxSalesHeader."Transaction Source" := OutboxTransaction."Transaction Source";
        AssignCurrencyCodeInOutBoxDoc(ICOutBoxSalesHeader."Currency Code", OutboxTransaction."IC Partner Code");
        DimMgt.CopyDocDimtoICDocDim(DATABASE::"IC Outbox Sales Header", ICOutBoxSalesHeader."IC Transaction No.",
          ICOutBoxSalesHeader."IC Partner Code", ICOutBoxSalesHeader."Transaction Source", 0, SalesHeader."Dimension Set ID");

        with ICOutBoxSalesLine do begin
            SalesLine.Reset;
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            if SalesLine.Find('-') then
                repeat
                    Init;
                    TransferFields(SalesLine);
                    case SalesLine."Document Type" of
                        SalesLine."Document Type"::Order:
                            "Document Type" := "Document Type"::Order;
                        SalesLine."Document Type"::Invoice:
                            "Document Type" := "Document Type"::Invoice;
                        SalesLine."Document Type"::"Credit Memo":
                            "Document Type" := "Document Type"::"Credit Memo";
                        SalesLine."Document Type"::"Return Order":
                            "Document Type" := "Document Type"::"Return Order";
                    end;
                    "IC Transaction No." := OutboxTransaction."Transaction No.";
                    "IC Partner Code" := OutboxTransaction."IC Partner Code";
                    "Transaction Source" := OutboxTransaction."Transaction Source";
                    "Currency Code" := ICOutBoxSalesHeader."Currency Code";
                    if SalesLine.Type = SalesLine.Type::" " then
                        "IC Partner Reference" := '';
                    DimMgt.CopyDocDimtoICDocDim(DATABASE::"IC Outbox Sales Line", "IC Transaction No.", "IC Partner Code", "Transaction Source",
                      "Line No.", SalesLine."Dimension Set ID");
                    UpdateICOutboxSalesLineReceiptShipment(ICOutBoxSalesLine, ICOutBoxSalesHeader);
                    if Insert(true) then begin
                        OnCreateOutboxSalesDocTransOnAfterICOutBoxSalesLineInsert(ICOutBoxSalesLine, SalesLine);
                        LinesCreated := true;
                    end;
                    OnAfterICOutBoxSalesLineInsert(SalesLine, ICOutBoxSalesLine);
                until SalesLine.Next = 0;
        end;

        if LinesCreated then begin
            ICOutBoxSalesHeader.Insert;
            if not Post then begin
                SalesHeader."IC Status" := SalesHeader."IC Status"::Pending;
                SalesHeader.Modify;
            end;
        end;
        OnBeforeICOutboxTransactionCreatedSalesDocTrans(SalesHeader, SalesLine, ICOutBoxSalesHeader, OutboxTransaction, LinesCreated);
        OnInsertICOutboxSalesDocTransaction(OutboxTransaction);
    end;

    procedure CreateOutboxSalesInvTrans(SalesInvHdr: Record "Sales Invoice Header")
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        Customer: Record Customer;
        ICPartner: Record "IC Partner";
        SalesInvLine: Record "Sales Invoice Line";
        ICOutBoxSalesHeader: Record "IC Outbox Sales Header";
        ICOutBoxSalesLine: Record "IC Outbox Sales Line";
        ICDocDim: Record "IC Document Dimension";
        ItemCrossReference: Record "Item Cross Reference";
        Item: Record Item;
        TransactionNo: Integer;
        RoundingLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateOutboxSalesInvTrans(SalesInvHdr, IsHandled);
        if IsHandled then
            exit;

        Customer.Get(SalesInvHdr."Bill-to Customer No.");
        ICPartner.Get(Customer."IC Partner Code");
        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
            exit;

        GLSetup.LockTable;
        GetGLSetup;
        TransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := TransactionNo;
        GLSetup.Modify;
        with SalesInvHdr do begin
            OutboxTransaction.Init;
            OutboxTransaction."Transaction No." := TransactionNo;
            OutboxTransaction."IC Partner Code" := Customer."IC Partner Code";
            OutboxTransaction."Source Type" := OutboxTransaction."Source Type"::"Sales Document";
            OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Invoice;
            OutboxTransaction."Document No." := "No.";
            OutboxTransaction."Posting Date" := "Posting Date";
            OutboxTransaction."Document Date" := "Document Date";
            OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
            OutboxTransaction.Insert;
        end;
        ICOutBoxSalesHeader.TransferFields(SalesInvHdr);
        ICOutBoxSalesHeader."Document Type" := ICOutBoxSalesHeader."Document Type"::Invoice;
        ICOutBoxSalesHeader."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICOutBoxSalesHeader."IC Transaction No." := OutboxTransaction."Transaction No.";
        ICOutBoxSalesHeader."Transaction Source" := OutboxTransaction."Transaction Source";
        AssignCurrencyCodeInOutBoxDoc(ICOutBoxSalesHeader."Currency Code", OutboxTransaction."IC Partner Code");
        ICOutBoxSalesHeader.Insert;

        ICDocDim.Init;
        ICDocDim."Transaction No." := OutboxTransaction."Transaction No.";
        ICDocDim."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICDocDim."Transaction Source" := OutboxTransaction."Transaction Source";

        CreateICDocDimFromPostedDocDim(ICDocDim, SalesInvHdr."Dimension Set ID", DATABASE::"IC Outbox Sales Header");

        RoundingLineNo := FindRoundingSalesInvLine(SalesInvHdr."No.");
        with ICOutBoxSalesLine do begin
            SalesInvLine.Reset;
            SalesInvLine.SetRange("Document No.", SalesInvHdr."No.");
            if RoundingLineNo <> 0 then
                SalesInvLine.SetRange("Line No.", 0, RoundingLineNo - 1);
            if SalesInvLine.FindSet then
                repeat
                    if (SalesInvLine.Type = SalesInvLine.Type::" ") or (SalesInvLine."No." <> '') then begin
                        Init;
                        TransferFields(SalesInvLine);
                        "Document Type" := "Document Type"::Invoice;
                        "IC Transaction No." := OutboxTransaction."Transaction No.";
                        "IC Partner Code" := OutboxTransaction."IC Partner Code";
                        "Transaction Source" := OutboxTransaction."Transaction Source";
                        "Currency Code" := ICOutBoxSalesHeader."Currency Code";
                        if SalesInvLine.Type = SalesInvLine.Type::" " then
                            "IC Partner Reference" := '';
                        if (SalesInvLine."Bill-to Customer No." <> SalesInvLine."Sell-to Customer No.") and
                           (SalesInvLine.Type = SalesInvLine.Type::Item)
                        then
                            case ICPartner."Outbound Sales Item No. Type" of
                                ICPartner."Outbound Sales Item No. Type"::"Internal No.":
                                    begin
                                        "IC Partner Ref. Type" := "IC Partner Ref. Type"::Item;
                                        "IC Partner Reference" := SalesInvLine."No.";
                                    end;
                                ICPartner."Outbound Sales Item No. Type"::"Cross Reference":
                                    begin
                                        Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Cross reference");
                                        ItemCrossReference.SetRange("Cross-Reference Type",
                                          ItemCrossReference."Cross-Reference Type"::Customer);
                                        ItemCrossReference.SetRange("Cross-Reference Type No.", SalesInvLine."Bill-to Customer No.");
                                        ItemCrossReference.SetRange("Item No.", SalesInvLine."No.");
                                        if ItemCrossReference.FindFirst then
                                            "IC Partner Reference" := ItemCrossReference."Cross-Reference No.";
                                    end;
                                ICPartner."Outbound Sales Item No. Type"::"Common Item No.":
                                    begin
                                        Item.Get(SalesInvLine."No.");
                                        "IC Partner Reference" := Item."Common Item No.";
                                    end;
                            end;
                        UpdateICOutboxSalesLineReceiptShipment(ICOutBoxSalesLine, ICOutBoxSalesHeader);
                        OnCreateOutboxSalesInvTransOnBeforeICOutBoxSalesLineInsert(ICOutBoxSalesLine, SalesInvLine);
                        Insert(true);

                        ICDocDim."Line No." := SalesInvLine."Line No.";
                        CreateICDocDimFromPostedDocDim(ICDocDim, SalesInvLine."Dimension Set ID", DATABASE::"IC Outbox Sales Line");
                    end;
                until SalesInvLine.Next = 0;
        end;

        OnBeforeICOutboxTransactionCreatedSalesInvTrans(SalesInvHdr, SalesInvLine, ICOutBoxSalesHeader, OutboxTransaction);
        OnInsertICOutboxSalesInvTransaction(OutboxTransaction);
    end;

    procedure CreateOutboxSalesCrMemoTrans(SalesCrMemoHdr: Record "Sales Cr.Memo Header")
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        Customer: Record Customer;
        ICPartner: Record "IC Partner";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ICOutBoxSalesHeader: Record "IC Outbox Sales Header";
        ICOutBoxSalesLine: Record "IC Outbox Sales Line";
        ICDocDim: Record "IC Document Dimension";
        TransactionNo: Integer;
        RoundingLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateOutboxSalesCrMemoTrans(SalesCrMemoHdr, IsHandled);
        if IsHandled then
            exit;

        Customer.Get(SalesCrMemoHdr."Bill-to Customer No.");
        ICPartner.Get(Customer."IC Partner Code");
        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::"No IC Transfer" then
            exit;

        GLSetup.LockTable;
        GetGLSetup;
        TransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := TransactionNo;
        GLSetup.Modify;
        with SalesCrMemoHdr do begin
            OutboxTransaction.Init;
            OutboxTransaction."Transaction No." := TransactionNo;
            OutboxTransaction."IC Partner Code" := Customer."IC Partner Code";
            OutboxTransaction."Source Type" := OutboxTransaction."Source Type"::"Sales Document";
            OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Credit Memo";
            OutboxTransaction."Document No." := "No.";
            OutboxTransaction."Posting Date" := "Posting Date";
            OutboxTransaction."Document Date" := "Document Date";
            OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
            OutboxTransaction.Insert;
        end;
        ICOutBoxSalesHeader.TransferFields(SalesCrMemoHdr);
        ICOutBoxSalesHeader."Document Type" := ICOutBoxSalesHeader."Document Type"::"Credit Memo";
        ICOutBoxSalesHeader."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICOutBoxSalesHeader."IC Transaction No." := OutboxTransaction."Transaction No.";
        ICOutBoxSalesHeader."Transaction Source" := OutboxTransaction."Transaction Source";
        AssignCurrencyCodeInOutBoxDoc(ICOutBoxSalesHeader."Currency Code", OutboxTransaction."IC Partner Code");
        ICOutBoxSalesHeader.Insert;

        ICDocDim.Init;
        ICDocDim."Transaction No." := OutboxTransaction."Transaction No.";
        ICDocDim."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICDocDim."Transaction Source" := OutboxTransaction."Transaction Source";

        CreateICDocDimFromPostedDocDim(ICDocDim, SalesCrMemoHdr."Dimension Set ID", DATABASE::"IC Outbox Sales Header");

        RoundingLineNo := FindRoundingSalesCrMemoLine(SalesCrMemoHdr."No.");
        with ICOutBoxSalesLine do begin
            SalesCrMemoLine.Reset;
            SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHdr."No.");
            if RoundingLineNo <> 0 then
                SalesCrMemoLine.SetRange("Line No.", 0, RoundingLineNo - 1);
            if SalesCrMemoLine.FindSet then
                repeat
                    if (SalesCrMemoLine.Type = SalesCrMemoLine.Type::" ") or (SalesCrMemoLine."No." <> '') then begin
                        Init;
                        TransferFields(SalesCrMemoLine);
                        "Document Type" := "Document Type"::"Credit Memo";
                        "IC Transaction No." := OutboxTransaction."Transaction No.";
                        "IC Partner Code" := OutboxTransaction."IC Partner Code";
                        "Transaction Source" := OutboxTransaction."Transaction Source";
                        "Currency Code" := ICOutBoxSalesHeader."Currency Code";
                        if SalesCrMemoLine.Type = SalesCrMemoLine.Type::" " then
                            "IC Partner Reference" := '';
                        UpdateICOutboxSalesLineReceiptShipment(ICOutBoxSalesLine, ICOutBoxSalesHeader);
                        OnCreateOutboxSalesCrMemoTransOnBeforeICOutBoxSalesLineInsert(ICOutBoxSalesLine, SalesCrMemoLine);
                        Insert(true);

                        ICDocDim."Line No." := SalesCrMemoLine."Line No.";
                        CreateICDocDimFromPostedDocDim(ICDocDim, SalesCrMemoLine."Dimension Set ID", DATABASE::"IC Outbox Sales Line");
                    end;
                until SalesCrMemoLine.Next = 0;
        end;
        OnBeforeICOutboxTransactionCreatedSalesCrMemoTrans(SalesCrMemoHdr, SalesCrMemoLine, ICOutBoxSalesHeader, OutboxTransaction);
        OnInsertICOutboxSalesCrMemoTransaction(OutboxTransaction);
    end;

    procedure CreateOutboxPurchDocTrans(PurchHeader: Record "Purchase Header"; Rejection: Boolean; Post: Boolean)
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        Vendor: Record Vendor;
        PurchLine: Record "Purchase Line";
        ICOutBoxPurchHeader: Record "IC Outbox Purchase Header";
        ICOutBoxPurchLine: Record "IC Outbox Purchase Line";
        TransactionNo: Integer;
        LinesCreated: Boolean;
    begin
        OnBeforeCreateOutboxPurchDocTrans(PurchHeader, Rejection, Post);

        GLSetup.LockTable;
        GetGLSetup;
        TransactionNo := GLSetup."Last IC Transaction No." + 1;
        GLSetup."Last IC Transaction No." := TransactionNo;
        GLSetup.Modify;
        Vendor.Get(PurchHeader."Buy-from Vendor No.");
        Vendor.CheckBlockedVendOnDocs(Vendor, false);
        with PurchHeader do begin
            OutboxTransaction.Init;
            OutboxTransaction."Transaction No." := TransactionNo;
            OutboxTransaction."IC Partner Code" := Vendor."IC Partner Code";
            OutboxTransaction."Source Type" := OutboxTransaction."Source Type"::"Purchase Document";
            case "Document Type" of
                "Document Type"::Order:
                    OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Order;
                "Document Type"::Invoice:
                    OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::Invoice;
                "Document Type"::"Credit Memo":
                    OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Credit Memo";
                "Document Type"::"Return Order":
                    OutboxTransaction."Document Type" := OutboxTransaction."Document Type"::"Return Order";
            end;
            OutboxTransaction."Document No." := "No.";
            OutboxTransaction."Posting Date" := "Posting Date";
            OutboxTransaction."Document Date" := "Document Date";
            if Rejection then
                OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Rejected by Current Company"
            else
                OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
            OutboxTransaction.Insert;
        end;
        ICOutBoxPurchHeader.TransferFields(PurchHeader);
        ICOutBoxPurchHeader."IC Transaction No." := OutboxTransaction."Transaction No.";
        ICOutBoxPurchHeader."IC Partner Code" := OutboxTransaction."IC Partner Code";
        ICOutBoxPurchHeader."Transaction Source" := OutboxTransaction."Transaction Source";

        GetCompanyInfo;
        AssignCurrencyCodeInOutBoxDoc(ICOutBoxPurchHeader."Currency Code", OutboxTransaction."IC Partner Code");
        DimMgt.CopyDocDimtoICDocDim(DATABASE::"IC Outbox Purchase Header", ICOutBoxPurchHeader."IC Transaction No.",
          ICOutBoxPurchHeader."IC Partner Code", ICOutBoxPurchHeader."Transaction Source", 0, PurchHeader."Dimension Set ID");
        with ICOutBoxPurchLine do begin
            PurchLine.Reset;
            PurchLine.SetRange("Document Type", PurchHeader."Document Type");
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            if PurchLine.Find('-') then
                repeat
                    Init;
                    TransferFields(PurchLine);
                    case PurchLine."Document Type" of
                        PurchLine."Document Type"::Order:
                            "Document Type" := "Document Type"::Order;
                        PurchLine."Document Type"::Invoice:
                            "Document Type" := "Document Type"::Invoice;
                        PurchLine."Document Type"::"Credit Memo":
                            "Document Type" := "Document Type"::"Credit Memo";
                        PurchLine."Document Type"::"Return Order":
                            "Document Type" := "Document Type"::"Return Order";
                    end;
                    "IC Partner Code" := OutboxTransaction."IC Partner Code";
                    "IC Transaction No." := OutboxTransaction."Transaction No.";
                    "Transaction Source" := OutboxTransaction."Transaction Source";
                    "Currency Code" := ICOutBoxPurchHeader."Currency Code";
                    DimMgt.CopyDocDimtoICDocDim(
                      DATABASE::"IC Outbox Purchase Line", "IC Transaction No.", "IC Partner Code", "Transaction Source",
                      "Line No.", PurchLine."Dimension Set ID");
                    if PurchLine.Type = PurchLine.Type::" " then
                        "IC Partner Reference" := '';
                    if Insert(true) then begin
                        OnCreateOutboxPurchDocTransOnAfterICOutBoxPurchLineInsert(ICOutBoxPurchLine, PurchLine);
                        LinesCreated := true;
                    end;
                until PurchLine.Next = 0;
        end;

        if LinesCreated then begin
            ICOutBoxPurchHeader.Insert;
            if not Post then begin
                PurchHeader."IC Status" := PurchHeader."IC Status"::Pending;
                PurchHeader.Modify;
            end;
        end;
        OnBeforeICOutboxTransactionCreatedPurchDocTrans(PurchHeader, PurchLine, ICOutBoxPurchHeader, OutboxTransaction, LinesCreated);
        OnInsertICOutboxPurchDocTransaction(OutboxTransaction);
    end;

    procedure CreateOutboxJnlLine(TransactionNo: Integer; TransactionSource: Option "Rejected by Current Company"," Created by Current Company"; TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
        GetGLSetup;
        with TempGenJnlLine do begin
            if (("Bal. Account Type" in
                 ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"IC Partner"]) and
                ("Bal. Account No." <> '')) or
               (("Account Type" = "Account Type"::"G/L Account") and ("IC Partner G/L Acc. No." <> '')) or
               (("Account Type" = "Account Type"::"Bank Account") and ("IC Partner G/L Acc. No." <> ''))
            then
                CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", TempGenJnlLine);
            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"IC Partner"]) and
               ("Account No." <> '')
            then
                InsertOutboxJnlLine(TempGenJnlLine, TransactionNo, TransactionSource, false);
            if "IC Partner G/L Acc. No." <> '' then
                InsertOutboxJnlLine(TempGenJnlLine, TransactionNo, TransactionSource, true);
        end;
    end;

    local procedure InsertOutboxJnlLine(TempGenJnlLine: Record "Gen. Journal Line" temporary; TransactionNo: Integer; TransactionSource: Option "Rejected by Current Company"," Created by Current Company"; BalancingLine: Boolean)
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        DimMgt: Codeunit DimensionManagement;
    begin
        GetGLSetup;
        with TempGenJnlLine do begin
            ICOutboxJnlLine.Init;
            ICOutboxJnlLine."Transaction No." := TransactionNo;
            ICOutboxJnlLine."IC Partner Code" := "IC Partner Code";
            ICOutboxJnlLine."Transaction Source" := TransactionSource;
            ICOutboxJnlLine.Description := Description;
            ICOutboxJnlLine."Currency Code" := "Currency Code";
            ICOutboxJnlLine.Quantity := Quantity;
            ICOutboxJnlLine."Document No." := "Document No.";
            if BalancingLine then begin
                ICOutboxJnlLine."Line No." := "Line No.";
                ICOutboxJnlLine."Account Type" := ICOutboxJnlLine."Account Type"::"G/L Account";
                ICOutboxJnlLine."Account No." := "IC Partner G/L Acc. No.";
                ICOutboxJnlLine.Amount := -Amount;
                ICOutboxJnlLine."VAT Amount" := "Bal. VAT Amount";
            end else begin
                ICOutboxJnlLine."Line No." := 0;
                case "Account Type" of
                    "Account Type"::Customer:
                        ICOutboxJnlLine."Account Type" := ICOutboxJnlLine."Account Type"::Customer;
                    "Account Type"::Vendor:
                        ICOutboxJnlLine."Account Type" := ICOutboxJnlLine."Account Type"::Vendor;
                    "Account Type"::"IC Partner":
                        ICOutboxJnlLine."Account Type" := ICOutboxJnlLine."Account Type"::"IC Partner";
                end;
                ICOutboxJnlLine."Account No." := "Account No.";
                ICOutboxJnlLine.Amount := Amount;
                ICOutboxJnlLine."VAT Amount" := "VAT Amount";
                ICOutboxJnlLine."Due Date" := "Due Date";
                ICOutboxJnlLine."Payment Discount %" := "Payment Discount %";
                ICOutboxJnlLine."Payment Discount Date" := "Pmt. Discount Date";
            end;
            DimMgt.CopyJnlLineDimToICJnlDim(
              DATABASE::"IC Outbox Jnl. Line", TransactionNo, "IC Partner Code",
              ICOutboxJnlLine."Transaction Source", ICOutboxJnlLine."Line No.", "Dimension Set ID");
            ICOutboxJnlLine.Insert;
            OnInsertICOutboxJnlLine(ICOutboxJnlLine);
        end;
    end;

    procedure TranslateICGLAccount(ICAccNo: Code[30]): Code[20]
    var
        ICGLAcc: Record "IC G/L Account";
    begin
        ICGLAcc.Get(ICAccNo);
        exit(ICGLAcc."Map-to G/L Acc. No.");
    end;

    procedure TranslateICPartnerToVendor(ICPartnerCode: Code[20]): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        exit(ICPartner."Vendor No.");
    end;

    procedure TranslateICPartnerToCustomer(ICPartnerCode: Code[20]): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        exit(ICPartner."Customer No.");
    end;

    procedure CreateJournalLines(InboxTransaction: Record "IC Inbox Transaction"; InboxJnlLine: Record "IC Inbox Jnl. Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; GenJnlTemplate: Record "Gen. Journal Template")
    var
        GenJnlLine2: Record "Gen. Journal Line";
        InOutBoxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        TempInOutBoxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary;
        HandledInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        DimMgt: Codeunit DimensionManagement;
    begin
        GetGLSetup;
        with GenJnlLine2 do
            if InboxTransaction."Transaction Source" = InboxTransaction."Transaction Source"::"Created by Partner" then begin
                Init;
                "Journal Template Name" := TempGenJnlLine."Journal Template Name";
                "Journal Batch Name" := TempGenJnlLine."Journal Batch Name";
                if TempGenJnlLine."Posting Date" <> 0D then
                    "Posting Date" := TempGenJnlLine."Posting Date"
                else
                    "Posting Date" := InboxTransaction."Posting Date";
                "Document Type" := InboxTransaction."Document Type";
                "Document No." := TempGenJnlLine."Document No.";
                "Source Code" := GenJnlTemplate."Source Code";
                "Line No." := TempGenJnlLine."Line No." + 10000;
                case InboxJnlLine."Account Type" of
                    InboxJnlLine."Account Type"::"G/L Account":
                        begin
                            "Account Type" := "Account Type"::"G/L Account";
                            Validate("Account No.", TranslateICGLAccount(InboxJnlLine."Account No."));
                        end;
                    InboxJnlLine."Account Type"::Customer:
                        begin
                            "Account Type" := "Account Type"::Customer;
                            Validate("Account No.", TranslateICPartnerToCustomer(InboxJnlLine."IC Partner Code"));
                        end;
                    InboxJnlLine."Account Type"::Vendor:
                        begin
                            "Account Type" := "Account Type"::Vendor;
                            Validate("Account No.", TranslateICPartnerToVendor(InboxJnlLine."IC Partner Code"));
                        end;
                    InboxJnlLine."Account Type"::"IC Partner":
                        begin
                            "Account Type" := "Account Type"::"IC Partner";
                            Validate("Account No.", InboxJnlLine."IC Partner Code");
                        end;
                end;
                if InboxJnlLine.Description <> '' then
                    Description := InboxJnlLine.Description;
                if InboxJnlLine."Currency Code" = GLSetup."LCY Code" then
                    InboxJnlLine."Currency Code" := '';
                Validate("Currency Code", InboxJnlLine."Currency Code");
                Validate(Amount, InboxJnlLine.Amount);
                if ("VAT Amount" <> InboxJnlLine."VAT Amount") and
                   ("VAT Amount" <> 0) and (InboxJnlLine."VAT Amount" <> 0)
                then
                    Validate("VAT Amount", InboxJnlLine."VAT Amount");
                "Due Date" := InboxJnlLine."Due Date";
                Validate("Payment Discount %", InboxJnlLine."Payment Discount %");
                Validate("Pmt. Discount Date", InboxJnlLine."Payment Discount Date");
                Quantity := InboxJnlLine.Quantity;
                "IC Direction" := TempGenJnlLine."IC Direction"::Incoming;
                "IC Partner Transaction No." := InboxJnlLine."Transaction No.";
                "External Document No." := InboxJnlLine."Document No.";
                OnBeforeInsertGenJnlLine(GenJnlLine2, InboxJnlLine);
                Insert;
                InOutBoxJnlLineDim.SetRange("Table ID", DATABASE::"IC Inbox Jnl. Line");
                InOutBoxJnlLineDim.SetRange("Transaction No.", InboxTransaction."Transaction No.");
                InOutBoxJnlLineDim.SetRange("Line No.", InboxJnlLine."Line No.");
                InOutBoxJnlLineDim.SetRange("IC Partner Code", InboxTransaction."IC Partner Code");
                TempInOutBoxJnlLineDim.DeleteAll;
                DimMgt.CopyICJnlDimToICJnlDim(InOutBoxJnlLineDim, TempInOutBoxJnlLineDim);
                "Dimension Set ID" := DimMgt.CreateDimSetIDFromICJnlLineDim(TempInOutBoxJnlLineDim);
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code",
                  "Shortcut Dimension 2 Code");
                Modify;
                HandledInboxJnlLine.TransferFields(InboxJnlLine);
                HandledInboxJnlLine.Insert;
                TempGenJnlLine."Line No." := "Line No.";
            end;
    end;

    procedure CreateSalesDocument(ICInboxSalesHeader: Record "IC Inbox Sales Header"; ReplacePostingDate: Boolean; PostingDate: Date)
    var
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        SalesHeader: Record "Sales Header";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header";
        HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line";
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSalesDocument(ICInboxSalesHeader, ReplacePostingDate, PostingDate, IsHandled);
        if IsHandled then
            exit;

        with ICInboxSalesHeader do begin
            SalesHeader.Init;
            SalesHeader."No." := '';
            SalesHeader."Document Type" := "Document Type";
            OnCreateSalesDocumentOnBeforeSalesHeaderInsert(SalesHeader, ICInboxSalesHeader);
            SalesHeader.Insert(true);
            SalesHeader.Validate("IC Direction", SalesHeader."IC Direction"::Incoming);
            SalesHeader.Validate("Sell-to Customer No.", "Sell-to Customer No.");
            if SalesHeader."Bill-to Customer No." <> "Bill-to Customer No." then
                SalesHeader.Validate("Bill-to Customer No.", "Bill-to Customer No.");
            SalesHeader."External Document No." := "No.";
            SalesHeader."Ship-to Name" := "Ship-to Name";
            SalesHeader."Ship-to Address" := "Ship-to Address";
            SalesHeader."Ship-to Address 2" := "Ship-to Address 2";
            SalesHeader."Ship-to City" := "Ship-to City";
            SalesHeader."Ship-to Post Code" := "Ship-to Post Code";
            SalesHeader."Ship-to County" := "Ship-to County";
            SalesHeader."Ship-to Country/Region Code" := "Ship-to Country/Region Code";
            if ReplacePostingDate then
                SalesHeader.Validate("Posting Date", PostingDate)
            else
                SalesHeader.Validate("Posting Date", "Posting Date");
            GetCurrency("Currency Code");
            SalesHeader.Validate("Currency Code", "Currency Code");
            SalesHeader.Validate("Document Date", "Document Date");
            SalesHeader.Validate("Prices Including VAT", "Prices Including VAT");
            SalesHeader.Modify;
            SalesHeader.Validate("Due Date", "Due Date");
            SalesHeader.Validate("Payment Discount %", "Payment Discount %");
            SalesHeader.Validate("Pmt. Discount Date", "Pmt. Discount Date");
            SalesHeader.Validate("Requested Delivery Date", "Requested Delivery Date");
            SalesHeader.Validate("Promised Delivery Date", "Promised Delivery Date");
            SalesHeader."Shortcut Dimension 1 Code" := '';
            SalesHeader."Shortcut Dimension 2 Code" := '';

            DimMgt.SetICDocDimFilters(
              ICDocDim, DATABASE::"IC Inbox Sales Header", "IC Transaction No.",
              "IC Partner Code", "Transaction Source", 0);
            DimensionSetIDArr[1] := SalesHeader."Dimension Set ID";
            DimensionSetIDArr[2] := DimMgt.CreateDimSetIDFromICDocDim(ICDocDim);
            SalesHeader."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr,
                SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code");
            DimMgt.UpdateGlobalDimFromDimSetID(SalesHeader."Dimension Set ID", SalesHeader."Shortcut Dimension 1 Code",
              SalesHeader."Shortcut Dimension 2 Code");
            SalesHeader.Modify;

            HandledICInboxSalesHeader.TransferFields(ICInboxSalesHeader);
            HandledICInboxSalesHeader.Insert;
            if ICDocDim.Find('-') then
                DimMgt.MoveICDocDimtoICDocDim(ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Header", "Transaction Source");
        end;

        with ICInboxSalesLine do begin
            SetRange("IC Transaction No.", ICInboxSalesHeader."IC Transaction No.");
            SetRange("IC Partner Code", ICInboxSalesHeader."IC Partner Code");
            SetRange("Transaction Source", ICInboxSalesHeader."Transaction Source");
            if Find('-') then
                repeat
                    CreateSalesLines(SalesHeader, ICInboxSalesLine);
                    HandledICInboxSalesLine.TransferFields(ICInboxSalesLine);
                    OnBeforeHandledICInboxSalesLineInsert(HandledICInboxSalesLine, ICInboxSalesLine);
                    HandledICInboxSalesLine.Insert;
                    DimMgt.SetICDocDimFilters(
                      ICDocDim, DATABASE::"IC Inbox Sales Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
                    if ICDocDim.Find('-') then
                        DimMgt.MoveICDocDimtoICDocDim(ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Line", "Transaction Source");
                until Next = 0;
        end;

        OnAfterCreateSalesDocument(SalesHeader, ICInboxSalesHeader, HandledICInboxSalesHeader);
    end;

    procedure CreateSalesLines(SalesHeader: Record "Sales Header"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    var
        SalesLine: Record "Sales Line";
        ICDocDim: Record "IC Document Dimension";
        ItemCrossReference: Record "Item Cross Reference";
        Currency: Record Currency;
        Precision: Decimal;
        Precision2: Decimal;
        DimensionSetIDArr: array[10] of Integer;
    begin
        with ICInboxSalesLine do begin
            SalesLine.Init;
            SalesLine.TransferFields(ICInboxSalesLine);
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            SalesLine."Line No." := "Line No.";
            case "IC Partner Ref. Type" of
                "IC Partner Ref. Type"::"Common Item No.":
                    begin
                        SalesLine.Type := SalesLine.Type::Item;
                        SalesLine."No." := GetItemFromCommonItem("IC Partner Reference");
                        if SalesLine."No." <> '' then
                            SalesLine.Validate("No.", SalesLine."No.")
                        else
                            SalesLine."No." := "IC Partner Reference";
                    end;
                "IC Partner Ref. Type"::"Cross reference":
                    begin
                        SalesLine.Validate(Type, SalesLine.Type::Item);
                        SalesLine.Validate("Cross-Reference No.", "IC Partner Reference");
                    end;
                "IC Partner Ref. Type"::Item, "IC Partner Ref. Type"::"Vendor Item No.":
                    begin
                        SalesLine.Validate(Type, SalesLine.Type::Item);
                        SalesLine."No." :=
                          GetItemFromRef(
                            "IC Partner Reference", ItemCrossReference."Cross-Reference Type"::Customer, SalesHeader."Sell-to Customer No.");
                        if SalesLine."No." <> '' then
                            SalesLine.Validate("No.", SalesLine."No.")
                        else
                            SalesLine."No." := "IC Partner Reference";
                    end;
                "IC Partner Ref. Type"::"G/L Account":
                    begin
                        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
                        SalesLine.Validate("No.", TranslateICGLAccount("IC Partner Reference"));
                    end;
                "IC Partner Ref. Type"::"Charge (Item)":
                    begin
                        SalesLine.Type := SalesLine.Type::"Charge (Item)";
                        SalesLine.Validate("No.", "IC Partner Reference");
                    end;
            end;
            SalesLine."Currency Code" := SalesHeader."Currency Code";
            SalesLine.Description := Description;
            SalesLine."Description 2" := "Description 2";
            if (SalesLine.Type <> SalesLine.Type::" ") and (Quantity <> 0) then begin
                if Currency.Get(SalesHeader."Currency Code") then begin
                    Precision := Currency."Unit-Amount Rounding Precision";
                    Precision2 := Currency."Amount Rounding Precision";
                end else begin
                    GLSetup.Get;
                    if GLSetup."Unit-Amount Rounding Precision" <> 0 then
                        Precision := GLSetup."Unit-Amount Rounding Precision"
                    else
                        Precision := 0.01;
                    if GLSetup."Amount Rounding Precision" <> 0 then
                        Precision2 := GLSetup."Amount Rounding Precision"
                    else
                        Precision2 := 0.01;
                end;
                SalesLine.Validate(Quantity, Quantity);
                SalesLine.Validate("Unit of Measure Code", "Unit of Measure Code");
                if SalesHeader."Prices Including VAT" then
                    SalesLine.Validate("Unit Price", Round("Amount Including VAT" / Quantity, Precision))
                else
                    SalesLine.Validate("Unit Price", "Unit Price");
                SalesLine.Validate("Line Discount Amount", "Line Discount Amount");
                SalesLine."Amount Including VAT" := "Amount Including VAT";
                SalesLine."VAT Base Amount" := Round("Amount Including VAT" / (1 + (SalesLine."VAT %" / 100)), Precision2);
                if SalesHeader."Prices Including VAT" then
                    SalesLine."Line Amount" := "Amount Including VAT"
                else
                    SalesLine."Line Amount" := Round("Amount Including VAT" / (1 + (SalesLine."VAT %" / 100)), Precision2);
                SalesLine."Line Discount %" := "Line Discount %";
                SalesLine.Validate("Requested Delivery Date", "Requested Delivery Date");
                SalesLine.Validate("Promised Delivery Date", "Promised Delivery Date");
                UpdateSalesLineICPartnerReference(SalesLine, SalesHeader, ICInboxSalesLine);
            end;
            SalesLine."Shortcut Dimension 1 Code" := '';
            SalesLine."Shortcut Dimension 2 Code" := '';
            SalesLine.Insert(true);
            SalesLine.Validate(Quantity);

            DimMgt.SetICDocDimFilters(
              ICDocDim, DATABASE::"IC Inbox Sales Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
            DimensionSetIDArr[1] := SalesLine."Dimension Set ID";
            DimensionSetIDArr[2] := DimMgt.CreateDimSetIDFromICDocDim(ICDocDim);

            SalesLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr,
                SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
            DimMgt.UpdateGlobalDimFromDimSetID(SalesLine."Dimension Set ID", SalesLine."Shortcut Dimension 1 Code",
              SalesLine."Shortcut Dimension 2 Code");
            OnAfterCreateSalesLines(ICInboxSalesLine, SalesLine);
            SalesLine.Modify;
        end;
    end;

    procedure CreatePurchDocument(ICInboxPurchHeader: Record "IC Inbox Purchase Header"; ReplacePostingDate: Boolean; PostingDate: Date)
    var
        ICInboxPurchLine: Record "IC Inbox Purchase Line";
        PurchHeader: Record "Purchase Header";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
        HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        DimensionSetIDArr: array[10] of Integer;
    begin
        with ICInboxPurchHeader do begin
            PurchHeader.Init;
            PurchHeader."No." := '';
            PurchHeader."Document Type" := "Document Type";
            OnCreatePurchDocumentOnBeforePurchHeaderInsert(PurchHeader, ICInboxPurchHeader);
            PurchHeader.Insert(true);
            PurchHeader.Validate("IC Direction", PurchHeader."IC Direction"::Incoming);
            PurchHeader.Validate("Buy-from Vendor No.", "Buy-from Vendor No.");
            if "Pay-to Vendor No." <> PurchHeader."Pay-to Vendor No." then
                PurchHeader.Validate("Pay-to Vendor No.", "Pay-to Vendor No.");
            case "Document Type" of
                "Document Type"::Order, "Document Type"::"Return Order":
                    PurchHeader."Vendor Order No." := "No.";
                "Document Type"::Invoice:
                    PurchHeader."Vendor Invoice No." := "No.";
                "Document Type"::"Credit Memo":
                    PurchHeader."Vendor Cr. Memo No." := "No.";
            end;
            PurchHeader."Your Reference" := "Your Reference";
            PurchHeader."Ship-to Name" := "Ship-to Name";
            PurchHeader."Ship-to Address" := "Ship-to Address";
            PurchHeader."Ship-to Address 2" := "Ship-to Address 2";
            PurchHeader."Ship-to City" := "Ship-to City";
            PurchHeader."Ship-to Post Code" := "Ship-to Post Code";
            PurchHeader."Ship-to County" := "Ship-to County";
            PurchHeader."Ship-to Country/Region Code" := "Ship-to Country/Region Code";
            PurchHeader."Vendor Order No." := "Vendor Order No.";
            if ReplacePostingDate then
                PurchHeader.Validate("Posting Date", PostingDate)
            else
                PurchHeader.Validate("Posting Date", "Posting Date");
            GetCurrency("Currency Code");
            PurchHeader.Validate("Currency Code", "Currency Code");
            PurchHeader.Validate("Document Date", "Document Date");
            PurchHeader.Validate("Requested Receipt Date", "Requested Receipt Date");
            PurchHeader.Validate("Promised Receipt Date", "Promised Receipt Date");
            PurchHeader.Validate("Prices Including VAT", "Prices Including VAT");
            PurchHeader.Validate("Due Date", "Due Date");
            PurchHeader.Validate("Payment Discount %", "Payment Discount %");
            PurchHeader.Validate("Pmt. Discount Date", "Pmt. Discount Date");
            PurchHeader."Shortcut Dimension 1 Code" := '';
            PurchHeader."Shortcut Dimension 2 Code" := '';
            PurchHeader.Modify;

            DimMgt.SetICDocDimFilters(
              ICDocDim, DATABASE::"IC Inbox Purchase Header", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
            GLSetup.Get;

            DimensionSetIDArr[1] := PurchHeader."Dimension Set ID";
            DimensionSetIDArr[2] := DimMgt.CreateDimSetIDFromICDocDim(ICDocDim);
            PurchHeader."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr,
                PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code");
            DimMgt.UpdateGlobalDimFromDimSetID(PurchHeader."Dimension Set ID", PurchHeader."Shortcut Dimension 1 Code",
              PurchHeader."Shortcut Dimension 2 Code");
            PurchHeader.Modify;

            HandledICInboxPurchHeader.TransferFields(ICInboxPurchHeader);
            HandledICInboxPurchHeader.Insert;
            if ICDocDim.Find('-') then
                DimMgt.MoveICDocDimtoICDocDim(ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Header", "Transaction Source");
        end;

        with ICInboxPurchLine do begin
            SetRange("IC Transaction No.", ICInboxPurchHeader."IC Transaction No.");
            SetRange("IC Partner Code", ICInboxPurchHeader."IC Partner Code");
            SetRange("Transaction Source", ICInboxPurchHeader."Transaction Source");
            if Find('-') then
                repeat
                    CreatePurchLines(PurchHeader, ICInboxPurchLine);
                    HandledICInboxPurchLine.TransferFields(ICInboxPurchLine);
                    OnCreatePurchDocumentOnBeforeHandledICInboxPurchLineInsert(ICInboxPurchLine, HandledICInboxPurchLine);
                    HandledICInboxPurchLine.Insert;

                    DimMgt.SetICDocDimFilters(
                      ICDocDim, DATABASE::"IC Inbox Purchase Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
                    if ICDocDim.Find('-') then
                        DimMgt.MoveICDocDimtoICDocDim(ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Line", "Transaction Source");
                until Next = 0;
        end;
        OnAfterCreatePurchDocument(PurchHeader, ICInboxPurchHeader, HandledICInboxPurchHeader);
    end;

    procedure CreatePurchLines(PurchHeader: Record "Purchase Header"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    var
        PurchLine: Record "Purchase Line";
        ICDocDim: Record "IC Document Dimension";
        ItemCrossReference: Record "Item Cross Reference";
        Currency: Record Currency;
        Precision: Decimal;
        Precision2: Decimal;
        DimensionSetIDArr: array[10] of Integer;
    begin
        with ICInboxPurchLine do begin
            PurchLine.Init;
            PurchLine.TransferFields(ICInboxPurchLine);
            PurchLine."Document Type" := PurchHeader."Document Type";
            PurchLine."Document No." := PurchHeader."No.";
            PurchLine."Line No." := "Line No.";
            PurchLine.Insert(true);
            PurchLine."Receipt No." := '';
            PurchLine."Return Shipment No." := '';
            case "IC Partner Ref. Type" of
                "IC Partner Ref. Type"::"Common Item No.":
                    begin
                        PurchLine.Type := PurchLine.Type::Item;
                        PurchLine."No." := GetItemFromCommonItem("IC Partner Reference");
                        if PurchLine."No." <> '' then
                            PurchLine.Validate("No.", PurchLine."No.")
                        else
                            PurchLine."No." := "IC Partner Reference";
                    end;
                "IC Partner Ref. Type"::Item:
                    begin
                        PurchLine.Validate(Type, PurchLine.Type::Item);
                        PurchLine."No." :=
                          GetItemFromRef(
                            "IC Partner Reference", ItemCrossReference."Cross-Reference Type"::Vendor, PurchHeader."Buy-from Vendor No.");
                        if PurchLine."No." <> '' then
                            PurchLine.Validate("No.", PurchLine."No.")
                        else
                            PurchLine."No." := "IC Partner Reference";
                    end;
                "IC Partner Ref. Type"::"G/L Account":
                    begin
                        PurchLine.Validate(Type, PurchLine.Type::"G/L Account");
                        PurchLine.Validate("No.", TranslateICGLAccount("IC Partner Reference"));
                    end;
                "IC Partner Ref. Type"::"Charge (Item)":
                    begin
                        PurchLine.Type := PurchLine.Type::"Charge (Item)";
                        PurchLine.Validate("No.", "IC Partner Reference");
                    end;
                "IC Partner Ref. Type"::"Cross reference":
                    begin
                        PurchLine.Validate(Type, PurchLine.Type::Item);
                        PurchLine.Validate("Cross-Reference No.", "IC Partner Reference");
                    end;
            end;
            PurchLine."Currency Code" := PurchHeader."Currency Code";
            PurchLine.Description := Description;
            PurchLine."Description 2" := "Description 2";
            if (PurchLine.Type <> PurchLine.Type::" ") and (Quantity <> 0) then begin
                if Currency.Get(PurchHeader."Currency Code") then begin
                    Precision := Currency."Unit-Amount Rounding Precision";
                    Precision2 := Currency."Amount Rounding Precision"
                end else begin
                    GLSetup.Get;
                    if GLSetup."Unit-Amount Rounding Precision" <> 0 then
                        Precision := GLSetup."Unit-Amount Rounding Precision"
                    else
                        Precision := 0.01;
                    if GLSetup."Amount Rounding Precision" <> 0 then
                        Precision2 := GLSetup."Amount Rounding Precision"
                    else
                        Precision2 := 0.01;
                end;
                PurchLine.Validate(Quantity, Quantity);
                PurchLine.Validate("Unit of Measure Code", "Unit of Measure Code");
                if PurchHeader."Prices Including VAT" then
                    PurchLine.Validate("Direct Unit Cost", Round("Amount Including VAT" / Quantity, Precision))
                else
                    PurchLine.Validate("Direct Unit Cost", "Direct Unit Cost");
                PurchLine.Validate("Line Discount Amount", "Line Discount Amount");
                PurchLine."Amount Including VAT" := "Amount Including VAT";
                PurchLine."VAT Base Amount" := Round("Amount Including VAT" / (1 + (PurchLine."VAT %" / 100)), Precision2);
                if PurchHeader."Prices Including VAT" then
                    PurchLine."Line Amount" := "Amount Including VAT"
                else
                    PurchLine."Line Amount" := Round("Amount Including VAT" / (1 + (PurchLine."VAT %" / 100)), Precision2);
                PurchLine.Validate("Requested Receipt Date", "Requested Receipt Date");
                PurchLine.Validate("Promised Receipt Date", "Promised Receipt Date");
                PurchLine."Line Discount %" := "Line Discount %";
                PurchLine."Receipt No." := "Receipt No.";
                PurchLine."Receipt Line No." := "Receipt Line No.";
                PurchLine."Return Shipment No." := "Return Shipment No.";
                PurchLine."Return Shipment Line No." := "Return Shipment Line No.";
                UpdatePurchLineICPartnerReference(PurchLine, PurchHeader, ICInboxPurchLine);
                UpdatePurchLineReceiptShipment(PurchLine);
            end;
            PurchLine."Shortcut Dimension 1 Code" := '';
            PurchLine."Shortcut Dimension 2 Code" := '';

            DimMgt.SetICDocDimFilters(
              ICDocDim, DATABASE::"IC Inbox Purchase Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
            DimensionSetIDArr[1] := PurchLine."Dimension Set ID";
            DimensionSetIDArr[2] := DimMgt.CreateDimSetIDFromICDocDim(ICDocDim);
            PurchLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr,
                PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code");
            DimMgt.UpdateGlobalDimFromDimSetID(PurchLine."Dimension Set ID", PurchLine."Shortcut Dimension 1 Code",
              PurchLine."Shortcut Dimension 2 Code");

            OnAfterCreatePurchLines(ICInboxPurchLine, PurchLine);
            PurchLine.Modify;
        end;
    end;

    procedure CreateHandledInbox(InboxTransaction: Record "IC Inbox Transaction")
    var
        HandledInboxTransaction: Record "Handled IC Inbox Trans.";
    begin
        HandledInboxTransaction.Init;
        HandledInboxTransaction."Transaction No." := InboxTransaction."Transaction No.";
        HandledInboxTransaction."IC Partner Code" := InboxTransaction."IC Partner Code";
        HandledInboxTransaction."Source Type" := InboxTransaction."Source Type";
        HandledInboxTransaction."Document Type" := InboxTransaction."Document Type";
        HandledInboxTransaction."Document No." := InboxTransaction."Document No.";
        HandledInboxTransaction."Posting Date" := InboxTransaction."Posting Date";
        HandledInboxTransaction."Transaction Source" := InboxTransaction."Transaction Source";
        HandledInboxTransaction."Document Date" := InboxTransaction."Document Date";

        case InboxTransaction."Line Action" of
            InboxTransaction."Line Action"::"Return to IC Partner":
                HandledInboxTransaction."Transaction Source" := HandledInboxTransaction."Transaction Source"::"Returned by Partner";
            InboxTransaction."Line Action"::Accept:
                if InboxTransaction."Transaction Source" = InboxTransaction."Transaction Source"::"Created by Partner" then
                    HandledInboxTransaction."Transaction Source" := HandledInboxTransaction."Transaction Source"::"Created by Partner"
                else
                    HandledInboxTransaction."Transaction Source" := HandledInboxTransaction."Transaction Source"::"Returned by Partner";
        end;
        OnBeforeHandledInboxTransactionInsert(HandledInboxTransaction, InboxTransaction);
        HandledInboxTransaction.Insert;
    end;

    procedure RecreateInboxTransaction(var HandledInboxTransaction: Record "Handled IC Inbox Trans.")
    var
        HandledInboxTransaction2: Record "Handled IC Inbox Trans.";
        HandledInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        InboxTransaction: Record "IC Inbox Transaction";
        InboxJnlLine: Record "IC Inbox Jnl. Line";
        ICCommentLine: Record "IC Comment Line";
        HandledInboxSalesHdr: Record "Handled IC Inbox Sales Header";
        InboxSalesHdr: Record "IC Inbox Sales Header";
        HandledInboxSalesLine: Record "Handled IC Inbox Sales Line";
        InboxSalesLine: Record "IC Inbox Sales Line";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HandledInboxPurchHdr: Record "Handled IC Inbox Purch. Header";
        InboxPurchHdr: Record "IC Inbox Purchase Header";
        HandledInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        InboxPurchLine: Record "IC Inbox Purchase Line";
        ICIOMgt: Codeunit ICInboxOutboxMgt;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        with HandledInboxTransaction do
            if not (Status in [Status::Accepted, Status::Cancelled]) then
                Error(Text005, FieldCaption(Status), Status::Accepted, Status::Cancelled);

        if ConfirmManagement.GetResponseOrDefault(Text000, true) then begin
            HandledInboxTransaction2 := HandledInboxTransaction;
            HandledInboxTransaction2.LockTable;
            InboxTransaction.LockTable;
            InboxTransaction.Init;
            InboxTransaction."Transaction No." := HandledInboxTransaction2."Transaction No.";
            InboxTransaction."IC Partner Code" := HandledInboxTransaction2."IC Partner Code";
            InboxTransaction."Source Type" := HandledInboxTransaction2."Source Type";
            InboxTransaction."Document Type" := HandledInboxTransaction2."Document Type";
            InboxTransaction."Document No." := HandledInboxTransaction2."Document No.";
            InboxTransaction."Posting Date" := HandledInboxTransaction2."Posting Date";
            InboxTransaction."Transaction Source" := InboxTransaction."Transaction Source"::"Created by Partner";
            InboxTransaction."Transaction Source" := HandledInboxTransaction2."Transaction Source";
            InboxTransaction."Document Date" := HandledInboxTransaction2."Document Date";
            InboxTransaction."IC Partner G/L Acc. No." := HandledInboxTransaction2."IC Partner G/L Acc. No.";
            InboxTransaction."Source Line No." := HandledInboxTransaction2."Source Line No.";
            OnRecreateInboxTransactionOnBeforeInboxTransactionInsert(InboxTransaction, HandledInboxTransaction2);
            InboxTransaction.Insert;
            case InboxTransaction."Source Type" of
                InboxTransaction."Source Type"::Journal:
                    begin
                        HandledInboxJnlLine.LockTable;
                        InboxJnlLine.LockTable;
                        HandledInboxJnlLine.SetRange("Transaction No.", HandledInboxTransaction2."Transaction No.");
                        HandledInboxJnlLine.SetRange("IC Partner Code", HandledInboxTransaction2."IC Partner Code");
                        if HandledInboxJnlLine.Find('-') then
                            repeat
                                InboxJnlLine.Init;
                                InboxJnlLine.TransferFields(HandledInboxJnlLine);
                                InboxJnlLine.Insert;
                                ICIOMgt.MoveICJnlDimToHandled(DATABASE::"Handled IC Inbox Jnl. Line", DATABASE::"IC Inbox Jnl. Line",
                                  HandledInboxTransaction."Transaction No.", HandledInboxTransaction."IC Partner Code",
                                  false, 0);
                            until HandledInboxJnlLine.Next = 0;
                        HandleICComments(ICCommentLine."Table Name"::"Handled IC Inbox Transaction",
                          ICCommentLine."Table Name"::"IC Inbox Transaction", HandledInboxTransaction2."Transaction No.",
                          HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source");
                        HandledInboxTransaction.Delete(true);
                        Commit;
                    end;
                InboxTransaction."Source Type"::"Sales Document":
                    begin
                        if HandledInboxSalesHdr.Get(HandledInboxTransaction2."Transaction No.",
                             HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source")
                        then begin
                            InboxSalesHdr.TransferFields(HandledInboxSalesHdr);
                            OnRecreateInboxTransactionOnBeforeInboxSalesHdrInsert(InboxSalesHdr, HandledInboxSalesHdr);
                            InboxSalesHdr.Insert;

                            ICDocDim.Reset;
                            DimMgt.SetICDocDimFilters(
                              ICDocDim, DATABASE::"Handled IC Inbox Sales Header", HandledInboxTransaction2."Transaction No.",
                              HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source", 0);
                            if ICDocDim.Find('-') then
                                DimMgt.MoveICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"IC Inbox Sales Header", InboxSalesHdr."Transaction Source");
                            HandledInboxSalesLine.SetRange("IC Transaction No.", HandledInboxTransaction2."Transaction No.");
                            HandledInboxSalesLine.SetRange("IC Partner Code", HandledInboxTransaction2."IC Partner Code");
                            HandledInboxSalesLine.SetRange("Transaction Source", HandledInboxTransaction2."Transaction Source");
                            if HandledInboxSalesLine.Find('-') then
                                repeat
                                    InboxSalesLine.TransferFields(HandledInboxSalesLine);
                                    OnBeforeInboxSalesLineInsert(InboxSalesLine, HandledInboxSalesLine);
                                    InboxSalesLine.Insert;

                                    ICDocDim.Reset;
                                    DimMgt.SetICDocDimFilters(
                                      ICDocDim, DATABASE::"Handled IC Inbox Sales Line", HandledInboxTransaction2."Transaction No.",
                                      HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source",
                                      HandledInboxSalesLine."Line No.");
                                    if ICDocDim.Find('-') then
                                        DimMgt.MoveICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"IC Inbox Sales Line", InboxSalesLine."Transaction Source");
                                    HandledInboxSalesLine.Delete(true);
                                until HandledInboxSalesLine.Next = 0;
                        end;
                        HandleICComments(ICCommentLine."Table Name"::"Handled IC Inbox Transaction",
                          ICCommentLine."Table Name"::"IC Inbox Transaction", HandledInboxTransaction2."Transaction No.",
                          HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source");
                        OnRecreateInboxTransactionOnBeforeDeleteSalesHeader(HandledInboxSalesHdr, HandledInboxTransaction2);
                        HandledInboxSalesHdr.Delete(true);
                        HandledInboxTransaction.Delete(true);
                        Commit;
                    end;
                InboxTransaction."Source Type"::"Purchase Document":
                    begin
                        if HandledInboxPurchHdr.Get(HandledInboxTransaction2."Transaction No.",
                             HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source")
                        then begin
                            InboxPurchHdr.TransferFields(HandledInboxPurchHdr);
                            OnRecreateInboxTransactionOnBeforeInboxPurchHdrInsert(InboxPurchHdr, HandledInboxPurchHdr);
                            InboxPurchHdr.Insert;

                            ICDocDim.Reset;
                            DimMgt.SetICDocDimFilters(
                              ICDocDim, DATABASE::"Handled IC Inbox Purch. Header", HandledInboxTransaction2."Transaction No.",
                              HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source", 0);
                            if ICDocDim.Find('-') then
                                DimMgt.MoveICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"IC Inbox Purchase Header", InboxPurchHdr."Transaction Source");
                            HandledInboxPurchLine.SetRange("IC Transaction No.", HandledInboxTransaction2."Transaction No.");
                            HandledInboxPurchLine.SetRange("IC Partner Code", HandledInboxTransaction2."IC Partner Code");
                            HandledInboxPurchLine.SetRange("Transaction Source", HandledInboxTransaction2."Transaction Source");
                            if HandledInboxPurchLine.Find('-') then
                                repeat
                                    InboxPurchLine.TransferFields(HandledInboxPurchLine);
                                    OnRecreateInboxTransactionOnBeforeInboxPurchLineInsert(InboxPurchLine, HandledInboxPurchLine);
                                    InboxPurchLine.Insert;

                                    ICDocDim.Reset;
                                    DimMgt.SetICDocDimFilters(
                                      ICDocDim, DATABASE::"Handled IC Inbox Purch. Line", HandledInboxTransaction2."Transaction No.",
                                      HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source",
                                      HandledInboxPurchLine."Line No.");
                                    if ICDocDim.Find('-') then
                                        DimMgt.MoveICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"IC Inbox Purchase Line", InboxPurchLine."Transaction Source");
                                    HandledInboxPurchLine.Delete(true);
                                until HandledInboxPurchLine.Next = 0;
                        end;
                        HandleICComments(ICCommentLine."Table Name"::"Handled IC Inbox Transaction",
                          ICCommentLine."Table Name"::"IC Inbox Transaction", HandledInboxTransaction2."Transaction No.",
                          HandledInboxTransaction2."IC Partner Code", HandledInboxTransaction2."Transaction Source");
                        OnRecreateInboxTransactionOnBeforeDeletePurchHeader(HandledInboxPurchHdr, HandledInboxTransaction2);
                        HandledInboxPurchHdr.Delete(true);
                        HandledInboxTransaction.Delete(true);
                    end;
            end;
        end
    end;

    procedure RecreateOutboxTransaction(var HandledOutboxTransaction: Record "Handled IC Outbox Trans.")
    var
        HandledOutboxTransaction2: Record "Handled IC Outbox Trans.";
        HandledOutboxJnlLine: Record "Handled IC Outbox Jnl. Line";
        OutboxTransaction: Record "IC Outbox Transaction";
        OutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICCommentLine: Record "IC Comment Line";
        HandledOutboxSalesHdr: Record "Handled IC Outbox Sales Header";
        OutboxSalesHdr: Record "IC Outbox Sales Header";
        HandledOutboxSalesLine: Record "Handled IC Outbox Sales Line";
        OutboxSalesLine: Record "IC Outbox Sales Line";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HandledOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        OutboxPurchHdr: Record "IC Outbox Purchase Header";
        HandledOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
        OutboxPurchLine: Record "IC Outbox Purchase Line";
        ICIOMgt: Codeunit ICInboxOutboxMgt;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        with HandledOutboxTransaction do
            if not (Status in [Status::"Sent to IC Partner", Status::Cancelled]) then
                Error(Text005, FieldCaption(Status), Status::"Sent to IC Partner", Status::Cancelled);

        if ConfirmManagement.GetResponseOrDefault(Text000, true) then begin
            HandledOutboxTransaction2 := HandledOutboxTransaction;
            HandledOutboxTransaction2.LockTable;
            OutboxTransaction.LockTable;
            OutboxTransaction.Init;
            OutboxTransaction."Transaction No." := HandledOutboxTransaction2."Transaction No.";
            OutboxTransaction."IC Partner Code" := HandledOutboxTransaction2."IC Partner Code";
            OutboxTransaction."Source Type" := HandledOutboxTransaction2."Source Type";
            OutboxTransaction."Document Type" := HandledOutboxTransaction2."Document Type";
            OutboxTransaction."Document No." := HandledOutboxTransaction2."Document No.";
            OutboxTransaction."Posting Date" := HandledOutboxTransaction2."Posting Date";
            OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Created by Current Company";
            OutboxTransaction."Transaction Source" := HandledOutboxTransaction2."Transaction Source";
            OutboxTransaction."Document Date" := HandledOutboxTransaction2."Document Date";
            OutboxTransaction."IC Partner G/L Acc. No." := HandledOutboxTransaction2."IC Partner G/L Acc. No.";
            OutboxTransaction."Source Line No." := HandledOutboxTransaction2."Source Line No.";
            OnRecreateOutboxTransactionOnBeforeOutboxTransactionInsert(OutboxTransaction, HandledOutboxTransaction2);
            OutboxTransaction.Insert;
            case OutboxTransaction."Source Type" of
                OutboxTransaction."Source Type"::"Journal Line":
                    begin
                        HandledOutboxJnlLine.LockTable;
                        OutboxJnlLine.LockTable;
                        HandledOutboxJnlLine.SetRange("Transaction No.", HandledOutboxTransaction2."Transaction No.");
                        HandledOutboxJnlLine.SetRange("IC Partner Code", HandledOutboxTransaction2."IC Partner Code");
                        if HandledOutboxJnlLine.Find('-') then
                            repeat
                                OutboxJnlLine.Init;
                                OutboxJnlLine.TransferFields(HandledOutboxJnlLine);
                                OutboxJnlLine.Insert;
                                ICIOMgt.MoveICJnlDimToHandled(DATABASE::"Handled IC Outbox Jnl. Line", DATABASE::"IC Outbox Jnl. Line",
                                  HandledOutboxTransaction."Transaction No.", HandledOutboxTransaction."IC Partner Code",
                                  false, 0);
                            until HandledOutboxJnlLine.Next = 0;
                        HandleICComments(ICCommentLine."Table Name"::"Handled IC Outbox Transaction",
                          ICCommentLine."Table Name"::"IC Outbox Transaction", HandledOutboxTransaction2."Transaction No.",
                          HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source");
                        HandledOutboxTransaction.Delete(true);
                        Commit;
                    end;
                OutboxTransaction."Source Type"::"Sales Document":
                    begin
                        if HandledOutboxSalesHdr.Get(HandledOutboxTransaction2."Transaction No.",
                             HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source")
                        then begin
                            OutboxSalesHdr.TransferFields(HandledOutboxSalesHdr);
                            OutboxSalesHdr.Insert;
                            ICDocDim.Reset;
                            DimMgt.SetICDocDimFilters(
                              ICDocDim, DATABASE::"Handled IC Outbox Sales Header", HandledOutboxTransaction2."Transaction No.",
                              HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source", 0);
                            if ICDocDim.Find('-') then
                                DimMgt.MoveICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"IC Outbox Sales Header", OutboxSalesHdr."Transaction Source");
                            HandledOutboxSalesLine.SetRange("IC Transaction No.", HandledOutboxTransaction2."Transaction No.");
                            HandledOutboxSalesLine.SetRange("IC Partner Code", HandledOutboxTransaction2."IC Partner Code");
                            HandledOutboxSalesLine.SetRange("Transaction Source", HandledOutboxTransaction2."Transaction Source");
                            if HandledOutboxSalesLine.Find('-') then
                                repeat
                                    OutboxSalesLine.TransferFields(HandledOutboxSalesLine);
                                    OutboxSalesLine.Insert;
                                    ICDocDim.Reset;
                                    DimMgt.SetICDocDimFilters(
                                      ICDocDim, DATABASE::"Handled IC Outbox Sales Line", HandledOutboxTransaction2."Transaction No.",
                                      HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source",
                                      HandledOutboxSalesLine."Line No.");
                                    if ICDocDim.Find('-') then
                                        DimMgt.MoveICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"IC Outbox Sales Line", OutboxSalesLine."Transaction Source");
                                    HandledOutboxSalesLine.Delete(true);
                                until HandledOutboxSalesLine.Next = 0;
                        end;
                        HandleICComments(ICCommentLine."Table Name"::"Handled IC Outbox Transaction",
                          ICCommentLine."Table Name"::"IC Outbox Transaction", HandledOutboxTransaction2."Transaction No.",
                          HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source");
                        OnRecreateOutboxTransactionOnBeforeDeleteSalesHeader(HandledOutboxSalesHdr, HandledOutboxTransaction2);
                        HandledOutboxSalesHdr.Delete(true);
                        HandledOutboxTransaction.Delete(true);
                    end;
                OutboxTransaction."Source Type"::"Purchase Document":
                    begin
                        if HandledOutboxPurchHdr.Get(HandledOutboxTransaction2."Transaction No.",
                             HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source")
                        then begin
                            OutboxPurchHdr.TransferFields(HandledOutboxPurchHdr);
                            OnRecreateOutboxTransactionOnBeforeOutboxPurchHdrInsert(OutboxPurchHdr, HandledOutboxPurchHdr);
                            OutboxPurchHdr.Insert;

                            ICDocDim.Reset;
                            DimMgt.SetICDocDimFilters(
                              ICDocDim, DATABASE::"Handled IC Outbox Purch. Hdr", HandledOutboxTransaction2."Transaction No.",
                              HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source", 0);
                            if ICDocDim.Find('-') then
                                DimMgt.MoveICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"IC Outbox Purchase Header", OutboxPurchHdr."Transaction Source");
                            HandledOutboxPurchLine.SetRange("IC Transaction No.", HandledOutboxTransaction2."Transaction No.");
                            HandledOutboxPurchLine.SetRange("IC Partner Code", HandledOutboxTransaction2."IC Partner Code");
                            HandledOutboxPurchLine.SetRange("Transaction Source", HandledOutboxTransaction2."Transaction Source");
                            if HandledOutboxPurchLine.Find('-') then
                                repeat
                                    OutboxPurchLine.TransferFields(HandledOutboxPurchLine);
                                    OnRecreateOutboxTransactionOnBeforeOutboxPurchLineInsert(OutboxPurchLine, HandledOutboxPurchLine);
                                    OutboxPurchLine.Insert;

                                    ICDocDim.Reset;
                                    DimMgt.SetICDocDimFilters(
                                      ICDocDim, DATABASE::"Handled IC Outbox Purch. Line", HandledOutboxTransaction2."Transaction No.",
                                      HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source",
                                      HandledOutboxPurchLine."Line No.");
                                    if ICDocDim.Find('-') then
                                        DimMgt.MoveICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"IC Outbox Purchase Line", OutboxPurchLine."Transaction Source");
                                    HandledOutboxPurchLine.Delete(true);
                                until HandledOutboxPurchLine.Next = 0;
                        end;
                        HandleICComments(ICCommentLine."Table Name"::"Handled IC Outbox Transaction",
                          ICCommentLine."Table Name"::"IC Outbox Transaction", HandledOutboxTransaction2."Transaction No.",
                          HandledOutboxTransaction2."IC Partner Code", HandledOutboxTransaction2."Transaction Source");
                        OnRecreateOutboxTransactionOnBeforeDeletePurchHeader(HandledOutboxPurchHdr, HandledOutboxTransaction2);
                        HandledOutboxPurchHdr.Delete(true);
                        HandledOutboxTransaction.Delete(true);
                    end;
            end;
        end
    end;

    procedure ForwardToOutBox(InboxTransaction: Record "IC Inbox Transaction")
    var
        OutboxTransaction: Record "IC Outbox Transaction";
        OutboxJnlLine: Record "IC Outbox Jnl. Line";
        InboxJnlLine: Record "IC Inbox Jnl. Line";
        OutboxSalesHdr: Record "IC Outbox Sales Header";
        OutboxSalesLine: Record "IC Outbox Sales Line";
        InboxSalesHdr: Record "IC Inbox Sales Header";
        InboxSalesLine: Record "IC Inbox Sales Line";
        OutboxPurchHdr: Record "IC Outbox Purchase Header";
        OutboxPurchLine: Record "IC Outbox Purchase Line";
        InboxPurchHdr: Record "IC Inbox Purchase Header";
        InboxPurchLine: Record "IC Inbox Purchase Line";
        ICDocDim: Record "IC Document Dimension";
        ICDocDim2: Record "IC Document Dimension";
        HndlInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        HndlInboxSalesHdr: Record "Handled IC Inbox Sales Header";
        HndlInboxSalesLine: Record "Handled IC Inbox Sales Line";
        HndlInboxPurchHdr: Record "Handled IC Inbox Purch. Header";
        HndlInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        ICJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        ICJnlLineDim2: Record "IC Inbox/Outbox Jnl. Line Dim.";
    begin
        with InboxTransaction do begin
            OutboxTransaction.Init;
            OutboxTransaction."Transaction No." := "Transaction No.";
            OutboxTransaction."IC Partner Code" := "IC Partner Code";
            OutboxTransaction."Source Type" := "Source Type";
            OutboxTransaction."Document Type" := "Document Type";
            OutboxTransaction."Document No." := "Document No.";
            OutboxTransaction."Posting Date" := "Posting Date";
            OutboxTransaction."Transaction Source" := OutboxTransaction."Transaction Source"::"Rejected by Current Company";
            OutboxTransaction."Document Date" := "Document Date";
            OnForwardToOutBoxOnBeforeOutboxTransactionInsert(OutboxTransaction, InboxTransaction);
            OutboxTransaction.Insert;
            case "Source Type" of
                "Source Type"::Journal:
                    begin
                        InboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                        InboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                        InboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                        if InboxJnlLine.Find('-') then
                            repeat
                                OutboxJnlLine.TransferFields(InboxJnlLine);
                                OutboxJnlLine."Transaction Source" := OutboxTransaction."Transaction Source";
                                OutboxJnlLine.Insert;
                                HndlInboxJnlLine.TransferFields(InboxJnlLine);
                                HndlInboxJnlLine.Insert;

                                ICJnlLineDim.SetRange("Table ID", DATABASE::"IC Inbox Jnl. Line");
                                ICJnlLineDim.SetRange("Transaction No.", InboxJnlLine."Transaction No.");
                                ICJnlLineDim.SetRange("IC Partner Code", InboxJnlLine."IC Partner Code");
                                ICJnlLineDim.SetRange("Line No.", InboxJnlLine."Line No.");
                                if ICJnlLineDim.Find('-') then
                                    repeat
                                        ICJnlLineDim2 := ICJnlLineDim;
                                        ICJnlLineDim2."Table ID" := DATABASE::"IC Outbox Jnl. Line";
                                        ICJnlLineDim2."Transaction Source" := OutboxJnlLine."Transaction Source";
                                        ICJnlLineDim2.Insert;
                                    until ICJnlLineDim.Next = 0;

                            until InboxJnlLine.Next = 0;
                    end;
                "Source Type"::"Sales Document":
                    begin
                        if InboxSalesHdr.Get("Transaction No.", "IC Partner Code", "Transaction Source") then begin
                            OutboxSalesHdr.TransferFields(InboxSalesHdr);
                            OutboxSalesHdr."Transaction Source" := OutboxTransaction."Transaction Source";
                            OutboxSalesHdr.Insert;
                            ICDocDim.Reset;
                            DimMgt.SetICDocDimFilters(
                              ICDocDim, DATABASE::"IC Inbox Sales Header", "Transaction No.", "IC Partner Code", "Transaction Source", 0);
                            if ICDocDim.Find('-') then
                                DimMgt.CopyICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"IC Outbox Sales Header", OutboxSalesHdr."Transaction Source");
                            HndlInboxSalesHdr.TransferFields(InboxSalesHdr);
                            HndlInboxSalesHdr.Insert;
                            if ICDocDim.Find('-') then
                                DimMgt.MoveICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Header", InboxSalesHdr."Transaction Source");
                            InboxSalesLine.SetRange("IC Transaction No.", "Transaction No.");
                            InboxSalesLine.SetRange("IC Partner Code", "IC Partner Code");
                            InboxSalesLine.SetRange("Transaction Source", "Transaction Source");
                            if InboxSalesLine.Find('-') then
                                repeat
                                    OutboxSalesLine.TransferFields(InboxSalesLine);
                                    OutboxSalesLine."Transaction Source" := OutboxTransaction."Transaction Source";
                                    OutboxSalesLine.Insert;
                                    ICDocDim.Reset;
                                    DimMgt.SetICDocDimFilters(
                                      ICDocDim, DATABASE::"IC Inbox Sales Line", "Transaction No.", "IC Partner Code", "Transaction Source",
                                      OutboxSalesLine."Line No.");
                                    if ICDocDim.Find('-') then
                                        DimMgt.CopyICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"IC Outbox Sales Line", OutboxSalesLine."Transaction Source");
                                    HndlInboxSalesLine.TransferFields(InboxSalesLine);
                                    OnForwardToOutBoxOnBeforeHndlInboxSalesLineInsert(HndlInboxSalesLine, InboxSalesLine);
                                    HndlInboxSalesLine.Insert;

                                    if ICDocDim.Find('-') then
                                        DimMgt.MoveICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Line", InboxSalesLine."Transaction Source");
                                until InboxSalesLine.Next = 0;
                        end;
                        OnAfterForwardToOutBoxSalesDoc(InboxTransaction, OutboxTransaction);
                    end;
                "Source Type"::"Purchase Document":
                    begin
                        if InboxPurchHdr.Get("Transaction No.", "IC Partner Code", "Transaction Source") then begin
                            OutboxPurchHdr.TransferFields(InboxPurchHdr);
                            OutboxPurchHdr."Transaction Source" := OutboxTransaction."Transaction Source";
                            OutboxPurchHdr.Insert;
                            ICDocDim.Reset;
                            DimMgt.SetICDocDimFilters(
                              ICDocDim, DATABASE::"IC Inbox Purchase Header", "Transaction No.", "IC Partner Code", "Transaction Source", 0);
                            if ICDocDim.Find('-') then
                                DimMgt.CopyICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"IC Outbox Purchase Header", OutboxPurchHdr."Transaction Source");
                            HndlInboxPurchHdr.TransferFields(InboxPurchHdr);
                            HndlInboxPurchHdr.Insert;
                            if ICDocDim.Find('-') then
                                DimMgt.MoveICDocDimtoICDocDim(
                                  ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Header", InboxPurchHdr."Transaction Source");
                            InboxPurchLine.SetRange("IC Transaction No.", "Transaction No.");
                            InboxPurchLine.SetRange("IC Partner Code", "IC Partner Code");
                            InboxPurchLine.SetRange("Transaction Source", "Transaction Source");
                            if InboxPurchLine.Find('-') then
                                repeat
                                    OutboxPurchLine.TransferFields(InboxPurchLine);
                                    OutboxPurchLine."Transaction Source" := OutboxTransaction."Transaction Source";
                                    OutboxPurchLine.Insert;
                                    ICDocDim.Reset;
                                    DimMgt.SetICDocDimFilters(
                                      ICDocDim, DATABASE::"IC Inbox Purchase Line", "Transaction No.", "IC Partner Code", "Transaction Source",
                                      OutboxPurchLine."Line No.");
                                    if ICDocDim.Find('-') then
                                        DimMgt.CopyICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"IC Outbox Purchase Line", OutboxPurchLine."Transaction Source");
                                    HndlInboxPurchLine.TransferFields(InboxPurchLine);
                                    HndlInboxPurchLine.Insert;
                                    if ICDocDim.Find('-') then
                                        DimMgt.MoveICDocDimtoICDocDim(
                                          ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Line", InboxPurchLine."Transaction Source");
                                until InboxPurchLine.Next = 0;
                        end;
                        OnAfterForwardToOutBoxPurchDoc(InboxTransaction, OutboxTransaction);
                    end;
            end;
            InsertICCommentLinesAsRejectedOutboxTransaction(InboxTransaction);
        end;
    end;

    local procedure InsertICCommentLinesAsRejectedOutboxTransaction(ICInboxTransaction: Record "IC Inbox Transaction")
    var
        ICCommentLine: Record "IC Comment Line";
        ICCommentLine2: Record "IC Comment Line";
    begin
        with ICInboxTransaction do begin
            ICCommentLine.SetRange("Table Name", ICCommentLine."Table Name"::"Handled IC Inbox Transaction");
            ICCommentLine.SetRange("Transaction No.", "Transaction No.");
            ICCommentLine.SetRange("IC Partner Code", "IC Partner Code");
            if ICCommentLine.Find('-') then
                repeat
                    ICCommentLine2 := ICCommentLine;
                    ICCommentLine2."Table Name" := ICCommentLine."Table Name"::"IC Outbox Transaction";
                    ICCommentLine2."Transaction Source" := ICCommentLine."Transaction Source"::Rejected;
                    ICCommentLine2.Insert;
                until ICCommentLine.Next = 0;
        end;
    end;

    procedure GetCompanyInfo()
    begin
        if not CompanyInfoFound then
            CompanyInfo.Get;
        CompanyInfoFound := true;
    end;

    procedure GetGLSetup()
    begin
        if not GLSetupFound then
            GLSetup.Get;
        GLSetupFound := true;
    end;

    procedure GetCurrency(var CurrencyCode: Code[20])
    begin
        GetGLSetup;
        if CurrencyCode = GLSetup."LCY Code" then
            CurrencyCode := '';
    end;

    procedure GetItemFromCommonItem(CommonItemNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        Item.SetCurrentKey("Common Item No.");
        Item.SetRange("Common Item No.", CommonItemNo);
        if not Item.FindFirst then
            Error(NoItemForCommonItemErr, CommonItemNo);
        exit(Item."No.");
    end;

    procedure GetItemFromRef("Code": Code[20]; CrossRefType: Option; CrossRefTypeNo: Code[20]): Code[20]
    var
        Item: Record Item;
        CrossRef: Record "Item Cross Reference";
        ItemVendor: Record "Item Vendor";
    begin
        if Item.Get(Code) then
            exit(Item."No.");
        CrossRef.SetCurrentKey("Cross-Reference No.", "Cross-Reference Type", "Cross-Reference Type No.");
        CrossRef.SetRange("Cross-Reference Type", CrossRefType);
        CrossRef.SetRange("Cross-Reference Type No.", CrossRefTypeNo);
        CrossRef.SetRange("Cross-Reference No.", Code);
        if CrossRef.FindFirst then
            exit(CrossRef."Item No.");

        if CrossRefType = CrossRef."Cross-Reference Type"::Vendor then begin
            ItemVendor.SetCurrentKey("Vendor No.", "Vendor Item No.");
            ItemVendor.SetRange("Vendor No.", CrossRefTypeNo);
            ItemVendor.SetRange("Vendor Item No.", Code);
            if ItemVendor.FindFirst then
                exit(ItemVendor."Item No.")
        end;
        exit('');
    end;

    local procedure GetCustInvRndgAccNo(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Invoice Rounding Account");
    end;

    procedure HandleICComments(TableName: Option; NewTableName: Option; TransactionNo: Integer; ICPartner: Code[20]; TransactionSource: Option)
    var
        ICCommentLine: Record "IC Comment Line";
        TempICCommentLine: Record "IC Comment Line" temporary;
    begin
        ICCommentLine.SetRange("Table Name", TableName);
        ICCommentLine.SetRange("Transaction No.", TransactionNo);
        ICCommentLine.SetRange("IC Partner Code", ICPartner);
        if ICCommentLine.Find('-') then begin
            repeat
                TempICCommentLine := ICCommentLine;
                ICCommentLine.Delete;
                TempICCommentLine."Table Name" := NewTableName;
                TempICCommentLine."Transaction Source" := TransactionSource;
                TempICCommentLine.Insert;
            until ICCommentLine.Next = 0;
            if TempICCommentLine.Find('-') then
                repeat
                    ICCommentLine := TempICCommentLine;
                    ICCommentLine.Insert;
                until TempICCommentLine.Next = 0;
        end;
    end;

    procedure OutboxTransToInbox(var ICOutboxTrans: Record "IC Outbox Transaction"; var ICInboxTrans: Record "IC Inbox Transaction"; FromICPartnerCode: Code[20])
    var
        PartnerICInboxTransaction: Record "IC Inbox Transaction";
        PartnerHandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICPartner: Record "IC Partner";
    begin
        ICInboxTrans."Transaction No." := ICOutboxTrans."Transaction No.";
        ICInboxTrans."IC Partner Code" := FromICPartnerCode;
        ICInboxTrans."Transaction Source" := ICOutboxTrans."Transaction Source";
        ICInboxTrans."Document Type" := ICOutboxTrans."Document Type";
        case ICOutboxTrans."Source Type" of
            ICOutboxTrans."Source Type"::"Journal Line":
                ICInboxTrans."Source Type" := ICInboxTrans."Source Type"::Journal;
            ICOutboxTrans."Source Type"::"Sales Document":
                ICInboxTrans."Source Type" := ICInboxTrans."Source Type"::"Purchase Document";
            ICOutboxTrans."Source Type"::"Purchase Document":
                ICInboxTrans."Source Type" := ICInboxTrans."Source Type"::"Sales Document";
        end;
        ICInboxTrans."Document No." := ICOutboxTrans."Document No.";
        ICInboxTrans."Original Document No." := ICOutboxTrans."Document No.";
        ICInboxTrans."Posting Date" := ICOutboxTrans."Posting Date";
        ICInboxTrans."Document Date" := ICOutboxTrans."Document Date";
        ICInboxTrans."Line Action" := ICInboxTrans."Line Action"::"No Action";
        ICInboxTrans."IC Partner G/L Acc. No." := ICOutboxTrans."IC Partner G/L Acc. No.";
        ICInboxTrans."Source Line No." := ICOutboxTrans."Source Line No.";

        GetCompanyInfo;
        if CompanyInfo."IC Partner Code" = ICInboxTrans."IC Partner Code" then
            ICPartner.Get(ICOutboxTrans."IC Partner Code")
        else
            ICPartner.Get(ICInboxTrans."IC Partner Code");

        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::Database then
            PartnerICInboxTransaction.ChangeCompany(ICPartner."Inbox Details");
        if PartnerICInboxTransaction.Get(
             ICInboxTrans."Transaction No.", ICInboxTrans."IC Partner Code",
             ICInboxTrans."Transaction Source", ICInboxTrans."Document Type")
        then
            Error(
              Text004, ICInboxTrans."Transaction No.", ICInboxTrans.FieldCaption("IC Partner Code"),
              ICInboxTrans."IC Partner Code", PartnerICInboxTransaction.TableCaption);

        if ICPartner."Inbox Type" = ICPartner."Inbox Type"::Database then
            PartnerHandledICInboxTrans.ChangeCompany(ICPartner."Inbox Details");
        if PartnerHandledICInboxTrans.Get(
             ICInboxTrans."Transaction No.", ICInboxTrans."IC Partner Code",
             ICInboxTrans."Transaction Source", ICInboxTrans."Document Type")
        then
            Error(
              Text004, ICInboxTrans."Transaction No.", ICInboxTrans.FieldCaption("IC Partner Code"),
              ICInboxTrans."IC Partner Code", PartnerHandledICInboxTrans.TableCaption);

        OnBeforeICInboxTransInsert(ICInboxTrans, ICOutboxTrans);
        ICInboxTrans.Insert;
        OnAfterICInboxTransInsert(ICInboxTrans, ICOutboxTrans);
    end;

    procedure OutboxJnlLineToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxJnlLine: Record "IC Outbox Jnl. Line"; var ICInboxJnlLine: Record "IC Inbox Jnl. Line")
    var
        LocalICPartner: Record "IC Partner";
        PartnerICPartner: Record "IC Partner";
    begin
        GetGLSetup;
        GetCompanyInfo;
        ICInboxJnlLine."Transaction No." := ICInboxTrans."Transaction No.";
        ICInboxJnlLine."IC Partner Code" := ICInboxTrans."IC Partner Code";
        ICInboxJnlLine."Transaction Source" := ICInboxTrans."Transaction Source";
        ICInboxJnlLine."Line No." := ICOutboxJnlLine."Line No.";

        if ICOutboxJnlLine."IC Partner Code" = CompanyInfo."IC Partner Code" then
            LocalICPartner.Get(ICInboxTrans."IC Partner Code")
        else
            LocalICPartner.Get(ICOutboxJnlLine."IC Partner Code");

        if ICOutboxJnlLine."IC Partner Code" = CompanyInfo."IC Partner Code" then
            PartnerICPartner.Get(ICInboxTrans."IC Partner Code")
        else begin
            LocalICPartner.TestField("Inbox Type", LocalICPartner."Inbox Type"::Database);
            PartnerICPartner.ChangeCompany(LocalICPartner."Inbox Details");
            PartnerICPartner.Get(ICInboxJnlLine."IC Partner Code");
        end;

        case ICOutboxJnlLine."Account Type" of
            ICOutboxJnlLine."Account Type"::"G/L Account":
                begin
                    ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::"G/L Account";
                    ICInboxJnlLine."Account No." := ICOutboxJnlLine."Account No.";
                end;
            ICOutboxJnlLine."Account Type"::Vendor:
                begin
                    ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::Customer;
                    PartnerICPartner.TestField("Customer No.");
                    ICInboxJnlLine."Account No." := PartnerICPartner."Customer No.";
                end;
            ICOutboxJnlLine."Account Type"::Customer:
                begin
                    ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::Vendor;
                    PartnerICPartner.TestField("Vendor No.");
                    ICInboxJnlLine."Account No." := PartnerICPartner."Vendor No.";
                end;
            ICOutboxJnlLine."Account Type"::"IC Partner":
                begin
                    ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::"IC Partner";
                    ICInboxJnlLine."Account No." := ICInboxJnlLine."IC Partner Code";
                end;
        end;
        ICInboxJnlLine.Amount := -ICOutboxJnlLine.Amount;
        ICInboxJnlLine.Description := ICOutboxJnlLine.Description;
        ICInboxJnlLine."VAT Amount" := -ICOutboxJnlLine."VAT Amount";
        if ICOutboxJnlLine."Currency Code" = GLSetup."LCY Code" then
            ICInboxJnlLine."Currency Code" := ''
        else
            ICInboxJnlLine."Currency Code" := ICOutboxJnlLine."Currency Code";
        ICInboxJnlLine."Due Date" := ICOutboxJnlLine."Due Date";
        ICInboxJnlLine."Payment Discount %" := ICOutboxJnlLine."Payment Discount %";
        ICInboxJnlLine."Payment Discount Date" := ICOutboxJnlLine."Payment Discount Date";
        ICInboxJnlLine.Quantity := -ICOutboxJnlLine.Quantity;
        ICInboxJnlLine."Document No." := ICOutboxJnlLine."Document No.";
        ICInboxJnlLine.Insert;
    end;

    procedure OutboxSalesHdrToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var ICInboxPurchHeader: Record "IC Inbox Purchase Header")
    var
        ICPartner: Record "IC Partner";
        Vendor: Record Vendor;
    begin
        GetCompanyInfo;
        if ICOutboxSalesHeader."IC Partner Code" = CompanyInfo."IC Partner Code" then
            ICPartner.Get(ICInboxTrans."IC Partner Code")
        else begin
            ICPartner.Get(ICOutboxSalesHeader."IC Partner Code");
            ICPartner.TestField("Inbox Type", ICPartner."Inbox Type"::Database);
            ICPartner.TestField("Inbox Details");
            ICPartner.ChangeCompany(ICPartner."Inbox Details");
            ICPartner.Get(ICInboxTrans."IC Partner Code");
        end;
        if ICPartner."Vendor No." = '' then
            Error(Text001, ICPartner.TableCaption, ICPartner.Code, Vendor.TableCaption, ICOutboxSalesHeader."IC Partner Code");

        with ICInboxPurchHeader do begin
            "IC Transaction No." := ICInboxTrans."Transaction No.";
            "IC Partner Code" := ICInboxTrans."IC Partner Code";
            "Transaction Source" := ICInboxTrans."Transaction Source";
            "Document Type" := ICOutboxSalesHeader."Document Type";
            "No." := ICOutboxSalesHeader."No.";
            "Ship-to Name" := ICOutboxSalesHeader."Ship-to Name";
            "Ship-to Address" := ICOutboxSalesHeader."Ship-to Address";
            "Ship-to Address 2" := ICOutboxSalesHeader."Ship-to Address 2";
            "Ship-to City" := ICOutboxSalesHeader."Ship-to City";
            "Ship-to Post Code" := ICOutboxSalesHeader."Ship-to Post Code";
            "Ship-to County" := ICOutboxSalesHeader."Ship-to County";
            "Ship-to Country/Region Code" := ICOutboxSalesHeader."Ship-to Country/Region Code";
            "Posting Date" := ICOutboxSalesHeader."Posting Date";
            "Due Date" := ICOutboxSalesHeader."Due Date";
            "Payment Discount %" := ICOutboxSalesHeader."Payment Discount %";
            "Pmt. Discount Date" := ICOutboxSalesHeader."Pmt. Discount Date";
            "Currency Code" := ICOutboxSalesHeader."Currency Code";
            "Document Date" := ICOutboxSalesHeader."Document Date";
            "Buy-from Vendor No." := ICPartner."Vendor No.";
            "Pay-to Vendor No." := ICPartner."Vendor No.";
            "Vendor Invoice No." := ICOutboxSalesHeader."No.";
            "Vendor Order No." := ICOutboxSalesHeader."Order No.";
            "Vendor Cr. Memo No." := ICOutboxSalesHeader."No.";
            "Your Reference" := ICOutboxSalesHeader."External Document No.";
            "Sell-to Customer No." := ICOutboxSalesHeader."Sell-to Customer No.";
            "Expected Receipt Date" := ICOutboxSalesHeader."Requested Delivery Date";
            "Requested Receipt Date" := ICOutboxSalesHeader."Requested Delivery Date";
            "Promised Receipt Date" := ICOutboxSalesHeader."Promised Delivery Date";
            "Prices Including VAT" := ICOutboxSalesHeader."Prices Including VAT";
            OnBeforeICInboxPurchHeaderInsert(ICInboxPurchHeader, ICOutboxSalesHeader);
            Insert;
            OnAfterICInboxPurchHeaderInsert(ICInboxPurchHeader, ICOutboxSalesHeader);
        end;
    end;

    procedure OutboxSalesLineToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxSalesLine: Record "IC Outbox Sales Line"; var ICInboxPurchLine: Record "IC Inbox Purchase Line")
    begin
        with ICInboxPurchLine do begin
            "IC Transaction No." := ICInboxTrans."Transaction No.";
            "IC Partner Code" := ICInboxTrans."IC Partner Code";
            "Transaction Source" := ICInboxTrans."Transaction Source";
            "Line No." := ICOutboxSalesLine."Line No.";
            "Document Type" := ICOutboxSalesLine."Document Type";
            "Document No." := ICOutboxSalesLine."Document No.";
            "IC Partner Ref. Type" := ICOutboxSalesLine."IC Partner Ref. Type";
            "IC Partner Reference" := ICOutboxSalesLine."IC Partner Reference";
            Description := ICOutboxSalesLine.Description;
            "Description 2" := ICOutboxSalesLine."Description 2";
            Quantity := ICOutboxSalesLine.Quantity;
            "Direct Unit Cost" := ICOutboxSalesLine."Unit Price";
            "Line Discount Amount" := ICOutboxSalesLine."Line Discount Amount";
            "Amount Including VAT" := ICOutboxSalesLine."Amount Including VAT";
            "Job No." := ICOutboxSalesLine."Job No.";
            "VAT Base Amount" := ICOutboxSalesLine."VAT Base Amount";
            "Unit Cost" := ICOutboxSalesLine."Unit Price";
            "Line Amount" := ICOutboxSalesLine."Line Amount";
            "Line Discount %" := ICOutboxSalesLine."Line Discount %";
            "Unit of Measure Code" := ICOutboxSalesLine."Unit of Measure Code";
            "Requested Receipt Date" := ICOutboxSalesLine."Requested Delivery Date";
            "Promised Receipt Date" := ICOutboxSalesLine."Promised Delivery Date";
            "Receipt No." := ICOutboxSalesLine."Shipment No.";
            "Receipt Line No." := ICOutboxSalesLine."Shipment Line No.";
            "Return Shipment No." := ICOutboxSalesLine."Return Receipt No.";
            "Return Shipment Line No." := ICOutboxSalesLine."Return Receipt Line No.";
            OnBeforeICInboxPurchLineInsert(ICInboxPurchLine, ICOutboxSalesLine);
            Insert;
            OnAfterICInboxPurchLineInsert(ICInboxPurchLine, ICOutboxSalesLine);
        end;
    end;

    procedure OutboxPurchHdrToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxPurchHeader: Record "IC Outbox Purchase Header"; var ICInboxSalesHeader: Record "IC Inbox Sales Header")
    var
        ICPartner: Record "IC Partner";
        Customer: Record Customer;
    begin
        GetCompanyInfo;
        if ICOutboxPurchHeader."IC Partner Code" = CompanyInfo."IC Partner Code" then
            ICPartner.Get(ICInboxTrans."IC Partner Code")
        else begin
            ICPartner.Get(ICOutboxPurchHeader."IC Partner Code");
            ICPartner.TestField("Inbox Type", ICPartner."Inbox Type"::Database);
            ICPartner.TestField("Inbox Details");
            ICPartner.ChangeCompany(ICPartner."Inbox Details");
            ICPartner.Get(ICInboxTrans."IC Partner Code");
        end;
        if ICPartner."Customer No." = '' then
            Error(Text001, ICPartner.TableCaption, ICPartner.Code, Customer.TableCaption);

        with ICInboxSalesHeader do begin
            "IC Transaction No." := ICInboxTrans."Transaction No.";
            "IC Partner Code" := ICInboxTrans."IC Partner Code";
            "Transaction Source" := ICInboxTrans."Transaction Source";
            "Document Type" := ICOutboxPurchHeader."Document Type";
            "No." := ICOutboxPurchHeader."No.";
            "Ship-to Name" := ICOutboxPurchHeader."Ship-to Name";
            "Ship-to Address" := ICOutboxPurchHeader."Ship-to Address";
            "Ship-to Address 2" := ICOutboxPurchHeader."Ship-to Address 2";
            "Ship-to City" := ICOutboxPurchHeader."Ship-to City";
            "Ship-to Post Code" := ICOutboxPurchHeader."Ship-to Post Code";
            "Ship-to County" := ICOutboxPurchHeader."Ship-to County";
            "Ship-to Country/Region Code" := ICOutboxPurchHeader."Ship-to Country/Region Code";
            "Posting Date" := ICOutboxPurchHeader."Posting Date";
            "Due Date" := ICOutboxPurchHeader."Due Date";
            "Payment Discount %" := ICOutboxPurchHeader."Payment Discount %";
            "Pmt. Discount Date" := ICOutboxPurchHeader."Pmt. Discount Date";
            "Currency Code" := ICOutboxPurchHeader."Currency Code";
            "Document Date" := ICOutboxPurchHeader."Document Date";
            "Sell-to Customer No." := ICPartner."Customer No.";
            "Bill-to Customer No." := ICPartner."Customer No.";
            "Prices Including VAT" := ICOutboxPurchHeader."Prices Including VAT";
            "Requested Delivery Date" := ICOutboxPurchHeader."Requested Receipt Date";
            "Promised Delivery Date" := ICOutboxPurchHeader."Promised Receipt Date";
            OnBeforeICInboxSalesHeaderInsert(ICInboxSalesHeader, ICOutboxPurchHeader);
            Insert;
            OnAfterICInboxSalesHeaderInsert(ICInboxSalesHeader, ICOutboxPurchHeader);
        end;
    end;

    procedure OutboxPurchLineToInbox(var ICInboxTrans: Record "IC Inbox Transaction"; var ICOutboxPurchLine: Record "IC Outbox Purchase Line"; var ICInboxSalesLine: Record "IC Inbox Sales Line")
    begin
        with ICInboxSalesLine do begin
            "IC Transaction No." := ICInboxTrans."Transaction No.";
            "IC Partner Code" := ICInboxTrans."IC Partner Code";
            "Transaction Source" := ICInboxTrans."Transaction Source";
            "Line No." := ICOutboxPurchLine."Line No.";
            "Document Type" := ICOutboxPurchLine."Document Type";
            "Document No." := ICOutboxPurchLine."Document No.";
            if ICOutboxPurchLine."IC Partner Ref. Type" = ICOutboxPurchLine."IC Partner Ref. Type"::"Vendor Item No." then
                "IC Partner Ref. Type" := "IC Partner Ref. Type"::Item
            else
                "IC Partner Ref. Type" := ICOutboxPurchLine."IC Partner Ref. Type";
            "IC Partner Reference" := ICOutboxPurchLine."IC Partner Reference";
            Description := ICOutboxPurchLine.Description;
            "Description 2" := ICOutboxPurchLine."Description 2";
            Quantity := ICOutboxPurchLine.Quantity;
            "Line Discount Amount" := ICOutboxPurchLine."Line Discount Amount";
            "Amount Including VAT" := ICOutboxPurchLine."Amount Including VAT";
            "Job No." := ICOutboxPurchLine."Job No.";
            "VAT Base Amount" := ICOutboxPurchLine."VAT Base Amount";
            "Unit Price" := ICOutboxPurchLine."Direct Unit Cost";
            "Line Amount" := ICOutboxPurchLine."Line Amount";
            "Line Discount %" := ICOutboxPurchLine."Line Discount %";
            "Unit of Measure Code" := ICOutboxPurchLine."Unit of Measure Code";
            "Requested Delivery Date" := ICOutboxPurchLine."Requested Receipt Date";
            "Promised Delivery Date" := ICOutboxPurchLine."Promised Receipt Date";
            OnBeforeICInboxSalesLineInsert(ICInboxSalesLine, ICOutboxPurchLine);
            Insert;
            OnAfterICInboxSalesLineInsert(ICInboxSalesLine, ICOutboxPurchLine);
        end;
    end;

    procedure OutboxJnlLineDimToInbox(var ICInboxJnlLine: Record "IC Inbox Jnl. Line"; var ICOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim."; var ICInboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim."; ICInboxTableID: Integer)
    begin
        ICInboxJnlLineDim := ICOutboxJnlLineDim;
        ICInboxJnlLineDim."Table ID" := ICInboxTableID;
        ICInboxJnlLineDim."IC Partner Code" := ICInboxJnlLine."IC Partner Code";
        ICInboxJnlLineDim."Transaction Source" := ICInboxJnlLine."Transaction Source";
        ICInboxJnlLineDim.Insert;
    end;

    procedure OutboxDocDimToInbox(var ICOutboxDocDim: Record "IC Document Dimension"; var ICInboxDocDim: Record "IC Document Dimension"; InboxTableID: Integer; InboxICPartnerCode: Code[20]; InboxTransSource: Integer)
    begin
        ICInboxDocDim := ICOutboxDocDim;
        ICInboxDocDim."Table ID" := InboxTableID;
        ICInboxDocDim."IC Partner Code" := InboxICPartnerCode;
        ICInboxDocDim."Transaction Source" := InboxTransSource;
        ICInboxDocDim.Insert;
    end;

    procedure MoveICJnlDimToHandled(TableID: Integer; NewTableID: Integer; TransactionNo: Integer; ICPartner: Code[20]; LineNoFilter: Boolean; LineNo: Integer)
    var
        InOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        TempInOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary;
    begin
        InOutboxJnlLineDim.SetRange("Table ID", TableID);
        InOutboxJnlLineDim.SetRange("Transaction No.", TransactionNo);
        InOutboxJnlLineDim.SetRange("IC Partner Code", ICPartner);
        if LineNoFilter then
            InOutboxJnlLineDim.SetRange("Line No.", LineNo);
        if InOutboxJnlLineDim.Find('-') then begin
            repeat
                TempInOutboxJnlLineDim := InOutboxJnlLineDim;
                InOutboxJnlLineDim.Delete;
                TempInOutboxJnlLineDim."Table ID" := NewTableID;
                TempInOutboxJnlLineDim.Insert;
            until InOutboxJnlLineDim.Next = 0;
            if TempInOutboxJnlLineDim.Find('-') then
                repeat
                    InOutboxJnlLineDim := TempInOutboxJnlLineDim;
                    InOutboxJnlLineDim.Insert;
                until TempInOutboxJnlLineDim.Next = 0;
        end;
    end;

    local procedure MoveICDocDimToHandled(FromTableID: Integer; ToTableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer)
    var
        ICDocDim: Record "IC Document Dimension";
        HandledICDocDim: Record "IC Document Dimension";
    begin
        ICDocDim.SetRange("Table ID", FromTableID);
        ICDocDim.SetRange("Transaction No.", TransactionNo);
        ICDocDim.SetRange("IC Partner Code", PartnerCode);
        ICDocDim.SetRange("Transaction Source", TransactionSource);
        ICDocDim.SetRange("Line No.", LineNo);
        if ICDocDim.Find('-') then
            repeat
                HandledICDocDim.TransferFields(ICDocDim, true);
                HandledICDocDim."Table ID" := ToTableID;
                HandledICDocDim.Insert;
                ICDocDim.Delete;
            until ICDocDim.Next = 0;
    end;

    procedure MoveOutboxTransToHandledOutbox(var ICOutboxTrans: Record "IC Outbox Transaction")
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        HandledICOutboxJnlLine: Record "Handled IC Outbox Jnl. Line";
        ICOutboxSalesHdr: Record "IC Outbox Sales Header";
        HandledICOutboxSalesHdr: Record "Handled IC Outbox Sales Header";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line";
        ICOutboxPurchHdr: Record "IC Outbox Purchase Header";
        HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        ICOutboxPurchLine: Record "IC Outbox Purchase Line";
        HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
        ICInOutJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        HandledICInOutJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        ICCommentLine: Record "IC Comment Line";
        HandledICCommentLine: Record "IC Comment Line";
    begin
        ICOutboxJnlLine.SetRange("Transaction No.", ICOutboxTrans."Transaction No.");
        if ICOutboxJnlLine.Find('-') then
            repeat
                HandledICOutboxJnlLine.TransferFields(ICOutboxJnlLine, true);
                HandledICOutboxJnlLine.Insert;
                ICInOutJnlLineDim.SetRange("Table ID", DATABASE::"IC Outbox Jnl. Line");
                ICInOutJnlLineDim.SetRange("Transaction No.", ICOutboxJnlLine."Transaction No.");
                ICInOutJnlLineDim.SetRange("IC Partner Code", ICOutboxJnlLine."IC Partner Code");
                ICInOutJnlLineDim.SetRange("Transaction Source", ICOutboxJnlLine."Transaction Source");
                ICInOutJnlLineDim.SetRange("Line No.", ICOutboxJnlLine."Line No.");
                if ICInOutJnlLineDim.Find('-') then
                    repeat
                        HandledICInOutJnlLineDim := ICInOutJnlLineDim;
                        HandledICInOutJnlLineDim."Table ID" := DATABASE::"Handled IC Outbox Jnl. Line";
                        HandledICInOutJnlLineDim.Insert;
                        ICInOutJnlLineDim.Delete;
                    until ICInOutJnlLineDim.Next = 0;
                ICOutboxJnlLine.Delete;
            until ICOutboxJnlLine.Next = 0;

        ICOutboxSalesHdr.SetRange("IC Transaction No.", ICOutboxTrans."Transaction No.");
        if ICOutboxSalesHdr.Find('-') then
            repeat
                HandledICOutboxSalesHdr.Init;
                HandledICOutboxSalesHdr.TransferFields(ICOutboxSalesHdr, true);
                HandledICOutboxSalesHdr.Insert;
                OnAfterHandledICOutboxSalesHdrInsert(HandledICOutboxSalesHdr, ICOutboxSalesHdr);
                MoveICDocDimToHandled(
                  DATABASE::"IC Outbox Sales Header", DATABASE::"Handled IC Outbox Sales Header", ICOutboxSalesHdr."IC Transaction No.",
                  ICOutboxSalesHdr."IC Partner Code", ICOutboxSalesHdr."Transaction Source", 0);

                ICOutboxSalesLine.SetRange("IC Transaction No.", ICOutboxSalesHdr."IC Transaction No.");
                ICOutboxSalesLine.SetRange("IC Partner Code", ICOutboxSalesHdr."IC Partner Code");
                ICOutboxSalesLine.SetRange("Transaction Source", ICOutboxSalesHdr."Transaction Source");
                if ICOutboxSalesLine.Find('-') then
                    repeat
                        HandledICOutboxSalesLine.TransferFields(ICOutboxSalesLine, true);
                        OnBeforeHandledICOutboxSalesLineInsert(HandledICOutboxSalesLine, ICOutboxSalesLine);
                        HandledICOutboxSalesLine.Insert;

                        MoveICDocDimToHandled(
                          DATABASE::"IC Outbox Sales Line", DATABASE::"Handled IC Outbox Sales Line", ICOutboxSalesHdr."IC Transaction No.",
                          ICOutboxSalesHdr."IC Partner Code", ICOutboxSalesHdr."Transaction Source", ICOutboxSalesLine."Line No.");
                        ICOutboxSalesLine.Delete;
                    until ICOutboxSalesLine.Next = 0;
                ICOutboxSalesHdr.Delete;
            until ICOutboxSalesHdr.Next = 0;

        ICOutboxPurchHdr.SetRange("IC Transaction No.", ICOutboxTrans."Transaction No.");
        if ICOutboxPurchHdr.Find('-') then
            repeat
                HandledICOutboxPurchHdr.Init;
                HandledICOutboxPurchHdr.TransferFields(ICOutboxPurchHdr, true);
                HandledICOutboxPurchHdr.Insert;
                OnAfterHandledICOutboxPurchHdrInsert(HandledICOutboxPurchHdr, ICOutboxPurchHdr);

                MoveICDocDimToHandled(
                  DATABASE::"IC Outbox Purchase Header", DATABASE::"Handled IC Outbox Purch. Hdr", ICOutboxPurchHdr."IC Transaction No.",
                  ICOutboxPurchHdr."IC Partner Code", ICOutboxPurchHdr."Transaction Source", 0);

                ICOutboxPurchLine.SetRange("IC Transaction No.", ICOutboxPurchHdr."IC Transaction No.");
                ICOutboxPurchLine.SetRange("IC Partner Code", ICOutboxPurchHdr."IC Partner Code");
                ICOutboxPurchLine.SetRange("Transaction Source", ICOutboxPurchHdr."Transaction Source");
                if ICOutboxPurchLine.Find('-') then
                    repeat
                        HandledICOutboxPurchLine.TransferFields(ICOutboxPurchLine, true);
                        OnBeforeHandledICOutboxPurchLineInsert(HandledICOutboxPurchLine, ICOutboxPurchLine);
                        HandledICOutboxPurchLine.Insert;

                        MoveICDocDimToHandled(
                          DATABASE::"IC Outbox Purchase Line", DATABASE::"Handled IC Outbox Purch. Line", ICOutboxPurchHdr."IC Transaction No.",
                          ICOutboxPurchHdr."IC Partner Code", ICOutboxPurchHdr."Transaction Source", ICOutboxPurchLine."Line No.");
                        ICOutboxPurchLine.Delete;
                    until ICOutboxPurchLine.Next = 0;
                ICOutboxPurchHdr.Delete;
            until ICOutboxPurchHdr.Next = 0;

        HandledICOutboxTrans.TransferFields(ICOutboxTrans, true);
        case ICOutboxTrans."Line Action" of
            ICOutboxTrans."Line Action"::"Send to IC Partner":
                if ICOutboxTrans."Transaction Source" = ICOutboxTrans."Transaction Source"::"Created by Current Company" then
                    HandledICOutboxTrans.Status := HandledICOutboxTrans.Status::"Sent to IC Partner"
                else
                    HandledICOutboxTrans.Status := HandledICOutboxTrans.Status::"Rejection Sent to IC Partner";
            ICOutboxTrans."Line Action"::Cancel:
                HandledICOutboxTrans.Status := HandledICOutboxTrans.Status::Cancelled;
        end;
        HandledICOutboxTrans.Insert;
        ICOutboxTrans.Delete;

        ICCommentLine.SetRange("Table Name", ICCommentLine."Table Name"::"IC Outbox Transaction");
        ICCommentLine.SetRange("Transaction No.", ICOutboxTrans."Transaction No.");
        ICCommentLine.SetRange("IC Partner Code", ICOutboxTrans."IC Partner Code");
        ICCommentLine.SetRange("Transaction Source", ICOutboxTrans."Transaction Source");
        if ICCommentLine.Find('-') then
            repeat
                HandledICCommentLine := ICCommentLine;
                HandledICCommentLine."Table Name" := HandledICCommentLine."Table Name"::"Handled IC Outbox Transaction";
                HandledICCommentLine.Insert;
                ICCommentLine.Delete;
            until ICCommentLine.Next = 0;
    end;

    procedure CreateICDocDimFromPostedDocDim(ICDocDim: Record "IC Document Dimension"; DimSetID: Integer; TableNo: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        DimSetEntry.Reset;
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet then
            repeat
                ICDocDim."Table ID" := TableNo;
                ICDocDim."Dimension Code" := DimMgt.ConvertDimtoICDim(DimSetEntry."Dimension Code");
                ICDocDim."Dimension Value Code" :=
                  DimMgt.ConvertDimValuetoICDimVal(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                if (ICDocDim."Dimension Code" <> '') and (ICDocDim."Dimension Value Code" <> '') then
                    ICDocDim.Insert;
            until DimSetEntry.Next = 0;
    end;

    local procedure FindReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLineSource: Record "Purchase Line"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLineSource."Receipt No.") then
            exit(false);

        with PurchRcptLine do begin
            SetCurrentKey("Qty. Rcd. Not Invoiced");
            SetRange("Order No.", PurchaseHeader."No.");
            SetRange("Order Line No.", PurchaseLineSource."Receipt Line No.");
            SetRange(Type, PurchaseLineSource.Type);
            SetRange("No.", PurchaseLineSource."No.");
            SetFilter("Qty. Rcd. Not Invoiced", '<>%1', 0);
            if FindSet then
                repeat
                    PurchaseLine.SetCurrentKey("Document Type", "Receipt No.");
                    PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
                    PurchaseLine.SetRange("Receipt No.", "Document No.");
                    PurchaseLine.SetRange("Receipt Line No.", "Line No.");
                    PurchaseLine.SetRange(Type, PurchaseLineSource.Type);
                    PurchaseLine.SetRange("No.", PurchaseLineSource."No.");
                    PurchaseLine.CalcSums(Quantity);
                    if Abs("Qty. Rcd. Not Invoiced" - PurchaseLine.Quantity) >= Abs(PurchaseLineSource.Quantity) then
                        exit(true);
                until Next = 0;
            exit(false);
        end;
    end;

    local procedure FindShipmentLine(var ReturnShptLine: Record "Return Shipment Line"; PurchaseLineSource: Record "Purchase Line"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", PurchaseLineSource."Return Shipment No.") then
            exit(false);

        with ReturnShptLine do begin
            SetCurrentKey("Return Qty. Shipped Not Invd.");
            SetRange("Return Order No.", PurchaseHeader."No.");
            SetRange("Return Order Line No.", PurchaseLineSource."Return Shipment Line No.");
            SetRange(Type, PurchaseLineSource.Type);
            SetRange("No.", PurchaseLineSource."No.");
            SetFilter("Return Qty. Shipped Not Invd.", '<>%1', 0);
            if FindSet then
                repeat
                    PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
                    PurchaseLine.SetRange("Return Shipment No.", "Document No.");
                    PurchaseLine.SetRange("Return Shipment Line No.", "Line No.");
                    PurchaseLine.SetRange(Type, PurchaseLineSource.Type);
                    PurchaseLine.SetRange("No.", PurchaseLineSource."No.");
                    PurchaseLine.CalcSums(Quantity);
                    if Abs("Return Qty. Shipped Not Invd." - PurchaseLine.Quantity) >= Abs(PurchaseLineSource.Quantity) then
                        exit(true);
                until Next = 0;
            exit(false);
        end;
    end;

    local procedure FindRoundingSalesInvLine(DocumentNo: Code[20]): Integer
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        with SalesInvoiceLine do begin
            SetRange("Document No.", DocumentNo);
            if FindLast then
                if Type = Type::"G/L Account" then
                    if "No." <> '' then
                        if "No." = GetCustInvRndgAccNo("Bill-to Customer No.") then
                            exit("Line No.");
            exit(0);
        end;
    end;

    local procedure FindRoundingSalesCrMemoLine(DocumentNo: Code[20]): Integer
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        with SalesCrMemoLine do begin
            SetRange("Document No.", DocumentNo);
            if FindLast then
                if Type = Type::"G/L Account" then
                    if "No." <> '' then
                        if "No." = GetCustInvRndgAccNo("Bill-to Customer No.") then
                            exit("Line No.");
            exit(0);
        end;
    end;

    local procedure UpdateSalesLineICPartnerReference(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    var
        ICPartner: Record "IC Partner";
        ItemCrossReference: Record "Item Cross Reference";
        GLAccount: Record "G/L Account";
    begin
        with ICInboxSalesLine do
            if ("IC Partner Ref. Type" <> "IC Partner Ref. Type"::"G/L Account") and
               ("IC Partner Ref. Type" <> 0) and
               ("IC Partner Ref. Type" <> "IC Partner Ref. Type"::"Charge (Item)") and
               ("IC Partner Ref. Type" <> "IC Partner Ref. Type"::"Cross reference")
            then begin
                ICPartner.Get(SalesHeader."Sell-to IC Partner Code");
                case ICPartner."Outbound Sales Item No. Type" of
                    ICPartner."Outbound Sales Item No. Type"::"Common Item No.":
                        SalesLine.Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Common Item No.");
                    ICPartner."Outbound Sales Item No. Type"::"Internal No.":
                        begin
                            SalesLine."IC Partner Ref. Type" := "IC Partner Ref. Type"::Item;
                            SalesLine."IC Partner Reference" := "IC Partner Reference";
                        end;
                    ICPartner."Outbound Sales Item No. Type"::"Cross Reference":
                        begin
                            SalesLine.Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Cross reference");
                            ItemCrossReference.SetRange("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::Customer);
                            ItemCrossReference.SetRange("Cross-Reference Type No.", SalesHeader."Sell-to Customer No.");
                            ItemCrossReference.SetRange("Item No.", "IC Partner Reference");
                            if ItemCrossReference.FindFirst then
                                SalesLine."IC Partner Reference" := ItemCrossReference."Cross-Reference No.";
                        end;
                end;
            end else begin
                SalesLine."IC Partner Ref. Type" := "IC Partner Ref. Type";
                if "IC Partner Ref. Type" <> "IC Partner Ref. Type"::"G/L Account" then
                    SalesLine."IC Partner Reference" := "IC Partner Reference"
                else
                    if GLAccount.Get(TranslateICGLAccount("IC Partner Reference")) then
                        SalesLine."IC Partner Reference" := GLAccount."Default IC Partner G/L Acc. No";
            end;
    end;

    local procedure UpdatePurchLineICPartnerReference(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ICInboxPurchLine: Record "IC Inbox Purchase Line")
    var
        ICPartner: Record "IC Partner";
        ItemCrossReference: Record "Item Cross Reference";
        GLAccount: Record "G/L Account";
    begin
        with ICInboxPurchLine do
            if ("IC Partner Ref. Type" <> "IC Partner Ref. Type"::"G/L Account") and
               ("IC Partner Ref. Type" <> 0) and
               ("IC Partner Ref. Type" <> "IC Partner Ref. Type"::"Charge (Item)") and
               ("IC Partner Ref. Type" <> "IC Partner Ref. Type"::"Cross reference")
            then begin
                ICPartner.Get(PurchaseHeader."Buy-from IC Partner Code");
                case ICPartner."Outbound Purch. Item No. Type" of
                    ICPartner."Outbound Purch. Item No. Type"::"Common Item No.":
                        PurchaseLine.Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Common Item No.");
                    ICPartner."Outbound Purch. Item No. Type"::"Internal No.":
                        begin
                            PurchaseLine."IC Partner Ref. Type" := "IC Partner Ref. Type"::Item;
                            PurchaseLine."IC Partner Reference" := "IC Partner Reference";
                        end;
                    ICPartner."Outbound Purch. Item No. Type"::"Cross Reference":
                        begin
                            PurchaseLine.Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Cross reference");
                            ItemCrossReference.SetRange("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::Vendor);
                            ItemCrossReference.SetRange("Cross-Reference Type No.", PurchaseHeader."Buy-from Vendor No.");
                            ItemCrossReference.SetRange("Item No.", "IC Partner Reference");
                            if ItemCrossReference.FindFirst then
                                PurchaseLine."IC Partner Reference" := ItemCrossReference."Cross-Reference No.";
                        end;
                    ICPartner."Outbound Purch. Item No. Type"::"Vendor Item No.":
                        begin
                            PurchaseLine."IC Partner Ref. Type" := "IC Partner Ref. Type"::"Vendor Item No.";
                            PurchaseLine."IC Partner Reference" := PurchaseLine."Vendor Item No.";
                        end;
                end;
            end else begin
                PurchaseLine."IC Partner Ref. Type" := "IC Partner Ref. Type";
                if "IC Partner Ref. Type" <> "IC Partner Ref. Type"::"G/L Account" then
                    PurchaseLine."IC Partner Reference" := "IC Partner Reference"
                else
                    if GLAccount.Get(TranslateICGLAccount("IC Partner Reference")) then
                        PurchaseLine."IC Partner Reference" := GLAccount."Default IC Partner G/L Acc. No";
            end;
    end;

    local procedure UpdatePurchLineReceiptShipment(var PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        PurchaseOrderLine: Record "Purchase Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OrderDocumentNo: Code[20];
    begin
        if FindReceiptLine(PurchRcptLine, PurchaseLine) then begin
            OrderDocumentNo := PurchaseLine."Receipt No.";
            PurchaseLine."Location Code" := PurchRcptLine."Location Code";
            PurchaseLine."Receipt No." := PurchRcptLine."Document No.";
            PurchaseLine."Receipt Line No." := PurchRcptLine."Line No.";
            if PurchaseOrderLine.Get(PurchaseOrderLine."Document Type"::Order, OrderDocumentNo, PurchaseLine."Receipt Line No.") then
                ItemTrackingMgt.CopyHandledItemTrkgToPurchLineWithLineQty(PurchaseOrderLine, PurchaseLine);
        end else begin
            PurchaseLine."Receipt No." := '';
            PurchaseLine."Receipt Line No." := 0;
        end;

        if FindShipmentLine(ReturnShptLine, PurchaseLine) then begin
            OrderDocumentNo := PurchaseLine."Return Shipment No.";
            PurchaseLine."Location Code" := ReturnShptLine."Location Code";
            PurchaseLine."Return Shipment No." := ReturnShptLine."Document No.";
            PurchaseLine."Return Shipment Line No." := ReturnShptLine."Line No.";
            if PurchaseOrderLine.Get(
                 PurchaseOrderLine."Document Type"::"Return Order", OrderDocumentNo, PurchaseLine."Return Shipment Line No.")
            then
                ItemTrackingMgt.CopyHandledItemTrkgToInvLine(PurchaseOrderLine, PurchaseLine);
        end else begin
            PurchaseLine."Return Shipment No." := '';
            PurchaseLine."Return Shipment Line No." := 0;
        end;
    end;

    local procedure UpdateICOutboxSalesLineReceiptShipment(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        with ICOutboxSalesLine do
            case "Document Type" of
                "Document Type"::Order,
              "Document Type"::Invoice:
                    if "Shipment No." = '' then begin
                        "Shipment No." := CopyStr(ICOutboxSalesHeader."External Document No.", 1, MaxStrLen("Shipment No."));
                        "Shipment Line No." := "Line No.";
                    end else
                        if SalesShipmentHeader.Get("Shipment No.") then
                            "Shipment No." := CopyStr(SalesShipmentHeader."External Document No.", 1, MaxStrLen("Shipment No."));
                "Document Type"::"Credit Memo",
              "Document Type"::"Return Order":
                    if "Return Receipt No." = '' then begin
                        "Return Receipt No." := CopyStr(ICOutboxSalesHeader."External Document No.", 1, MaxStrLen("Return Receipt No."));
                        "Return Receipt Line No." := "Line No.";
                    end else
                        if ReturnReceiptHeader.Get("Return Receipt No.") then
                            "Return Receipt No." := CopyStr(ReturnReceiptHeader."External Document No.", 1, MaxStrLen("Return Receipt No."));
            end;
    end;

    local procedure AssignCurrencyCodeInOutBoxDoc(var CurrencyCode: Code[10]; ICPartnerCode: Code[20])
    var
        AnotherCompGLSetup: Record "General Ledger Setup";
        ICPartner: Record "IC Partner";
    begin
        if CurrencyCode = '' then begin
            ICPartner.Get(ICPartnerCode);
            if ICPartner."Inbox Type" = ICPartner."Inbox Type"::Database then begin
                GetGLSetup;
                AnotherCompGLSetup.ChangeCompany(ICPartner."Inbox Details");
                AnotherCompGLSetup.Get;
                if GLSetup."LCY Code" <> AnotherCompGLSetup."LCY Code" then
                    CurrencyCode := GLSetup."LCY Code";
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxSalesDocTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxSalesInvTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxSalesCrMemoTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxPurchDocTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertICOutboxJnlLine(var ICOutboxJnlLine: Record "IC Outbox Jnl. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesDocument(var SalesHeader: Record "Sales Header"; ICInboxSalesHeader: Record "IC Inbox Sales Header"; HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesLines(ICInboxSalesLine: Record "IC Inbox Sales Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchLines(ICInboxPurchLine: Record "IC Inbox Purchase Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterForwardToOutBoxSalesDoc(var ICInboxTransaction: Record "IC Inbox Transaction"; var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterForwardToOutBoxPurchDoc(var ICInboxTransaction: Record "IC Inbox Transaction"; var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandledICOutboxSalesHdrInsert(var HandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandledICOutboxPurchHdrInsert(var HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr"; var ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxPurchHeaderInsert(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxPurchLineInsert(var ICInboxPurchaseLine: Record "IC Inbox Purchase Line"; ICOutboxSalesLine: Record "IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxSalesHeaderInsert(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxSalesLineInsert(var ICInboxSalesLine: Record "IC Inbox Sales Line"; ICOutboxPurchaseLine: Record "IC Outbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICInboxTransInsert(var ICInboxTransaction: Record "IC Inbox Transaction"; ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOutboxPurchDocTrans(PurchaseHeader: Record "Purchase Header"; Rejection: Boolean; Post: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOutboxSalesCrMemoTrans(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; ICInboxJnlLine: Record "IC Inbox Jnl. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxPurchHeaderInsert(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxPurchLineInsert(var ICInboxPurchaseLine: Record "IC Inbox Purchase Line"; ICOutboxSalesLine: Record "IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxSalesHeaderInsert(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxSalesLineInsert(var ICInboxSalesLine: Record "IC Inbox Sales Line"; ICOutboxPurchaseLine: Record "IC Outbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICInboxTransInsert(var ICInboxTransaction: Record "IC Inbox Transaction"; ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICOutboxTransactionCreatedSalesDocTrans(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; LinesCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICOutboxTransactionCreatedSalesInvTrans(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICOutboxTransactionCreatedSalesCrMemoTrans(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeICOutboxTransactionCreatedPurchDocTrans(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; LinesCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICOutboxSalesLineInsert(var HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line"; ICOutboxSalesLine: Record "IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICOutboxPurchLineInsert(var HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line"; ICOutboxPurchLine: Record "IC Outbox Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInboxSalesLineInsert(var ICInboxSalesLine: Record "IC Inbox Sales Line"; HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOutBoxTransactionInsert(var ICOutboxTransaction: Record "IC Outbox Transaction"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxPurchDocTransOnAfterICOutBoxPurchLineInsert(var ICOutboxPurchaseLine: Record "IC Outbox Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesCrMemoTransOnBeforeICOutBoxSalesLineInsert(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesDocTransOnAfterICOutBoxSalesLineInsert(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutboxSalesInvTransOnBeforeICOutBoxSalesLineInsert(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; SalesInvLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchDocumentOnBeforeHandledICInboxPurchLineInsert(ICInboxPurchLine: Record "IC Inbox Purchase Line"; var HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchDocumentOnBeforePurchHeaderInsert(var PurchaseHeader: Record "Purchase Header"; ICInboxPurchaseHeader: Record "IC Inbox Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesDocumentOnBeforeSalesHeaderInsert(var SalesHeader: Record "Sales Header"; ICInboxSalesHeader: Record "IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForwardToOutBoxOnBeforeHndlInboxSalesLineInsert(var HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForwardToOutBoxOnBeforeOutboxTransactionInsert(var ICOutboxTransaction: Record "IC Outbox Transaction"; ICInboxTransaction: Record "IC Inbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeDeleteSalesHeader(HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header"; var HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeDeletePurchHeader(HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header"; var HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeInboxPurchHdrInsert(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeInboxPurchLineInsert(var ICInboxPurchaseLine: Record "IC Inbox Purchase Line"; HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeInboxSalesHdrInsert(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateInboxTransactionOnBeforeInboxTransactionInsert(var ICInboxTransaction: Record "IC Inbox Transaction"; HandledICInboxTrans: Record "Handled IC Inbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeDeleteSalesHeader(HandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header"; var HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeDeletePurchHeader(HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr"; var HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeOutboxPurchHdrInsert(var ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header"; HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeOutboxPurchLineInsert(var ICOutboxPurchaseLine: Record "IC Outbox Purchase Line"; HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateOutboxTransactionOnBeforeOutboxTransactionInsert(var ICOutboxTransaction: Record "IC Outbox Transaction"; HandledICOutboxTrans: Record "Handled IC Outbox Trans.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICOutBoxSalesLineInsert(var SalesLine: Record "Sales Line"; ICOutboxSalesLine: Record "IC Outbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterICOutBoxSalesHeaderTransferFields(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesDocument(ICInboxSalesHeader: Record "IC Inbox Sales Header"; ReplacePostingDate: Boolean; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOutboxSalesInvTrans(SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICInboxSalesLineInsert(var HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line"; ICInboxSalesLine: Record "IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledInboxTransactionInsert(var HandledICInboxTrans: Record "Handled IC Inbox Trans."; ICInboxTransaction: Record "IC Inbox Transaction")
    begin
    end;
}

