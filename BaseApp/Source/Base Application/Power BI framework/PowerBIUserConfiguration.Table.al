/// <summary>
/// Persists the first report to be displayed to a user, depending on the page and profile/role they are using.
/// </summary>
table 6304 "Power BI User Configuration"
{
    Caption = 'Power BI User Configuration';
    ReplicateData = false;

    fields
    {
        field(1; "Page ID"; Text[50])
        {
            Caption = 'Page ID';
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(3; "Profile ID"; Code[30])
        {
            Caption = 'Profile ID';
        }
        field(4; "Report Visibility"; Boolean)
        {
            Caption = 'Report Visibility';
            ObsoleteReason = 'The report part visibility is now handled by the standard personalization experience. Hide the page using Personalization instead of using this value.';
#if not CLEAN21
            ObsoleteState = Pending;
            ObsoleteTag = '21.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '24.0';
#endif
        }
        field(5; "Selected Report ID"; Guid)
        {
            Caption = 'Selected Report ID';
        }
    }

    keys
    {
        key(Key1; "Page ID", "User Security ID", "Profile ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CreateOrReadForCurrentUser(PageId: Text[50])
    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
#if not CLEAN21
        SetPowerBIUserConfig: Codeunit "Set Power BI User Config";
#endif
        IsHandled: Boolean;
    begin
        OnBeforeCreateOrReadUserConfigEntry(Rec, PageId, IsHandled);
        if IsHandled then
            exit;

        Reset();

        if not Get(PageId, UserSecurityId(), PowerBIServiceMgt.GetEnglishContext()) then begin
            "Page ID" := PageId;
            "User Security ID" := UserSecurityId();
            "Profile ID" := PowerBIServiceMgt.GetEnglishContext();
#if not CLEAN21
            "Report Visibility" := true;

            SetPowerBIUserConfig.OnCreateOrReadUserConfigEntryOnBeforePowerBIUserConfigurationInsert(Rec);
#endif
            OnCreateOrReadUserConfigEntryOnBeforePowerBIUserConfigurationInsert(Rec);
            Insert(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrReadUserConfigEntryOnBeforePowerBIUserConfigurationInsert(var PowerBIUserConfiguration: Record "Power BI User Configuration")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOrReadUserConfigEntry(var PowerBIUserConfiguration: Record "Power BI User Configuration"; PageID: Text; var IsHandled: Boolean)
    begin
    end;
}
