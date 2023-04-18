report 513 "Move IC Trans. to Partner Comp"
{
    Caption = 'Move IC Trans. to Partner Comp';
    ProcessingOnly = true;

    dataset
    {
        dataitem("IC Outbox Transaction"; "IC Outbox Transaction")
        {
            DataItemTableView = SORTING("Transaction No.", "IC Partner Code", "Transaction Source", "Document Type") ORDER(Ascending);
            dataitem("IC Outbox Jnl. Line"; "IC Outbox Jnl. Line")
            {
                DataItemLink = "Transaction No." = FIELD("Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source");
                DataItemTableView = SORTING("Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
                dataitem("IC Inbox/Outbox Jnl. Line Dim."; "IC Inbox/Outbox Jnl. Line Dim.")
                {
                    DataItemLink = "IC Partner Code" = FIELD("IC Partner Code"), "Transaction No." = FIELD("Transaction No."), "Line No." = FIELD("Line No.");
                    DataItemTableView = SORTING("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) WHERE("Table ID" = CONST(415));

                    trigger OnAfterGetRecord()
                    begin
                        if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                            ICInboxOutboxMgt.OutboxJnlLineDimToInbox(
                              TempICInboxJnlLine, "IC Inbox/Outbox Jnl. Line Dim.",
                              TempInboxOutboxJnlLineDim, DATABASE::"IC Inbox Jnl. Line");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                        ICInboxOutboxMgt.OutboxJnlLineToInbox(TempICInboxTransaction, "IC Outbox Jnl. Line", TempICInboxJnlLine);
                end;
            }
            dataitem("IC Outbox Sales Header"; "IC Outbox Sales Header")
            {
                DataItemLink = "IC Partner Code" = FIELD("IC Partner Code"), "IC Transaction No." = FIELD("Transaction No."), "Transaction Source" = FIELD("Transaction Source");
                DataItemTableView = SORTING("IC Transaction No.", "IC Partner Code", "Transaction Source");
                dataitem("IC Document Dimension SH"; "IC Document Dimension")
                {
                    DataItemLink = "Transaction No." = FIELD("IC Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source");
                    DataItemTableView = SORTING("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) WHERE("Table ID" = CONST(426), "Line No." = CONST(0));

                    trigger OnAfterGetRecord()
                    begin
                        if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                            ICInboxOutboxMgt.OutboxDocDimToInbox(
                              "IC Document Dimension SH", TempICDocDim, DATABASE::"IC Inbox Purchase Header",
                              TempInboxPurchHeader."IC Partner Code", TempInboxPurchHeader."Transaction Source");
                    end;
                }
                dataitem("IC Outbox Sales Line"; "IC Outbox Sales Line")
                {
                    DataItemLink = "IC Transaction No." = FIELD("IC Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source");
                    DataItemTableView = SORTING("IC Transaction No.", "IC Partner Code", "Transaction Source");
                    dataitem("IC Document Dimension SL"; "IC Document Dimension")
                    {
                        DataItemLink = "Transaction No." = FIELD("IC Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source"), "Line No." = FIELD("Line No.");
                        DataItemTableView = SORTING("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) WHERE("Table ID" = CONST(427));

                        trigger OnAfterGetRecord()
                        begin
                            if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                                ICInboxOutboxMgt.OutboxDocDimToInbox(
                                  "IC Document Dimension SL", TempICDocDim, DATABASE::"IC Inbox Purchase Line",
                                  TempInboxPurchLine."IC Partner Code", TempInboxPurchLine."Transaction Source");
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                            ICInboxOutboxMgt.OutboxSalesLineToInbox(TempICInboxTransaction, "IC Outbox Sales Line", TempInboxPurchLine);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                        ICInboxOutboxMgt.OutboxSalesHdrToInbox(TempICInboxTransaction, "IC Outbox Sales Header", TempInboxPurchHeader);
                end;
            }
            dataitem("IC Outbox Purchase Header"; "IC Outbox Purchase Header")
            {
                DataItemLink = "IC Partner Code" = FIELD("IC Partner Code"), "IC Transaction No." = FIELD("Transaction No."), "Transaction Source" = FIELD("Transaction Source");
                DataItemTableView = SORTING("IC Transaction No.", "IC Partner Code", "Transaction Source");
                dataitem("IC Document Dimension PH"; "IC Document Dimension")
                {
                    DataItemLink = "Transaction No." = FIELD("IC Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source");
                    DataItemTableView = SORTING("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) WHERE("Table ID" = CONST(428), "Line No." = CONST(0));

                    trigger OnAfterGetRecord()
                    begin
                        if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                            ICInboxOutboxMgt.OutboxDocDimToInbox(
                              "IC Document Dimension PH", TempICDocDim, DATABASE::"IC Inbox Sales Header",
                              TempInboxSalesHeader."IC Partner Code", TempInboxSalesHeader."Transaction Source");
                    end;
                }
                dataitem("IC Outbox Purchase Line"; "IC Outbox Purchase Line")
                {
                    DataItemLink = "IC Transaction No." = FIELD("IC Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source");
                    DataItemTableView = SORTING("IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
                    dataitem("IC Document Dimension PL"; "IC Document Dimension")
                    {
                        DataItemLink = "Transaction No." = FIELD("IC Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source"), "Line No." = FIELD("Line No.");
                        DataItemTableView = SORTING("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) WHERE("Table ID" = CONST(429));

                        trigger OnAfterGetRecord()
                        begin
                            if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                                ICInboxOutboxMgt.OutboxDocDimToInbox(
                                  "IC Document Dimension PL", TempICDocDim, DATABASE::"IC Inbox Sales Line",
                                  TempInboxSalesLine."IC Partner Code", TempInboxSalesLine."Transaction Source");
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                            ICInboxOutboxMgt.OutboxPurchLineToInbox(TempICInboxTransaction, "IC Outbox Purchase Line", TempInboxSalesLine);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if "IC Outbox Transaction"."Line Action" = "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                        ICInboxOutboxMgt.OutboxPurchHdrToInbox(TempICInboxTransaction, "IC Outbox Purchase Header", TempInboxSalesHeader);
                end;
            }
            dataitem("IC Comment Line"; "IC Comment Line")
            {
                DataItemLink = "IC Partner Code" = field("IC Partner Code"), "Transaction No." = field("Transaction No.");
                DataItemTableView = sorting("Table Name", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
                trigger OnAfterGetRecord()
                begin
                    if "IC Comment Line"."Table Name" <> "IC Comment Line"."Table Name"::"IC Outbox Transaction" then
                        exit; // We just send comments found on the IC Outbox
                    if "IC Outbox Transaction"."Line Action" <> "IC Outbox Transaction"."Line Action"::"Send to IC Partner" then
                        exit;

                    ICInboxOutboxMgt.OutboxICCommentLineToInbox(TempICInboxTransaction, "IC Comment Line", TempICCommentLine);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if CurrentPartner.Code <> "IC Partner Code" then
                    CurrentPartner.Get("IC Partner Code");

                case "Line Action" of
                    "Line Action"::"Send to IC Partner":
                        ICInboxOutboxMgt.OutboxTransToInbox(
                          "IC Outbox Transaction", TempICInboxTransaction, ICSetup."IC Partner Code");
                    "Line Action"::"Return to Inbox":
                        RecreateInboxTrans("IC Outbox Transaction");
                end;
            end;

            trigger OnPostDataItem()
            begin
                TransferToPartner();
            end;

            trigger OnPreDataItem()
            begin
                ICSetup.Get();
                ICSetup.TestField("IC Partner Code");
                GLSetup.Get();
                GLSetup.TestField("LCY Code");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ICSetup: Record "IC Setup";
        GLSetup: Record "General Ledger Setup";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;

        Text001: Label 'Your IC registration code %1 is not recognized by IC Partner %2.';
        Text002: Label '%1 %2 to IC Partner %3 already exists in the IC inbox of IC Partner %3. IC Partner %3 must complete the line action for transaction %2 in their IC inbox.';

    protected var
        CurrentPartner: Record "IC Partner";
        TempICInboxTransaction: Record "IC Inbox Transaction" temporary;
        TempICInboxJnlLine: Record "IC Inbox Jnl. Line" temporary;
        TempInboxPurchHeader: Record "IC Inbox Purchase Header" temporary;
        TempInboxPurchLine: Record "IC Inbox Purchase Line" temporary;
        TempInboxSalesHeader: Record "IC Inbox Sales Header" temporary;
        TempInboxSalesLine: Record "IC Inbox Sales Line" temporary;
        TempInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary;
        TempICDocDim: Record "IC Document Dimension" temporary;
        TempICCommentLine: Record "IC Comment Line" temporary;

    local procedure TransferToPartner()
    var
        PartnerInboxTransaction: Record "IC Inbox Transaction";
        PartnerInboxJnlLine: Record "IC Inbox Jnl. Line";
        PartnerInboxSalesHeader: Record "IC Inbox Sales Header";
        PartnerInboxSalesLine: Record "IC Inbox Sales Line";
        PartnerInboxPurchHeader: Record "IC Inbox Purchase Header";
        PartnerInboxPurchLine: Record "IC Inbox Purchase Line";
        PartnerInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        PartnerICDocDim: Record "IC Document Dimension";
        PartnerICPartner: Record "IC Partner";
        PartnerICCommentLine: Record "IC Comment Line";
    begin
        PartnerICPartner.ChangeCompany(CurrentPartner."Inbox Details");
        if not PartnerICPartner.Get(ICSetup."IC Partner Code") then
            Error(Text001, ICSetup."IC Partner Code", CurrentPartner.Code);

        PartnerInboxTransaction.ChangeCompany(CurrentPartner."Inbox Details");
        PartnerInboxTransaction.LockTable();
        if TempICInboxTransaction.Find('-') then
            repeat
                PartnerInboxTransaction := TempICInboxTransaction;
                OnTransferToPartnerOnBeforePartnerInboxTransactionInsert(PartnerInboxTransaction, CurrentPartner);
                if not PartnerInboxTransaction.Insert() then
                    Error(
                      Text002, TempICInboxTransaction.FieldCaption("Transaction No."),
                      TempICInboxTransaction."Transaction No.",
                      TempICInboxTransaction."IC Partner Code");
            until TempICInboxTransaction.Next() = 0;

        PartnerInboxJnlLine.ChangeCompany(CurrentPartner."Inbox Details");
        if TempICInboxJnlLine.Find('-') then
            repeat
                PartnerInboxJnlLine := TempICInboxJnlLine;
                if PartnerInboxJnlLine."Currency Code" = '' then
                    PartnerInboxJnlLine."Currency Code" := GLSetup."LCY Code";
                if PartnerInboxJnlLine."Currency Code" = CurrentPartner."Currency Code" then
                    PartnerInboxJnlLine."Currency Code" := '';
                PartnerInboxJnlLine.Insert();
            until TempICInboxJnlLine.Next() = 0;

        PartnerInboxPurchHeader.ChangeCompany(CurrentPartner."Inbox Details");
        if TempInboxPurchHeader.Find('-') then
            repeat
                PartnerInboxPurchHeader := TempInboxPurchHeader;
                PartnerInboxPurchHeader."Buy-from Vendor No." := PartnerICPartner."Vendor No.";
                PartnerInboxPurchHeader."Pay-to Vendor No." := PartnerICPartner."Vendor No.";
                OnBeforePartnerInboxPurchHeaderInsert(PartnerInboxPurchHeader, CurrentPartner);
                PartnerInboxPurchHeader.Insert();
            until TempInboxPurchHeader.Next() = 0;

        PartnerInboxPurchLine.ChangeCompany(CurrentPartner."Inbox Details");
        if TempInboxPurchLine.Find('-') then
            repeat
                PartnerInboxPurchLine := TempInboxPurchLine;
                PartnerInboxPurchLine.Insert();
            until TempInboxPurchLine.Next() = 0;

        PartnerInboxSalesHeader.ChangeCompany(CurrentPartner."Inbox Details");
        if TempInboxSalesHeader.Find('-') then
            repeat
                PartnerInboxSalesHeader := TempInboxSalesHeader;
                PartnerInboxSalesHeader."Sell-to Customer No." := PartnerICPartner."Customer No.";
                PartnerInboxSalesHeader."Bill-to Customer No." := PartnerICPartner."Customer No.";
                OnBeforePartnerInboxSalesHeaderInsert(PartnerInboxSalesHeader, CurrentPartner, TempInboxSalesHeader);
                PartnerInboxSalesHeader.Insert();
            until TempInboxSalesHeader.Next() = 0;

        PartnerInboxSalesLine.ChangeCompany(CurrentPartner."Inbox Details");
        if TempInboxSalesLine.Find('-') then
            repeat
                PartnerInboxSalesLine := TempInboxSalesLine;
                PartnerInboxSalesLine.Insert();
            until TempInboxSalesLine.Next() = 0;

        PartnerInboxOutboxJnlLineDim.ChangeCompany(CurrentPartner."Inbox Details");
        if TempInboxOutboxJnlLineDim.Find('-') then
            repeat
                PartnerInboxOutboxJnlLineDim := TempInboxOutboxJnlLineDim;
                PartnerInboxOutboxJnlLineDim.Insert();
            until TempInboxOutboxJnlLineDim.Next() = 0;

        PartnerICDocDim.ChangeCompany(CurrentPartner."Inbox Details");
        if TempICDocDim.Find('-') then
            repeat
                PartnerICDocDim := TempICDocDim;
                PartnerICDocDim.Insert();
            until TempICDocDim.Next() = 0;

        PartnerICCommentLine.ChangeCompany(CurrentPartner."Inbox Details");
        if TempICCommentLine.Find('-') then
            repeat
                PartnerICCommentLine := TempICCommentLine;
                PartnerICCommentLine.Insert();
            until TempICCommentLine.Next() = 0;

        OnICInboxTransactionCreated(PartnerInboxTransaction, CurrentPartner."Inbox Details");

        TempICInboxTransaction.DeleteAll();
        TempInboxPurchHeader.DeleteAll();
        TempInboxPurchLine.Reset();
        TempInboxPurchLine.DeleteAll();
        TempInboxSalesHeader.DeleteAll();
        TempInboxSalesLine.Reset();
        TempInboxSalesLine.DeleteAll();
        TempICInboxJnlLine.Reset();
        TempICInboxJnlLine.DeleteAll();
        TempInboxOutboxJnlLineDim.DeleteAll();
        TempICDocDim.DeleteAll();
        TempICCommentLine.DeleteAll();
    end;

    procedure RecreateInboxTrans(OutboxTrans: Record "IC Outbox Transaction")
    var
        ICInboxTrans: Record "IC Inbox Transaction";
        ICInboxJnlLine: Record "IC Inbox Jnl. Line";
        ICInboxSalesHdr: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICInboxPurchHdr: Record "IC Inbox Purchase Header";
        ICInboxPurchLine: Record "IC Inbox Purchase Line";
        ICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        HandledICInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        HandledICInboxSalesHdr: Record "Handled IC Inbox Sales Header";
        HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line";
        HandledICInboxPurchHdr: Record "Handled IC Inbox Purch. Header";
        HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        HandledICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        ICCommentLine: Record "IC Comment Line";
        HandledICCommentLine: Record "IC Comment Line";
    begin
        HandledICInboxTrans.LockTable();
        ICInboxTrans.LockTable();

        HandledICInboxTrans.Get(
          OutboxTrans."Transaction No.", OutboxTrans."IC Partner Code",
          ICInboxTrans."Transaction Source"::"Created by Partner", OutboxTrans."Document Type");
        ICInboxTrans.TransferFields(HandledICInboxTrans, true);
        ICInboxTrans."Line Action" := ICInboxTrans."Line Action"::"No Action";
        ICInboxTrans.Insert();
        HandledICInboxTrans.Delete();

        HandledICCommentLine.SetRange("Table Name", HandledICCommentLine."Table Name"::"Handled IC Inbox Transaction");
        HandledICCommentLine.SetRange("Transaction No.", HandledICInboxTrans."Transaction No.");
        HandledICCommentLine.SetRange("IC Partner Code", HandledICInboxTrans."IC Partner Code");
        HandledICCommentLine.SetRange("Transaction Source", HandledICInboxTrans."Transaction Source");
        if HandledICCommentLine.Find('-') then
            repeat
                ICCommentLine := HandledICCommentLine;
                ICCommentLine."Table Name" := ICCommentLine."Table Name"::"IC Inbox Transaction";
                ICCommentLine.Insert();
                HandledICCommentLine.Delete();
            until HandledICCommentLine.Next() = 0;

        with HandledICInboxJnlLine do begin
            SetRange("Transaction No.", ICInboxTrans."Transaction No.");
            SetRange("IC Partner Code", ICInboxTrans."IC Partner Code");
            SetRange("Transaction Source", ICInboxTrans."Transaction Source");
            if Find('-') then
                repeat
                    ICInboxJnlLine.TransferFields(HandledICInboxJnlLine, true);
                    ICInboxJnlLine.Insert();
                    HandledICInboxOutboxJnlLineDim.SetRange("Table ID", DATABASE::"Handled IC Inbox Jnl. Line");
                    HandledICInboxOutboxJnlLineDim.SetRange("Transaction No.", "Transaction No.");
                    HandledICInboxOutboxJnlLineDim.SetRange("IC Partner Code", "IC Partner Code");
                    if HandledICInboxOutboxJnlLineDim.Find('-') then
                        repeat
                            ICInboxOutboxJnlLineDim := HandledICInboxOutboxJnlLineDim;
                            ICInboxOutboxJnlLineDim."Table ID" := DATABASE::"IC Inbox Jnl. Line";
                            ICInboxOutboxJnlLineDim.Insert();
                            HandledICInboxOutboxJnlLineDim.Delete();
                        until HandledICInboxOutboxJnlLineDim.Next() = 0;
                    Delete();
                until Next() = 0;
        end;

        with HandledICInboxSalesHdr do begin
            SetRange("IC Transaction No.", ICInboxTrans."Transaction No.");
            SetRange("IC Partner Code", ICInboxTrans."IC Partner Code");
            SetRange("Transaction Source", ICInboxTrans."Transaction Source");
            if Find('-') then
                repeat
                    ICInboxSalesHdr.TransferFields(HandledICInboxSalesHdr, true);
                    ICInboxSalesHdr.Insert();
                    MoveHandledICDocDim(
                      DATABASE::"Handled IC Inbox Sales Header", DATABASE::"IC Inbox Sales Header",
                      "IC Transaction No.", "IC Partner Code");

                    HandledICInboxSalesLine.SetRange("IC Transaction No.", "IC Transaction No.");
                    HandledICInboxSalesLine.SetRange("IC Partner Code", "IC Partner Code");
                    HandledICInboxSalesLine.SetRange("Transaction Source", "Transaction Source");
                    if HandledICInboxSalesLine.Find('-') then
                        repeat
                            ICInboxSalesLine.TransferFields(HandledICInboxSalesLine, true);
                            ICInboxSalesLine.Insert();
                            MoveHandledICDocDim(
                              DATABASE::"Handled IC Inbox Sales Line", DATABASE::"IC Inbox Sales Line",
                              "IC Transaction No.", "IC Partner Code");
                            OnBeforeHandledICInboxSalesLineDelete(HandledICInboxSalesLine);
                            HandledICInboxSalesLine.Delete();
                        until HandledICInboxSalesLine.Next() = 0;
                    OnBeforeHandledICInboxSalesHdrDelete(HandledICInboxSalesHdr);
                    Delete();
                until Next() = 0;
        end;

        with HandledICInboxPurchHdr do begin
            SetRange("IC Transaction No.", ICInboxTrans."Transaction No.");
            SetRange("IC Partner Code", ICInboxTrans."IC Partner Code");
            SetRange("Transaction Source", ICInboxTrans."Transaction Source");
            if Find('-') then
                repeat
                    ICInboxPurchHdr.TransferFields(HandledICInboxPurchHdr, true);
                    ICInboxPurchHdr.Insert();
                    MoveHandledICDocDim(
                      DATABASE::"Handled IC Inbox Purch. Header", DATABASE::"IC Inbox Purchase Header",
                      "IC Transaction No.", "IC Partner Code");

                    HandledICInboxPurchLine.SetRange("IC Transaction No.", "IC Transaction No.");
                    HandledICInboxPurchLine.SetRange("IC Partner Code", "IC Partner Code");
                    HandledICInboxPurchLine.SetRange("Transaction Source", "Transaction Source");
                    if HandledICInboxPurchLine.Find('-') then
                        repeat
                            ICInboxPurchLine.TransferFields(HandledICInboxPurchLine, true);
                            ICInboxPurchLine.Insert();
                            MoveHandledICDocDim(
                              DATABASE::"Handled IC Inbox Purch. Line", DATABASE::"IC Inbox Purchase Line",
                              "IC Transaction No.", "IC Partner Code");
                            OnBeforeHandledICInboxPurchLineDelete(HandledICInboxPurchLine);
                            HandledICInboxPurchLine.Delete();
                        until HandledICInboxPurchLine.Next() = 0;
                    OnBeforeHandledICInboxPurchHdrDelete(HandledICInboxPurchHdr);
                    Delete();
                until Next() = 0;
        end;
    end;

    local procedure MoveHandledICDocDim(FromTableID: Integer; ToTableID: Integer; TransactionNo: Integer; PartnerCode: Code[20])
    var
        ICDocDim: Record "IC Document Dimension";
        HandledICDocDim: Record "IC Document Dimension";
    begin
        HandledICDocDim.SetRange("Table ID", FromTableID);
        HandledICDocDim.SetRange("Transaction No.", TransactionNo);
        HandledICDocDim.SetRange("IC Partner Code", PartnerCode);
        if HandledICDocDim.Find('-') then
            repeat
                ICDocDim := HandledICDocDim;
                ICDocDim."Table ID" := ToTableID;
                ICDocDim.Insert();
                HandledICDocDim.Delete();
            until HandledICDocDim.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICInboxPurchHdrDelete(var HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICInboxPurchLineDelete(var HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICInboxSalesHdrDelete(var HandledICInboxSalesHdr: Record "Handled IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledICInboxSalesLineDelete(var HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePartnerInboxPurchHeaderInsert(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; ICPartner: Record "IC Partner")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePartnerInboxSalesHeaderInsert(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; ICPartner: Record "IC Partner"; TempICInboxSalesHeader: Record "IC Inbox Sales Header" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnICInboxTransactionCreated(var ICInboxTransaction: Record "IC Inbox Transaction"; PartnerCompanyName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferToPartnerOnBeforePartnerInboxTransactionInsert(var PartnerInboxTransaction: Record "IC Inbox Transaction"; CurrentICPartner: Record "IC Partner")
    begin
    end;
}

