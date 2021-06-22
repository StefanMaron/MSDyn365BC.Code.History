codeunit 130441 "Library - Email Feature"
{
    var
        EmailFeatureKeyTxt: Label 'EmailHandlingImprovements', Locked = true;

    /// <summary>
    /// Sets if the email feature is enabled in system or not by overwriting the output of IsEnabled function.
    /// </summary>
    /// <param name="IsEnabled">The value that will be returned by the IsEnabled function.</param>
    [Scope('OnPrem')]
    procedure SetEmailFeatureEnabled(IsEnabled: Boolean)
    var
        FeatureKey: Record "Feature Key";
    begin
        if FeatureKey.Get(EmailFeatureKeyTxt) then begin
            case FeatureKey.Enabled of
                FeatureKey.Enabled::"All Users":
                    if not IsEnabled then begin
                        FeatureKey.Enabled := FeatureKey.Enabled::None;
                        FeatureKey.Modify();
                    end;
                FeatureKey.Enabled::None:
                    if IsEnabled then begin
                        FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
                        FeatureKey.Modify();
                    end;
            end;
        end;
    end;
}

