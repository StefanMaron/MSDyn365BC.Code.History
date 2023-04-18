#if not CLEAN20
codeunit 5444 "Graph Business Setting"
{
    ObsoleteReason = 'This codeunit will be deleted since the functionality that it was used for was discontinued';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure GetMSPayBusinessSetting() MSPayData: Text
    begin
    end;
}
#endif
