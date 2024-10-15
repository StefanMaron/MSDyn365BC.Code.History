table 12205 "Fattura Setup"
{
    Caption = 'Fattura Setup';

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            Caption = 'Primary Key';
        }
        field(2; "Self-Billing VAT Bus. Group"; Code[20])
        {
            Caption = 'Self-Billing VAT Bus. Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(3; "Company PA Code"; Code[7])
        {
            Caption = 'Company PA Code';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        MissingFatturaSetupQst: Label 'You must enter information on the Fattura Setup page before you can use the Fattura Electronic Document functionality.\\Do you want to open the page now?';
        MissingFatturaSetupErr: Label 'Required setup information is missing on the Fattura Setup page.';

    procedure VerifyAndSetData()
    var
        FatturaSetupPage: Page "Fattura Setup";
    begin
        if Get() and IsDataAvailable() then
            exit;

        if Confirm(MissingFatturaSetupQst) then begin
            FatturaSetupPage.SetRecord(Rec);
            FatturaSetupPage.Editable(true);
            if FatturaSetupPage.RunModal() = ACTION::OK then
                FatturaSetupPage.GetRecord(Rec);
            if not IsDataAvailable() then
                Error(MissingFatturaSetupErr);
        end else
            Error(MissingFatturaSetupErr);
    end;

    local procedure IsDataAvailable(): Boolean
    begin
        exit(("Self-Billing VAT Bus. Group" <> '') and ("Company PA Code" <> ''));
    end;
}

