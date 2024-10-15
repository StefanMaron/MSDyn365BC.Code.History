table 4009 "Migration Table Mapping"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; "App ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Description = 'Specifies the App ID to which the mapped table belongs.';
            TableRelation = "Published Application".ID;

            trigger OnValidate()
            var
                PublishedApp: Record "Published Application";
            begin
                PublishedApp.SetRange(ID, "App ID");
                PublishedApp.FindFirst();

                if PublisherDenied(PublishedApp.Publisher) then
                    Error(InvalidExtensionPublisherErr);

                Clear("Table Name");
                Clear("Source Table Name");
                CalcFields("Extension Package ID");
                CalcFields("Extension Name");
            end;
        }

        field(2; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Description = 'Specifies the ID of the table to map.';
            NotBlank = true;

            trigger OnValidate()
            var
                TableMetadata: Record "Table Metadata";
            begin
                TableMetadata.Get("Table ID");
                "Table Name" := TableMetadata.Name;
                "Source Table Name" := TableMetadata.Name;
                Validate("Data Per Company", TableMetadata.DataPerCompany);
            end;
        }

        field(3; "Table Name"; Text[30])
        {
            DataClassification = SystemMetadata;
            Description = 'Specifies the name of the table to map.';
            NotBlank = true;

            trigger OnValidate()
            var
                ApplicationObjectMetadata: Record "Application Object Metadata";
            begin
                ApplicationObjectMetadata.SetRange("Package ID", "Extension Package ID");
                ApplicationObjectMetadata.SetRange("Object Type", ApplicationObjectMetadata."Object Type"::Table);
                ApplicationObjectMetadata.SetFilter("Object Name", StrSubstNo('@%1*', "Table Name"));
                if ApplicationObjectMetadata.FindFirst() then
                    Validate("Table ID", ApplicationObjectMetadata."Object ID")
                else
                    Error(InvalidTableNameErr);
            end;
        }

        field(4; "Source Table Name"; Text[128])
        {
            DataClassification = SystemMetadata;
            Description = 'Specifies the name of the source table in the mapping.';
            NotBlank = true;
        }

        field(5; "Data Per Company"; Boolean)
        {
            DataClassification = SystemMetadata;
            Description = 'Specifies whether the data from the table is per company.';
        }

        field(6; Locked; Boolean)
        {
            DataClassification = SystemMetadata;
            InitValue = false;
            Description = 'Specifies whether to prevent users from modifying the table mapping record.';
        }

        field(8; "Extension Name"; Text[250])
        {
            FieldClass = FlowField;
            CalcFormula = lookup ("Published Application".Name where(ID = field("App ID")));
        }

        field(9; "Extension Package ID"; Guid)
        {
            FieldClass = FlowField;
            CalcFormula = lookup ("Published Application"."Package ID" where(ID = field("App ID")));
        }
    }

    keys
    {
        key(PK; "App ID", "Table ID")
        {
            Clustered = true;
        }
    }

    var
        InvalidExtensionPublisherErr: Label 'Extensions from the specified Publisher are not enabled for custom table mapping.';
        InvalidTableNameErr: Label 'This table does not exist in the specified extension.';
        InvalidPublisherTxt: Label 'Microsoft', Locked = true;

    local procedure PublisherDenied(ExtensionPublisher: Text): Boolean
    var
        InvalidPublishers: Text;
    begin
        InvalidPublishers := InvalidPublisherTxt;
        exit(InvalidPublishers.Split(',').Contains(ExtensionPublisher));
    end;

    procedure InvalidExtensionPublishers(): Text
    begin
        exit(InvalidPublisherTxt);
    end;
}