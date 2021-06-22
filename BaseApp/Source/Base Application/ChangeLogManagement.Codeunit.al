codeunit 423 "Change Log Management"
{
    Permissions = TableData "Change Log Setup" = r,
                  TableData "Change Log Setup (Table)" = r,
                  TableData "Change Log Setup (Field)" = r,
                  TableData "Change Log Entry" = ri;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        ChangeLogSetup: Record "Change Log Setup";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        TempChangeLogSetupTable: Record "Change Log Setup (Table)" temporary;
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        TempChangeLogSetupField: Record "Change Log Setup (Field)" temporary;
        ChangeLogSetupRead: Boolean;

    procedure GetDatabaseTableTriggerSetup(TableID: Integer; var LogInsert: Boolean; var LogModify: Boolean; var LogDelete: Boolean; var LogRename: Boolean)
    begin
        if CompanyName = '' then
            exit;

        if TableID = DATABASE::"Change Log Entry" then
            exit;

        if IsAlwaysLoggedTable(TableID) then begin
            LogInsert := true;
            LogModify := true;
            LogDelete := true;
            LogRename := true;
            exit;
        end;

        if not ChangeLogSetupRead then begin
            if ChangeLogSetup.Get then;
            ChangeLogSetupRead := true;
        end;

        if not ChangeLogSetup."Change Log Activated" then
            exit;

        if not TempChangeLogSetupTable.Get(TableID) then begin
            if not ChangeLogSetupTable.Get(TableID) then begin
                TempChangeLogSetupTable.Init();
                TempChangeLogSetupTable."Table No." := TableID;
            end else
                TempChangeLogSetupTable := ChangeLogSetupTable;
            TempChangeLogSetupTable.Insert();
        end;

        with TempChangeLogSetupTable do begin
            LogInsert := "Log Insertion" <> "Log Insertion"::" ";
            LogModify := "Log Modification" <> "Log Modification"::" ";
            LogRename := "Log Modification" <> "Log Modification"::" ";
            LogDelete := "Log Deletion" <> "Log Deletion"::" ";
        end;
    end;

    local procedure IsLogActive(TableNumber: Integer; FieldNumber: Integer; TypeOfChange: Option Insertion,Modification,Deletion): Boolean
    var
        IsActive: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsLogActive(TableNumber, FieldNumber, TypeOfChange, IsActive, IsHandled);
        IF IsHandled THEN
            exit(IsActive);

        if IsAlwaysLoggedTable(TableNumber) then
            exit(true);

        if not ChangeLogSetupRead then begin
            if ChangeLogSetup.Get then;
            ChangeLogSetupRead := true;
        end;
        if not ChangeLogSetup."Change Log Activated" then
            exit(false);
        if not TempChangeLogSetupTable.Get(TableNumber) then begin
            if not ChangeLogSetupTable.Get(TableNumber) then begin
                TempChangeLogSetupTable.Init();
                TempChangeLogSetupTable."Table No." := TableNumber;
            end else
                TempChangeLogSetupTable := ChangeLogSetupTable;
            TempChangeLogSetupTable.Insert();
        end;

        with TempChangeLogSetupTable do
            case TypeOfChange of
                TypeOfChange::Insertion:
                    if "Log Insertion" = "Log Insertion"::"Some Fields" then
                        exit(IsFieldLogActive(TableNumber, FieldNumber, TypeOfChange))
                    else
                        exit("Log Insertion" = "Log Insertion"::"All Fields");
                TypeOfChange::Modification:
                    if "Log Modification" = "Log Modification"::"Some Fields" then
                        exit(IsFieldLogActive(TableNumber, FieldNumber, TypeOfChange))
                    else
                        exit("Log Modification" = "Log Modification"::"All Fields");
                TypeOfChange::Deletion:
                    if "Log Deletion" = "Log Deletion"::"Some Fields" then
                        exit(IsFieldLogActive(TableNumber, FieldNumber, TypeOfChange))
                    else
                        exit("Log Deletion" = "Log Deletion"::"All Fields");
            end;
    end;

    local procedure IsFieldLogActive(TableNumber: Integer; FieldNumber: Integer; TypeOfChange: Option Insertion,Modification,Deletion): Boolean
    begin
        if FieldNumber = 0 then
            exit(true);

        if not TempChangeLogSetupField.Get(TableNumber, FieldNumber) then begin
            if not ChangeLogSetupField.Get(TableNumber, FieldNumber) then begin
                TempChangeLogSetupField.Init();
                TempChangeLogSetupField."Table No." := TableNumber;
                TempChangeLogSetupField."Field No." := FieldNumber;
            end else
                TempChangeLogSetupField := ChangeLogSetupField;
            TempChangeLogSetupField.Insert();
        end;

        with TempChangeLogSetupField do
            case TypeOfChange of
                TypeOfChange::Insertion:
                    exit("Log Insertion");
                TypeOfChange::Modification:
                    exit("Log Modification");
                TypeOfChange::Deletion:
                    exit("Log Deletion");
            end;
    end;

    local procedure IsAlwaysLoggedTable(TableID: Integer) AlwaysLogTable: Boolean
    begin
        AlwaysLogTable :=
          TableID in
          [DATABASE::User,
           DATABASE::"User Property",
           DATABASE::"Access Control",
           DATABASE::"Permission Set",
           DATABASE::Permission,
           DATABASE::"Change Log Setup",
           DATABASE::"Change Log Setup (Table)",
           DATABASE::"Change Log Setup (Field)",
           DATABASE::"User Group",
           DATABASE::"User Group Member",
           DATABASE::"User Group Access Control",
           DATABASE::"User Group Permission Set",
           9004, // Plan
           9005, // UserPlan
           DATABASE::"Plan Permission Set",
           DATABASE::"User Group Plan",
           DATABASE::"Tenant Permission Set",
           DATABASE::"Tenant Permission"];

        OnAfterIsAlwaysLoggedTable(TableID, AlwaysLogTable);
    end;

    local procedure InsertLogEntry(var FldRef: FieldRef; var xFldRef: FieldRef; var RecRef: RecordRef; TypeOfChange: Option Insertion,Modification,Deletion; IsReadable: Boolean)
    var
        ChangeLogEntry: Record "Change Log Entry";
        KeyFldRef: FieldRef;
        KeyRef1: KeyRef;
        i: Integer;
    begin
        if RecRef.CurrentCompany <> ChangeLogEntry.CurrentCompany then
            ChangeLogEntry.ChangeCompany(RecRef.CurrentCompany);
        ChangeLogEntry.Init();
        ChangeLogEntry."Date and Time" := CurrentDateTime;
        ChangeLogEntry.Time := DT2Time(ChangeLogEntry."Date and Time");

        ChangeLogEntry."User ID" := UserId;

        ChangeLogEntry."Table No." := RecRef.Number;
        ChangeLogEntry."Field No." := FldRef.Number;
        ChangeLogEntry."Type of Change" := TypeOfChange;
        if (RecRef.Number = DATABASE::"User Property") and (FldRef.Number in [2 .. 5]) then begin // Password like
            ChangeLogEntry."Old Value" := '*';
            ChangeLogEntry."New Value" := '*';
        end else begin
            if TypeOfChange <> TypeOfChange::Insertion then
                if IsReadable then
                    ChangeLogEntry."Old Value" := Format(xFldRef.Value, 0, 9)
                else
                    ChangeLogEntry."Old Value" := '';
            if TypeOfChange <> TypeOfChange::Deletion then
                ChangeLogEntry."New Value" := Format(FldRef.Value, 0, 9);
        end;

        ChangeLogEntry."Record ID" := RecRef.RecordId;
        ChangeLogEntry."Primary Key" := CopyStr(RecRef.GetPosition(false), 1, MaxStrLen(ChangeLogEntry."Primary Key"));

        KeyRef1 := RecRef.KeyIndex(1);
        for i := 1 to KeyRef1.FieldCount do begin
            KeyFldRef := KeyRef1.FieldIndex(i);

            case i of
                1:
                    begin
                        ChangeLogEntry."Primary Key Field 1 No." := KeyFldRef.Number;
                        ChangeLogEntry."Primary Key Field 1 Value" :=
                          CopyStr(Format(KeyFldRef.Value, 0, 9), 1, MaxStrLen(ChangeLogEntry."Primary Key Field 1 Value"));
                    end;
                2:
                    begin
                        ChangeLogEntry."Primary Key Field 2 No." := KeyFldRef.Number;
                        ChangeLogEntry."Primary Key Field 2 Value" :=
                          CopyStr(Format(KeyFldRef.Value, 0, 9), 1, MaxStrLen(ChangeLogEntry."Primary Key Field 2 Value"));
                    end;
                3:
                    begin
                        ChangeLogEntry."Primary Key Field 3 No." := KeyFldRef.Number;
                        ChangeLogEntry."Primary Key Field 3 Value" :=
                          CopyStr(Format(KeyFldRef.Value, 0, 9), 1, MaxStrLen(ChangeLogEntry."Primary Key Field 3 Value"));
                    end;
            end;
        end;
        ChangeLogEntry.Insert(true);
    end;

    procedure LogInsertion(var RecRef: RecordRef)
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        if RecRef.IsTemporary then
            exit;

        if not IsLogActive(RecRef.Number, 0, 0) then
            exit;
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            if HasValue(FldRef) then
                if IsNormalField(FldRef) then
                    if IsLogActive(RecRef.Number, FldRef.Number, 0) then
                        InsertLogEntry(FldRef, FldRef, RecRef, 0, true);
        end;
    end;

    procedure LogModification(var RecRef: RecordRef)
    var
        xRecRef: RecordRef;
        FldRef: FieldRef;
        xFldRef: FieldRef;
        i: Integer;
        IsReadable: Boolean;
    begin
        if RecRef.IsTemporary then
            exit;

        if not IsLogActive(RecRef.Number, 0, 1) then
            exit;

        xRecRef.Open(RecRef.Number);
        xRecRef."SecurityFiltering" := SECURITYFILTER::Filtered;
        if xRecRef.ReadPermission then begin
            IsReadable := true;
            if not xRecRef.Get(RecRef.RecordId) then
                exit;
        end;

        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            xFldRef := xRecRef.FieldIndex(i);
            if IsNormalField(FldRef) then
                if Format(FldRef.Value) <> Format(xFldRef.Value) then
                    if IsLogActive(RecRef.Number, FldRef.Number, 1) then
                        InsertLogEntry(FldRef, xFldRef, RecRef, 1, IsReadable);
        end;
    end;

    procedure LogRename(var RecRef: RecordRef; var xRecRefParam: RecordRef)
    var
        xRecRef: RecordRef;
        FldRef: FieldRef;
        xFldRef: FieldRef;
        i: Integer;
    begin
        if RecRef.IsTemporary then
            exit;

        if not IsLogActive(RecRef.Number, 0, 1) then
            exit;

        xRecRef.Open(xRecRefParam.Number, false, RecRef.CurrentCompany);
        xRecRef.Get(xRecRefParam.RecordId);
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            xFldRef := xRecRef.FieldIndex(i);
            if IsNormalField(FldRef) then
                if Format(FldRef.Value) <> Format(xFldRef.Value) then
                    if IsLogActive(RecRef.Number, FldRef.Number, 1) then
                        InsertLogEntry(FldRef, xFldRef, RecRef, 1, true);
        end;
    end;

    procedure LogDeletion(var RecRef: RecordRef)
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        if RecRef.IsTemporary then
            exit;

        if not IsLogActive(RecRef.Number, 0, 2) then
            exit;
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            if HasValue(FldRef) then
                if IsNormalField(FldRef) then
                    if IsLogActive(RecRef.Number, FldRef.Number, 2) then
                        InsertLogEntry(FldRef, FldRef, RecRef, 2, true);
        end;
    end;

    local procedure IsNormalField(FieldRef: FieldRef): Boolean
    begin
        exit(FieldRef.Class = FieldClass::Normal)
    end;

    local procedure HasValue(FldRef: FieldRef): Boolean
    var
        HasValue: Boolean;
        Int: Integer;
        Dec: Decimal;
        D: Date;
        T: Time;
    begin
        case FldRef.Type of
            FieldType::Boolean:
                HasValue := FldRef.Value;
            FieldType::Option:
                HasValue := true;
            FieldType::Integer:
                begin
                    Int := FldRef.Value;
                    HasValue := Int <> 0;
                end;
            FieldType::Decimal:
                begin
                    Dec := FldRef.Value;
                    HasValue := Dec <> 0;
                end;
            FieldType::Date:
                begin
                    D := FldRef.Value;
                    HasValue := D <> 0D;
                end;
            FieldType::Time:
                begin
                    T := FldRef.Value;
                    HasValue := T <> 0T;
                end;
            FieldType::BLOB:
                HasValue := false;
            else
                HasValue := Format(FldRef.Value) <> '';
        end;

        exit(HasValue);
    end;

    procedure InitChangeLog()
    begin
        ChangeLogSetupRead := false;
        TempChangeLogSetupField.DeleteAll();
        TempChangeLogSetupTable.DeleteAll();
    end;

    procedure EvaluateTextToFieldRef(InputText: Text; var FieldRef: FieldRef): Boolean
    var
        IntVar: Integer;
        DecimalVar: Decimal;
        DateVar: Date;
        TimeVar: Time;
        DateTimeVar: DateTime;
        BoolVar: Boolean;
        DurationVar: Duration;
        BigIntVar: BigInteger;
        GUIDVar: Guid;
        DateFormulaVar: DateFormula;
    begin
        if FieldRef.Class in [FieldClass::FlowField, FieldClass::FlowFilter] then
            exit(true);

        case FieldRef.Type of
            FieldType::Integer, FieldType::Option:
                if Evaluate(IntVar, InputText) then begin
                    FieldRef.Value := IntVar;
                    exit(true);
                end;
            FieldType::Decimal:
                if Evaluate(DecimalVar, InputText, 9) then begin
                    FieldRef.Value := DecimalVar;
                    exit(true);
                end;
            FieldType::Date:
                if Evaluate(DateVar, InputText, 9) then begin
                    FieldRef.Value := DateVar;
                    exit(true);
                end;
            FieldType::Time:
                if Evaluate(TimeVar, InputText, 9) then begin
                    FieldRef.Value := TimeVar;
                    exit(true);
                end;
            FieldType::DateTime:
                if Evaluate(DateTimeVar, InputText, 9) then begin
                    FieldRef.Value := DateTimeVar;
                    exit(true);
                end;
            FieldType::Boolean:
                if Evaluate(BoolVar, InputText, 9) then begin
                    FieldRef.Value := BoolVar;
                    exit(true);
                end;
            FieldType::Duration:
                if Evaluate(DurationVar, InputText, 9) then begin
                    FieldRef.Value := DurationVar;
                    exit(true);
                end;
            FieldType::BigInteger:
                if Evaluate(BigIntVar, InputText) then begin
                    FieldRef.Value := BigIntVar;
                    exit(true);
                end;
            FieldType::GUID:
                if Evaluate(GUIDVar, InputText, 9) then begin
                    FieldRef.Value := GUIDVar;
                    exit(true);
                end;
            FieldType::Code, FieldType::Text:
                begin
                    if StrLen(InputText) > FieldRef.Length then begin
                        FieldRef.Value := PadStr(InputText, FieldRef.Length);
                        exit(false);
                    end;
                    FieldRef.Value := InputText;
                    exit(true);
                end;
            FieldType::DateFormula:
                if Evaluate(DateFormulaVar, InputText, 9) then begin
                    FieldRef.Value := DateFormulaVar;
                    exit(true);
                end;
        end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAlwaysLoggedTable(TableID: Integer; var AlwaysLogTable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsLogActive(TableNumber: Integer; FieldNumber: Integer; TypeOfChange: Option Insertion,Modification,Deletion; var IsActive: Boolean; var IsHandled: Boolean);
    begin
    end;
}

