page 5129 "Update Opportunity"
{
    Caption = 'Update Opportunity';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Opportunity Entry";

    layout
    {
        area(content)
        {
            field("Action type"; "Action Type")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies options that you can take when you reenter an opportunity to update it in the Update Opportunity window. Certain options are not available, depending on what stage you are in for your opportunity. For example, if you are in stage 1, you cannot select the Previous option.';
                ValuesAllowed = First, Next, Previous, Skip, Jump, Update;

                trigger OnValidate()
                begin
                    if "Action Type" = "Action Type"::Update then
                        UpdateActionTypeOnValidate;
                    if "Action Type" = "Action Type"::Jump then
                        JumpActionTypeOnValidate;
                    if "Action Type" = "Action Type"::Skip then
                        SkipActionTypeOnValidate;
                    if "Action Type" = "Action Type"::Previous then
                        PreviousActionTypeOnValidate;
                    if "Action Type" = "Action Type"::Next then
                        NextActionTypeOnValidate;
                    if "Action Type" = "Action Type"::First then
                        FirstActionTypeOnValidate;

                    WizardActionTypeValidate2;
                    UpdateCntrls;
                end;
            }
            field("Sales Cycle Stage"; "Sales Cycle Stage")
            {
                ApplicationArea = RelationshipMgmt;
                CaptionClass = Format("Sales Cycle Stage Description");
                Editable = SalesCycleStageEditable;
                ToolTip = 'Specifies the sales cycle stage currently of the opportunity.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    LookupSalesCycleStage;
                    ValidateSalesCycleStage;
                end;

                trigger OnValidate()
                begin
                    WizardSalesCycleStageValidate2;
                    SalesCycleStageOnAfterValidate;
                end;
            }
            field("Date of Change"; "Date of Change")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the date this opportunity entry was last changed.';
            }
            field("Estimated Value (LCY)"; "Estimated Value (LCY)")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Estimated sales value (LCY)';
                ToolTip = 'Specifies the estimated value of the opportunity entry.';
            }
            field("Chances of Success %"; "Chances of Success %")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Chances of Success (%)';
                ToolTip = 'Specifies the chances of success of the opportunity entry.';
            }
            field("Estimated Close Date"; "Estimated Close Date")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Estimated Closing Date';
                ToolTip = 'Specifies the estimated date when the opportunity entry will be closed.';
            }
            field("Cancel Old To Do"; "Cancel Old To Do")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Cancel Existing Open Tasks';
                Enabled = CancelOldTaskEnable;
                ToolTip = 'Specifies a task is to be cancelled from the opportunity.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Finish';
                Image = Approve;
                InFooterBar = true;
                Promoted = true;
                ToolTip = 'Finish updating the opportunity.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    FinishPage;
                    CurrPage.Close;
                end;
            }
            action(SalesQuote)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Sales Quote';
                Enabled = SalesQuoteEnable;
                Image = Quote;
                InFooterBar = true;
                Promoted = true;
                ToolTip = 'Create a sales quote based on the opportunity.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if Opp.Get("Opportunity No.") then begin
                        Opp.ShowQuote;
                        if SalesHeader.Get(SalesHeader."Document Type"::Quote, Opp."Sales Document No.") then begin
                            "Estimated Value (LCY)" := GetSalesDocValue(SalesHeader);
                            CurrPage.Update;
                        end;
                    end;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        CancelOldTaskEnable := true;
        SalesQuoteEnable := true;
        OptionSixEnable := true;
        OptionFiveEnable := true;
        OptionFourEnable := true;
        OptionThreeEnable := true;
        OptionTwoEnable := true;
        OptionOneEnable := true;
        SalesCycleStageEditable := true;
    end;

    trigger OnOpenPage()
    begin
        IsOnMobile := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone;
        CreateStageList;
        UpdateEditable;
        if Opp.Get("Opportunity No.") then
            if Opp."Sales Document No." <> '' then
                SalesQuoteEnable := true
            else
                SalesQuoteEnable := false;

        UpdateCntrls;
        UpdateEstimatedValues;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            FinishPage;
    end;

    var
        Text000: Label 'untitled';
        Cont: Record Contact;
        SalesCycleStage: Record "Sales Cycle Stage";
        Opp: Record Opportunity;
        ClientTypeManagement: Codeunit "Client Type Management";
        [InDataSet]
        SalesCycleStageEditable: Boolean;
        [InDataSet]
        OptionOneEnable: Boolean;
        [InDataSet]
        OptionTwoEnable: Boolean;
        [InDataSet]
        OptionThreeEnable: Boolean;
        [InDataSet]
        OptionFiveEnable: Boolean;
        [InDataSet]
        OptionFourEnable: Boolean;
        [InDataSet]
        OptionSixEnable: Boolean;
        [InDataSet]
        SalesQuoteEnable: Boolean;
        [InDataSet]
        CancelOldTaskEnable: Boolean;
        Text666: Label '%1 is not a valid selection.';
        IsOnMobile: Boolean;

    procedure Caption(): Text
    var
        CaptionStr: Text;
    begin
        if Cont.Get("Contact Company No.") then
            CaptionStr := CopyStr(Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if Cont.Get("Contact No.") then
            CaptionStr := CopyStr(CaptionStr + ' ' + Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text000;

        exit(CaptionStr);
    end;

    local procedure UpdateEditable()
    begin
        OptionOneEnable := NoOfSalesCyclesFirst > 0;
        OptionTwoEnable := NoOfSalesCyclesNext > 0;
        OptionThreeEnable := NoOfSalesCyclesPrev > 0;
        OptionFourEnable := NoOfSalesCyclesSkip > 1;
        OptionFiveEnable := NoOfSalesCyclesUpdate > 0;
        OptionSixEnable := NoOfSalesCyclesJump > 1;
    end;

    local procedure UpdateCntrls()
    var
        Task: Record "To-do";
    begin
        case "Action Type" of
            "Action Type"::First:
                begin
                    SalesCycleStageEditable := false;
                    CancelOldTaskEnable := false;
                end;
            "Action Type"::Next:
                begin
                    SalesCycleStageEditable := false;
                    CancelOldTaskEnable := true;
                end;
            "Action Type"::Previous:
                begin
                    SalesCycleStageEditable := false;
                    CancelOldTaskEnable := true;
                end;
            "Action Type"::Skip:
                begin
                    SalesCycleStageEditable := true;
                    CancelOldTaskEnable := true;
                end;
            "Action Type"::Update:
                begin
                    SalesCycleStageEditable := false;
                    CancelOldTaskEnable := false;
                end;
            "Action Type"::Jump:
                begin
                    SalesCycleStageEditable := true;
                    CancelOldTaskEnable := true;
                end;
        end;
        Task.Reset();
        Task.SetCurrentKey("Opportunity No.");
        Task.SetRange("Opportunity No.", "Opportunity No.");
        if Task.FindFirst then
            CancelOldTaskEnable := true;
        Modify;
    end;

    local procedure SalesCycleStageOnAfterValidate()
    begin
        if SalesCycleStage.Get("Sales Cycle Code", "Sales Cycle Stage") then
            "Sales Cycle Stage Description" := SalesCycleStage.Description;
    end;

    local procedure FirstActionTypeOnValidate()
    begin
        if not OptionOneEnable then
            Error(Text666, "Action Type");
    end;

    local procedure NextActionTypeOnValidate()
    begin
        if not OptionTwoEnable then
            Error(Text666, "Action Type");
    end;

    local procedure PreviousActionTypeOnValidate()
    begin
        if not OptionThreeEnable then
            Error(Text666, "Action Type");
    end;

    local procedure SkipActionTypeOnValidate()
    begin
        if not OptionFourEnable then
            Error(Text666, "Action Type");
    end;

    local procedure JumpActionTypeOnValidate()
    begin
        if not OptionSixEnable then
            Error(Text666, "Action Type");
    end;

    local procedure UpdateActionTypeOnValidate()
    begin
        if not OptionFiveEnable then
            Error(Text666, "Action Type");
    end;

    local procedure FinishPage()
    begin
        CheckStatus2;
        FinishWizard2;
    end;

    local procedure UpdateEstimatedValues()
    var
        SalesCycleStage: Record "Sales Cycle Stage";
        SalesHeader: Record "Sales Header";
    begin
        if SalesCycleStage.Get("Sales Cycle Code", "Sales Cycle Stage") then begin
            "Estimated Close Date" := CalcDate(SalesCycleStage."Date Formula", "Date of Change");
            "Chances of Success %" := SalesCycleStage."Chances of Success %";
        end;
        if SalesHeader.Get(SalesHeader."Document Type"::Quote, Opp."Sales Document No.") then
            "Estimated Value (LCY)" := GetSalesDocValue(SalesHeader);

        Modify;
    end;
}

