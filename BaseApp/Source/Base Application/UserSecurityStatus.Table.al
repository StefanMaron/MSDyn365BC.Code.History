table 9062 "User Security Status"
{
    Caption = 'User Security Status';
    DataPerCompany = false;
    LookupPageID = "User Security Status List";
    ReplicateData = false;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            TableRelation = User."User Security ID";
        }
        field(2; "User Name"; Code[50])
        {
            CalcFormula = Lookup (User."User Name" WHERE("User Security ID" = FIELD("User Security ID")));
            Caption = 'User Name';
            FieldClass = FlowField;
        }
        field(3; "Full Name"; Text[80])
        {
            CalcFormula = Lookup (User."Full Name" WHERE("User Security ID" = FIELD("User Security ID")));
            Caption = 'Full Name';
            FieldClass = FlowField;
        }
        field(13; Reviewed; Boolean)
        {
            Caption = 'Reviewed';
        }
        field(14; "Belongs To Subscription Plan"; Boolean)
        {
            CalcFormula = Exist ("User Plan" WHERE("User Security ID" = FIELD("User Security ID")));
            Caption = 'Belongs To Subscription Plan';
            FieldClass = FlowField;
            ObsoleteState = Removed;
            ObsoleteReason = 'Removed because it uses the table "User Plan" (internal table). The logic has been moved to the page where the value is used';
            ObsoleteTag = '15.0';
        }
        field(15; "Belongs to User Group"; Boolean)
        {
            CalcFormula = Exist ("User Group Member" WHERE("User Security ID" = FIELD("User Security ID")));
            Caption = 'Belongs to User Group';
            FieldClass = FlowField;
        }
        field(20; "Users - To review"; Integer)
        {
            CalcFormula = Count ("User Security Status" WHERE(Reviewed = CONST(false),
                                                              "User Security ID" = FILTER(<> '{00000000-0000-0000-0000-000000000000}')));
            Caption = 'Users - To review';
            FieldClass = FlowField;
        }
        field(21; "Users - Without Subscriptions"; Integer)
        { 
            Caption = 'Users - Without Subscriptions';
            FieldClass = FlowField;
            ObsoleteState = Removed; 
            ObsoleteReason = 'Removed because it refers to the field "Belongs To Subscription Plan" (marked as obsolete). The logic has been moved to the page where the value is used';
            ObsoleteTag = '15.0';
        }
        field(22; "Users - Not Group Members"; Integer)
        {
            CalcFormula = Count ("User Security Status" WHERE("Belongs to User Group" = CONST(false),
                                                              "User Security ID" = FILTER(<> '{00000000-0000-0000-0000-000000000000}')));
            Caption = 'Users - Not Group Members';
            FieldClass = FlowField;
        }
        field(25; "CDS Integration Errors"; Integer)
        {
            CalcFormula = Count ("Integration Synch. Job Errors");
            Caption = 'Common Data Service Integration Errors';
            FieldClass = FlowField;
        }
        field(26; "Coupled Data Synch Errors"; Integer)
        {
            CalcFormula = Count ("CRM Integration Record" WHERE(Skipped = CONST(true)));
            Caption = 'Coupled Data Synch Errors';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User Security ID")
        {
            Clustered = true;
        }
        key(Key2; Reviewed)
        {
        }
    }

    fieldgroups
    {
    }

    var
        UserNotReviewedTxt: Label 'User %1: not reviewed.', Comment = '%1 = user name';
        UserReviewedTxt: Label 'User %1: reviewed.', Comment = '%1: User name';
        SecurityActivityTok: Label 'User review';
        SecurityContextTok: Label 'Security administration';

    procedure KeepOnlyEnabledUsers()
    var
        User: Record User;
        UserSecurityStatus: Record "User Security Status";
    begin
        User.SetRange(State, User.State::Disabled);
        if not User.FindSet then
            exit;
        repeat
            if UserSecurityStatus.Get(User."User Security ID") then
                UserSecurityStatus.Delete();
        until User.Next = 0;
    end;

    procedure LoadUsers()
    var
        User: Record User;
        UserSecurityStatus: Record "User Security Status";
        EnvironmentInfo: Codeunit "Environment Information";
        AzureADPlan: Codeunit "Azure AD Plan";
        IsSaaS: Boolean;
    begin
        User.SetRange(State, User.State::Enabled);
        HideExternalUsers(User);
        if not User.FindSet then
            exit;

        IsSaaS := EnvironmentInfo.IsSaaS;
        repeat
            if UserSecurityStatus.Get(User."User Security ID") then begin
                if not AzureADPlan.DoesUserHavePlans("User Security ID") and IsSaaS then begin
                    UserSecurityStatus.Reviewed := false;
                    UserSecurityStatus.Modify(true);
                end;
            end else begin
                UserSecurityStatus.Init();
                UserSecurityStatus."User Security ID" := User."User Security ID";
                UserSecurityStatus.Reviewed := false;
                UserSecurityStatus.Insert();
            end;
        until User.Next = 0;
    end;

    procedure LogUserReviewActivity()
    var
        ActivityLog: Record "Activity Log";
        ActivityMessage: Text[250];
    begin
        CalcFields("User Name");
        if Reviewed then
            ActivityMessage := StrSubstNo(UserReviewedTxt, "User Name")
        else
            ActivityMessage := StrSubstNo(UserNotReviewedTxt, "User Name");
        ActivityLog.LogActivity(RecordId, ActivityLog.Status::Success, SecurityContextTok, SecurityActivityTok, ActivityMessage);
    end;

    local procedure HideExternalUsers(var User: Record User)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS then
            User.SetFilter("License Type", '<>%1', User."License Type"::"External User");
    end;
}

