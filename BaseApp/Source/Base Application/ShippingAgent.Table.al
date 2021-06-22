table 291 "Shipping Agent"
{
    Caption = 'Shipping Agent';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Shipping Agents";
    LookupPageID = "Shipping Agents";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Internet Address"; Text[250])
        {
            Caption = 'Internet Address';
            ExtendedDatatype = URL;
        }
        field(4; "Account No."; Text[30])
        {
            Caption = 'Account No.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    var
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        ShippingAgentServices.SetRange("Shipping Agent Code", Code);
        ShippingAgentServices.DeleteAll();

        CalendarManagement.DeleteCustomizedBaseCalendarData(CustomizedCalendarChange."Source Type"::"Shipping Agent", Code);
    end;

    trigger OnRename()
    var
        CRMSyncHelper: Codeunit "CRM Synch. Helper";
    begin
        CalendarManagement.RenameCustomizedBaseCalendarData(CustomizedCalendarChange."Source Type"::"Shipping Agent", Code, xRec.Code);
        CRMSyncHelper.UpdateCDSOptionMapping(xRec.RecordId(), RecordId());
    end;

    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CalendarManagement: Codeunit "Calendar Management";
}

