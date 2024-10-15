page 11410 "Elec. Tax Declaration Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Elec. Tax Declaration Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Elec. Tax Declaration Setup";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Part of Fiscal Entity"; "Part of Fiscal Entity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the electronic declarations must be created for a subsidiary company that is part of a fiscal entity.';
                }
                field("VAT Contact Type"; "VAT Contact Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the contact person for the electronic VAT declaration is the tax payer or an agent.';

                    trigger OnValidate()
                    begin
                        VATContactTypeOnAfterValidate;
                    end;
                }
                field("ICP Contact Type"; "ICP Contact Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the contact person for the electronic ICP declaration is the tax payer or an agent.';

                    trigger OnValidate()
                    begin
                        ICPContactTypeOnAfterValidate;
                    end;
                }
                field("Tax Payer Contact Name"; "Tax Payer Contact Name")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Tax Payer Contact NameEnable";
                    ToolTip = 'Specifies the name of the contact person of the taxpayer.';
                }
                field("Tax Payer Contact Phone No."; "Tax Payer Contact Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = TaxPayerContactPhoneNoEnable;
                    ToolTip = 'Specifies the phone number of the contact person of the tax payer.';
                }
                field("Agent Contact ID"; "Agent Contact ID")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact IDEnable";
                    ToolTip = 'Specifies the BECON-number of the agent.';
                }
                field("Agent Contact Name"; "Agent Contact Name")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact NameEnable";
                    ToolTip = 'Specifies the name of the contact person of the agent.';
                }
                field("Agent Contact Address"; "Agent Contact Address")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact AddressEnable";
                    ToolTip = 'Specifies the address of the agent.';
                }
                field("Agent Contact Post Code"; "Agent Contact Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact Post CodeEnable";
                    ToolTip = 'Specifies the postal code of the agent.';
                }
                field("Agent Contact City"; "Agent Contact City")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact CityEnable";
                    ToolTip = 'Specifies the city where the agent is located.';
                }
                field("Agent Contact Phone No."; "Agent Contact Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = "Agent Contact Phone No.Enable";
                    ToolTip = 'Specifies the phone number of the contact person of the agent.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("VAT Declaration Nos."; "VAT Declaration Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign numbers to an electronic VAT declaration.';
                }
                field("ICP Declaration Nos."; "ICP Declaration Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign numbers to an electronic ICP declaration.';
                }
            }
            group(Digipoort)
            {
                Caption = 'Digipoort';
                field("Digipoort Client Cert. Name"; "Digipoort Client Cert. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the certificate, which was set when you requested the certificate.';
                    Visible = NOT IsSoftwareAsAService;
                }
                field("Digipoort Service Cert. Name"; "Digipoort Service Cert. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the service with which you are communicating.';
                    Visible = NOT IsSoftwareAsAService;
                }
                field("Digipoort Delivery URL"; "Digipoort Delivery URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL for the delivery service.';
                }
                field("Digipoort Status URL"; "Digipoort Status URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL for the status information service.';
                }
                field("Use Certificate Setup"; "Use Certificate Setup")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that certificates codes determined below must be considered to transfer data to the information service.';

                    trigger OnValidate()
                    begin
                        UpdateControls();
                    end;
                }
                field("Client Certificate Code"; "Client Certificate Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = UseCertificateSetup;
                    ToolTip = 'Specifies the client certificate code.';
                }
                field("Service Certificate Code"; "Service Certificate Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = UseCertificateSetup;
                    ToolTip = 'Specifies the service certificate code.';
                }
            }
            group(Endpoints)
            {
                Caption = 'Endpoints';
                field("Tax Decl. Schema Version"; "Tax Decl. Schema Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the schema version for the electronic tax declaration.';
                }
                field("Tax Decl. BD Data Endpoint"; "Tax Decl. BD Data Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BD data endpoint for the electronic tax declaration.';
                }
                field("Tax Decl. BD Tuples Endpoint"; "Tax Decl. BD Tuples Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BD tuples endpoint for the electronic tax declaration.';
                }
                field("Tax Decl. Schema Endpoint"; "Tax Decl. Schema Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the schema endpoint for the electronic tax declaration.';
                }
                field("ICP Decl. Schema Endpoint"; "ICP Decl. Schema Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the schema endpoint for the ICP declaration.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls;
        AfterGetCurrentRecord;
    end;

    trigger OnInit()
    begin
        "Agent Contact Phone No.Enable" := true;
        "Agent Contact CityEnable" := true;
        "Agent Contact Post CodeEnable" := true;
        "Agent Contact AddressEnable" := true;
        "Agent Contact NameEnable" := true;
        "Agent Contact IDEnable" := true;
        TaxPayerContactPhoneNoEnable := true;
        "Tax Payer Contact NameEnable" := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord;
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        IsSoftwareAsAService := EnvironmentInfo.IsSaaS;

        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        UpdateControls;
        OnActivateForm;
    end;

    var
        [InDataSet]
        "Tax Payer Contact NameEnable": Boolean;
        [InDataSet]
        TaxPayerContactPhoneNoEnable: Boolean;
        [InDataSet]
        "Agent Contact IDEnable": Boolean;
        [InDataSet]
        "Agent Contact NameEnable": Boolean;
        [InDataSet]
        "Agent Contact AddressEnable": Boolean;
        [InDataSet]
        "Agent Contact Post CodeEnable": Boolean;
        [InDataSet]
        "Agent Contact CityEnable": Boolean;
        [InDataSet]
        "Agent Contact Phone No.Enable": Boolean;
        IsSoftwareAsAService: Boolean;
        UseCertificateSetup: Boolean;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        "Tax Payer Contact NameEnable" := TaxpayerActive;
        TaxPayerContactPhoneNoEnable := TaxpayerActive;

        "Agent Contact IDEnable" := AgentActive;
        "Agent Contact NameEnable" := AgentActive;
        "Agent Contact AddressEnable" := AgentActive;
        "Agent Contact Post CodeEnable" := AgentActive;
        "Agent Contact CityEnable" := AgentActive;
        "Agent Contact Phone No.Enable" := AgentActive;
        UseCertificateSetup := "Use Certificate Setup";
    end;

    local procedure AgentActive(): Boolean
    begin
        exit(("VAT Contact Type" = "VAT Contact Type"::Agent) or
          ("ICP Contact Type" = "ICP Contact Type"::Agent));
    end;

    local procedure TaxpayerActive(): Boolean
    begin
        exit(("VAT Contact Type" = "VAT Contact Type"::"Tax Payer") or
          ("ICP Contact Type" = "ICP Contact Type"::"Tax Payer"));
    end;

    local procedure VATContactTypeOnAfterValidate()
    begin
        UpdateControls;
    end;

    local procedure ICPContactTypeOnAfterValidate()
    begin
        UpdateControls;
    end;

    local procedure AfterGetCurrentRecord()
    begin
    end;

    local procedure OnActivateForm()
    begin
        UpdateControls;
    end;
}

