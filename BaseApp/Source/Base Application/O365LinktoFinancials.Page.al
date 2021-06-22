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
                Caption = 'Thanks for choosing to explore Dynamics 365 Business Central!';
                Editable = false;
                Style = StrongAccent;
                StyleExpr = TRUE;
                ToolTip = 'Specifies thanks for choosing to explore Dynamics 365 Business Central!';
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
        TryD365FinancialsLbl: Label 'Click here to try out the evaluation company in Dynamics 365 Business Central.';
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
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
    end;
}

