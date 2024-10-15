namespace Microsoft.Foundation.Task;

using System.Security.AccessControl;

table 1176 "User Task Group Member"
{
    Caption = 'User Task Group Member';
    DataCaptionFields = "User Task Group Code";
    ReplicateData = false;

    fields
    {
        field(1; "User Task Group Code"; Code[20])
        {
            Caption = 'User Task Group Code';
            DataClassification = CustomerContent;
            TableRelation = "User Task Group".Code;
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Security ID" where("License Type" = const("Full User"));
        }
        field(3; "User Name"; Code[50])
        {
            CalcFormula = Lookup(User."User Name" where("User Security ID" = field("User Security ID"),
                                                         "License Type" = const("Full User")));
            Caption = 'User Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User Task Group Code", "User Security ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

