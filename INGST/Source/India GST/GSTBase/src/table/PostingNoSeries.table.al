table 18010 "Posting No. Series"
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
            Begin
                If IsonRunHandled(Rec) Then
                    Exit;
                Case "Document Type" of
                    "Document Type"::"Sales Shipment Header",
                    "Document Type"::"Sales Invoice Header",
                    "Document Type"::"Sales Cr.Memo Header":
                        "Table Id" := Database::"Sales Header";
                    "Document Type"::"Purch. Rcpt. Header",
                    "Document Type"::"Purch. Inv. Header",
                    "Document Type"::"Purch. Cr. Memo Hdr.":
                        "Table Id" := Database::"Purchase Header";
                    "Document Type"::"Transfer Shipment Header",
                    "Document Type"::"Transfer Receipt Header":
                        "Table Id" := Database::"Transfer Header";
                    "Document Type"::"Gen. Journals":
                        "Table Id" := Database::"Gen. Journal Line"
                    Else
                        Error('Document Type is not handled %1', "Document Type");
                End;
            End;
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
    Begin
        if not Record.IsRecord() then
            exit;

        RecRef.GetTable(Record);
        Case RecRef.Number() of
            Database::"Sales Header":
                GetSalesPostingNoSeries(Record);
            Database::"Purchase Header":
                GetPurchasePostingNoSeries(Record);
            Database::"Transfer Header":
                ;
            Database::"Gen. Journal Line":
                GetGenJournalpostingSeries(Record);
            Else
                Error('Record is not handled for Posting No. Series');
        End;
    End;

    local procedure GetSalesPostingNoSeries(var SalesHeader: Record "Sales Header")
    var
        PostingNoSeries: Record "Posting No. Series";
        NoSeriesCode: Code[20];
    Begin
        PostingNoSeries.SetRange("Table Id", Database::"Sales Header");
        Case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice,
            SalesHeader."Document Type"::Order,
            SalesHeader."Document Type"::Quote,
            SalesHeader."Document Type"::"Blanket Order":
                Begin
                    NoSeriesCode := LoopPostingNoSeries(
                        PostingNoSeries,
                        SalesHeader,
                        PostingNoSeries."Document Type"::"Sales Shipment Header");
                    if NoSeriesCode <> '' then
                        SalesHeader."Shipping No. Series" := NoSeriesCode;
                    NoSeriesCode := LoopPostingNoSeries(
                        PostingNoSeries,
                        SalesHeader,
                        PostingNoSeries."Document Type"::"Sales Invoice Header");
                    if NoSeriesCode <> '' then
                        SalesHeader."Posting No. Series" := NoSeriesCode;

                End;
            SalesHeader."Document Type"::"Return Order",
            SalesHeader."Document Type"::"Credit Memo":
                Begin
                    NoSeriesCode := LoopPostingNoSeries(
                        PostingNoSeries,
                        SalesHeader,
                        PostingNoSeries."Document Type"::"Sales Shipment Header");
                    if NoSeriesCode <> '' then
                        SalesHeader."Return Receipt No. Series" := NoSeriesCode;
                    NoSeriesCode := LoopPostingNoSeries(
                        PostingNoSeries,
                        SalesHeader,
                        PostingNoSeries."Document Type"::"Sales Cr.Memo Header");
                    if NoSeriesCode <> '' then
                        SalesHeader."Posting No. Series" := NoSeriesCode;
                End;
        End;
    End;

    local procedure GetGenJournalpostingSeries(var GenJouornalLine: Record "Gen. Journal Line")
    var
        PostingNoSeries: Record "Posting No. Series";
        NoSeriesCode: Code[20];
    Begin
        PostingNoSeries.SetRange("Table Id", Database::"Gen. Journal Line");
        NoSeriesCode := LoopPostingNoSeries(
                PostingNoSeries,
                GenJouornalLine,
                PostingNoSeries."Document Type"::"Gen. Journals");
        if NoSeriesCode <> '' then
            GenJouornalLine."Posting No. Series" := NoSeriesCode;

    End;

    local procedure GetPurchasePostingNoSeries(var PurchHeader: Record "Purchase Header")
    var
        PostingNoSeries: Record "Posting No. Series";
        NoSeriesCode: Code[20];
    Begin
        PostingNoSeries.SetRange("Table Id", Database::"purchase Header");
        Case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Invoice,
            PurchHeader."Document Type"::Order,
            PurchHeader."Document Type"::Quote,
            PurchHeader."Document Type"::"Blanket Order":
                Begin
                    NoSeriesCode := LoopPostingNoSeries(
                        PostingNoSeries,
                        PurchHeader,
                        PostingNoSeries."Document Type"::"Purch. Rcpt. Header");
                    if NoSeriesCode <> '' then
                        PurchHeader."Receiving No. Series" := NoSeriesCode;
                    NoSeriesCode := LoopPostingNoSeries(
                        PostingNoSeries,
                        PurchHeader,
                        PostingNoSeries."Document Type"::"Purch. Inv. Header");
                    if NoSeriesCode <> '' then
                        PurchHeader."Posting No. Series" := NoSeriesCode;

                End;
            PurchHeader."Document Type"::"Return Order",
            PurchHeader."Document Type"::"Credit Memo":
                Begin
                    NoSeriesCode := LoopPostingNoSeries(
                        PostingNoSeries,
                        PurchHeader,
                        PostingNoSeries."Document Type"::"Purch. Rcpt. Header");
                    if NoSeriesCode <> '' then
                        PurchHeader."Return Shipment No. Series" := NoSeriesCode;
                    NoSeriesCode := LoopPostingNoSeries(
                        PostingNoSeries,
                        PurchHeader,
                        PostingNoSeries."Document Type"::"Purch. Inv. Header");
                    if NoSeriesCode <> '' then
                        PurchHeader."Posting No. Series" := NoSeriesCode;
                End;
        End;
    End;

    local procedure LoopPostingNoSeries(
        var PostingNoSeries: Record "Posting No. Series";
        Record: Variant;
        PostingDocumentType: Enum "Posting Document Type"): Code[20]
    var
        Filters: Text;
    Begin
        PostingNoSeries.SetRange("Document Type", PostingDocumentType);
        if PostingNoSeries.FindSet() then
            repeat
                Filters := GetRecordView(PostingNoSeries);
                if RecordViewFound(Record, Filters) then Begin
                    PostingNoSeries.TestField("Posting No. Series");
                    exit(PostingNoSeries."Posting No. Series");
                End;
            until PostingNoSeries.Next() = 0;
    End;

    local procedure GetRecordView(var PostingNoSeries: Record "Posting No. Series") Filters: Text;
    var
        ConditionInStream: InStream;
    Begin
        PostingNoSeries.calcfields(Condition);
        PostingNoSeries.Condition.CREATEINSTREAM(ConditionInStream);
        ConditionInStream.READ(Filters);
    End;

    local procedure RecordViewFound(Record: Variant; Filters: Text) Found: Boolean;
    var
        Field: Record Field;
        DuplicateRecRef: RecordRef;
        TempRecRef: RecordRef;
        FieldRef: FieldRef;
        TempFieldRef: FieldRef;
    Begin
        DuplicateRecRef.GetTable(Record);
        CLEAR(TempRecRef);
        TempRecRef.OPEN(DuplicateRecRef.NUMBER(), TRUE);
        Field.SETRANGE(TableNo, DuplicateRecRef.NUMBER());
        if Field.FINDSET() THEN
            REPEAT
                FieldRef := DuplicateRecRef.FIELD(Field."No.");
                TempFieldRef := TempRecRef.FIELD(Field."No.");
                TempFieldRef.VALUE := FieldRef.VALUE();
            UNTIL Field.NEXT() = 0;
        TempRecRef.INSERT();
        Found := true;
        if Filters = '' then
            exit;
        TempRecRef.SetView(Filters);
        Found := TempRecRef.Find();
    End;

    [IntegrationEvent(False, false)]
    Local Procedure OnBeforeRun(Var PostngNoSeries: Record "Posting No. Series"; Var IsHandled: Boolean)
    Begin
    End;

    Local procedure IsonRunHandled(Var PostingNoSeries: Record "Posting No. Series") IsHandled: Boolean
    begin
        IsHandled := False;
        OnBeforeRun(PostingNoSeries, IsHandled);
        Exit(IsHandled);
    end;
}