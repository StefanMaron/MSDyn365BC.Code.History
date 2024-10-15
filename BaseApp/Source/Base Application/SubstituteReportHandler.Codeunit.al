#if not CLEAN20
codeunit 31427 "Substitute Report Handler"
{
    Access = Internal;
    Permissions = tabledata "NAV App Installed App" = r,
                  tabledata "Feature Data Update Status" = r;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnSubstituteGeneralReport(ReportId: Integer; var NewReportId: Integer)
    begin
        if IsTestingEnvironment() then
            exit;

#pragma warning disable AL0432
        if IsReplaceMulIntRateEnabled() then
            exit;

        case ReportId of
            Report::"Finance Charge Memo - Test":
                NewReportId := Report::"Finance Charge Memo - Test CZ";
            Report::"Finance Charge Memo":
                NewReportId := Report::"Finance Charge Memo CZ";
        end;
#pragma warning restore AL0432
    end;

    local procedure IsReplaceMulIntRateEnabled(): Boolean
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
#pragma warning disable AL0432
        ReplaceMulIntRateMgt: Codeunit "Replace Mul. Int. Rate Mgt.";
    begin
        if not FeatureDataUpdateStatus.Get(ReplaceMulIntRateMgt.GetFeatureKey(), CompanyName()) then
            exit(false);
        exit(ReplaceMulIntRateMgt.IsEnabled());
#pragma warning restore AL0432
    end;

    local procedure IsTestingEnvironment(): Boolean
    var
        NAVAppInstalledApp: Record "NAV App Installed App";
    begin
        exit(NAVAppInstalledApp.Get('fa3e2564-a39e-417f-9be6-c0dbe3d94069')); // application "Tests-ERM"
    end;
}
#endif