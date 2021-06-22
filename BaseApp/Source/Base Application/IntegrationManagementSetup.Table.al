table 5515 "Integration Management Setup"
{
    Caption = 'Integration Management Setup';
    ObsoleteState = Pending;
    ObsoleteReason = 'The table will be removed with Integration Management. Refactor to use systemID, systemLastModifiedAt and other system fields.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;
        }
        field(2; "Table Caption"; Text[249])
        {
            Caption = 'Table Caption';
            Editable = false;
        }
        field(3; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(4; "Completed"; Boolean)
        {
            Caption = 'Completed';
            Editable = false;
        }
        field(5; "Last DateTime Modified"; DateTime)
        {
            Caption = 'Last DateTime Modified';
        }
        field(6; "Batch Size"; Integer)
        {
            Caption = 'Batch Size';
        }
    }

    keys
    {
        key(Key1; "Table ID")
        {
            Clustered = true;
        }
        key(Key2; "Completed", "Enabled")
        {
        }
    }

    var
        RecordIsNotIntegrationRecordErr: Label 'The table %1 is not enabled for integraiton', Comment = '%1 Table name';

    trigger OnInsert()
    begin
        SetDefaultValeus(Rec);
    end;

    local procedure SetDefaultValeus(var IntegrationManagementSetup: Record "Integration Management Setup")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        IntegrationManagement: Codeunit "Integration Management";
        IntegrationManagementSetupCodeunit: Codeunit "Integration Management Setup";
    begin
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::TableData, IntegrationManagementSetup."Table ID");

        if not IntegrationManagement.IsIntegrationRecord(AllObjWithCaption."Object ID") then
            Error(RecordIsNotIntegrationRecordErr, AllObjWithCaption."Object Caption");
        IntegrationManagementSetup."Table ID" := AllObjWithCaption."Object ID";
        IntegrationManagementSetup."Table Caption" := AllObjWithCaption."Object Caption";
        IntegrationManagementSetup."Batch Size" := IntegrationManagementSetupCodeunit.GetDefaultBatchSize();
    end;
}

