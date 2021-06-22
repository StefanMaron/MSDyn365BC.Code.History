codeunit 5065 "Email Logging Context Adapter"
{
    SingleInstance = false;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        EmailLoggingDispatcher: Codeunit "Email Logging Dispatcher";
    begin
        if not EmailLoggingDispatcher.Run(Rec) then
            Error(Text001, EmailLoggingDispatcher.GetErrorContext, GetLastErrorText);
    end;

    var
        Text001: Label '%1 : %2.';
}

