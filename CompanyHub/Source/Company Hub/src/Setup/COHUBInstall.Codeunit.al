codeunit 1160 "COHUB Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany();
    begin
        InstallPerCompany();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    begin
        InstallPerCompany();
    end;

    local procedure InstallPerCompany()
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);

        if AppInfo.DataVersion() <> Version.Create('0.0.0.0') then
            exit;

        // Version = 0.0.0.0 on first install.  Only create sample data on initial install.
        ApplyEvaluationClassificationsForPrivacy();
    end;


    local procedure ApplyEvaluationClassificationsForPrivacy()
    var
        Company: Record Company;
        COHUBCompanyKPI: Record "COHUB Company KPI";
        EnviromentCompanyEndpoint: Record "COHUB Company Endpoint";
        COHUBEnviroment: Record "COHUB Enviroment";
        COHUBUserTask: Record "COHUB User Task";
        COHUBGroupCompanySummary: Record "COHUB Group Company Summary";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        Company.Get(CompanyName());
        if not Company."Evaluation Company" then
            exit;

        DataClassificationMgt.SetTableFieldsToNormal(Database::"COHUB Company KPI");
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Company KPI", COHUBCompanyKPI.FieldNo("Company Display Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Company KPI", COHUBCompanyKPI.FieldNo("Company Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Company KPI", COHUBCompanyKPI.FieldNo("Assigned To"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Company KPI", COHUBCompanyKPI.FieldNo("Contact Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Company KPI", COHUBCompanyKPI.FieldNo("Name"));

        DataClassificationMgt.SetTableFieldsToNormal(Database::"COHUB Company Endpoint");
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Company Endpoint", EnviromentCompanyEndpoint.FieldNo("Company Display Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Company Endpoint", EnviromentCompanyEndpoint.FieldNo("Company Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Company Endpoint", EnviromentCompanyEndpoint.FieldNo("Assigned To"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Company Endpoint", EnviromentCompanyEndpoint.FieldNo("ODATA Company URL"));

        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Enviroment", COHUBEnviroment.FieldNo(Link));

        DataClassificationMgt.SetTableFieldsToNormal(Database::"COHUB User Task");
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB User Task", COHUBUserTask.FieldNo("Company Display Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB User Task", COHUBUserTask.FieldNo("Assigned To"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB User Task", COHUBUserTask.FieldNo("Company Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB User Task", COHUBUserTask.FieldNo("Created By"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB User Task", COHUBUserTask.FieldNo("User Task Group Assigned To"));

        DataClassificationMgt.SetTableFieldsToNormal(Database::"COHUB Group");

        DataClassificationMgt.SetTableFieldsToNormal(Database::"COHUB Group Company Summary");
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Group Company Summary", COHUBGroupCompanySummary.FieldNo("Enviroment Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Group Company Summary", COHUBGroupCompanySummary.FieldNo("Company Display Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Group Company Summary", COHUBGroupCompanySummary.FieldNo("Company Name"));
        DataClassificationMgt.SetFieldToPersonal(Database::"COHUB Group Company Summary", COHUBGroupCompanySummary.FieldNo("Assigned To"));
    end;
}