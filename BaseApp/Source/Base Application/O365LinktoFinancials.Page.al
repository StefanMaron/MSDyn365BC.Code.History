page 2196 "O365 Link to Financials"
{
    Caption = 'O365 Link to Financials';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            label(TryOutLbl)
            {
                ApplicationArea = Invoicing;
                Caption = 'This company has been used in Microsoft Invoicing. It cannot be used in Dynamics 365 Business Central.';
                Editable = false;
                Style = StrongAccent;
                StyleExpr = TRUE;
                ToolTip = 'Specifies that this company cannot be used in Dynamics 365 Business Central.';
                Visible = ShowLabel;
            }
            field(LinkToFinancials; TryD365FinancialsLbl)
            {
                ApplicationArea = Invoicing;
                Editable = false;
                ShowCaption = false;
                Visible = ShowLabel;

                trigger OnDrillDown()
                begin
                    O365SetupMgmt.ChangeToEvaluationCompany;
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Initialize;
    end;

    var
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
        TryD365FinancialsLbl: Label 'Click here to switch to the evaluation company.';
        InvoicingCategoryLbl: Label 'AL Invoicing', Locked = true;
        InvoicingCompanyTelemetryTxt: Label 'Invoicing company message shown.', Locked = true;
        ShowLabel: Boolean;

    local procedure Initialize()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        IsFinApp: Boolean;
        IsSaas: Boolean;
        IsInvAppAreaSet: Boolean;
    begin
        IsFinApp := EnvironmentInfo.IsFinancials;
        IsSaas := EnvironmentInfo.IsSaaS;
        IsInvAppAreaSet := ApplicationAreaMgmt.IsInvoicingOnlyEnabled;

        ShowLabel := IsFinApp and IsSaas and IsInvAppAreaSet;

        if ShowLabel then
            SendTraceTag('0000CJJ', InvoicingCategoryLbl, Verbosity::Normal,
              InvoicingCompanyTelemetryTxt, DataClassification::SystemMetadata);

    end;
}

