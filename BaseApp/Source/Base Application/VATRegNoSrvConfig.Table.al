table 248 "VAT Reg. No. Srv Config"
{
    Caption = 'VAT Reg. No. Srv Config';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(3; "Service Endpoint"; Text[250])
        {
            Caption = 'Service Endpoint';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if not IsEmpty then
            Error(CannotInsertMultipleSettingsErr);
    end;

    var
        VATRegNoVIESSettingIsNotEnabledErr: Label 'VAT Reg. No. Validation Setup is not enabled.';
        CannotInsertMultipleSettingsErr: Label 'You cannot insert multiple settings.';

    procedure VATRegNoSrvIsEnabled(): Boolean
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.SetRange(Enabled, true);
        exit(VATRegNoSrvConfig.FindFirst and VATRegNoSrvConfig.Enabled);
    end;

    procedure GetVATRegNoURL(): Text
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.SetRange(Enabled, true);
        if not VATRegNoSrvConfig.FindFirst then
            Error(VATRegNoVIESSettingIsNotEnabledErr);

        VATRegNoSrvConfig.TestField("Service Endpoint");

        exit(VATRegNoSrvConfig."Service Endpoint");
    end;
}

