codeunit 132250 "Library - Test Initialize"
{

    trigger OnRun()
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnTestInitialize(CallerCodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTestSuiteInitialize(CallerCodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnAfterTestSuiteInitialize(CallerCodeunitID: Integer)
    begin
    end;
}

