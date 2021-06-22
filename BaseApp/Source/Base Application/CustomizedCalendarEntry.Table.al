table 7603 "Customized Calendar Entry"
{
    Caption = 'Customized Calendar Entry';

    fields
    {
        field(1; "Source Type"; Enum "Calendar Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(2; "Source Code"; Code[20])
        {
            Caption = 'Source Code';
            Editable = false;
        }
        field(3; "Additional Source Code"; Code[20])
        {
            Caption = 'Additional Source Code';
        }
        field(4; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            Editable = false;
            TableRelation = "Base Calendar";
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
            Editable = false;
        }
        field(6; Description; Text[30])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                UpdateExceptionEntry;
            end;
        }
        field(7; Nonworking; Boolean)
        {
            Caption = 'Nonworking';
            Editable = true;

            trigger OnValidate()
            begin
                UpdateExceptionEntry;
            end;
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source Code", "Additional Source Code", "Base Calendar Code", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure UpdateExceptionEntry()
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
    begin
        CustomizedCalendarChange.SetRange("Source Type", "Source Type");
        CustomizedCalendarChange.SetRange("Source Code", "Source Code");
        CustomizedCalendarChange.SetRange("Base Calendar Code", "Base Calendar Code");
        CustomizedCalendarChange.SetRange(Date, Date);
        CustomizedCalendarChange.DeleteAll();

        CustomizedCalendarChange.Init();
        CustomizedCalendarChange."Source Type" := "Source Type";
        CustomizedCalendarChange."Source Code" := "Source Code";
        CustomizedCalendarChange."Base Calendar Code" := "Base Calendar Code";
        CustomizedCalendarChange.Validate(Date, Date);
        CustomizedCalendarChange.Nonworking := Nonworking;
        CustomizedCalendarChange.Description := Description;
        CustomizedCalendarChange.Insert();

        OnAfterUpdateExceptionEntry(CustomizedCalendarChange, Rec);
    end;

    procedure GetCaption(): Text[250]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
        ServMgtSetup: Record "Service Mgt. Setup";
        ShippingAgentService: Record "Shipping Agent Services";
    begin
        case "Source Type" of
            "Source Type"::Company:
                exit(CompanyName);
            "Source Type"::Customer:
                if Customer.Get("Source Code") then
                    exit("Source Code" + ' ' + Customer.Name);
            "Source Type"::Vendor:
                if Vendor.Get("Source Code") then
                    exit("Source Code" + ' ' + Vendor.Name);
            "Source Type"::Location:
                if Location.Get("Source Code") then
                    exit("Source Code" + ' ' + Location.Name);
            "Source Type"::"Shipping Agent":
                if ShippingAgentService.Get("Source Code", "Additional Source Code") then
                    exit("Source Code" + ' ' + "Additional Source Code" + ' ' + ShippingAgentService.Description);
            "Source Type"::Service:
                if ServMgtSetup.Get then
                    exit("Source Code" + ' ' + ServMgtsetup.TableCaption);
        end;
    end;

    procedure CopyFromCustomizedCalendarChange(CustomizedCalendarChange: Record "Customized Calendar Change")
    begin
        "Source Type" := CustomizedCalendarChange."Source Type";
        "Source Code" := CustomizedCalendarChange."Source Code";
        "Additional Source Code" := CustomizedCalendarChange."Additional Source Code";
        "Base Calendar Code" := CustomizedCalendarChange."Base Calendar Code";
        Date := CustomizedCalendarChange.Date;
        Description := CustomizedCalendarChange.Description;
        Nonworking := CustomizedCalendarChange.Nonworking;
        OnAfterCopyFromCustomizedCalendarChange(CustomizedCalendarChange, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCustomizedCalendarChange(CustomizedCalendarChange: Record "Customized Calendar Change"; var CustomizedCalendarEntry: Record "Customized Calendar Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateExceptionEntry(var CustomizedCalendarChange: Record "Customized Calendar Change"; CustomizedCalendarEntry: Record "Customized Calendar Entry")
    begin
    end;
}

