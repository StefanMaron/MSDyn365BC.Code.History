page 7016 "Sales Price List"
{
    Caption = 'Sales Price List';
    PageType = ListPlus;
    PromotedActionCategories = 'New,Process,Report,Navigate';
    RefreshOnActivate = true;
    SourceTable = "Price List Header";
    SourceTableView = WHERE("Price Type" = CONST(Sale));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code of the price list.';
                    Editable = PriceListIsEditable;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEditCode(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ShowMandatory = true;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(SourceType; CustomerSourceType)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Applies-to Type';
                    Editable = PriceListIsEditable;
                    Visible = IsCustomerGroup;
                    ToolTip = 'Specifies the customer source type of the price list.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(CustomerSourceType.AsInteger());
                    end;
                }
                field(JobSourceType; JobSourceType)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Applies-to Type';
                    Editable = PriceListIsEditable;
                    Visible = IsJobGroup;
                    ToolTip = 'Specifies the job source type of the price list.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(JobSourceType.AsInteger());
                    end;
                }
                field(SourceNo; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Enabled = SourceNoEnabled;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the number of the source for the price list.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                group(Tax)
                {
                    Caption = 'Tax';
                    field(VATBusPostingGrPrice; Rec."VAT Bus. Posting Gr. (Price)")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the default VAT business posting group code.';
                    }
                    field(PriceIncludesVAT; Rec."Price Includes VAT")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the if prices include VAT.';
                    }
                }
                group(View)
                {
                    Caption = 'View';
                    Visible = ViewGroupIsVisible;
                    field(AmountType; ViewAmountType)
                    {
                        ApplicationArea = All;
                        Caption = 'View Columns for';
                        ToolTip = 'Specifies the amount type filter that defines the columns shown in the price list lines.';
                        trigger OnValidate()
                        begin
                            CurrPage.Lines.Page.SetSubFormLinkFilter(ViewAmountType);
                        end;
                    }
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the price list.';

                    trigger OnValidate()
                    begin
                        PriceListIsEditable := Rec.IsEditable();
                    end;
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the currency code of the price list.';
                }
                field(StartingDate; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the starting date of the price list.';
                }
                field(EndingDate; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the ending date of the price list.';
                }
                group(LineDefaults)
                {
                    Caption = 'Line Defaults';
                    field(AllowInvoiceDisc; Rec."Allow Invoice Disc.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the if the invoice discount allowed. This value can be changed in the lines.';
                    }
                    field(AllowLineDisc; Rec."Allow Line Disc.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the if the line discount allowed. This value can be changed in the lines.';
                    }
                }
            }
            part(Lines; "Price List Lines")
            {
                ApplicationArea = Basic, Suite;
                Editable = PriceListIsEditable;
                SubPageLink = "Price List Code" = FIELD(Code);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SuggestLines)
            {
                ApplicationArea = Basic, Suite;
                Enabled = PriceListIsEditable;
                Ellipsis = true;
                Image = SuggestItemPrice;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Suggest Lines';
                ToolTip = 'Creates the sales price list lines based on the unit price in the product cards, like item or resource. Change the price list status to ''Draft'' to run this action.';

                trigger OnAction()
                var
                    PriceListManagement: Codeunit "Price List Management";
                begin
                    PriceListManagement.AddLines(Rec);
                end;
            }
            action(CopyLines)
            {
                ApplicationArea = Basic, Suite;
                Enabled = PriceListIsEditable;
                Ellipsis = true;
                Image = CopyWorksheet;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Copy Lines';
                ToolTip = 'Copies the lines from the existing price list. New prices can be adjusted by a factor and rounded differently. Change the price list status to ''Draft'' to run this action.';

                trigger OnAction()
                var
                    PriceListManagement: Codeunit "Price List Management";
                begin
                    PriceListManagement.CopyLines(Rec);
                end;
            }
        }
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                action(CRMGoToPricelevel)
                {
                    ApplicationArea = Suite;
                    Caption = 'Pricelevel';
                    Image = CoupledItem;
                    ToolTip = 'View price information introduced through synchronization with Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(Rec.RecordId);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            PriceListHeader: Record "Price List Header";
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(PriceListHeader);
                            RecRef.GetTable(PriceListHeader);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the price list header table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
        }
    }

    trigger OnInit()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        PriceCalculationMgt.TestIsEnabled();
    end;

    trigger OnOpenPage()
    begin
        UpdateSourceType();
        PriceUXManagement.GetFirstSourceFromFilter(Rec, OriginalPriceSource, DefaultSourceType);
        SetSourceNoEnabled();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
        PriceListIsEditable := Rec.IsEditable();
        UpdateSourceType();
        ViewAmountType := Rec."Amount Type";
        if ViewAmountType = ViewAmountType::Any then
            ViewGroupIsVisible := true
        else
            ViewGroupIsVisible := not PriceUXManagement.IsAmountTypeFiltered(Rec);

        CurrPage.Lines.Page.SetPriceType(Rec."Price Type");
        CurrPage.Lines.Page.SetSubFormLinkFilter(ViewAmountType);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DefaultAmountType: Enum "Price Amount Type";
    begin
        Rec.CopyFrom(OriginalPriceSource);
        UpdateSourceType();
        if PriceUXManagement.IsAmountTypeFiltered(Rec, DefaultAmountType) then
            Rec."Amount Type" := DefaultAmountType;
        SetSourceNoEnabled();
    end;

    trigger OnClosePage()
    begin
        if Rec.Code <> '' then
            Rec.UpdateAmountType();
    end;

    local procedure UpdateSourceType()
    begin
        case Rec."Source Group" of
            Rec."Source Group"::Customer:
                begin
                    IsCustomerGroup := true;
                    CustomerSourceType := "Sales Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                    DefaultSourceType := Rec."Source Type"::"All Customers";
                end;
            Rec."Source Group"::Job:
                begin
                    IsJobGroup := true;
                    JobSourceType := "Job Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                    DefaultSourceType := Rec."Source Type"::"All Jobs";
                end;
        end;
    end;

    var
        OriginalPriceSource: Record "Price Source";
        PriceUXManagement: Codeunit "Price UX Management";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        DefaultSourceType: Enum "Price Source Type";
        JobSourceType: Enum "Job Price Source Type";
        CustomerSourceType: Enum "Sales Price Source Type";
        ViewAmountType: Enum "Price Amount Type";
        IsCustomerGroup: Boolean;
        IsJobGroup: Boolean;
        SourceNoEnabled: Boolean;
        PriceListIsEditable: Boolean;
        ViewGroupIsVisible: Boolean;

    local procedure SetSourceNoEnabled()
    begin
        SourceNoEnabled := Rec.IsSourceNoAllowed();
    end;

    local procedure ValidateSourceType(SourceType: Integer)
    begin
        Rec.Validate("Source Type", SourceType);
        SetSourceNoEnabled();
        CurrPage.SaveRecord();
    end;
}