table 26569 "Statutory Report Setup"
{
    Caption = 'Statutory Report Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(4; "Report Data Nos"; Code[20])
        {
            Caption = 'Report Data Nos';
            TableRelation = "No. Series";
        }
        field(5; "Report Export Log Nos"; Code[20])
        {
            Caption = 'Report Export Log Nos';
            TableRelation = "No. Series";
        }
        field(6; "Group End Separator"; Text[10])
        {
            Caption = 'Group End Separator';
            ObsoleteReason = 'Obsolete functionality';
            ObsoleteState = Removed;
            ObsoleteTag = '19.0';
        }
        field(7; "Fragment End Separator"; Text[10])
        {
            Caption = 'Fragment End Separator';
            ObsoleteReason = 'Obsolete functionality';
            ObsoleteState = Removed;
            ObsoleteTag = '19.0';
        }
        field(8; "File End Separator"; Text[10])
        {
            Caption = 'File End Separator';
            ObsoleteReason = 'Obsolete functionality';
            ObsoleteState = Removed;
            ObsoleteTag = '19.0';
        }
        field(9; "Reports Templates Folder Name"; Text[250])
        {
            Caption = 'Reports Templates Folder Name';
            ObsoleteReason = 'Obsolete functionality';
            ObsoleteState = Removed;
            ObsoleteTag = '19.0';
        }
        field(10; "Excel Reports Folder Name"; Text[250])
        {
            Caption = 'Excel Reports Folder Name';
            ObsoleteReason = 'Obsolete functionality';
            ObsoleteState = Removed;
            ObsoleteTag = '19.0';
        }
        field(11; "Electronic Files Folder Name"; Text[250])
        {
            Caption = 'Electronic Files Folder Name';
            ObsoleteReason = 'Obsolete functionality';
            ObsoleteState = Removed;
            ObsoleteTag = '19.0';
        }
        field(12; "Use XML Schema Validation"; Boolean)
        {
            Caption = 'Use XML Schema Validation';
        }
        field(15; "Dflt. XML File Name Elem. Name"; Text[100])
        {
            Caption = 'Dflt. XML File Name Elem. Name';
        }
        field(16; "Setup Mode"; Boolean)
        {
            Caption = 'Setup Mode';
        }
        field(17; "Default Comp. Addr. Code"; Code[10])
        {
            Caption = 'Default Comp. Addr. Code';
            TableRelation = "Company Address".Code where("Address Type" = const(Legal));

            trigger OnLookup()
            begin
                Clear(CompanyAddressList);
                if CompanyAddress.Get("Default Comp. Addr. Code", "Default Comp. Addr. Lang. Code") then
                    CompanyAddressList.SetRecord(CompanyAddress);

                CompanyAddressList.LookupMode := true;
                if CompanyAddressList.RunModal() = ACTION::LookupOK then begin
                    CompanyAddressList.GetRecord(CompanyAddress);
                    "Default Comp. Addr. Code" := CompanyAddress.Code;
                    "Default Comp. Addr. Lang. Code" := CompanyAddress."Language Code";
                end;
            end;

            trigger OnValidate()
            begin
                if "Default Comp. Addr. Code" <> xRec."Default Comp. Addr. Code" then
                    "Default Comp. Addr. Lang. Code" := '';
            end;
        }
        field(18; "Default Comp. Addr. Lang. Code"; Code[10])
        {
            Caption = 'Default Comp. Addr. Lang. Code';
            TableRelation = "Company Address"."Language Code" where(Code = field("Default Comp. Addr. Code"),
                                                                     "Address Type" = const(Legal));
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CompanyAddress: Record "Company Address";
        CompanyAddressList: Page "Company Address List";
}

