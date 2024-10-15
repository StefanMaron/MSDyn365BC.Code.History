﻿namespace Microsoft.Intercompany.Outbox;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Intercompany;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

report 513 "Move IC Trans. to Partner Comp"
{
    Caption = 'Move IC Trans. to Partner Comp';
    ProcessingOnly = true;

    dataset
    {
        dataitem("IC Outbox Transaction"; "IC Outbox Transaction")
        {
            DataItemTableView = sorting("Transaction No.", "IC Partner Code", "Transaction Source", "Document Type") order(Ascending);
            dataitem("IC Outbox Jnl. Line"; "IC Outbox Jnl. Line")
            {
                DataItemLink = "Transaction No." = field("Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                DataItemTableView = sorting("Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
                dataitem("IC Inbox/Outbox Jnl. Line Dim."; "IC Inbox/Outbox Jnl. Line Dim.")
                {
                    DataItemLink = "IC Partner Code" = field("IC Partner Code"), "Transaction No." = field("Transaction No."), "Line No." = field("Line No.");
                    DataItemTableView = sorting("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) where("Table ID" = const(415));

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
                DataItemLink = "IC Partner Code" = field("IC Partner Code"), "IC Transaction No." = field("Transaction No."), "Transaction Source" = field("Transaction Source");
                DataItemTableView = sorting("IC Transaction No.", "IC Partner Code", "Transaction Source");
                dataitem("IC Document Dimension SH"; "IC Document Dimension")
                {
                    DataItemLink = "Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                    DataItemTableView = sorting("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) where("Table ID" = const(426), "Line No." = const(0));

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
                    DataItemLink = "IC Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                    DataItemTableView = sorting("IC Transaction No.", "IC Partner Code", "Transaction Source");
                    dataitem("IC Document Dimension SL"; "IC Document Dimension")
                    {
                        DataItemLink = "Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source"), "Line No." = field("Line No.");
                        DataItemTableView = sorting("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) where("Table ID" = const(427));

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
                DataItemLink = "IC Partner Code" = field("IC Partner Code"), "IC Transaction No." = field("Transaction No."), "Transaction Source" = field("Transaction Source");
                DataItemTableView = sorting("IC Transaction No.", "IC Partner Code", "Transaction Source");
                dataitem("IC Document Dimension PH"; "IC Document Dimension")
                {
                    DataItemLink = "Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                    DataItemTableView = sorting("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) where("Table ID" = const(428), "Line No." = const(0));

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
                    DataItemLink = "IC Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source");
                    DataItemTableView = sorting("IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
                    dataitem("IC Document Dimension PL"; "IC Document Dimension")
                    {
                        DataItemLink = "Transaction No." = field("IC Transaction No."), "IC Partner Code" = field("IC Partner Code"), "Transaction Source" = field("Transaction Source"), "Line No." = field("Line No.");
                        DataItemTableView = sorting("Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.", "Dimension Code") ORDER(Ascending) where("Table ID" = const(429));

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
        TempRegisteredPartner: Record "IC Partner" temporary;
        ICDataExchange: Interface "IC Data Exchange";
    begin
        ICDataExchange := CurrentPartner."Data Exchange Type";
        ICDataExchange.GetICPartnerFromICPartner(CurrentPartner, TempRegisteredPartner);

        ICDataExchange.PostICTransactionToICPartnerInbox(CurrentPartner, TempICInboxTransaction);
        ICDataExchange.PostICJournalLineToICPartnerInbox(CurrentPartner, TempICInboxJnlLine);

        ICDataExchange.PostICPurchaseHeaderToICPartnerInbox(CurrentPartner, TempInboxPurchHeader, TempRegisteredPartner);
        ICDataExchange.PostICPurchaseLineToICPartnerInbox(CurrentPartner, TempInboxPurchLine);

        ICDataExchange.PostICSalesHeaderToICPartnerInbox(CurrentPartner, TempInboxSalesHeader, TempRegisteredPartner);
        ICDataExchange.PostICSalesLineToICPartnerInbox(CurrentPartner, TempInboxSalesLine);

        ICDataExchange.PostICJournalLineDimensionToICPartnerInbox(CurrentPartner, TempInboxOutboxJnlLineDim);
        ICDataExchange.PostICDocumentDimensionToICPartnerInbox(CurrentPartner, TempICDocDim);
        ICDataExchange.PostICCommentLineToICPartnerInbox(CurrentPartner, TempICCommentLine);

        OnICInboxTransactionCreated(TempICInboxTransaction, CurrentPartner."Inbox Details");

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

    internal procedure GetCurrentPartnerCode(): Code[20]
    begin
        exit(CurrentPartner.Code);
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

#if not CLEAN23
    [Obsolete('It is no longer applicable due to the implementation of cross-environment intercompany capabilities using APIs.', '23.0')]
    [IntegrationEvent(false, false)]
    internal procedure OnBeforePartnerInboxPurchHeaderInsert(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; ICPartner: Record "IC Partner")
    begin
    end;
#endif

#if not CLEAN23
    [Obsolete('It is no longer applicable due to the implementation of cross-environment intercompany capabilities using APIs.', '23.0')]
    [IntegrationEvent(false, false)]
    internal procedure OnBeforePartnerInboxSalesHeaderInsert(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; ICPartner: Record "IC Partner"; TempICInboxSalesHeader: Record "IC Inbox Sales Header" temporary)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnICInboxTransactionCreated(var ICInboxTransaction: Record "IC Inbox Transaction"; PartnerCompanyName: Text)
    begin
    end;

#if not CLEAN23
    [Obsolete('It is no longer applicable due to the implementation of cross-environment intercompany capabilities using APIs.', '23.0')]
    [IntegrationEvent(false, false)]
    internal procedure OnTransferToPartnerOnBeforePartnerInboxTransactionInsert(var PartnerInboxTransaction: Record "IC Inbox Transaction"; CurrentICPartner: Record "IC Partner")
    begin
    end;
#endif
}

