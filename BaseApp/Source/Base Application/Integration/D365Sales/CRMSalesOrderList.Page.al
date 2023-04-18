page 5353 "CRM Sales Order List"
{
    ApplicationArea = Suite;
    Caption = 'Sales Orders - Microsoft Dynamics 365 Sales';
    CardPageID = "CRM Sales Order";
    Editable = false;
    PageType = List;
    SourceTable = "CRM Salesorder";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(OrderNumber; OrderNumber)
                {
                    ApplicationArea = Suite;
                    Caption = 'Order ID';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the record.';
                }
                field(TransactionCurrencyIdName; TransactionCurrencyIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Transaction Currency';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(PriceLevelIdName; PriceLevelIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Price List';
                    ToolTip = 'Specifies a list of your items and their prices, for example, to send to customers. You can create the list for specific customers, campaigns, currencies, or other criteria.';
                }
                field(IsPriceLocked; IsPriceLocked)
                {
                    ApplicationArea = Suite;
                    Caption = 'Prices Locked';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(StateCode; StateCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(StatusCode; StatusCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status Reason';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(RequestDeliveryBy; RequestDeliveryBy)
                {
                    ApplicationArea = Suite;
                    Caption = 'Requested Delivery Date';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(DateFulfilled; DateFulfilled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Date Fulfilled';
                    ToolTip = 'Specifies when the sales order was delivered.';
                }
                field(ShippingMethodCode; ShippingMethodCodeEnum)
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipping Method';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(PaymentTermsCode; PaymentTermsCodeEnum)
                {
                    ApplicationArea = Suite;
                    Caption = 'Payment Terms';
                    ToolTip = 'Specifies the payment terms that you select from on customer cards to define when the customer must pay, such as within 14 days.';
                }
                field(FreightTermsCode; FreightTermsCodeEnum)
                {
                    ApplicationArea = Suite;
                    Caption = 'Freight Terms';
                    ToolTip = 'Specifies the shipment method.';
                }
                field(BillTo_Composite; BillTo_Composite)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bill To Address';
                    ToolTip = 'Specifies the address that the invoice will be sent to.';
                }
                field(WillCall; WillCall)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(ShipTo_Composite; ShipTo_Composite)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ship To Address';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(OpportunityIdName; OpportunityIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunity';
                    ToolTip = 'Specifies the sales opportunity that is coupled to this Dynamics 365 Sales opportunity.';
                }
                field(QuoteIdName; QuoteIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quote';
                    ToolTip = 'Specifies information related to the Dynamics 365 Sales connection. ';
                }
                field(ContactIdName; ContactIdName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Contact';
                    ToolTip = 'Specifies the contact person at the customer.';
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
                action(CRMGoToSalesOrder)
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Order';
                    Enabled = HasRecords;
                    Image = CoupledOrder;
                    RunPageOnRec = true;
                    ToolTip = 'Open the coupled Dynamics 365 Sales sales order.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        if IsEmpty() then
                            exit;
                        HyperLink(CRMIntegrationManagement.GetCRMEntityUrlFromCRMID(DATABASE::"CRM Salesorder", SalesOrderId));
                    end;
                }
            }
            group(ActionGroupNAV)
            {
                Caption = 'Business Central';
                Visible = CRMIntegrationEnabled;
                action(CreateInNAV)
                {
                    ApplicationArea = Suite;
                    Caption = 'Create in Business Central';
                    Enabled = (BidirectionalSalesOrderIntEnabled) or (not BidirectionalSalesOrderIntEnabled and (HasRecords and CRMIntegrationEnabled));
                    Image = New;
                    ToolTip = 'Create a sales order in Dynamics 365 that is coupled to the Dynamics 365 Sales entity.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        CRMSalesorder: Record "CRM Salesorder";
                        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        if IsEmpty() then
                            exit;

                        if BidirectionalSalesOrderIntEnabled then begin
                            CurrPage.SetSelectionFilter(CRMSalesOrder);
                            CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(CRMSalesorder);
                        end else begin
                            Session.LogMessage('0000DFA', StrSubstNo(StartingToCreateSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), Rec.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                            if CRMSalesOrderToSalesOrder.CreateInNAV(Rec, SalesHeader) then begin
                                Session.LogMessage('0000DFB', StrSubstNo(CommittingAfterCreateSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), Rec.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                                Commit();
                                PAGE.RunModal(PAGE::"Sales Order", SalesHeader);
                            end;
                        end;
                    end;
                }
                action(ShowOnlyUncoupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Hide Coupled Sales Orders';
                    Image = FilterLines;
                    ToolTip = 'Do not show coupled sales orders.';
                    Visible = BidirectionalSalesOrderIntEnabled;

                    trigger OnAction()
                    begin
                        MarkedOnly(true);
                    end;
                }
                action(ShowAll)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Coupled Sales Orders';
                    Image = ClearFilter;
                    ToolTip = 'Show coupled sales orders.';
                    Visible = BidirectionalSalesOrderIntEnabled;

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
                Caption = 'Process';

                actionref(CreateInNAV_Promoted; CreateInNAV)
                {
                }
                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            if CRMIntegrationRecord.FindRecordIDFromID(SalesOrderId, Database::"Sales Header", RecordID) then
                if CurrentlyCoupledCRMSalesorder.SalesOrderId = SalesOrderId then begin
                    Coupled := 'Current';
                    FirstColumnStyle := 'Strong';
                    Mark(true);
                end else begin
                    Coupled := 'Yes';
                    FirstColumnStyle := 'Subordinate';
                    Mark(false);
                end
            else begin
                Coupled := 'No';
                FirstColumnStyle := 'None';
                Mark(true);
            end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        HasRecords := not IsNullGuid(SalesOrderId);
    end;

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
    end;

    trigger OnOpenPage()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        BidirectionalSalesOrderIntEnabled := CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled();
        if BidirectionalSalesOrderIntEnabled then begin
            FilterGroup(4);
            SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Salesorder"));
            FilterGroup(0);
        end else begin
            SetRange(StateCode, StateCode::Submitted);
            SetFilter(LastBackofficeSubmit, '%1|%2', 0D, DMY2Date(1, 1, 1900));
        end;
        CRMIntegrationEnabled := CRMConnectionSetup.IsEnabled();
    end;

    var
        CurrentlyCoupledCRMSalesorder: Record "CRM Salesorder";
        CRMProductName: Codeunit "CRM Product Name";
        CRMIntegrationEnabled: Boolean;
        BidirectionalSalesOrderIntEnabled: Boolean;
        HasRecords: Boolean;
        Coupled: Text;
        FirstColumnStyle: Text;
        CrmTelemetryCategoryTok: Label 'AL CRM Integration', Locked = true;
        StartingToCreateSalesOrderTelemetryMsg: Label 'Starting to create sales order from %1 order %2 via a page action.', Locked = true;
        CommittingAfterCreateSalesOrderTelemetryMsg: Label 'Committing after processing %1 order %2 via a page action.', Locked = true;

    procedure SetCurrentlyCoupledCRMSalesorder(CRMSalesorder: Record "CRM Salesorder")
    begin
        CurrentlyCoupledCRMSalesorder := CRMSalesorder;
    end;
}

