codeunit 6305 "Set Power BI User Config"
{

    trigger OnRun()
    begin
    end;

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
        PowerBIUserConfiguration.SetFilter("User Security ID", UserSecurityId);
        PowerBIUserConfiguration.SetFilter("Profile ID", PowerBIServiceMgt.GetEnglishContext);
        if not PowerBIUserConfiguration.IsEmpty then begin
            PowerBIUserConfiguration.FindFirst;
            exit(PowerBIUserConfiguration."Report Visibility");
        end;
    end;

    procedure CreateOrReadUserConfigEntry(var PowerBIUserConfiguration: Record "Power BI User Configuration"; var LastOpenedReportID: Guid; Context: Text[50])
    begin
        // create a new Power BI User Configuration table entry or read one if it exist
        PowerBIUserConfiguration.Reset();
        PowerBIUserConfiguration.SetFilter("Page ID", Context);
        PowerBIUserConfiguration.SetFilter("User Security ID", UserSecurityId);
        PowerBIUserConfiguration.SetFilter("Profile ID", PowerBIServiceMgt.GetEnglishContext);
        if PowerBIUserConfiguration.IsEmpty then begin
            PowerBIUserConfiguration."Page ID" := Context;
            PowerBIUserConfiguration."User Security ID" := UserSecurityId;
            PowerBIUserConfiguration."Profile ID" := PowerBIServiceMgt.GetEnglishContext;
            PowerBIUserConfiguration."Report Visibility" := true;
            // SelectedReportId field is set to an empty GUID by default
            Clear(LastOpenedReportID);
            PowerBIUserConfiguration.Insert(true);
            Commit();
        end else begin
            PowerBIUserConfiguration.FindFirst;
            LastOpenedReportID := PowerBIUserConfiguration."Selected Report ID";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUserConfig(var PowerBIUserConfiguration: Record "Power BI User Configuration"; PageID: Text; var PowerBIVisible: Boolean; var IsHandled: Boolean)
    begin
    end;
}

