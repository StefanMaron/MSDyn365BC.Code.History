page 7015 "Sales Price Lists"
{
    Caption = 'Sales Price Lists';
    CardPageID = "Sales Price List";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report';
    QueryCategory = 'Sales Price Lists';
    RefreshOnActivate = true;
    SourceTable = "Price List Header";
    SourceTableView = WHERE("Source Group" = CONST(Customer), "Price Type" = CONST(Sale));
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Caption = 'Code';
                    ToolTip = 'Specifies the unique identifier of the price list.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the price list is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';
                }
                field("Allow Updating Defaults"; Rec."Allow Updating Defaults")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Multi-Type Price List';
                    ToolTip = 'Specifies whether users can change the values in the fields on the price list line that contain default values from the header.';
                }
                field(Defines; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Defines';
                    ToolTip = 'Specifies whether the price list defines prices, discounts, or both.';
                }
                field("Currency Code"; CurrRec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency';
                    ToolTip = 'Specifies the currency that is used on the price list.';
                }
                field(SourceGroup; Rec."Source Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Group';
                    Visible = false;
                    ToolTip = 'Specifies whether the prices come from groups of customers, vendors or jobs.';
                }
                field(SourceType; CurrRec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Type';
                    ToolTip = 'Specifies the source type of the price list.';
                }
                field(SourceNo; CurrRec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to No.';
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field("Starting Date"; CurrRec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; CurrRec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date when the sales price agreement ends.';
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
                Enabled = CRMIntegrationAllowed;
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
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureDisabled();
    end;

    trigger OnAfterGetRecord()
    begin
        CurrRec := Rec;
        CurrRec.BlankDefaults();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrRec := Rec;
        CurrRec.BlankDefaults();
        CRMIntegrationAllowed := Rec.IsCRMIntegrationAllowed(StatusActiveFilterApplied);
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        if CRMIntegrationEnabled then
            if IntegrationTableMapping.Get('PLHEADER-PRICE') then
                StatusActiveFilterApplied := true;
    end;

    var
        CurrRec: Record "Price List Header";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationAllowed: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        StatusActiveFilterApplied: Boolean;

    procedure SetRecordFilter(var PriceListHeader: Record "Price List Header")
    begin
        Rec.FilterGroup := 2;
        Rec.CopyFilters(PriceListHeader);
        Rec.SetRange("Source Group", Rec."Source Group"::Customer);
        Rec.SetRange("Price Type", Rec."Price Type"::Sale);
        Rec.FilterGroup := 0;
    end;

    procedure SetSource(PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    var
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceUXManagement.SetPriceListsFilters(Rec, PriceSourceList, AmountType);
    end;

    procedure SetAsset(PriceAsset: Record "Price Asset"; AmountType: Enum "Price Amount Type")
    var
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceUXManagement.SetPriceListsFilters(Rec, PriceAsset."Price Type", AmountType);
    end;
}
