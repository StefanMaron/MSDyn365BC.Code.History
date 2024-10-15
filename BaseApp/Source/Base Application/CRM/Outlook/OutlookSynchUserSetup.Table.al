namespace Microsoft.CRM.Outlook;

using System.Security.AccessControl;

table 5305 "Outlook Synch. User Setup"
{
    Caption = 'Outlook Synch. User Setup';
    DataClassification = CustomerContent;
    PasteIsValid = false;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'Legacy outlook sync functionality has been removed.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; "Synch. Entity Code"; Code[10])
        {
            Caption = 'Synch. Entity Code';
            NotBlank = true;
        }
        field(3; Description; Text[80])
        {
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; Condition; Text[250])
        {
            Caption = 'Condition';
            Editable = false;
        }
        field(5; "Synch. Direction"; Option)
        {
            Caption = 'Synch. Direction';
            OptionCaption = 'Bidirectional,Microsoft Dynamics NAV to Outlook,Outlook to Microsoft Dynamics NAV';
            OptionMembers = Bidirectional,"Microsoft Dynamics NAV to Outlook","Outlook to Microsoft Dynamics NAV";
        }
        field(6; "Last Synch. Time"; DateTime)
        {
            Caption = 'Last Synch. Time';
        }
        field(7; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "No. of Elements"; Integer)
        {
            Caption = 'No. of Elements';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User ID", "Synch. Entity Code")
        {
            Clustered = true;
        }
        key(Key2; "Record GUID")
        {
        }
    }

    fieldgroups
    {
    }
}
