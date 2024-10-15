codeunit 11769 "Change Dimension Management"
{
    Permissions = TableData "Dimension Value" = rim,
                  TableData "Default Dimension" = r;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        TempChangeLogSetupTable: Record "Change Log Setup (Table)" temporary;
        TempDefaultDimension: Record "Default Dimension" temporary;
        DimChangeSetupRead: Boolean;

    [EventSubscriber(ObjectType::Codeunit, 49, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if CompanyName = '' then
            exit;

        CheckChangeSetupRead;

        if TempChangeLogSetupTable.Get(TableId) then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 49, 'OnAfterOnDatabaseInsert', '', false, false)]
    [Scope('OnPrem')]
    procedure DimensionInsert(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary then
            exit;

        CheckChangeSetupRead;

        if not TempChangeLogSetupTable.Get(RecRef.Number) then
            exit;

        UpdateDimensionValue(RecRef, RecRef, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 49, 'OnAfterOnDatabaseModify', '', false, false)]
    [Scope('OnPrem')]
    procedure DimensionModify(RecRef: RecordRef)
    var
        xRecRef: RecordRef;
    begin
        if RecRef.IsTemporary then
            exit;

        CheckChangeSetupRead;

        if not TempChangeLogSetupTable.Get(RecRef.Number) then
            exit;

        if not xRecRef.Get(RecRef.RecordId) then
            xRecRef := RecRef;

        UpdateDimensionValue(RecRef, xRecRef, false);
    end;

    [Scope('OnPrem')]
    procedure UpdateDimensionValue(RecRef: RecordRef; XRecRef: RecordRef; IsInsert: Boolean)
    var
        DimensionValue: Record "Dimension Value";
        FieldTab: Record "Field";
        FieldRefField: FieldRef;
        FieldRefFieldOld: FieldRef;
        FieldRefFieldPK: FieldRef;
        KeyRefKey: KeyRef;
        TempValueText: Text[250];
        TempValueTextOld: Text[250];
        IsUpdate: Boolean;
    begin
        with TempDefaultDimension do begin
            Reset;
            SetRange("Table ID", RecRef.Number);
            SetRange("Automatic Create", true);
            SetRange("No.", '');
            SetFilter("Dimension Description Field ID", '<>%1', 0);
            SetFilter("Dimension Description Update", '<>%1', "Dimension Description Update"::" ");
            if FindSet(false, false) then
                repeat
                    IsUpdate := false;
                    FieldRefField := RecRef.Field("Dimension Description Field ID");
                    KeyRefKey := RecRef.KeyIndex(1);
                    FieldRefFieldPK := KeyRefKey.FieldIndex(1);
                    if DimensionValue.Get("Dimension Code", Format(FieldRefFieldPK.Value)) then begin
                        if FieldTab.Get("Table ID", "Dimension Description Field ID") then
                            if FieldTab.Class = FieldTab.Class::FlowField then
                                FieldRefField.CalcField;
                        TempValueText := Format(FieldRefField.Value);
                        if "Dimension Description Format" <> '' then
                            TempValueText := StrSubstNo("Dimension Description Format", TempValueText);
                        if TempValueText <> '' then
                            TempValueText := CopyStr(TempValueText, 1, MaxStrLen(DimensionValue.Name));
                        if "Dimension Description Update" = "Dimension Description Update"::Create then
                            if (DimensionValue.Name = '') or IsInsert then
                                IsUpdate := true
                            else begin
                                FieldRefFieldOld := XRecRef.Field("Dimension Description Field ID");
                                if FieldTab.Get("Table ID", "Dimension Description Field ID") then
                                    if FieldTab.Class = FieldTab.Class::FlowField then
                                        FieldRefFieldOld.CalcField;
                                TempValueTextOld := Format(FieldRefFieldOld.Value);
                                if "Dimension Description Format" <> '' then
                                    TempValueTextOld := StrSubstNo("Dimension Description Format", TempValueTextOld);
                                if TempValueTextOld <> '' then
                                    TempValueTextOld := CopyStr(TempValueTextOld, 1, MaxStrLen(DimensionValue.Name));
                                IsUpdate := DimensionValue.Name = TempValueTextOld;
                            end
                        else
                            IsUpdate := true;
                        if (DimensionValue.Name <> TempValueText) and IsUpdate then begin
                            DimensionValue.Name := CopyStr(TempValueText, 1, MaxStrLen(DimensionValue.Name));
                            DimensionValue.Modify;
                        end;
                    end;
                until Next = 0;
        end;
    end;

    local procedure CheckChangeSetupRead()
    begin
        if not DimChangeSetupRead then begin
            ReadSetup;
            DimChangeSetupRead := true;
        end;
    end;

    local procedure ReadSetup()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Automatic Create", true);
        DefaultDimension.SetRange("No.", '');
        DefaultDimension.SetFilter("Dimension Description Field ID", '<>%1', 0);
        DefaultDimension.SetFilter("Dimension Description Update", '<>%1', DefaultDimension."Dimension Description Update"::" ");
        if DefaultDimension.FindSet(false, false) then
            repeat
                if not TempChangeLogSetupTable.Get(DefaultDimension."Table ID") then begin
                    TempChangeLogSetupTable."Table No." := DefaultDimension."Table ID";
                    TempChangeLogSetupTable.Insert;
                end;
                TempDefaultDimension := DefaultDimension;
                TempDefaultDimension.Insert;
            until DefaultDimension.Next = 0;
    end;
}

