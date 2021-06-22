table 414 "IC Outbox Transaction"
{
    Caption = 'IC Outbox Transaction';

    fields
    {
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner".Code;
        }
        field(3; "Source Type"; Option)
        {
            Caption = 'Source Type';
            Editable = false;
            OptionCaption = 'Journal Line,Sales Document,Purchase Document';
            OptionMembers = "Journal Line","Sales Document","Purchase Document";
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Refund,Order,Return Order';
            OptionMembers = " ",Payment,Invoice,"Credit Memo",Refund,"Order","Return Order";
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;

            trigger OnLookup()
            begin
                OnBeforeLookupDocumentNo(Rec);
            end;
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(10; "Line Action"; Option)
        {
            Caption = 'Line Action';
            OptionCaption = 'No Action,Send to IC Partner,Return to Inbox,Cancel';
            OptionMembers = "No Action","Send to IC Partner","Return to Inbox",Cancel;

            trigger OnValidate()
            begin
                case "Line Action" of
                    "Line Action"::"Return to Inbox":
                        TestField("Transaction Source", "Transaction Source"::"Rejected by Current Company");
                    "Line Action"::"Send to IC Partner":
                        OutboxCheckSend;
                end;
            end;
        }
        field(12; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
        }
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "IC Partner Code", "Transaction Source", "Document Type")
        {
            Clustered = true;
        }
        key(Key2; "IC Partner Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICOutboxPurchHdr: Record "IC Outbox Purchase Header";
        ICOutboxSalesHdr: Record "IC Outbox Sales Header";
        ICCommentLine: Record "IC Comment Line";
    begin
        case "Source Type" of
            "Source Type"::"Journal Line":
                begin
                    ICOutboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                    ICOutboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                    if ICOutboxJnlLine.FindFirst then
                        ICOutboxJnlLine.DeleteAll(true);
                end;
            "Source Type"::"Sales Document":
                begin
                    ICOutboxSalesHdr.SetRange("IC Transaction No.", "Transaction No.");
                    ICOutboxSalesHdr.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxSalesHdr.SetRange("Transaction Source", "Transaction Source");
                    if ICOutboxSalesHdr.FindFirst then
                        ICOutboxSalesHdr.Delete(true);
                end;
            "Source Type"::"Purchase Document":
                begin
                    ICOutboxPurchHdr.SetRange("IC Transaction No.", "Transaction No.");
                    ICOutboxPurchHdr.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxPurchHdr.SetRange("Transaction Source", "Transaction Source");
                    if ICOutboxPurchHdr.FindFirst then
                        ICOutboxPurchHdr.Delete(true);
                end;
            else
                OnDeleteOnSourceTypeCase(Rec);
        end;

        ICCommentLine.SetRange("Table Name", ICCommentLine."Table Name"::"IC Outbox Transaction");
        ICCommentLine.SetRange("Transaction No.", "Transaction No.");
        ICCommentLine.SetRange("IC Partner Code", "IC Partner Code");
        ICCommentLine.SetRange("Transaction Source", "Transaction Source");
        if ICCommentLine.Find('-') then
            repeat
                ICCommentLine.Delete(true);
            until ICCommentLine.Next = 0;
    end;

    procedure ShowDetails()
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
        ICOutboxPurchHeader: Record "IC Outbox Purchase Header";
        ICOutboxJnlLines: Page "IC Outbox Jnl. Lines";
        ICOutboxSalesDoc: Page "IC Outbox Sales Doc.";
        ICOutboxPurchDoc: Page "IC Outbox Purchase Doc.";
    begin
        case "Source Type" of
            "Source Type"::"Journal Line":
                begin
                    ICOutboxJnlLine.SetRange("Transaction No.", "Transaction No.");
                    ICOutboxJnlLine.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxJnlLine.SetRange("Transaction Source", "Transaction Source");
                    Clear(ICOutboxJnlLines);
                    ICOutboxJnlLines.SetTableView(ICOutboxJnlLine);
                    ICOutboxJnlLines.RunModal;
                end;
            "Source Type"::"Sales Document":
                begin
                    ICOutboxSalesHeader.SetRange("IC Transaction No.", "Transaction No.");
                    ICOutboxSalesHeader.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxSalesHeader.SetRange("Transaction Source", "Transaction Source");
                    Clear(ICOutboxSalesDoc);
                    ICOutboxSalesDoc.SetTableView(ICOutboxSalesHeader);
                    ICOutboxSalesDoc.RunModal;
                end;
            "Source Type"::"Purchase Document":
                begin
                    ICOutboxPurchHeader.SetRange("IC Partner Code", "IC Partner Code");
                    ICOutboxPurchHeader.SetRange("IC Transaction No.", "Transaction No.");
                    ICOutboxPurchHeader.SetRange("Transaction Source", "Transaction Source");
                    Clear(ICOutboxPurchDoc);
                    ICOutboxPurchDoc.SetTableView(ICOutboxPurchHeader);
                    ICOutboxPurchDoc.RunModal;
                end;
        end;
    end;

    local procedure OutboxCheckSend()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction2: Record "IC Outbox Transaction";
        Text001: Label 'Transaction No. %2 is a copy of Transaction No. %1, which has already been set to Send to IC Partner.\Do you also want to send Transaction No. %2?';
        Text002: Label 'A copy of Transaction No. %1 has already been sent to IC Partner and is now in the Handled IC Outbox Transactions window.\Do you also want to send Transaction No. %1?';
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOutboxCheckSend(Rec, IsHandled);
        if IsHandled then
            exit;

        HandledICOutboxTrans.SetRange("Source Type", "Source Type");
        HandledICOutboxTrans.SetRange("Document Type", "Document Type");
        HandledICOutboxTrans.SetRange("Document No.", "Document No.");
        if HandledICOutboxTrans.FindFirst then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text002, "Transaction No."), true) then
                Error('');

        ICOutboxTransaction2.SetRange("Source Type", "Source Type");
        ICOutboxTransaction2.SetRange("Document Type", "Document Type");
        ICOutboxTransaction2.SetRange("Document No.", "Document No.");
        ICOutboxTransaction2.SetFilter("Transaction No.", '<>%1', "Transaction No.");
        ICOutboxTransaction2.SetRange("IC Partner G/L Acc. No.", "IC Partner G/L Acc. No.");
        ICOutboxTransaction2.SetRange("Source Line No.", "Source Line No.");
        ICOutboxTransaction2.SetRange("Line Action", "Line Action"::"Send to IC Partner");
        if ICOutboxTransaction2.FindFirst then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text001, ICOutboxTransaction2."Transaction No.", "Transaction No."), true)
            then
                Error('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocumentNo(ICOutboxTransaction: Record "IC Outbox Transaction");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOutboxCheckSend(var ICOutboxTransaction: Record "IC Outbox Transaction"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnSourceTypeCase(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;
}

