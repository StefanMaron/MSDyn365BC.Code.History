codeunit 1332 "Template Feature Mgt."
{
    trigger OnRun()
    begin
    end;

    procedure IsEnabled() Result: Boolean
    var
        FeatureKey: Record "Feature Key";
    begin
        if FeatureKey.Get(GetFeatureKey()) then
            Result := FeatureKey.Enabled = FeatureKey.Enabled::"All Users";

        OnAfterIsEnabled(Result);
    end;

    procedure GetFeatureKey(): Text[50]
    begin
        exit('NewTemplates');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;
}