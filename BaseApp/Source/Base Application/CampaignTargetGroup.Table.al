table 7030 "Campaign Target Group"
{
    Caption = 'Campaign Target Group';

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Customer,Contact';
            OptionMembers = Customer,Contact;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(Customer)) Customer
            ELSE
            IF (Type = CONST(Contact)) Contact WHERE(Type = FILTER(Company));
        }
        field(3; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Campaign No.")
        {
            Clustered = true;
        }
        key(Key2; "Campaign No.")
        {
        }
        key(Key3; "No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure CopyTo(var TempCampaignTargetGroup: Record "Campaign Target Group" temporary) Found: Boolean;
    begin
        Found := FindSet();
        if Found then
            repeat
                TempCampaignTargetGroup := Rec;
                TempCampaignTargetGroup.Insert();
            until Next() = 0;
    end;
}

