codeunit 18201 "GST Distribution Subcsribers"
{

    //GST Posting No. Series Table
    [EventSubscriber(ObjectType::Table, Database::"Posting No. Series", 'OnBeforeRun', '', false, false)]
    local procedure ValidatePostingSeriesDocumentType(var PostngNoSeries: Record "Posting No. Series"; var IsHandled: Boolean)
    begin
        case PostngNoSeries."Document Type" of
            PostngNoSeries."Document Type"::"GST Distribution":
                begin
                    PostngNoSeries."Table Id" := Database::"GST Distribution Header";
                    IsHandled := True;
                end;
        end;
    end;

    //GST Component Distribution Validation - Subscribers
    [EventSubscriber(ObjectType::Table, Database::"GST Component Distribution", 'Onaftervalidateevent', 'Intrastate Distribution', false, false)]
    local procedure ValidateIntrastateDistribution(var Rec: Record "GST Component Distribution")
    begin
        IntrastateDistribution(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Component Distribution", 'Onaftervalidateevent', 'Interstate Distribution', false, false)]
    local procedure ValidateInterstateDistribution(var Rec: Record "GST Component Distribution")
    begin
        InterstateDistribution(Rec);
    end;

    //GST Distribution Header Validation - Subcsribers
    [EventSubscriber(ObjectType::Table, Database::"GST Distribution Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure GSTDistHeaderOnInsertTrigger(var Rec: Record "GST Distribution Header")
    begin
        OnGSTDistHeaderInsert(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Distribution Header", 'OnAfterValidateEvent', 'NO.', false, false)]
    local procedure ValidateNoField(var Rec: Record "GST Distribution Header"; var xRec: Record "GST Distribution Header")
    var
        GLSetup: Record "General Ledger Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        GLSetup.Get();
        if Rec."No." <> xRec."No." then begin
            GLSetup.Get();
            NoSeriesManagement.TestManual(GLSetup."GST Distribution Nos.");
            Rec."No. Series" := '';
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Distribution Header", 'OnAfterValidateEvent', 'posting date', false, false)]
    local procedure ValidatePostingDate(var Rec: Record "GST Distribution Header")
    begin
        PostingDate(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Distribution Header", 'OnAfterValidateEvent', 'Dist. Document Type', false, false)]
    local procedure ValidateDistDocumentType(var Rec: Record "GST Distribution Header")
    begin
        DistDocumentType(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Distribution Header", 'OnAfterValidateEvent', 'Reversal Invoice No.', false, false)]
    local procedure ValidateReversalInvoiceNo(var Rec: Record "GST Distribution Header")
    begin
        ReversalInvoiceNo(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Distribution Header", 'OnAfterValidateEvent', 'From Location Code', false, false)]
    local procedure ValidateFromLocationCode(var Rec: Record "GST Distribution Header")
    begin
        FromLocationCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Distribution Header", 'OnAfterValidateEvent', 'Dist. Credit Type', false, false)]
    local procedure ValidateDistCreditType(var Rec: Record "GST Distribution Header")
    begin
        Rec.TestField("Total Amout Applied for Dist.", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Distribution Header", 'OnAfterValidateEvent', 'Shortcut Dimension 1 Code', false, false)]
    local procedure ValidateShortcutDimension1Code(var Rec: Record "GST Distribution Header")
    begin
        ValidateShortcutDimCode(1, Rec."Shortcut Dimension 1 Code", Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Distribution Header", 'OnAfterValidateEvent', 'Shortcut Dimension 2 Code', false, false)]
    local procedure ValidateShortcutDimension2Code(var Rec: Record "GST Distribution Header")
    begin
        ValidateShortcutDimCode(2, Rec."Shortcut Dimension 2 Code", Rec);
    end;

    //GST Claim Setoff Validations
    [EventSubscriber(ObjectType::Table, Database::"GST Claim Setoff", 'OnAfterValidateEvent', 'Set Off Component Code', False, False)]
    local procedure ValidateSetOffComponentCode(var Rec: Record "GST Claim Setoff")
    begin
        if Rec."GST Component Code" = Rec."Set Off Component Code" then
            Error(SameComponentErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Claim Setoff", 'OnAfterValidateEvent', 'Priority', False, False)]
    local procedure ValidatePriority(var Rec: Record "GST Claim Setoff"; var xRec: Record "GST Claim Setoff")
    begin
        if (xRec.Priority <> Rec.Priority) and IsSamePriority(Rec."GST Component Code", Rec.Priority) then
            Error(SamePriorityErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GST Claim Setoff", 'OnAfterInsertEvent', '', False, False)]
    local procedure ValidateInsertRecord(var Rec: Record "GST Claim Setoff")
    begin
        Rec.Priority := GetLastPriority(Rec."GST Component Code");
        if IsZeroPriority(Rec."GST Component Code") then
            Error(ZeroPriorityErr);
    end;

    local procedure GetLastPriority(GSTComponentCode: Code[10]): Integer
    var
        GSTClaimSetoff: Record "GST Claim Setoff";
    begin
        GSTClaimSetoff.SetCurrentKey(Priority);
        GSTClaimSetoff.SetRange("GST Component Code", GSTComponentCode);
        if GSTClaimSetoff.FindLast() then
            exit(GSTClaimSetoff.Priority + 1);
        exit(1);
    end;

    local procedure IsZeroPriority(GSTComponentCode: Code[10]): Boolean
    var
        GSTClaimSetoff: Record "GST Claim Setoff";
    begin
        GSTClaimSetoff.SetRange("GST Component Code", GSTComponentCode);
        GSTClaimSetoff.SetRange(Priority, 0);
        exit(not GSTClaimSetoff.IsEmpty());
    end;

    local procedure IsSamePriority(GSTComponentCode: Code[10]; GSTPriority: Integer): Boolean
    var
        GSTClaimSetoff: Record "GST Claim Setoff";
    begin
        GSTClaimSetoff.SetCurrentKey(Priority);
        GSTClaimSetoff.SetRange("GST Component Code", GSTComponentCode);
        GSTClaimSetoff.SetRange(Priority, GSTPriority);
        exit(not GSTClaimSetoff.IsEmpty());
    end;

    //GST Component Distribution Validation - Definition
    local procedure IntrastateDistribution(var GSTCompDistribution: Record "GST Component Distribution")
    var
        GSTCompDistribution2: Record "GST Component Distribution";
    begin
        GSTCompDistribution2.Reset();
        GSTCompDistribution2.SetRange("GST Component Code", GSTCompDistribution."GST Component Code");
        GSTCompDistribution2.SetFilter(
            "Distribution Component Code",
            '<>%1',
            GSTCompDistribution."Distribution Component Code");
        GSTCompDistribution2.SetRange("Intrastate Distribution", true);
        if GSTCompDistribution2.FindFirst() then
            Error(
                IntrastateInterstateErr,
                GSTCompDistribution.FieldCaption(GSTCompDistribution."Intrastate Distribution"),
                GSTCompDistribution."GST Component Code",
                GSTCompDistribution2."Distribution Component Code");
    end;

    local procedure InterstateDistribution(var GSTCompDistribution: Record "GST Component Distribution")
    var
        GSTCompDistribution2: Record "GST Component Distribution";
    begin
        GSTCompDistribution2.Reset();
        GSTCompDistribution2.SetRange("GST Component Code", GSTCompDistribution."GST Component Code");
        GSTCompDistribution2.SetFilter(
            "Distribution Component Code",
            '<>%1',
            GSTCompDistribution."Distribution Component Code");
        GSTCompDistribution2.SetRange("Interstate Distribution", true);
        if GSTCompDistribution2.FindFirst() then
            Error(
                  IntrastateInterstateErr,
                  GSTCompDistribution.FieldCaption(GSTCompDistribution."Interstate Distribution"),
                  GSTCompDistribution."GST Component Code",
                  GSTCompDistribution2."Distribution Component Code");
    end;

    //GST Distribution Header Validation - Definition
    local procedure OnGSTDistHeaderInsert(var GSTDistributionHeader: record "GST Distribution Header")
    var
        GLSetup: Record "General Ledger Setup";
        NoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        if GSTDistributionHeader."No." = '' then begin
            GLSetup.Get();
            if GLSetup."GST Distribution Nos." <> '' then begin
                GLSetup.TestField("GST Distribution Nos.");
                NoSeries.Get(GLSetup."GST Distribution Nos.");
                GSTDistributionHeader."No." := NoSeriesManagement.GetNextNo(NoSeries.Code, WORKDATE(), true);
                GSTDistributionHeader."No. Series" := GLSetup."GST Distribution Nos.";
            end;
        end;

        GSTDistributionHeader."Creation Date" := WorkDate();
        GSTDistributionHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(GSTDistributionHeader."User ID"));
        GSTDistributionHeader."Posting Date" := WorkDate();
    end;

    local procedure PostingDate(var GSTDistHeader: Record "GST Distribution Header")
    var
        GSTDistLine: Record "GST Distribution Line";
    begin
        if not GSTDistHeader.Reversal then
            GSTDistHeader.TestField("Total Amout Applied for Dist.", 0)
        else
            if GSTDistributionLinesExist(GSTDistHeader."No.") then begin
                GSTDistLine.Reset();
                GSTDistLine.SetRange("Distribution No.", GSTDistHeader."No.");
                if GSTDistLine.FindSet() then
                    repeat
                        GSTDistLine."Posting Date" := GSTDistHeader."Posting Date";
                        GSTDistLine.ModIfy();
                    until GSTDistLine.Next() = 0;
            end;
    end;

    local procedure GSTDistributionLinesExist(No: Code[20]): Boolean
    var
        GSTDistLine: Record "GST Distribution Line";
    begin
        GSTDistLine.SetRange("Distribution No.", no);
        exit(GSTDistLine.IsEmpty());
    end;

    local procedure DistDocumentType(var GSTDistHeader: Record "GST Distribution Header")
    var
        Location: Record location;
        Record: Variant;
    begin
        GSTDistHeader.TestField("Total Amout Applied for Dist.", 0);
        GSTDistHeader.TestField("From Location Code");
        Location.Get(GSTDistHeader."From Location Code");

        case GSTDistHeader."Dist. Document Type" OF
            GSTDistHeader."Dist. Document Type"::Invoice:
                begin
                    Record := GSTDistHeader;
                    GetDistributionNoSeriesCode(Record);
                    GSTDistHeader := Record;
                    if GSTDistHeader."Posting No. Series" = '' then
                        Error(PostingNoSeriesNotDefinedErr);
                    GSTDistHeader."ISD Document Type" := GSTDistHeader."ISD Document Type"::Invoice;
                end;
            GSTDistHeader."Dist. Document Type"::"Credit Memo":
                begin
                    Record := GSTDistHeader;
                    GetDistributionNoSeriesCode(Record);
                    GSTDistHeader := Record;
                    if GSTDistHeader."Posting No. Series" = '' then
                        Error(PostingNoSeriesNotDefinedErr);
                    GSTDistHeader."ISD Document Type" := GSTDistHeader."ISD Document Type"::"Credit Memo";
                end;
        end;
    end;

    local procedure ReversalInvoiceNo(var GSTDistHeader: Record "GST Distribution Header")
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        DetailedGSTLedgerEntry.Reset();
        DetailedGSTLedgerEntry.SetRange("Dist. Reverse Document No.", GSTDistHeader."No.");
        DetailedGSTLedgerEntry.SetRange("Distributed Reversed", false);
        DetailedGSTLedgerEntry.SetFilter("Dist. Document No.", '<>%1', GSTDistHeader."Reversal Invoice No.");
        DetailedGSTLedgerEntry.ModifyAll("Dist. Reverse Document No.", '');
        InsertDistHeaderReversal(GSTDistHeader);
        InsertDistLineReversal(GSTDistHeader);
    end;

    local procedure ValidateShortcutDimCode(
        FieldNumber: Integer;
        var ShortcutDimCode: Code[20];
        var GSTDistHeader: Record "GST Distribution Header")
    var
        DimMgt: Codeunit DimensionManagement;
        OldDimSetID: Integer;
    begin
        OldDimSetID := GSTDistHeader."Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, GSTDistHeader."Dimension Set ID");
        if GSTDistHeader."No." <> '' then
            GSTDistHeader.ModIfy();

        if OldDimSetID <> GSTDistHeader."Dimension Set ID" then begin
            GSTDistHeader.ModIfy();
            if GSTDistributionLinesExist(GSTDistHeader."No.") then
                UpdateAllLineDim(GSTDistHeader."Dimension Set ID", OldDimSetID, GSTDistHeader."No.");
        end;
    end;

    local procedure UpdateAllLineDim(
        NewParentDimSetID: Integer;
        OldParentDimSetID: Integer;
        DisTributionNo: Code[20])
    var
        GSTDistLine: Record "GST Distribution Line";
        DimMgt: Codeunit DimensionManagement;
        NewDimSetID: Integer;
    begin
        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(UpdateDimQst) then
            exit;

        GSTDistLine.SetRange("Distribution No.", "DisTributionNo");
        GSTDistLine.LockTable();
        if GSTDistLine.FindSet() then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(
                    GSTDistLine."Dimension Set ID",
                    NewParentDimSetID,
                    OldParentDimSetID);

                if GSTDistLine."Dimension Set ID" <> NewDimSetID then begin
                    GSTDistLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                        GSTDistLine."Dimension Set ID",
                        GSTDistLine."Shortcut Dimension 1 Code",
                        GSTDistLine."Shortcut Dimension 2 Code");
                    GSTDistLine.ModIfy();
                end;
            until GSTDistLine.Next() = 0;
    end;

    local procedure FromLocationCode(var GSTDistHeader: Record "GST Distribution Header")
    var
        Location: Record Location;
    begin
        GSTDistHeader.TestField("Total Amout Applied for Dist.", 0);
        if Location.Get(GSTDistHeader."From Location Code") then begin
            GSTDistHeader."From GSTIN No." := Location."GST Registration No.";
            case GSTDistHeader."Dist. Document Type" OF
                GSTDistHeader."Dist. Document Type"::Invoice:
                    GSTDistHeader."ISD Document Type" := GSTDistHeader."ISD Document Type"::Invoice;
                GSTDistHeader."Dist. Document Type"::"Credit Memo":
                    GSTDistHeader."ISD Document Type" := GSTDistHeader."ISD Document Type"::"Credit Memo";
            end;
        end else begin
            GSTDistHeader."From GSTIN No." := '';
            GSTDistHeader."Posting No. Series" := '';
        end;
    end;

    local procedure InsertDistHeaderReversal(var GSTDistHeader: Record "GST Distribution Header")
    var
        PostedGSTDistHeader: Record "Posted GST Distribution Header";
        Location: Record Location;
        GSTDistribution: Codeunit "GST Distribution";
    begin
        GSTDistHeader.TestField("Posting Date");
        if GSTDistHeader."Reversal Invoice No." <> '' then begin
            GSTDistribution.DeleteGSTDistributionLine(GSTDistHeader."No.");
            PostedGSTDistHeader.Get(GSTDistHeader."Reversal Invoice No.");

            GSTDistHeader."From GSTIN No." := PostedGSTDistHeader."From GSTIN No.";
            GSTDistHeader."Creation Date" := WORKDATE();
            GSTDistHeader."User ID" := copystr(USERID(), 1, MaxStrLen(GSTDistHeader."User ID"));
            GSTDistHeader."From Location Code" := PostedGSTDistHeader."From Location Code";
            GSTDistHeader."Dist. Document Type" := PostedGSTDistHeader."Dist. Document Type";
            Location.Get(GSTDistHeader."From Location Code");
            if PostedGSTDistHeader."Dist. Document Type" = PostedGSTDistHeader."Dist. Document Type"::Invoice then begin
                GSTDistHeader."ISD Document Type" := GSTDistHeader."ISD Document Type"::"Credit Memo";
                GSTDistHeader."Posting No. Series" := Location."Posted Dist. Cr. Memo Nos.";
            end else begin
                GSTDistHeader."ISD Document Type" := GSTDistHeader."ISD Document Type"::Invoice;
                GSTDistHeader."Posting No. Series" := Location."Posted Dist. Invoice Nos.";
            end;

            GSTDistHeader."Dist. Credit Type" := PostedGSTDistHeader."Dist. Credit Type";
            GSTDistHeader."Total Amout Applied for Dist." := 0;
        end else begin
            GSTDistHeader."From GSTIN No." := '';
            GSTDistHeader."Posting Date" := 0D;
            GSTDistHeader."Dist. Document Type" := GSTDistHeader."Dist. Document Type"::" ";
            GSTDistHeader."From Location Code" := '';
            GSTDistHeader."Dist. Credit Type" := GSTDistHeader."Dist. Credit Type"::" ";
            GSTDistHeader."Total Amout Applied for Dist." := 0;
            GSTDistribution.DeleteGSTDistributionLine(GSTDistHeader."No.");
        end;
    end;

    local procedure InsertDistLineReversal(var GSTDistHeader: Record "GST Distribution Header")
    var
        PostedGSTDistLine: Record "Posted GST Distribution Line";
        GSTDistHeader2: Record "GST Distribution Header";
        GSTDistLine: Record "GST Distribution Line";
    begin
        GSTDistHeader2.Get(GSTDistHeader."No.");
        PostedGSTDistLine.SetRange("Distribution No.", GSTDistHeader."Reversal Invoice No.");
        if PostedGSTDistLine.FindSet() then
            repeat
                GSTDistLine.Init();
                GSTDistLine.TRANSFERFIELDS(PostedGSTDistLine);
                GSTDistLine."Distribution No." := GSTDistHeader."No.";
                GSTDistLine."Posting Date" := GSTDistHeader2."Posting Date";
                GSTDistLine."Distribution Amount" := 0;
                GSTDistLine.Insert(true);
            until PostedGSTDistLine.Next() = 0;
    end;

    procedure GetDistributionNoSeriesCode(var Record: Variant)
    var
        RecRef: RecordRef;
    begin
        if not Record.IsRecord() then
            exit;

        RecRef.GetTable(Record);
        case RecRef.Number() of
            Database::"GST Distribution Header":
                GetDistributionPostingNoSeries(Record);
        end;
    end;

    local procedure GetDistributionPostingNoSeries(var GSTDistributionHeader: Record "GST Distribution Header")
    var
        PostingNoSeries: Record "Posting No. Series";
        NoSeriesCode: Code[20];
    begin
        PostingNoSeries.SetRange("Table Id", Database::"GST Distribution Header");
        NoSeriesCode := LoopPostingNoSeries(
            PostingNoSeries,
            GSTDistributionHeader,
            PostingNoSeries."Document Type"::"GST Distribution");
        if NoSeriesCode <> '' then
            GSTDistributionHeader."Posting No. Series" := NoSeriesCode;
    end;

    local procedure LoopPostingNoSeries(
            var PostingNoSeries: Record "Posting No. Series";
            Record: Variant;
            PostingDocumentType: Enum "Posting Document Type"): Code[20]
    var
        Filters: Text;
    begin
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

    local procedure GetRecordView(var PostingNoSeries: Record "Posting No. Series") Filters: Text;
    var
        ConditionInStream: InStream;
    begin
        PostingNoSeries.calcfields(Condition);
        PostingNoSeries.Condition.CREATEINSTREAM(ConditionInStream);
        ConditionInStream.Read(Filters);
    end;

    var
        IntrastateInterstateErr: Label '%1 is already true for GST Component Code: %2 Distribution Component Code: %3.', Comment = '%1 = Intrastate Distribution , %2 = GST Component Code , %3 = Distribution Component Code';
        UpdateDimQst: Label 'You may have changed a dimension.Do you want to update the lines?';
        SamePriorityErr: Label 'Priority CanNot be duplicate.';
        SameComponentErr: Label 'You canNot select same GST Component in GST Claim Setoff.';
        ZeroPriorityErr: Label 'Priority CanNot be Zero.';
        PostingNoSeriesNotDefinedErr: Label 'Posting no. series not defined, in posting no. series setup.';
}
