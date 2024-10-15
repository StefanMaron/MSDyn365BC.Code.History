namespace System.Security.User;

using System.Security.AccessControl;

table 1552 "User Callouts"
{
    Caption = 'User Callouts';
    DataPerCompany = false;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Use "User Settings" instead.';
    DataClassification = CustomerContent;

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
}