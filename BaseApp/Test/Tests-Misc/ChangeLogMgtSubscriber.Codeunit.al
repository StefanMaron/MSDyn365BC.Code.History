codeunit 139132 "Change Log Mgt. Subscriber"
{
    EventSubscriberInstance = manual;
    SingleInstance = true;

    trigger OnRun()
    begin
        // [FEATURE] [Change Log Extensions]
    end;

    var
        TestValue: Integer;

    procedure SetTestValue(NewTestValue: Integer)
    begin
        TestValue := NewTestValue;
    end;

    procedure GetTestValue(): Integer
    begin
        exit(TestValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Log Management", 'OnBeforeInsertChangeLogEntry', '', true, true)]
    local procedure OnBeforeInsertChangeLogEntry(var ChangeLogEntry: Record "Change Log Entry"; AlwaysLog: Boolean; var Handled: Boolean)
    begin
        SetTestValue(ChangeLogEntry."Table No.");
        Handled := true;
    end;
}