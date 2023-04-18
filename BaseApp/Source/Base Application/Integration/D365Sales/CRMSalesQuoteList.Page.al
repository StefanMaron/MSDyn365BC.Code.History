page 5351 "CRM Sales Quote List"
{
    ApplicationArea = Suite;
    Caption = 'Sales Quotes - Microsoft Dynamics 365 Sales';
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "CRM Quote";
    SourceTableView = WHERE(StateCode = FILTER(Active | Won));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(StateCode; StateCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    OptionCaption = 'Draft,Active,Won,Closed';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(EffectiveFrom; EffectiveFrom)
                {
                    ApplicationArea = Suite;
                    Caption = 'Effective From';
                    ToolTip = 'Specifies which date the sales quote is valid from.';
                }
                field(EffectiveTo; EffectiveTo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Effective To';
                    ToolTip = 'Specifies which date the sales quote is valid to.';
                }
                field(ClosedOn; ClosedOn)
                {
                    ApplicationArea = Suite;
                    Caption = 'Closed On';
                    ToolTip = 'Specifies the date when quote was closed.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dynamics 365 Sales record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                action(CRMGoToQuote)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quote';
                    Image = CoupledQuote;
                    ToolTip = 'Open the selected Dynamics 365 Sales quote.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        HyperLink(CRMIntegrationManagement.GetCRMEntityUrlFromCRMID(DATABASE::"CRM Quote", QuoteId));
                    end;
                }
            }
            group(ActionGroupNAV)
            {
                Caption = 'Business Central';
                Visible = CRMIntegrationEnabled;
                action(ProcesseInNAV)
                {
                    ApplicationArea = Suite;
                    Caption = 'Process in Business Central';
                    Enabled = HasRecords and CRMIntegrationEnabled;
                    Image = New;
                    ToolTip = 'Create a sales quote in Business Central for the quote entity in Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        OrderSalesHeader: Record "Sales Header";
                        CRMQuoteToSalesQuote: Codeunit "CRM Quote to Sales Quote";
                        PageManagement: Codeunit "Page Management";
                    begin
                        if IsEmpty() then
                            exit;

                        if Coupled = 'Yes' then
                            Error(AlreadyProcessedErr);

                        if CRMQuoteToSalesQuote.ProcessInNAV(Rec, SalesHeader) then begin
                            Commit();
                            if SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.") then begin
                                OrderSalesHeader.SetRange("Quote No.", SalesHeader."No.");
                                if OrderSalesHeader.FindFirst() then
                                    PageManagement.PageRun(OrderSalesHeader)
                                else
                                    PageManagement.PageRun(SalesHeader)
                            end;
                        end;
                    end;
                }
                action(ShowOnlyUncoupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Hide Coupled Quotes';
                    Enabled = HasRecords;
                    Image = FilterLines;
                    ToolTip = 'Do not show coupled quotes.';

                    trigger OnAction()
                    begin
                        MarkedOnly(true);
                    end;
                }
                action(ShowAll)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Coupled Quotes';
                    Enabled = HasRecords;
                    Image = ClearFilter;
                    ToolTip = 'Show coupled quotes.';

                    trigger OnAction()
                    begin
                        MarkedOnly(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ProcesseInNAV_Promoted; ProcesseInNAV)
                {
                }
                group(Category_Synchronize)
                {
                    Caption = 'Synchronize';

                    actionref(CRMGoToQuote_Promoted; CRMGoToQuote)
                    {
                    }
                }
                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Dynamics 365 Sales', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        HasRecords := not IsNullGuid(QuoteId);
    end;

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        BlankGUID: Guid;
        Style: Integer;
    begin
        CRMIntegrationRecord.SetRange("CRM ID", QuoteId);
        if CRMIntegrationRecord.FindFirst() then begin
            if CurrentlyCoupledCRMQuote.QuoteId = QuoteId then
                Style := 1
            else
                if StateCode = StateCode::Active then
                    Style := 2
                else
                    if StateCode = StateCode::Won then
                        if CRMIntegrationRecord."Integration ID" = BlankGUID then
                            Style := 2
                        else
                            Style := 3;
        end else
            Style := 3;

        if Style = 1 then begin
            Coupled := 'Current';
            FirstColumnStyle := 'Strong';
            Mark(true);
        end else
            if Style = 2 then begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Mark(false);
            end else
                if Style = 3 then begin
                    Coupled := 'No';
                    FirstColumnStyle := 'None';
                    Mark(true);
                end;
    end;

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        CDSCompany: Record "CDS Company";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
    begin
        CRMIntegrationEnabled := CRMConnectionSetup.IsEnabled();
        FilterGroup(2);
        if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
            SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
        FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMQuote: Record "CRM Quote";
        CRMIntegrationEnabled: Boolean;
        HasRecords: Boolean;
        Coupled: Text;
        FirstColumnStyle: Text;
        AlreadyProcessedErr: Label 'The current record has already been processed in Business Central.';

    procedure SetCurrentlyCoupledCRMQuote(CRMQuote: Record "CRM Quote")
    begin
        CurrentlyCoupledCRMQuote := CRMQuote;
    end;
}

