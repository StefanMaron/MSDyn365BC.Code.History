table 1552 "User Callouts"
{
    Caption = 'User Callouts';
    DataPerCompany = false;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User SID';
            TableRelation = User."User Security ID";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; Enabled; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "User Security ID")
        {
            Clustered = true;
        }
    }

    internal procedure AreCalloutsEnabled(UserSecurityID: Guid): Boolean
    begin
        InitUserIfNecessary(Rec, UserSecurityID);
        exit(Rec.Enabled);
    end;

    internal procedure SwitchCalloutsEnabledValue(UserSecurityID: Guid): Boolean
    begin
        InitUserIfNecessary(Rec, UserSecurityID);

        if Rec.Enabled then
            Rec.Enabled := false
        else
            Rec.Enabled := true;
        Rec.Modify();

        exit(Rec.Enabled);
    end;

    // The record for a specific user is created as soon as that User 
    // try to access to this table for the first time
    internal procedure InitUserIfNecessary(var UserCallouts: Record "User Callouts"; UserSecurityID: Guid)
    begin
        if not UserCallouts.Get(UserSecurityID) then begin
            UserCallouts.AddNewUser(UserSecurityId);
            UserCallouts.Get(UserSecurityId);
        end;
    end;

    internal procedure AddNewUser(UserSecurityID: Guid)
    begin
        Rec."User Security ID" := UserSecurityID;
        Rec.Enabled := true; // default value
        Rec.Insert();
    end;
}