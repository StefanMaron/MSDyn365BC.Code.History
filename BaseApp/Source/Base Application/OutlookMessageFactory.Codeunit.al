codeunit 9530 "Outlook Message Factory"
{
    SingleInstance = true;
    Subtype = Normal;

    trigger OnRun()
    begin
    end;

    var
        [RunOnClient]
        OutlookMessageFactory: DotNet IOutlookMessageFactory;

    [Scope('OnPrem')]
    procedure CreateOutlookMessage(var OutlookMessage: DotNet IOutlookMessage)
    begin
        if IsNull(OutlookMessageFactory) then
            CreateDefaultOutlookMessageFactory;
        OutlookMessage := OutlookMessageFactory.CreateOutlookMessage;
    end;

    [Scope('OnPrem')]
    procedure SetOutlookMessageFactory(ParmOutlookMessageFactory: DotNet IOutlookMessageFactory)
    begin
        OutlookMessageFactory := ParmOutlookMessageFactory;
    end;

    local procedure CreateDefaultOutlookMessageFactory()
    var
        [RunOnClient]
        CreateOutlookMessageFactory: DotNet OutlookMessageFactory;
    begin
        OutlookMessageFactory := CreateOutlookMessageFactory.OutlookMessageFactory;
    end;
}

