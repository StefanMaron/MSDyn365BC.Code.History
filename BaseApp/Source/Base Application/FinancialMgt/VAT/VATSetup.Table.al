table 189 "VAT Setup"
{
    Caption = 'VAT Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Enable Non-Deductible VAT"; Boolean)
        {
            Caption = 'Enable Non-Deductible VAT';

            trigger OnValidate()
            var
                ConfirmMgt: Codeunit "Confirm Management";
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                if "Non-Deductible VAT Is Enabled" then
                    Error(NotPossibleToDisableNonDedVATErr);
                if not ConfirmMgt.GetResponse(OneWayWarningMsg, false) then
                    error('');
                If GuiAllowed and "Enable Non-Deductible VAT" then
                    ShowEnableNonDeductibleVATNotification();
                "Non-Deductible VAT Is Enabled" := true;
                FeatureTelemetry.LogUsage('0000KI4', 'Non-Deductible VAT', 'The feature is enabled');
            end;
        }
        field(3; "Use For Item Cost"; Boolean)
        {
            Caption = 'Use For Item Cost';
        }
        field(4; "Use For Fixed Asset Cost"; Boolean)
        {
            Caption = 'Use For Fixed Asset Cost';
        }
        field(5; "Use For Job Cost"; Boolean)
        {
            Caption = 'Use For Job Cost';
        }
        field(10; "Show Non-Ded. VAT In Lines"; Boolean)
        {
            Caption = 'Show Non-Ded. VAT In Lines';
        }
        field(11; "Non-Deductible VAT Is Enabled"; Boolean)
        {
            Caption = 'Show Non-Ded. VAT In Lines';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        OneWayWarningMsg: Label 'After you enable this feature, you cannot turn it off again. This is because the feature may include changes to your data and may initiate an upgrade of some database tables as soon as you enable it.\\We strongly recommend that you first enable and test this feature on a sandbox environment that has a copy of production data before doing this on a production environment.\\For detailed information about the impact of enabling this feature, you should choose No and use the Learn more link.\\Are you sure you want to enable this feature?';
        NotPossibleToDisableNonDedVATErr: Label 'It is not possible to disable the Non-Deductible VAT';
        CompleteVATPostingSetupLbl: Label 'Choose Complete to open the VAT Posting Setup page where you can allow certain VAT Posting Setup for Non-Deductible VAT and set Non-Deductible VAT %';
        CompleteLbl: Label 'Complete';

    procedure ShowEnableNonDeductibleVATNotification()
    var
        EnableNonDedVATNotification: Notification;
    begin
        EnableNonDedVATNotification.Message := CompleteVATPostingSetupLbl;
        EnableNonDedVATNotification.Scope := NotificationScope::LocalScope;
        EnableNonDedVATNotification.AddAction(CompleteLbl, Codeunit::"Non-Ded. VAT Impl.", 'OpenVATPostingSetupPage');
        EnableNonDedVATNotification.Send();
    end;
}

