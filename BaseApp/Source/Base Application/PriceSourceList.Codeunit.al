codeunit 7011 "Price Source List"
{
    var
        TempPriceSource: Record "Price Source" temporary;
        CurrentLevel: Integer;

    procedure Init()
    begin
        CurrentLevel := 0;
        TempPriceSource.Reset();
        TempPriceSource.DeleteAll();
    end;

    procedure GetMinMaxLevel(var Level: array[2] of Integer)
    var
        LocalTempPriceSource: Record "Price Source" temporary;
    begin
        LocalTempPriceSource.Copy(TempPriceSource, true);
        LocalTempPriceSource.Reset();
        if LocalTempPriceSource.IsEmpty then begin
            Level[2] := Level[1] - 1;
            exit;
        end;

        LocalTempPriceSource.SetCurrentKey(Level);
        LocalTempPriceSource.FindFirst();
        Level[1] := LocalTempPriceSource.Level;
        LocalTempPriceSource.FindLast();
        Level[2] := LocalTempPriceSource.Level;
    end;

    procedure IncLevel()
    begin
        CurrentLevel += 1;
    end;

    procedure SetLevel(Level: Integer)
    begin
        CurrentLevel := Level;
    end;

    procedure Add(SourceType: Enum "Price Source Type"; SourceNo: Code[20])
    begin
        if SourceNo = '' then
            exit;
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Validate("Source No.", SourceNo);
        OnAddOnBeforeInsert(TempPriceSource);
        TempPriceSource.Insert(true);
    end;

    procedure Add(SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; SourceNo: Code[20])
    begin
        if SourceNo = '' then
            exit;
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Validate("Parent Source No.", ParentSourceNo);
        TempPriceSource.Validate("Source No.", SourceNo);
        OnAddOnBeforeInsert(TempPriceSource);
        TempPriceSource.Insert(true);
    end;

    procedure Add(SourceType: Enum "Price Source Type"; SourceId: Guid)
    begin
        if IsNullGuid(SourceId) then
            exit;
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Validate("Source ID", SourceId);
        OnAddOnBeforeInsert(TempPriceSource);
        TempPriceSource.Insert(true);
    end;

    procedure Add(SourceType: Enum "Price Source Type")
    begin
        TempPriceSource.NewEntry(SourceType, CurrentLevel);
        TempPriceSource.Insert(true);
    end;

    procedure GetValue(SourceType: Enum "Price Source Type") Result: Code[20];
    var
        LocalTempPriceSource: Record "Price Source" temporary;
        PriceSourceInterface: Interface "Price Source";
    begin
        LocalTempPriceSource.Copy(TempPriceSource, true);
        LocalTempPriceSource.Reset();
        LocalTempPriceSource.SetRange("Source Type", SourceType);
        If LocalTempPriceSource.FindFirst() then begin
            PriceSourceInterface := LocalTempPriceSource."Source Type";
            Result := LocalTempPriceSource."Source No.";
        end;
        OnAfterGetValue(SourceType, Result);
    end;

    procedure Copy(var FromPriceSourceList: Codeunit "Price Source List")
    begin
        Init();
        FromPriceSourceList.GetList(TempPriceSource);
    end;

    procedure GetList(var ToTempPriceSource: Record "Price Source" temporary): Boolean
    begin
        if ToTempPriceSource.IsTemporary then
            ToTempPriceSource.Copy(TempPriceSource, true);
        exit(not ToTempPriceSource.IsEmpty())
    end;

    procedure First(var PriceSource: Record "Price Source"; AtLevel: Integer): Boolean;
    begin
        TempPriceSource.Reset();
        TempPriceSource.SetCurrentKey(Level);
        TempPriceSource.SetRange(Level, AtLevel);
        exit(GetRecordIfFound(TempPriceSource.FindSet(), PriceSource))
    end;

    procedure Next(var PriceSource: Record "Price Source"): Boolean;
    begin
        exit(GetRecordIfFound(TempPriceSource.Next() > 0, PriceSource))
    end;

    local procedure GetRecordIfFound(Found: Boolean; var PriceSource: Record "Price Source"): Boolean
    begin
        if Found then begin
            PriceSource := TempPriceSource;
            CurrentLevel := TempPriceSource.Level;
        end else
            Clear(PriceSource);
        exit(Found)
    end;

    procedure GetSourceGroup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean;
    var
        PriceSource: Record "Price Source";
    begin
        if GetSourceGroup(PriceSource) then begin
            DtldPriceCalculationSetup."Source Group" := PriceSource."Source Group";
            DtldPriceCalculationSetup."Source Type" := PriceSource."Source Type";
            DtldPriceCalculationSetup."Source No." := PriceSource.GetGroupNo();
            exit(true);
        end;
    end;

    local procedure GetSourceGroup(var FoundPriceSource: Record "Price Source"): Boolean;
    var
        LocalTempPriceSource: Record "Price Source" temporary;
    begin
        LocalTempPriceSource.Copy(TempPriceSource, true);
        LocalTempPriceSource.Reset();
        LocalTempPriceSource.SetCurrentKey(Level);
        LocalTempPriceSource.SetAscending(Level, false);
        LocalTempPriceSource.SetFilter("Source Group", '<>%1', LocalTempPriceSource."Source Group"::All);
        if LocalTempPriceSource.IsEmpty() then
            exit(false);
        LocalTempPriceSource.SetFilter("Source No.", '<>%1', '');
        if LocalTempPriceSource.FindFirst() then begin
            FoundPriceSource := LocalTempPriceSource;
            exit(true);
        end;
        LocalTempPriceSource.SetRange("Source No.");
        if LocalTempPriceSource.FindFirst() then begin
            FoundPriceSource := LocalTempPriceSource;
            exit(true);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddOnBeforeInsert(var PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetValue(SourceType: Enum "Price Source Type"; var Result: Code[20])
    begin
    end;
}