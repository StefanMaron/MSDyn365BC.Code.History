table 443 "IC Setup"
{
    Caption = 'IC Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
#if not CLEAN20
            trigger OnValidate()
            begin
                UpdateCompanyInfo();
            end;
#endif
        }
        field(3; "IC Inbox Type"; Option)
        {
            Caption = 'IC Inbox Type';
            InitValue = Database;
            OptionCaption = 'File Location,Database';
            OptionMembers = "File Location",Database;

            trigger OnValidate()
            begin
                if "IC Inbox Type" = "IC Inbox Type"::Database then
                    "IC Inbox Details" := '';
#if not CLEAN20
                UpdateCompanyInfo();
#endif
            end;
        }
        field(4; "IC Inbox Details"; Text[250])
        {
            Caption = 'IC Inbox Details';
#if not CLEAN20
            trigger OnValidate()
            begin
                UpdateCompanyInfo();
            end;
#endif
        }
        field(5; "Auto. Send Transactions"; Boolean)
        {
            Caption = 'Auto. Send Transactions';
#if not CLEAN20
            trigger OnValidate()
            begin
                UpdateCompanyInfo();
            end;
#endif
        }
        field(6; "Default IC Gen. Jnl. Template"; Code[10])
        {
            Caption = 'Default IC General Journal Template';
            TableRelation = "Gen. Journal Template";
        }
        field(7; "Default IC Gen. Jnl. Batch"; Code[10])
        {
            Caption = 'Default IC General Journal Batch';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Default IC Gen. Jnl. Template"));
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

#if not CLEAN20
    local procedure UpdateCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
    begin
        if not CompanyInfo.Get() then
            exit;

        if Rec."IC Partner Code" <> xRec."IC Partner Code" then
            CompanyInfo."IC Partner Code" := Rec."IC Partner Code";
        if Rec."IC Inbox Type" <> xRec."IC Inbox Type" then
            CompanyInfo."IC Inbox Type" := Rec."IC Inbox Type";
        if Rec."IC Inbox Details" <> xRec."IC Inbox Details" then
            CompanyInfo."IC Inbox Details" := Rec."IC Inbox Details";
        if Rec."Auto. Send Transactions" <> xRec."Auto. Send Transactions" then
            CompanyInfo."Auto. Send Transactions" := Rec."Auto. Send Transactions";
        CompanyInfo.Modify();
    end;
#endif
}