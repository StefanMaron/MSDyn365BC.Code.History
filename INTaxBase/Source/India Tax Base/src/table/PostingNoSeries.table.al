table 18552 "Posting No. Series"
{
    DataClassification = EndUserIdentifiableInformation;
    fields
    {
        field(1; ID; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            AutoIncrement = true;
        }
        field(2; "Document Type"; Enum "Posting Document Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Document Type';
            trigger OnValidate()
            var
                Handled: Boolean;
            begin
                if IsonRunHandled(Rec) then
                    exit;
                case "Document Type" of
                    "Document Type"::"Sales Shipment Header",
                    "Document Type"::"Sales Invoice Header",
                    "Document Type"::"Sales Cr.Memo Header",
                    "Document Type"::"Sales Return Receipt No.":
                        "Table Id" := Database::"Sales Header";
                    "Document Type"::"Purch. Rcpt. Header",
                    "Document Type"::"Purch. Inv. Header",
                    "Document Type"::"Purch. Cr. Memo Hdr.",
                    "Document Type"::"Purchase Return Shipment No.":
                        "Table Id" := Database::"Purchase Header";
                    "Document Type"::"Transfer Shipment Header",
                    "Document Type"::"Transfer Receipt Header":
                        "Table Id" := Database::"Transfer Header";
                    "Document Type"::"Gen. Journals":
                        "Table Id" := Database::"Gen. Journal Line"
                    else begin
                            OnGetPostingTableID("Document Type", "Table Id", Handled);
                            if not Handled then
                                Error('Document Type is not handled %1', "Document Type");
                        end;
                end;
            end;
        }
        field(3; "Table Id"; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Table Id';
        }
        field(4; Condition; Blob)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Condition';
        }
        field(5; "Posting No. Series"; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(PK; ID, "Document Type")
        {
            Clustered = true;
        }
    }
    procedure GetPostingNoSeriesCode(var Record: Variant)
    var
        RecRef: RecordRef;
        Handled: Boolean;
    begin
        if not Record.IsRecord() then
            exit;

        RecRef.GetTable(Record);

        case RecRef.Number() of
            Database::"Sales Header":
                GetSalesPostingNoSeries(Record);
            Database::"Purchase Header":
                GetPurchasePostingNoSeries(Record);
            Database::"Transfer Header":
                ;
            Database::"Gen. Journal Line":
                GetGenJournalpostingSeries(Record);
            else begin
                    OnGetPostingNoSeries(Record, Handled);
                    if not Handled then
                        Error('Record is not handled for Posting No. Series');
                end;
        end;
    end;

    local procedure GetSalesPostingNoSeries(var SalesHeader: Record "Sales Header")
    var
        PostingNoSeries: Record "Posting No. Series";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
        TableID: Integer;
    begin
        SalesSetup.Get();
        TableID := Database::"Sales Header";
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice,
            SalesHeader."Document Type"::Order,
            SalesHeader."Document Type"::Quote,
            SalesHeader."Document Type"::"Blanket Order":
                begin
                    NoSeriesCode := LoopPostingNoSeries(TableID, PostingNoSeries, SalesHeader, PostingNoSeries."Document Type"::"Sales Shipment Header");
                    if NoSeriesCode <> '' then
                        SalesHeader."Shipping No. Series" := NoSeriesCode
                    else
                        NoSeriesMgt.SetDefaultSeries(SalesHeader."Shipping No. Series", SalesSetup."Posted Shipment Nos.");

                    NoSeriesCode := LoopPostingNoSeries(TableID, PostingNoSeries, SalesHeader, PostingNoSeries."Document Type"::"Sales Invoice Header");
                    if NoSeriesCode <> '' then
                        SalesHeader."Posting No. Series" := NoSeriesCode
                    else
                        NoSeriesMgt.SetDefaultSeries(SalesHeader."Posting No. Series", SalesSetup."Posted Invoice Nos.");
                end;

            SalesHeader."Document Type"::"Return Order",
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    NoSeriesCode := LoopPostingNoSeries(TableID, PostingNoSeries, SalesHeader, PostingNoSeries."Document Type"::"Sales Cr.Memo Header");
                    if NoSeriesCode <> '' then
                        SalesHeader."Posting No. Series" := NoSeriesCode
                    else
                        NoSeriesMgt.SetDefaultSeries(SalesHeader."Posting No. Series", SalesSetup."Posted Credit Memo Nos.");

                    NoSeriesCode := LoopPostingNoSeries(TableID, PostingNoSeries, SalesHeader, PostingNoSeries."Document Type"::"Sales Return Receipt No.");
                    if NoSeriesCode <> '' then
                        SalesHeader."Return Receipt No. Series" := NoSeriesCode
                    else
                        if SalesSetup."Return Receipt on Credit Memo" then
                            NoSeriesMgt.SetDefaultSeries(SalesHeader."Return Receipt No. Series", SalesSetup."Posted Return Receipt Nos.");

                end;
        end;
    end;

    local procedure GetGenJournalpostingSeries(var GenJournalLine: Record "Gen. Journal Line")
    var
        PostingNoSeries: Record "Posting No. Series";
        NoSeriesCode: Code[20];
        TableID: Integer;
    begin
        TableID := Database::"Gen. Journal Line";
        NoSeriesCode := LoopPostingNoSeries(TableID, PostingNoSeries, GenJournalLine, PostingNoSeries."Document Type"::"Gen. Journals");

        if NoSeriesCode <> '' then
            GenJournalLine."Posting No. Series" := NoSeriesCode;

    end;

    local procedure GetPurchasePostingNoSeries(var PurchaseHeader: Record "Purchase Header")
    var
        PostingNoSeries: Record "Posting No. Series";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
        TableID: Integer;
    begin
        PurchSetup.Get();
        TableID := Database::"Purchase Header";
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Invoice,
            PurchaseHeader."Document Type"::Order,
            PurchaseHeader."Document Type"::Quote,
            PurchaseHeader."Document Type"::"Blanket Order":
                begin
                    NoSeriesCode := LoopPostingNoSeries(TableID, PostingNoSeries, PurchaseHeader, PostingNoSeries."Document Type"::"Purch. Rcpt. Header");
                    if NoSeriesCode <> '' then
                        PurchaseHeader."Receiving No. Series" := NoSeriesCode
                    else
                        NoSeriesMgt.SetDefaultSeries(PurchaseHeader."Receiving No. Series", PurchSetup."Posted Receipt Nos.");

                    NoSeriesCode := LoopPostingNoSeries(TableID, PostingNoSeries, PurchaseHeader, PostingNoSeries."Document Type"::"Purch. Inv. Header");
                    if NoSeriesCode <> '' then
                        PurchaseHeader."Posting No. Series" := NoSeriesCode
                    else
                        NoSeriesMgt.SetDefaultSeries(PurchaseHeader."Posting No. Series", PurchSetup."Posted Invoice Nos.");
                end;

            PurchaseHeader."Document Type"::"Return Order",
            PurchaseHeader."Document Type"::"Credit Memo":
                begin
                    NoSeriesCode := LoopPostingNoSeries(TableID, PostingNoSeries, PurchaseHeader, PostingNoSeries."Document Type"::"Purch. Cr. Memo Hdr.");
                    if NoSeriesCode <> '' then
                        PurchaseHeader."Posting No. Series" := NoSeriesCode
                    else
                        NoSeriesMgt.SetDefaultSeries(PurchaseHeader."Posting No. Series", PurchSetup."Posted Credit Memo Nos.");

                    NoSeriesCode := LoopPostingNoSeries(TableID, PostingNoSeries, PurchaseHeader, PostingNoSeries."Document Type"::"Purchase Return Shipment No.");
                    if NoSeriesCode <> '' then
                        PurchaseHeader."Return Shipment No. Series" := NoSeriesCode
                    else
                        if PurchSetup."Return Shipment on Credit Memo" then
                            NoSeriesMgt.SetDefaultSeries(PurchaseHeader."Return Shipment No. Series", PurchSetup."Posted Return Shpt. Nos.");
                end;
        end;
    end;

    procedure LoopPostingNoSeries(TableID: Integer; var PostingNoSeries: Record "Posting No. Series"; Record: Variant; PostingDocumentType: Enum "Posting Document Type"): Code[20]
    var
        Filters: Text;
    begin
        PostingNoSeries.SetRange("Table Id", TableID);
        PostingNoSeries.SetRange("Document Type", PostingDocumentType);
        if PostingNoSeries.FindSet() then
            repeat
                Filters := GetRecordView(PostingNoSeries);
                if RecordViewFound(Record, Filters) then begin
                    PostingNoSeries.TestField("Posting No. Series");
                    exit(PostingNoSeries."Posting No. Series");
                end;
            until PostingNoSeries.Next() = 0;
    end;

    local procedure GetRecordView(var PostingNoSeries: Record "Posting No. Series") Filters: Text;
    var
        ConditionInStream: InStream;
    begin
        PostingNoSeries.CalcFields(Condition);
        PostingNoSeries.Condition.CREATEINSTREAM(ConditionInStream);
        ConditionInStream.Read(Filters);
    end;

    local procedure RecordViewFound(Record: Variant; Filters: Text) Found: Boolean;
    var
        Field: Record Field;
        DuplicateRecRef: RecordRef;
        TempRecRef: RecordRef;
        FieldRef: FieldRef;
        TempFieldRef: FieldRef;
    begin
        DuplicateRecRef.GetTable(Record);
        Clear(TempRecRef);
        TempRecRef.Open(DuplicateRecRef.Number(), true);
        Field.SetRange(TableNo, DuplicateRecRef.Number());
        if Field.FindSet() then
            repeat
                FieldRef := DuplicateRecRef.Field(Field."No.");
                TempFieldRef := TempRecRef.Field(Field."No.");
                TempFieldRef.Value := FieldRef.Value();
            until Field.Next() = 0;

        TempRecRef.Insert();
        Found := true;
        if Filters = '' then
            exit;

        TempRecRef.SetView(Filters);
        Found := TempRecRef.Find();
    end;

    local procedure IsonRunHandled(var PostingNoSeries: Record "Posting No. Series") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeRun(PostingNoSeries, IsHandled);
        exit(IsHandled);
    end;

    [IntegrationEvent(False, false)]
    local procedure OnBeforeRun(var PostingNoSeries: Record "Posting No. Series"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPostingTableID(Type: Enum "Posting Document Type"; var TableID: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetPostingNoSeries(var Record: Variant; var Handled: Boolean)
    begin
    end;
}