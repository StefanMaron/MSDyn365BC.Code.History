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
            begin
                Validate();
            end;
        }
        field(2; "Business Unit Id"; Guid)
        {
            Caption = 'Business Unit ID';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnValidate()
            begin
                Validate();
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
        BusinessUnitAlreadyCoupledErr: Label 'The coupling Common Data Service Business Unit is coupled to another BC Company.';
        CompanyAlreadyCoupledErr: Label 'The coupling BC Company is coupled to another Common Data Service Business Unit.';

    local procedure Validate()
    var
        CDSCoupledBusinesUnit: Record "CDS Coupled Business Unit";
    begin
        CDSCoupledBusinesUnit.SetRange("Business Unit Id", "Business Unit Id");
        if CDSCoupledBusinesUnit.FindFirst() then
            if SystemId <> CDSCoupledBusinesUnit.SystemId then
                Error(BusinessUnitAlreadyCoupledErr);

        CDSCoupledBusinesUnit.SetRange("Company Id", "Company Id");
        if CDSCoupledBusinesUnit.FindFirst() then
            if SystemId <> CDSCoupledBusinesUnit.SystemId then
                Error(CompanyAlreadyCoupledErr);
    end;
}
