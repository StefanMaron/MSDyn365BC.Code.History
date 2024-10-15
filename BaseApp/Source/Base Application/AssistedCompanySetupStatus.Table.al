table 1802 "Assisted Company Setup Status"
{
    Caption = 'Assisted Company Setup Status';
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            begin
                OnEnabled("Company Name", Enabled);
            end;
        }
        field(3; "Package Imported"; Boolean)
        {
            Caption = 'Package Imported';
        }
        field(4; "Import Failed"; Boolean)
        {
            Caption = 'Import Failed';
        }
        field(5; "Company Setup Session ID"; Integer)
        {
            Caption = 'Company Setup Session ID';
        }
        field(6; "Task ID"; Guid)
        {
            Caption = 'Task ID';
        }
        field(7; "Server Instance ID"; Integer)
        {
            Caption = 'Server Instance ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Company Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN19
    [Obsolete('Replaced with GetCompanySetupStatusValue', '19.0')]
    procedure GetCompanySetupStatus(Name: Text[30]) SetupStatus: Integer
    begin
        SetupStatus := GetCompanySetupStatusValue(Name).AsInteger();
    end;
#endif

    procedure GetCompanySetupStatusValue(Name: Text[30]) SetupStatus: Enum "Company Setup Status"
    begin
        if "Company Name" <> Name then
            if not Get(Name) then
                exit(Enum::"Company Setup Status"::" ");
        OnGetCompanySetupStatusValue("Company Name", SetupStatus);
    end;

    procedure DrillDownSetupStatus(Name: Text[30])
    begin
        if Get(Name) then
            OnSetupStatusDrillDown("Company Name");
    end;

    procedure SetEnabled(CompanyName: Text[30]; Enable: Boolean; ResetState: Boolean)
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        if not AssistedCompanySetupStatus.Get(CompanyName) then begin
            AssistedCompanySetupStatus.Init();
            AssistedCompanySetupStatus.Validate("Company Name", CompanyName);
            AssistedCompanySetupStatus.Validate(Enabled, Enable);
            AssistedCompanySetupStatus.Insert();
        end else begin
            AssistedCompanySetupStatus.Validate(Enabled, Enable);
            if ResetState then begin
                AssistedCompanySetupStatus."Package Imported" := false;
                AssistedCompanySetupStatus."Import Failed" := false;
            end;
            AssistedCompanySetupStatus.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnabled(SetupCompanyName: Text[30]; AssistedSetupEnabled: Boolean)
    begin
    end;

#if not CLEAN19
    [IntegrationEvent(false, false)]
    [Obsolete('Replaced with OnGetCompanySetupStatusValue', '19.0')]
    internal procedure OnGetCompanySetupStatus(Name: Text[30]; var SetupStatus: Integer)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetCompanySetupStatusValue(Name: Text[30]; var SetupStatus: Enum "Company Setup Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupStatusDrillDown(Name: Text[30])
    begin
    end;

    procedure CopySaaSCompanySetupStatus(CompanyNameFrom: Text[30]; CompanyNameTo: Text[30])
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        if AssistedCompanySetupStatus.GetCompanySetupStatusValue(CompanyNameFrom) = Enum::"Company Setup Status"::Completed then begin
            AssistedCompanySetupStatus.Init();
            AssistedCompanySetupStatus."Company Name" := CompanyNameTo;
            if AssistedCompanySetupStatus.Insert() then;
        end;
    end;
}

