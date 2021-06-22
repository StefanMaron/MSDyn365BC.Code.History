report 511 "Complete IC Inbox Action"
{
    Caption = 'Complete IC Inbox Action';
    ProcessingOnly = true;

    dataset
    {
        dataitem("IC Inbox Transaction"; "IC Inbox Transaction")
        {
            DataItemTableView = SORTING("Transaction No.", "IC Partner Code", "Transaction Source", "Document Type");
            RequestFilterFields = "IC Partner Code", "Transaction Source", "Line Action";
            dataitem("IC Inbox Jnl. Line"; "IC Inbox Jnl. Line")
            {
                DataItemLink = "Transaction No." = FIELD("Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source");
                DataItemTableView = SORTING("Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");

                trigger OnAfterGetRecord()
                var
                    InboxJnlLine2: Record "IC Inbox Jnl. Line";
                    HandledInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
                begin
                    InboxJnlLine2 := "IC Inbox Jnl. Line";
                    case "IC Inbox Transaction"."Line Action" of
                        "IC Inbox Transaction"."Line Action"::Accept:
                            ICIOMgt.CreateJournalLines("IC Inbox Transaction", "IC Inbox Jnl. Line", TempGenJnlLine, GenJnlTemplate);
                        "IC Inbox Transaction"."Line Action"::"Return to IC Partner":
                            if not Forward then begin
                                ICIOMgt.ForwardToOutBox("IC Inbox Transaction");
                                Forward := true;
                            end;
                        "IC Inbox Transaction"."Line Action"::Cancel:
                            begin
                                HandledInboxJnlLine.TransferFields(InboxJnlLine2);
                                HandledInboxJnlLine.Insert();
                            end;
                    end;

                    ICIOMgt.MoveICJnlDimToHandled(DATABASE::"IC Inbox Jnl. Line", DATABASE::"Handled IC Inbox Jnl. Line",
                      "IC Inbox Transaction"."Transaction No.", "IC Inbox Transaction"."IC Partner Code",
                      true, InboxJnlLine2."Line No.");
                    InboxJnlLine2.Delete(true);
                end;

                trigger OnPostDataItem()
                begin
                    TempGenJnlLine."Document No." := IncStr(TempGenJnlLine."Document No.");
                end;
            }
            dataitem("IC Inbox Sales Header"; "IC Inbox Sales Header")
            {
                DataItemLink = "IC Transaction No." = FIELD("Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source");
                DataItemTableView = SORTING("IC Transaction No.", "IC Partner Code", "Transaction Source");

                trigger OnAfterGetRecord()
                var
                    InboxSalesHeader2: Record "IC Inbox Sales Header";
                    HandledInboxSalesHeader: Record "Handled IC Inbox Sales Header";
                    InboxSalesLine: Record "IC Inbox Sales Line";
                    HandledInboxSalesLine: Record "Handled IC Inbox Sales Line";
                    ICDocDim: Record "IC Document Dimension";
                    ICDocDim2: Record "IC Document Dimension";
                begin
                    InboxSalesHeader2 := "IC Inbox Sales Header";
                    case "IC Inbox Transaction"."Line Action" of
                        "IC Inbox Transaction"."Line Action"::Accept:
                            ICIOMgt.CreateSalesDocument("IC Inbox Sales Header",
                              ReplaceDocPostingDate, DocPostingDate);
                        "IC Inbox Transaction"."Line Action"::"Return to IC Partner":
                            ICIOMgt.ForwardToOutBox("IC Inbox Transaction");
                        "IC Inbox Transaction"."Line Action"::Cancel:
                            begin
                                HandledInboxSalesHeader.TransferFields(InboxSalesHeader2);
                                HandledInboxSalesHeader.Insert();
                                DimMgt.SetICDocDimFilters(
                                  ICDocDim, DATABASE::"IC Inbox Sales Header", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
                                if ICDocDim.FindFirst then
                                    DimMgt.MoveICDocDimtoICDocDim(ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Header", "Transaction Source");
                                with InboxSalesLine do begin
                                    SetRange("IC Transaction No.", InboxSalesHeader2."IC Transaction No.");
                                    SetRange("IC Partner Code", InboxSalesHeader2."IC Partner Code");
                                    SetRange("Transaction Source", InboxSalesHeader2."Transaction Source");
                                    if Find('-') then
                                        repeat
                                            HandledInboxSalesLine.TransferFields(InboxSalesLine);
                                            HandledInboxSalesLine.Insert();
                                            DimMgt.SetICDocDimFilters(
                                              ICDocDim, DATABASE::"IC Inbox Sales Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
                                            if ICDocDim.FindFirst then
                                                DimMgt.MoveICDocDimtoICDocDim(ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Sales Line", "Transaction Source");
                                        until Next = 0;
                                end;
                                OnAfterMoveICInboxSalesHeaderToHandled(InboxSalesHeader2, HandledInboxSalesHeader);
                            end;
                    end;
                    InboxSalesHeader2.Delete(true);
                end;
            }
            dataitem("IC Inbox Purchase Header"; "IC Inbox Purchase Header")
            {
                DataItemLink = "IC Transaction No." = FIELD("Transaction No."), "IC Partner Code" = FIELD("IC Partner Code"), "Transaction Source" = FIELD("Transaction Source");
                DataItemTableView = SORTING("IC Transaction No.", "IC Partner Code", "Transaction Source");

                trigger OnAfterGetRecord()
                var
                    InboxPurchHeader2: Record "IC Inbox Purchase Header";
                    HandledInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
                    InboxPurchLine: Record "IC Inbox Purchase Line";
                    HandledInboxPurchLine: Record "Handled IC Inbox Purch. Line";
                    ICDocDim: Record "IC Document Dimension";
                    ICDocDim2: Record "IC Document Dimension";
                begin
                    InboxPurchHeader2 := "IC Inbox Purchase Header";
                    case "IC Inbox Transaction"."Line Action" of
                        "IC Inbox Transaction"."Line Action"::Accept:
                            ICIOMgt.CreatePurchDocument("IC Inbox Purchase Header",
                              ReplaceDocPostingDate, DocPostingDate);
                        "IC Inbox Transaction"."Line Action"::"Return to IC Partner":
                            ICIOMgt.ForwardToOutBox("IC Inbox Transaction");
                        "IC Inbox Transaction"."Line Action"::Cancel:
                            begin
                                HandledInboxPurchHeader.TransferFields(InboxPurchHeader2);
                                HandledInboxPurchHeader.Insert();
                                DimMgt.SetICDocDimFilters(
                                  ICDocDim, DATABASE::"IC Inbox Purchase Header", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
                                if ICDocDim.FindFirst then
                                    DimMgt.MoveICDocDimtoICDocDim(ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Header", "Transaction Source");
                                with InboxPurchLine do begin
                                    SetRange("IC Transaction No.", InboxPurchHeader2."IC Transaction No.");
                                    SetRange("IC Partner Code", InboxPurchHeader2."IC Partner Code");
                                    SetRange("Transaction Source", InboxPurchHeader2."Transaction Source");
                                    if Find('-') then
                                        repeat
                                            HandledInboxPurchLine.TransferFields(InboxPurchLine);
                                            HandledInboxPurchLine.Insert();
                                            DimMgt.SetICDocDimFilters(
                                              ICDocDim, DATABASE::"IC Inbox Purchase Line", "IC Transaction No.", "IC Partner Code",
                                              "Transaction Source", "Line No.");
                                            if ICDocDim.FindFirst then
                                                DimMgt.MoveICDocDimtoICDocDim(ICDocDim, ICDocDim2, DATABASE::"Handled IC Inbox Purch. Line", "Transaction Source");
                                        until Next = 0;
                                end;
                                OnAfterMoveICInboxPurchHeaderToHandled(InboxPurchHeader2, HandledInboxPurchHeader);
                            end;
                    end;
                    InboxPurchHeader2.Delete(true);
                end;
            }

            trigger OnAfterGetRecord()
            var
                InboxTransaction2: Record "IC Inbox Transaction";
                HandledInboxTransaction2: Record "Handled IC Inbox Trans.";
                ICCommentLine: Record "IC Comment Line";
                ICPartner: Record "IC Partner";
            begin
                if "Line Action" = "Line Action"::"No Action" then
                    CurrReport.Skip();
                InboxTransaction2 := "IC Inbox Transaction";
                if ("Source Type" = "Source Type"::Journal) and
                   (InboxTransaction2."Line Action" <> InboxTransaction2."Line Action"::Cancel) and
                   (InboxTransaction2."Line Action" <> InboxTransaction2."Line Action"::"Return to IC Partner")
                then begin
                    TempGenJnlLine.TestField("Journal Template Name");
                    TempGenJnlLine.TestField("Journal Batch Name");
                end;
                if (InboxTransaction2."Line Action" <> InboxTransaction2."Line Action"::Cancel) and
                   ICPartner.Get(InboxTransaction2."IC Partner Code")
                then
                    ICPartner.TestField(Blocked, false);
                HandledInboxTransaction2.TransferFields(InboxTransaction2);
                case InboxTransaction2."Line Action" of
                    InboxTransaction2."Line Action"::Accept:
                        HandledInboxTransaction2.Status := HandledInboxTransaction2.Status::Accepted;
                    InboxTransaction2."Line Action"::"Return to IC Partner":
                        HandledInboxTransaction2.Status := HandledInboxTransaction2.Status::"Returned to IC Partner";
                    InboxTransaction2."Line Action"::Cancel:
                        HandledInboxTransaction2.Status := HandledInboxTransaction2.Status::Cancelled;
                end;
                OnBeforeHandledInboxTransactionInsert(HandledInboxTransaction2, InboxTransaction2);
                if not HandledInboxTransaction2.Insert() then
                    Error(
                      Text001, InboxTransaction2.FieldCaption("Transaction No."),
                      InboxTransaction2."Transaction No.", InboxTransaction2."IC Partner Code",
                      HandledInboxTransaction2.TableCaption);
                InboxTransaction2.Delete();

                ICIOMgt.HandleICComments(ICCommentLine."Table Name"::"IC Inbox Transaction",
                  ICCommentLine."Table Name"::"Handled IC Inbox Transaction", "Transaction No.",
                  "IC Partner Code", "Transaction Source");

                Forward := false;
            end;

            trigger OnPreDataItem()
            var
                IsHandled: Boolean;
            begin
                if TempGenJnlLine."Journal Template Name" <> '' then begin
                    GenJnlTemplate.Get(TempGenJnlLine."Journal Template Name");
                    IsHandled := false;
                    OnBeforeTestGenJnlTemplateType(TempGenJnlLine, GenJnlTemplate, IsHandled);
                    if not IsHandled then
                        GenJnlTemplate.TestField(Type, GenJnlTemplate.Type::Intercompany);
                    TempGenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
                    TempGenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
                end;
                GetGLSetup;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(Journals)
                    {
                        Caption = 'Journals';
                        field("TempGenJnlLine.""Journal Template Name"""; TempGenJnlLine."Journal Template Name")
                        {
                            ApplicationArea = Intercompany;
                            Caption = 'IC Gen. Journal Template';
                            TableRelation = "Gen. Journal Template";
                            ToolTip = 'Specifies the journal template in which you want to create the journal lines.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                if PAGE.RunModal(0, GenJnlTemplate) = ACTION::LookupOK then begin
                                    TempGenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
                                    ValidateJnl;
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                TempGenJnlLine."Journal Batch Name" := '';
                                ValidateJnl;
                            end;
                        }
                        field("TempGenJnlLine.""Journal Batch Name"""; TempGenJnlLine."Journal Batch Name")
                        {
                            ApplicationArea = Intercompany;
                            Caption = 'Gen. Journal Batch';
                            Lookup = true;
                            ToolTip = 'Specifies the journal batch in which you want to create the journal lines.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                TempGenJnlLine.TestField("Journal Template Name");
                                GenJnlTemplate.Get(TempGenJnlLine."Journal Template Name");
                                GenJnlBatch.FilterGroup(2);
                                GenJnlBatch.SetRange("Journal Template Name", TempGenJnlLine."Journal Template Name");
                                GenJnlBatch.FilterGroup(0);
                                GenJnlBatch."Journal Template Name" := TempGenJnlLine."Journal Template Name";
                                GenJnlBatch.Name := TempGenJnlLine."Journal Batch Name";
                                if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
                                    Text := GenJnlBatch.Name;
                                    exit(true);
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                if TempGenJnlLine."Journal Batch Name" <> '' then begin
                                    TempGenJnlLine.TestField("Journal Template Name");
                                    GenJnlBatch.Get(TempGenJnlLine."Journal Template Name", TempGenJnlLine."Journal Batch Name");
                                end;
                                ValidateJnl;
                            end;
                        }
                        field("TempGenJnlLine.""Document No."""; TempGenJnlLine."Document No.")
                        {
                            ApplicationArea = Intercompany;
                            Caption = 'Starting Document No.';
                            ToolTip = 'Specifies the next available number in the number series for the journal batch that is linked to the payment journal. When you run the batch job, this is the document number that appears on the first payment journal line. The batch job automatically fills in this field, but you can also fill in this field manually. ';
                        }
                        field("Replace Posting Date"; ReplacePostingDate)
                        {
                            ApplicationArea = Intercompany;
                            Caption = 'Replace Posting Date';
                            ToolTip = 'Specifies if you want to replace the journals'' posting date with the date that is entered in the Posting Date field.';

                            trigger OnValidate()
                            begin
                                if ReplacePostingDate then
                                    PostingDateEditable := true
                                else begin
                                    TempGenJnlLine."Posting Date" := 0D;
                                    PostingDateEditable := false;
                                end;
                            end;
                        }
                        field("Posting Date"; TempGenJnlLine."Posting Date")
                        {
                            ApplicationArea = Intercompany;
                            Caption = 'Posting Date';
                            Editable = PostingDateEditable;
                            ToolTip = 'Specifies the date that will be used when you post, if you have selected the Replace Posting Date field. If the posting date on a document is blank, the date in the Posting Date field is used even if you have not selected it. ';

                            trigger OnValidate()
                            begin
                                ValidateJnl;
                            end;
                        }
                    }
                    group(Documents)
                    {
                        Caption = 'Documents';
                        field(ReplaceDocPostingDate; ReplaceDocPostingDate)
                        {
                            ApplicationArea = Intercompany;
                            Caption = 'Replace Posting Date';
                            ToolTip = 'Specifies if you want to replace the journals'' posting date with the date that is entered in the Posting Date field.';

                            trigger OnValidate()
                            begin
                                if ReplaceDocPostingDate then begin
                                    DocPostingDateEditable := true
                                end else begin
                                    DocPostingDate := 0D;
                                    DocPostingDateEditable := false;
                                end;
                            end;
                        }
                        field("Doc Posting Date"; DocPostingDate)
                        {
                            ApplicationArea = Intercompany;
                            Caption = 'Posting Date';
                            Editable = DocPostingDateEditable;
                            ToolTip = 'Specifies Posting Date.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PostingDateEditable := true;
            DocPostingDateEditable := true;
        end;

        trigger OnOpenPage()
        begin
            ValidateJnl;
            if ReplaceDocPostingDate then
                DocPostingDateEditable := true
            else
                DocPostingDateEditable := false;
        end;
    }

    labels
    {
    }

    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLSetup: Record "General Ledger Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ICIOMgt: Codeunit ICInboxOutboxMgt;
        DimMgt: Codeunit DimensionManagement;
        GLSetupFound: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocPostingDate: Boolean;
        DocPostingDate: Date;
        Forward: Boolean;
        Text001: Label '%1 %2 from IC Partner %3 already exists in the %4 window. You have to delete %1 %2 in the %4 window before you complete the line action.';
        [InDataSet]
        DocPostingDateEditable: Boolean;
        [InDataSet]
        PostingDateEditable: Boolean;

    local procedure ValidateJnl()
    begin
        PageValidateJnl;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupFound then
            GLSetup.Get();
        GLSetupFound := true;
    end;

    local procedure PageValidateJnl()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TempGenJnlLine."Document No." := '';
        GenJnlLine.SetRange("Journal Template Name", TempGenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", TempGenJnlLine."Journal Batch Name");
        if GenJnlLine.FindLast then begin
            TempGenJnlLine."Document No." := IncStr(GenJnlLine."Document No.");
            TempGenJnlLine."Line No." := GenJnlLine."Line No.";
        end else
            if GenJnlBatch.Get(TempGenJnlLine."Journal Template Name", TempGenJnlLine."Journal Batch Name") then
                if GenJnlBatch."No. Series" = '' then
                    TempGenJnlLine."Document No." := ''
                else begin
                    TempGenJnlLine."Document No." := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", TempGenJnlLine."Posting Date", false);
                    Clear(NoSeriesMgt);
                end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveICInboxSalesHeaderToHandled(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; var HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveICInboxPurchHeaderToHandled(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; var HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledInboxTransactionInsert(var HandledICInboxTrans: Record "Handled IC Inbox Trans."; InboxTransaction: Record "IC Inbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestGenJnlTemplateType(var TempGenJnlLine: Record "Gen. Journal Line" temporary; GenJnlTemplate: Record "Gen. Journal Template"; var IsHandled: Boolean)
    begin
    end;
}

