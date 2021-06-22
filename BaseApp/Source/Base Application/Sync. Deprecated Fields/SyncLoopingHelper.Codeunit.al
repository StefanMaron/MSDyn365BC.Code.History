codeunit 9300 "Sync. Looping Helper"
{
    EventSubscriberInstance = Manual;

    var
        TempSkippedField: Record Field temporary;

    procedure SkipFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; TableNo: Integer; FieldNo: Integer)
    begin
        BindSubscription(SyncLoopingHelper);

        if TempSkippedField.Get(TableNo, FieldNo) then
            exit;

        TempSkippedField.Init();
        TempSkippedField.TableNo := TableNo;
        TempSkippedField."No." := FieldNo;
        TempSkippedField.Insert();
    end;

    procedure SkipFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; TableNo: Integer)
    begin
        SkipFieldSynchronization(SyncLoopingHelper, TableNo, 0);
    end;

    procedure RestoreFieldSynchronization(TableNo: Integer; FieldNo: Integer)
    begin
        if not TempSkippedField.Get(TableNo, FieldNo) then
            exit;

        TempSkippedField.Delete();
    end;

    procedure RestoreFieldSynchronization(TableNo: Integer)
    begin
        RestoreFieldSynchronization(TableNo, 0);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnIsFieldSynchronizationSkipped(TableNo: Integer; FieldNo: Integer; var Skipped: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sync. Looping Helper", 'OnIsFieldSynchronizationSkipped', '', false, false)]
    local procedure CheckTableFieldOnIsFieldSynchronizationSkipped(TableNo: Integer; FieldNo: Integer; var Skipped: Boolean)
    begin
        Skipped := TempSkippedField.Get(TableNo, FieldNo);
    end;

    procedure IsFieldSynchronizationSkipped(TableNo: Integer; FieldNo: Integer): Boolean
    var
        Skipped: Boolean;
    begin
        OnIsFieldSynchronizationSkipped(TableNo, FieldNo, Skipped);
        exit(Skipped);
    end;

    procedure IsFieldSynchronizationSkipped(TableNo: Integer): Boolean
    begin
        exit(IsFieldSynchronizationSkipped(TableNo, 0));
    end;
}
