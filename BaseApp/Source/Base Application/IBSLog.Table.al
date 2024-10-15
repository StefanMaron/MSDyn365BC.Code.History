table 2000010 "IBS Log"
{
    Caption = 'IBS Log';
    ObsoleteReason = 'Legacy ISABEL';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(21; "Process Status"; Option)
        {
            Caption = 'Process Status';
            Editable = false;
            OptionCaption = 'Created,Processed,Archived';
            OptionMembers = Created,Processed,Archived;
        }
        field(22; "Transaction Type"; Option)
        {
            Caption = 'Transaction Type';
            Editable = false;
            OptionCaption = 'Upload,Download,Report';
            OptionMembers = Upload,Download,"Report";
        }
        field(23; "Integration Type"; Option)
        {
            Caption = 'Integration Type';
            OptionCaption = 'Manual,Attended';
            OptionMembers = Manual,Attended;
        }
        field(24; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(25; "File Name"; Text[250])
        {
            Caption = 'File Name';
            Editable = false;
        }
        field(26; "File Type"; Option)
        {
            Caption = 'File Type';
            Editable = false;
            OptionCaption = 'National,International,Dom,SEPA,,,,,,,,,,Coda';
            OptionMembers = National,International,Dom,SEPA,,,,,,,,,,Coda;
        }
        field(27; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
            Editable = false;
        }
        field(28; "BAN/IBAN"; Text[30])
        {
            Caption = 'BAN/IBAN';
            Editable = false;
        }
        field(31; "Processed Date"; Date)
        {
            Caption = 'Processed Date';
            Editable = false;
        }
        field(32; "Processed Time"; Time)
        {
            Caption = 'Processed Time';
            Editable = false;
        }
        field(33; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(34; "Request ID"; Code[20])
        {
            Caption = 'Request ID';
            Editable = false;
        }
        field(40; "IBS User ID"; Code[50])
        {
            Caption = 'IBS User ID';
        }
        field(41; "IBS Contract ID"; Code[50])
        {
            Caption = 'IBS Contract ID';
        }
        field(42; "Upload Status"; Option)
        {
            Caption = 'Upload Status';
            OptionCaption = ' ,Conflicts Exist,Ready for Upload';
            OptionMembers = " ","Conflicts Exist","Ready for Upload";
        }
        field(45; "IBS Request ID"; Text[250])
        {
            Caption = 'IBS Request ID';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Upload Status")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldRef2: FieldRef;
    begin
        RecRef.GetTable(Rec);
        FieldRef := RecRef.Field(23);
        FieldRef2 := RecRef.Field(21);
        if not (("Integration Type" = "Integration Type"::Manual) or ("Process Status" = "Process Status"::Archived)) then
            Error(Text000, SelectStr("Integration Type"::Manual + 1, FieldRef.OptionCaption),
              SelectStr("Process Status"::Archived + 1, FieldRef2.OptionCaption));
    end;

    var
        Text000: Label 'Only IBS log entries with an integration type of %1 or a process status of %2 can be deleted.';

    [Scope('OnPrem')]
    procedure ResolveConflicts()
    var
        IBSAccountConflict: Record "IBS Account Conflict";
    begin
        IBSAccountConflict.SetRange("IBS Log Entry No.", "No.");
        if IBSAccountConflict.FindFirst then
            if PAGE.RunModal(0, IBSAccountConflict) = ACTION::LookupOK then begin
                "IBS User ID" := IBSAccountConflict."User ID";
                "IBS Contract ID" := IBSAccountConflict."Contract ID";
                "Upload Status" := "Upload Status"::"Ready for Upload";
                Modify;
                IBSAccountConflict.DeleteAll;
            end;
    end;
}

