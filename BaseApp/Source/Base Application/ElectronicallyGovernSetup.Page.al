page 11761 "Electronically Govern. Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Electronic Communication Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Electronically Govern. Setup";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group("Proxy Setup")
            {
                Caption = 'Proxy Setup';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this group should not be used. (Obsolete::Removed in release 01.2021)';
                field("Proxy Server"; "Proxy Server")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies proxy server for electronically communication.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
                field("Proxy User"; "Proxy User")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies proxy user for electronically communication.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
                field(ProxyPassword; ProxyPassword)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Proxy Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies proxy password for electronically communication.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Communication using Proxy server will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';

                    trigger OnValidate()
                    begin
                        SavePassword(ProxyPassword);
                        if ProxyPassword <> '' then
                            CheckEncryption;
                    end;
                }
            }
            group("Payer Uncertainty")
            {
                Caption = 'Payer Uncertainty';
                field(UncertaintyPayerWebService; UncertaintyPayerWebService)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies web service for control uncertainty payers';
                }
                field("Public Bank Acc.Chck.Star.Date"; "Public Bank Acc.Chck.Star.Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the first date for checking public bank account of uncertainty payer.';
                }
                field("Public Bank Acc.Check Limit"; "Public Bank Acc.Check Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the limit of purchase document for checking public bank account of uncertainty payer.';
                }
                field("Unc.Payer Request Record Limit"; "Unc.Payer Request Record Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the record limit in one batch for checking uncertainty payer.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(EncryptionManagement)
            {
                ApplicationArea = Advanced;
                Caption = 'Encryption Management';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Data Encryption Management";
                RunPageMode = View;
                ToolTip = 'Enable or disable data encryption. Data encryption helps make sure that unauthorized users cannot read business data.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEncryptedField("Proxy Password Key", ProxyPassword);
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;

    var
        [Obsolete('The functionality of Communication using Proxy server will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021')]
        ProxyPassword: Text[50];
        [Obsolete('The functionality of Communication using Proxy server will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021')]
        CheckedEncryption: Boolean;
        [Obsolete('The functionality of Communication using Proxy server will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021')]
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';

    [Obsolete('The functionality of Communication using Proxy server will be removed and this function should not be used. (Obsolete::Removed in release 01.2021')]
    local procedure UpdateEncryptedField(InputGUID: Guid; var Text: Text[50])
    begin
        if IsNullGuid(InputGUID) then
            Text := ''
        else
            Text := '*************';
    end;

    [Obsolete('The functionality of Communication using Proxy server will be removed and this function should not be used. (Obsolete::Removed in release 01.2021')]
    local procedure CheckEncryption()
    begin
        if not CheckedEncryption and not EncryptionEnabled then begin
            CheckedEncryption := true;
            if not EncryptionEnabled then
                if Confirm(EncryptionIsNotActivatedQst) then
                    PAGE.Run(PAGE::"Data Encryption Management");
        end;
    end;
}

