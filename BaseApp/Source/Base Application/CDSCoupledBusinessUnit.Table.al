table 7201 "CDS Coupled Business Unit"
{
    Access = Internal;
    Caption = 'Common Data Service Coupled Business Unit';
    DataPerCompany = false;

    fields
    {
        field(1; "Company Id"; Guid)
        {
            Caption = 'Company ID';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnValidate()
            var
                CDSCoupledBusinesUnit: Record "CDS Coupled Business Unit";
            begin
                CDSCoupledBusinesUnit.SetRange("Company Id", "Company Id");
                if CDSCoupledBusinesUnit.FindFirst() then
                    if SystemId <> CDSCoupledBusinesUnit.SystemId then begin
                        if not Confirm(CompanyAlreadyCoupledQst) then
                            Error('');
                        Session.LogMessage('0000DRI', CompanyAlreadyCoupledTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
            end;
        }
        field(2; "Business Unit Id"; Guid)
        {
            Caption = 'Business Unit ID';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnValidate()
            var
                CDSCoupledBusinesUnit: Record "CDS Coupled Business Unit";
            begin
                CDSCoupledBusinesUnit.SetRange("Business Unit Id", "Business Unit Id");
                if CDSCoupledBusinesUnit.FindFirst() then
                    if SystemId <> CDSCoupledBusinesUnit.SystemId then begin
                        if not Confirm(BusinessUnitAlreadyCoupledQst) then
                            Error('');
                        Session.LogMessage('0000DRH', BusinessUnitAlreadyCoupledTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
            end;
        }
    }

    keys
    {
        key(Key1; "Company Id")
        {
            Clustered = true;
        }
        key(Key2; "Business Unit Id")
        {
        }
    }

    var
        BusinessUnitAlreadyCoupledQst: Label 'The specified business unit in Common Data Service is coupled to another Business Central company.\\Do you want to continue anyway?';
        CompanyAlreadyCoupledQst: Label 'The specified Business Central company is coupled to another business unit in Common Data Service.\\Do you want to continue anyway?';
        BusinessUnitAlreadyCoupledTxt: Label 'The specified business unit in Common Data Service is coupled to another Business Central company.';
        CompanyAlreadyCoupledTxt: Label 'The specified Business Central company is coupled to another business unit in Common Data Service.';
        CategoryTok: Label 'AL Common Data Service Integration', Locked = true;
}
