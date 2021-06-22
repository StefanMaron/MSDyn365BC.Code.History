table 1610 "Office Add-in"
{
    Caption = 'Office Add-in';
    DataPerCompany = false;

    fields
    {
        field(1; "Application ID"; Guid)
        {
            Caption = 'Application ID';
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; Version; Text[20])
        {
            Caption = 'Version';
        }
        field(6; "Manifest Codeunit"; Integer)
        {
            Caption = 'Manifest Codeunit';
        }
        field(10; "Deployment Date"; Date)
        {
            Caption = 'Deployment Date';
        }
        field(12; "Default Manifest"; BLOB)
        {
            Caption = 'Default Manifest';
        }
        field(13; Manifest; BLOB)
        {
            Caption = 'Manifest';
        }
        field(14; Breaking; Boolean)
        {
            Caption = 'Breaking';
        }
    }

    keys
    {
        key(Key1; "Application ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetAddins(): Boolean
    var
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        if IsEmpty() then
            AddinManifestManagement.CreateDefaultAddins(Rec);

        exit(FindSet);
    end;

    procedure GetDefaultManifestText() ManifestText: Text
    var
        ManifestInStream: InStream;
    begin
        CalcFields("Default Manifest");
        "Default Manifest".CreateInStream(ManifestInStream, TextEncoding::UTF8);
        ManifestInStream.Read(ManifestText);
    end;

    procedure SetDefaultManifestText(ManifestText: Text)
    var
        ManifestOutStream: OutStream;
    begin
        Clear("Default Manifest");
        "Default Manifest".CreateOutStream(ManifestOutStream, TextEncoding::UTF8);
        ManifestOutStream.WriteText(ManifestText);
    end;

    procedure IsAdminDeployed(): Boolean
    begin
        exit(Format("Deployment Date") <> '');
    end;

    [Scope('OnPrem')]
    procedure IsBreakingChange(UserVersion: Text) IsBreaking: Boolean
    var
        Components: DotNet Array;
        UserComponents: DotNet Array;
        Separator: DotNet String;
        TempString: DotNet String;
        i: Integer;
    begin
        Separator := '.';
        TempString := UserVersion;
        UserComponents := TempString.Split(Separator.ToCharArray);
        TempString := Version;
        Components := TempString.Split(Separator.ToCharArray);

        if (Components.Length() < 3) or (UserComponents.Length() < 3) then
            SendTraceTag('0000BOQ', OfficeManagement.GetOfficeAddinTelemetryCategory(), Verbosity::Error,
                StrSubstNo(VersionFormatMismatchTelemetryErr, UserVersion, Version), DataClassification::SystemMetadata);

        for i := 0 to 2 do
            IsBreaking := IsBreaking or (Format(UserComponents.GetValue(i)) <> Format(Components.GetValue(i)));
    end;

    var
        OfficeManagement: Codeunit "Office Management";
        VersionFormatMismatchTelemetryErr: Label 'The version numbers have an unexpected format. UserVersion: %1, Version: %2.', Locked = true;
}

