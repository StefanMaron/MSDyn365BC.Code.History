#if not CLEAN21
codeunit 6305 "Set Power BI User Config"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit has been merged to table 6304 "Power BI User Configuration". Use the same functions in the record instead.';
    ObsoleteTag = '21.0';

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";

    procedure SetUserConfig(var PowerBIUserConfiguration: Record "Power BI User Configuration"; PageID: Text): Boolean
    var
        PowerBIVisible: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetUserConfig(PowerBIUserConfiguration, PageID, PowerBIVisible, IsHandled);
        if IsHandled then
            exit(PowerBIVisible);

        // load existing UserConfig entry to get PowerBI FactBox visibility
        // entry by itself is created on the FactBox page
        PowerBIUserConfiguration.Reset();
        PowerBIUserConfiguration.SetFilter("Page ID", PageID);
        PowerBIUserConfiguration.SetFilter("User Security ID", UserSecurityId());
        PowerBIUserConfiguration.SetFilter("Profile ID", PowerBIServiceMgt.GetEnglishContext());
        if not PowerBIUserConfiguration.IsEmpty() then begin
            PowerBIUserConfiguration.FindFirst();
            exit(PowerBIUserConfiguration."Report Visibility");
        end;
    end;

    procedure HasConfig(PageID: Text): Boolean
    var
        PowerBIUserConfiguration: Record "Power BI User Configuration";
    begin
        PowerBIUserConfiguration.Reset();
        PowerBIUserConfiguration.SetFilter("Page ID", PageID);
        PowerBIUserConfiguration.SetFilter("User Security ID", UserSecurityId());
        PowerBIUserConfiguration.SetFilter("Profile ID", PowerBIServiceMgt.GetEnglishContext());
        exit(not PowerBIUserConfiguration.IsEmpty());
    end;

    procedure CreateOrReadUserConfigEntry(var PowerBIUserConfiguration: Record "Power BI User Configuration"; Context: Text[50])
    begin
        // create a new Power BI User Configuration table entry or read one if it exist
        PowerBIUserConfiguration.Reset();

        if not PowerBIUserConfiguration.Get(Context, UserSecurityId(), PowerBIServiceMgt.GetEnglishContext()) then begin
            PowerBIUserConfiguration."Page ID" := Context;
            PowerBIUserConfiguration."User Security ID" := UserSecurityId();
            PowerBIUserConfiguration."Profile ID" := PowerBIServiceMgt.GetEnglishContext();
            PowerBIUserConfiguration."Report Visibility" := true;
            OnCreateOrReadUserConfigEntryOnBeforePowerBIUserConfigurationInsert(PowerBIUserConfiguration);
            PowerBIUserConfiguration.Insert(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUserConfig(var PowerBIUserConfiguration: Record "Power BI User Configuration"; PageID: Text; var PowerBIVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCreateOrReadUserConfigEntryOnBeforePowerBIUserConfigurationInsert(var PowerBIUserConfiguration: Record "Power BI User Configuration")
    begin
    end;
}
#endif
