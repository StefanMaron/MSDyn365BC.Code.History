#if not CLEAN22
codeunit 5065 "Email Logging Context Adapter"
{
    SingleInstance = false;
    TableNo = "Job Queue Entry";
    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    trigger OnRun()
    var
        EmailLoggingDispatcher: Codeunit "Email Logging Dispatcher";
    begin
        if not EmailLoggingDispatcher.Run(Rec) then
            Error(Text001, EmailLoggingDispatcher.GetErrorContext(), GetLastErrorText);
    end;

    var
        Text001: Label '%1 : %2.';
}
#endif
