codeunit 703 "Find Record Management"
{

    trigger OnRun()
    begin
    end;

    var
        WrongParameterTypeErr: Label 'Parameter type must be Record or RecordRef.';

    procedure FindLastEntryIgnoringSecurityFilter(var RecRef: RecordRef) Found: Boolean;
    var
        IsHandled: Boolean;
        xSecurityFilter: SecurityFilter;
    begin
        OnBeforeFindLastEntryIgnoringSecurityFilter(RecRef, Found, IsHandled);
        if IsHandled then
            exit(Found);

        with RecRef do begin
            xSecurityFilter := SecurityFiltering;
            SecurityFiltering(SecurityFiltering::Ignored);
            Found := FindLast();
            if SecurityFiltering <> xSecurityFilter then
                SecurityFiltering(xSecurityFilter)
        end;
    end;

    [Scope('OnPrem')]
    procedure GetIntFieldValue(RecRef: RecordRef; FieldNo: Integer): Integer;
    var
        IntFields: list of [Integer];
    begin
        IntFields.Add(FieldNo);
        GetIntFieldValues(RecRef, IntFields);
        exit(IntFields.Get(1));
    end;

    [Scope('OnPrem')]
    procedure GetIntFieldValues(RecRef: RecordRef; var IntFields: list of [Integer])
    var
        FldRef: FieldRef;
        FieldNos: list of [Integer];
        FieldNo: Integer;
        FieldValue: Variant;
    begin
        FieldNos := IntFields;
        clear(IntFields);
        foreach FieldNo in FieldNos do begin
            if IsFieldValid(RecRef, FieldNo, FieldType::Integer, FieldValue) then
                IntFields.Add(FieldValue)
            else
                IntFields.Add(0);
        end;
    end;

    procedure GetLastEntryIntFieldValue(SourceRec: Variant; FieldNo: Integer): Integer;
    var
        IntFields: list of [Integer];
    begin
        IntFields.Add(FieldNo);
        GetLastEntryIntFieldValues(SourceRec, IntFields);
        exit(IntFields.Get(1));
    end;

    procedure GetLastEntryIntFieldValues(SourceRec: Variant; var FieldNoValues: List of [Integer])
    var
        RecRef: RecordRef;
    begin
        ConvertVariantToRecordRef(SourceRec, RecRef);
        RecRef.Reset();
        FindLastEntryIgnoringSecurityFilter(RecRef);
        GetIntFieldValues(RecRef, FieldNoValues);
    end;

    local procedure ConvertVariantToRecordRef(SourceRec: Variant; var RecRef: RecordRef)
    begin
        case true of
            SourceRec.IsRecordRef:
                RecRef := SourceRec;
            SourceRec.IsRecord:
                RecRef.GetTable(SourceRec);
            else
                Error(WrongParameterTypeErr);
        end;
    end;

    local procedure IsFieldValid(RecRef: RecordRef; FieldNo: Integer; ExpectedFieldType: FieldType; var Value: Variant): Boolean
    var
        FldRef: FieldRef;
    begin
        Clear(Value);
        if RecRef.FieldExist(FieldNo) then begin
            FldRef := RecRef.Field(FieldNo);
            if FldRef.Type = ExpectedFieldType then begin
                if FldRef.Class = FieldClass::FlowField then
                    FldRef.CalcField();
                Value := FldRef.Value;
                exit(true);
            end;
        end;
    end;

    procedure FindNoFromTypedValue(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; Value: Code[20]; UseDefaultTableRelationFilters: Boolean): Code[20]
    var
        Item: Record Item;
        FoundNo: Code[20];
    begin
        OnBeforeFindNoFromTypedValue(Type, Value, FoundNo);
        if FoundNo <> '' then
            exit(FoundNo);

        if Type = Type::Item then
            exit(Item.GetItemNo(Value));

        FoundNo := FindNoByDescription(Type, Value, UseDefaultTableRelationFilters);
        if FoundNo <> '' then
            exit(FoundNo);
        exit(Value);
    end;

    [Scope('OnPrem')]
    procedure FindNoByDescription(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; Description: Text; UseDefaultTableRelationFilters: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
        ResultValue: Text;
        RecordView: Text;
    begin
        if UseDefaultTableRelationFilters and (Type = Type::"G/L Account") then
            RecordView := GetGLAccountTableRelationView;

        if FindRecordByDescriptionAndView(ResultValue, Type, Description, RecordView) = 1 then
            exit(CopyStr(ResultValue, 1, MaxStrLen(GLAccount."No.")));

        exit('');
    end;

    procedure FindRecordByDescription(var Result: Text; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; SearchText: Text): Integer
    begin
        exit(FindRecordByDescriptionAndView(Result, Type, SearchText, ''));
    end;

    [Scope('OnPrem')]
    procedure FindRecordByDescriptionAndView(var Result: Text; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; SearchText: Text; RecordView: Text): Integer
    var
        RecRef: RecordRef;
        SearchFieldRef: array[4] of FieldRef;
        SearchFieldNo: array[4] of Integer;
        KeyNoMaxStrLen: Integer;
        RecWithoutQuote: Text;
        RecFilterFromStart: Text;
        RecFilterContains: Text;
        MatchCount: Integer;
        IsHandled: Boolean;
    begin
        // Try to find a record by SearchText looking into "No." OR "Description" fields
        // SearchFieldNo[1] - "No."
        // SearchFieldNo[2] - "Description"/"Name"
        // SearchFieldNo[3] - "Base Unit of Measure" (used for items)
        Result := '';
        if SearchText = '' then
            exit(0);

        if not (Type in [Type::" " .. Type::"Charge (Item)"]) then
            exit(0);

        GetRecRefAndFieldsNoByType(RecRef, Type, SearchFieldNo);
        RecRef.SetView(RecordView);

        SearchFieldRef[1] := RecRef.Field(SearchFieldNo[1]);
        SearchFieldRef[2] := RecRef.Field(SearchFieldNo[2]);
        if SearchFieldNo[3] <> 0 then
            SearchFieldRef[3] := RecRef.Field(SearchFieldNo[3]);

        IsHandled := false;
        MatchCount := 0;
        OnBeforeFindRecordByDescriptionAndView(Result, Type, RecRef, SearchFieldRef, SearchText, RecordView, MatchCount, IsHandled);
        if IsHandled then
            exit(MatchCount);

        // Try GET(SearchText)
        KeyNoMaxStrLen := SearchFieldRef[1].Length;
        if StrLen(SearchText) <= KeyNoMaxStrLen then begin
            SearchFieldRef[1].SetRange(CopyStr(SearchText, 1, KeyNoMaxStrLen));
            if RecRef.FindFirst then begin
                Result := SearchFieldRef[1].Value;
                exit(1);
            end;
        end;
        SearchFieldRef[1].SetRange;
        ClearLastError;

        RecWithoutQuote := ConvertStr(SearchText, '''()&|', '?????');

        // Try FINDFIRST "No." by mask "Search string *"
        if TrySetFilterOnFieldRef(SearchFieldRef[1], RecWithoutQuote + '*') then
            if RecRef.FindFirst then begin
                Result := SearchFieldRef[1].Value;
                exit(1);
            end;
        SearchFieldRef[1].SetRange;
        ClearLastError;

        // Two items with descrptions = "aaa" and "AAA";
        // Try FINDFIRST by exact "Description" = "AAA"
        SearchFieldRef[2].SetRange(CopyStr(SearchText, 1, SearchFieldRef[2].Length));
        if RecRef.FindFirst then begin
            Result := SearchFieldRef[1].Value;
            exit(1);
        end;
        SearchFieldRef[2].SetRange;

        // Example of SearchText = "Search string ''";
        // Try FINDFIRST "Description" by mask "@Search string ?"
        SearchFieldRef[2].SetFilter('''@' + RecWithoutQuote + '''');
        if RecRef.FindFirst then begin
            Result := SearchFieldRef[1].Value;
            exit(1);
        end;
        SearchFieldRef[2].SetRange;

        // Try FINDFIRST "No." OR "Description" by mask "@Search string ?*"
        RecRef.FilterGroup := -1;
        RecFilterFromStart := '''@' + RecWithoutQuote + '*''';
        SearchFieldRef[1].SetFilter(RecFilterFromStart);
        SearchFieldRef[2].SetFilter(RecFilterFromStart);
        OnBeforeFindRecordStartingWithSearchString(Type, RecRef, RecFilterFromStart);
        if RecRef.FindFirst then begin
            Result := SearchFieldRef[1].Value;
            exit(1);
        end;

        // Try FINDFIRST "No." OR "Description" OR additional field by mask "@*Search string ?*"
        RecFilterContains := '''@*' + RecWithoutQuote + '*''';
        SearchFieldRef[1].SetFilter(RecFilterContains);
        SearchFieldRef[2].SetFilter(RecFilterContains);
        if SearchFieldNo[3] <> 0 then
            SearchFieldRef[3].SetFilter(RecFilterContains);
        OnBeforeFindRecordContainingSearchString(Type, RecRef, RecFilterContains);
        if RecRef.FindFirst then begin
            Result := SearchFieldRef[1].Value;
            exit(RecRef.Count);
        end;

        // Try FINDLAST record with similar "Description"
        if FindRecordWithSimilarName(RecRef, SearchText, SearchFieldNo[2]) then begin
            Result := SearchFieldRef[1].Value;
            exit(1);
        end;

        // Try find for extension
        MatchCount := 0;
        OnAfterFindRecordByDescriptionAndView(Result, Type, RecRef, SearchFieldRef, SearchFieldNo, SearchText, MatchCount);
        if MatchCount <> 0 then
            exit(MatchCount);

        // Not found
        exit(0);
    end;

    procedure FindRecordWithSimilarName(RecRef: RecordRef; SearchText: Text; DescriptionFieldNo: Integer): Boolean
    var
        TypeHelper: Codeunit "Type Helper";
        Description: Text;
        RecCount: Integer;
        TextLength: Integer;
        Treshold: Integer;
    begin
        if SearchText = '' then
            exit(false);

        TextLength := StrLen(SearchText);
        if TextLength > RecRef.Field(DescriptionFieldNo).Length then
            exit(false);

        Treshold := TextLength div 5;
        if Treshold = 0 then
            exit(false);

        RecRef.Reset();
        RecRef."SecurityFiltering" := SECURITYFILTER::Filtered;
        RecRef.Ascending(false); // most likely to search for newest records
        if RecRef.FindSet then
            repeat
                RecCount += 1;
                Description := RecRef.Field(DescriptionFieldNo).Value;
                if Abs(TextLength - StrLen(Description)) <= Treshold then
                    if TypeHelper.TextDistance(UpperCase(SearchText), UpperCase(Description)) <= Treshold then
                        exit(true);
            until (RecRef.Next = 0) or (RecCount > 1000);

        exit(false);
    end;

    local procedure GetRecRefAndFieldsNoByType(RecRef: RecordRef; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; var SearchFieldNo: array[4] of Integer)
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        FixedAsset: Record "Fixed Asset";
        Resource: Record Resource;
        ItemCharge: Record "Item Charge";
        StandardText: Record "Standard Text";
    begin
        OnBeforeGetRecRefAndFieldsNoByType(RecRef, Type, SearchFieldNo);
        case Type of
            Type::"G/L Account":
                begin
                    RecRef.Open(DATABASE::"G/L Account");
                    SearchFieldNo[1] := GLAccount.FieldNo("No.");
                    SearchFieldNo[2] := GLAccount.FieldNo(Name);
                    SearchFieldNo[3] := 0;
                end;
            Type::Item:
                begin
                    RecRef.Open(DATABASE::Item);
                    SearchFieldNo[1] := Item.FieldNo("No.");
                    SearchFieldNo[2] := Item.FieldNo(Description);
                    SearchFieldNo[3] := Item.FieldNo("Base Unit of Measure");
                end;
            Type::Resource:
                begin
                    RecRef.Open(DATABASE::Resource);
                    SearchFieldNo[1] := Resource.FieldNo("No.");
                    SearchFieldNo[2] := Resource.FieldNo(Name);
                    SearchFieldNo[3] := 0;
                end;
            Type::"Fixed Asset":
                begin
                    RecRef.Open(DATABASE::"Fixed Asset");
                    SearchFieldNo[1] := FixedAsset.FieldNo("No.");
                    SearchFieldNo[2] := FixedAsset.FieldNo(Description);
                    SearchFieldNo[3] := 0;
                end;
            Type::"Charge (Item)":
                begin
                    RecRef.Open(DATABASE::"Item Charge");
                    SearchFieldNo[1] := ItemCharge.FieldNo("No.");
                    SearchFieldNo[2] := ItemCharge.FieldNo(Description);
                    SearchFieldNo[3] := 0;
                end;
            Type::" ":
                begin
                    RecRef.Open(DATABASE::"Standard Text");
                    SearchFieldNo[1] := StandardText.FieldNo(Code);
                    SearchFieldNo[2] := StandardText.FieldNo(Description);
                    SearchFieldNo[3] := 0;
                end;
        end;
        OnAfterGetRecRefAndFieldsNoByType(RecRef, Type, SearchFieldNo);
    end;

    local procedure GetGLAccountTableRelationView(): Text
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange(Blocked, false);
        exit(GLAccount.GetView);
    end;

    [TryFunction]
    local procedure TrySetFilterOnFieldRef(var FieldRef: FieldRef; "Filter": Text)
    begin
        FieldRef.SetFilter(Filter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindRecordByDescriptionAndView(var Result: Text; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; var RecRef: RecordRef; SearchFieldRef: array[4] of FieldRef; SearchFieldNo: array[4] of Integer; SearchText: Text; var MatchCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecRefAndFieldsNoByType(RecRef: RecordRef; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; var SearchFieldNo: array[4] of Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLastEntryIgnoringSecurityFilter(var RecRef: RecordRef; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNoFromTypedValue(var Type: Option; var Value: Code[20]; var FoundNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecordByDescriptionAndView(var Result: Text; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; var RecRef: RecordRef; SearchFieldRef: array[4] of FieldRef; SearchText: Text; RecordView: Text; var MatchCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecordContainingSearchString(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; var RecRef: RecordRef; RecFilterFromStart: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecordStartingWithSearchString(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; var RecRef: RecordRef; RecFilterFromStart: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRecRefAndFieldsNoByType(RecRef: RecordRef; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; var SearchFieldNo: array[4] of Integer)
    begin
    end;
}

