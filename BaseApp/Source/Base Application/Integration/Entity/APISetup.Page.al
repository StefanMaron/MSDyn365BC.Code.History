page 5469 "API Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'API Setup';
    DelayedInsert = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "Config. Tmpl. Selection Rules";
    SourceTableView = SORTING(Order)
                      ORDER(Ascending);
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Order"; Order)
                {
                    ApplicationArea = All;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table that the template applies to.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = All;
                    TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Page),
                                                                         "Object Subtype" = CONST('API'));
                    ToolTip = 'Specifies the API web service page that the template applies to.';
                }
                field("Template Code"; Rec."Template Code")
                {
                    ApplicationArea = All;
                    TableRelation = "Config. Template Header".Code WHERE("Table ID" = FIELD("Table ID"));
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the API template selection.';
                }
                field("<Template Code>"; ConditionsText)
                {
                    ApplicationArea = All;
                    Caption = 'Conditions';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        SetSelectionCriteria();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(IntegrateAPIs)
            {
                ApplicationArea = All;
                Caption = 'Integrate APIs';
                Image = Setup;
                Visible = SetupActionVisible;
                ObsoleteReason = 'This functionality will be removed because APIs are refactored in Integration Management to not use integration records.';
                ObsoleteState = Pending;
                ObsoleteTag = '17.0';
                ToolTip = 'Integrates records to the associated integration tables';

                trigger OnAction()
                begin
                    if Confirm(ConfirmApiSetupQst) then
                        CODEUNIT.Run(CODEUNIT::"Graph Mgt - General Tools");
                end;
            }

            action(FixSalesAndPurchaseApiRecords)
            {
                ApplicationArea = All;
                Caption = 'Fix Sales and Purchase API Records';
                Image = Setup;
                ObsoleteReason = 'This action will be removed together with the upgrade code.';
                ObsoleteState = Pending;
                ObsoleteTag = '18.0';
                ToolTip = 'Update records that are used by the salesInvoices, salesOrders, salesCreditMemos, and purchaseInvoices APIs.';

                trigger OnAction()
                var
                    SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
                    GraphMgtSalesOrderBuffer: Codeunit "Graph Mgt - Sales Order Buffer";
                    PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
                begin
                    SalesInvoiceAggregator.FixInvoicesCreatedFromOrders();
                    PurchInvAggregator.FixInvoicesCreatedFromOrders();
                    GraphMgtSalesOrderBuffer.DeleteOrphanedRecords();
                    Message(AllRecordsHaveBeenUpdatedMsg);
                end;
            }

            action(FixSalesShipmentLine)
            {
                ApplicationArea = All;
                Caption = 'Fix Sales Shipment Line API Records';
                Image = Setup;
                ObsoleteReason = 'This action will be removed together with the upgrade code.';
                ObsoleteState = Pending;
                ObsoleteTag = '18.0';
                ToolTip = 'Updates records that are used by the salesShipmentLines API.';

                trigger OnAction()
                var
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Fix Sales Shipment Line");
                end;
            }

            action(FixPurchRcptLine)
            {
                ApplicationArea = All;
                Caption = 'Fix Purchase Recepit Line API Records';
                Image = Setup;
                ObsoleteReason = 'This action will be removed together with the upgrade code.';
                ObsoleteState = Pending;
                ObsoleteTag = '18.0';
                ToolTip = 'Updates records that are used by the purchaseReceiptLines API.';

                trigger OnAction()
                var
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Fix Purch Rcpt Line");
                end;
            }

            action(FixPurchOrder)
            {
                ApplicationArea = All;
                Caption = 'Fix Purchase Order API Records';
                Image = Setup;
                ToolTip = 'Updates records that are used by the purchaseOrders API';
                Visible = false;

                trigger OnAction()
                var
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Fix Purchase Order");
                end;
            }

            action(FixSalesCrMemoReasonCode)
            {
                ApplicationArea = All;
                Caption = 'Fix Sales Credit Memo API Records Reason Codes';
                Image = Setup;
                ToolTip = 'Updates reason codes of the records that are used by the salesCreditMemos API';
                ObsoleteReason = 'This action will be removed together with the upgrade code.';
                ObsoleteState = Pending;
                ObsoleteTag = '19.0';

                trigger OnAction()
                var
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Fix Sales Cr. Memo");
                end;
            }
            action(FixSalesInvoiceShortcutDimension)
            {
                ApplicationArea = All;
                Caption = 'Fix document API records Shortcut Dimensions';
                Image = Setup;
                ToolTip = 'Updates shortcut dimension codes of the records that are used by the salesInvoices, salesOrders, salesCreditMemos, salesQuotes, purchaseOrders and purchaseInvoices API';
                ObsoleteReason = 'This action will be removed together with the upgrade code.';
                ObsoleteState = Pending;
                ObsoleteTag = '20.0';

                trigger OnAction()
                var
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Fix Document Shortcut Dim.");
                end;
            }
            action(FixItemCategoryCode)
            {
                ApplicationArea = All;
                Caption = 'Fix Item Category Codes of Items';
                Image = Setup;
                ToolTip = 'Updates the item category codes of the item records';

                trigger OnAction()
                var
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Fix Item Cat. Code");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(IntegrateAPIs_Promoted; IntegrateAPIs)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality will be removed because APIs are refactored in Integration Management to not use integration records.';
                    ObsoleteTag = '17.0';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ConditionsText := GetFiltersAsTextDisplay();
    end;

    trigger OnAfterGetRecord()
    begin
        ConditionsText := GetFiltersAsTextDisplay();
    end;

    trigger OnOpenPage()
    var
        EnviromentInformation: Codeunit "Environment Information";
    begin
        SetAutoCalcFields("Selection Criteria");
        SetupActionVisible := EnviromentInformation.IsOnPrem();
    end;

    var
        SetupActionVisible: Boolean;
        ConditionsText: Text;
        ConfirmApiSetupQst: Label 'This action will populate the integration tables for all APIs and may take several minutes to complete. Do you want to continue?';
        AllRecordsHaveBeenUpdatedMsg: Label 'All records have been sucessfully updated.';
}

