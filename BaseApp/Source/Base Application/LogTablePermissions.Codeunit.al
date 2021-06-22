codeunit 9800 "Log Table Permissions"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        TempTablePermissionBuffer: Record "Table Permission Buffer" temporary;
        [WithEvents]
        EventReceiver: DotNet NavPermissionEventReceiver;

    procedure Start()
    begin
        OnBeforeStart(SessionId());

        TempTablePermissionBuffer.DeleteAll();
        if IsNull(EventReceiver) then
            EventReceiver := EventReceiver.NavPermissionEventReceiver(SessionId);

        EventReceiver.RegisterForEvents;
    end;

    procedure Stop(var TempTablePermissionBufferVar: Record "Table Permission Buffer" temporary)
    begin
        EventReceiver.UnregisterEvents;
        TempTablePermissionBufferVar.Copy(TempTablePermissionBuffer, true)
    end;

    local procedure LogUsage(TypeOfObject: Option; ObjectId: Integer; Permissions: Integer; PermissionsFromCaller: Integer)
    begin
        // Note: Do not start any write transactions inside this method and do not make
        // any commits. This code is invoked on permission checks - where there may be
        // no transaction.
        if (ObjectId = DATABASE::"Table Permission Buffer") and
           ((TypeOfObject = TempTablePermissionBuffer."Object Type"::Table) or
            (TypeOfObject = TempTablePermissionBuffer."Object Type"::"Table Data") or
            ((TypeOfObject = TempTablePermissionBuffer."Object Type"::Codeunit) and (ObjectId = CODEUNIT::"Log Table Permissions")))
        then
            exit;

        if not TempTablePermissionBuffer.Get(SessionId, TypeOfObject, ObjectId) then begin
            TempTablePermissionBuffer.Init();
            TempTablePermissionBuffer."Session ID" := SessionId;
            TempTablePermissionBuffer."Object Type" := TypeOfObject;
            TempTablePermissionBuffer."Object ID" := ObjectId;
            TempTablePermissionBuffer."Read Permission" := TempTablePermissionBuffer."Read Permission"::" ";
            TempTablePermissionBuffer."Insert Permission" := TempTablePermissionBuffer."Insert Permission"::" ";
            TempTablePermissionBuffer."Modify Permission" := TempTablePermissionBuffer."Modify Permission"::" ";
            TempTablePermissionBuffer."Delete Permission" := TempTablePermissionBuffer."Delete Permission"::" ";
            TempTablePermissionBuffer."Execute Permission" := TempTablePermissionBuffer."Execute Permission"::" ";
            TempTablePermissionBuffer.Insert();
        end;

        TempTablePermissionBuffer."Object Type" := TypeOfObject;

        case SelectDirectOrIndirect(Permissions, PermissionsFromCaller) of
            1:
                TempTablePermissionBuffer."Read Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Read Permission", TempTablePermissionBuffer."Read Permission"::Yes);
            32:
                TempTablePermissionBuffer."Read Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Read Permission", TempTablePermissionBuffer."Read Permission"::Indirect);
            2:
                TempTablePermissionBuffer."Insert Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Insert Permission", TempTablePermissionBuffer."Insert Permission"::Yes);
            64:
                TempTablePermissionBuffer."Insert Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Insert Permission", TempTablePermissionBuffer."Insert Permission"::Indirect);
            4:
                TempTablePermissionBuffer."Modify Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Modify Permission", TempTablePermissionBuffer."Modify Permission"::Yes);
            128:
                TempTablePermissionBuffer."Modify Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Modify Permission", TempTablePermissionBuffer."Modify Permission"::Indirect);
            8:
                TempTablePermissionBuffer."Delete Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Delete Permission", TempTablePermissionBuffer."Delete Permission"::Yes);
            256:
                TempTablePermissionBuffer."Delete Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Delete Permission", TempTablePermissionBuffer."Delete Permission"::Indirect);
            16:
                TempTablePermissionBuffer."Execute Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Execute Permission", TempTablePermissionBuffer."Execute Permission"::Yes);
            512:
                TempTablePermissionBuffer."Execute Permission" :=
                  GetMaxPermission(TempTablePermissionBuffer."Execute Permission", TempTablePermissionBuffer."Execute Permission"::Indirect);
        end;
        TempTablePermissionBuffer.Modify();
    end;

    procedure GetMaxPermission(CurrentPermission: Option; NewPermission: Option): Integer
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        if PermissionManager.IsFirstPermissionHigherThanSecond(CurrentPermission, NewPermission) then
            exit(CurrentPermission);
        exit(NewPermission);
    end;

    local procedure SelectDirectOrIndirect(DirectPermission: Integer; IndirectPermission: Integer): Integer
    begin
        if IndirectPermission = 0 then
            exit(DirectPermission);
        exit(IndirectPermission);
    end;

    trigger EventReceiver::OnPermissionCheckEvent(sender: Variant; e: DotNet PermissionCheckEventArgs)
    begin
        case e.EventId of
            801:
                case e.ValidationCategory of
                    EventReceiver.NormalValidationCategoryId,
                  EventReceiver.ReadPermissionValidationCategoryId,
                  EventReceiver.WritePermissionValidationCategoryId:
                        LogUsage(e.ObjectType, e.ObjectId, e.Permissions, e.IndirectPermissionsFromCaller);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStart(SessionID: Integer)
    begin
    end;
}

