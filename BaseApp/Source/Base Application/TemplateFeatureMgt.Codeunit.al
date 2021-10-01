codeunit 1332 "Template Feature Mgt."
{
    trigger OnRun()
    begin
    end;

    procedure IsEnabled() Result: Boolean
    begin
        Result := true;
        OnAfterIsEnabled(Result);
    end;

#if not CLEAN19
    [Obsolete('Feature key is not required anymore and will be removed.', '19.0')]
    procedure GetFeatureKey(): Text[50]
    begin
        exit('NewTemplates');
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;
}