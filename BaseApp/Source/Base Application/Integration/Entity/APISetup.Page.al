// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Integration.Graph;
using System;
using System.Environment;
using System.IO;
using System.Reflection;
using Microsoft.API.Upgrade;

page 5469 "API Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'API Setup';
    DelayedInsert = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "Config. Tmpl. Selection Rules";
    SourceTableView = sorting(Order)
                      order(ascending);
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Order"; Rec.Order)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the order of the entry.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table that the template applies to.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = All;
                    TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page),
                                                                         "Object Subtype" = const('API'));
                    ToolTip = 'Specifies the API web service page that the template applies to.';
                }
                field("Template Code"; Rec."Template Code")
                {
                    ApplicationArea = All;
                    TableRelation = "Config. Template Header".Code where("Table ID" = field("Table ID"));
                    ToolTip = 'Specifies the config template that should be applied';
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
                    ToolTip = 'Specifies the condition for when the config template should be applied.';

                    trigger OnAssistEdit()
                    begin
                        Rec.SetSelectionCriteria();
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
#if not CLEAN23
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
#endif
#if not CLEAN23
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
#endif
#if not CLEAN23
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
#endif
#if not CLEAN23
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
#endif
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
#if not CLEAN23
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
#endif
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
#if not CLEAN23
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
#endif
    }

    trigger OnAfterGetCurrRecord()
    begin
        ConditionsText := Rec.GetFiltersAsTextDisplay();
    end;

    trigger OnAfterGetRecord()
    begin
        ConditionsText := Rec.GetFiltersAsTextDisplay();
    end;

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Rec.SetAutoCalcFields("Selection Criteria");
        SetupActionVisible := EnvironmentInformation.IsOnPrem();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        MyCustomerAuditLoggerALHelper: DotNet CustomerAuditLoggerALHelper;
        MyALSecurityOperationResult: DotNet ALSecurityOperationResult;
        MyALAuditCategory: DotNet ALAuditCategory;
        APISetupRecordCreatedLbl: Label 'The new API Setup record Table ID %1, Template Code %2, Page ID %3 is created by the UserSecurityId %4.', Locked = true;
    begin
        MyCustomerAuditLoggerALHelper.LogAuditMessage(StrSubstNo(APISetupRecordCreatedLbl, Rec."Table ID", Rec."Template Code", Rec."Page ID", UserSecurityId()), MyALSecurityOperationResult::Success, MyALAuditCategory::ApplicationManagement, 4, 0);
    end;

    var
        SetupActionVisible: Boolean;
        ConditionsText: Text;
#if not CLEAN23
        ConfirmApiSetupQst: Label 'This action will populate the integration tables for all APIs and may take several minutes to complete. Do you want to continue?';
        AllRecordsHaveBeenUpdatedMsg: Label 'All records have been sucessfully updated.';
#endif
}

